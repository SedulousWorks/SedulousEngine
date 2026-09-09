using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Scene;

namespace Sedulous.Net.Replication;

/// Server authoritative state replication.
///
/// The FULL snapshot, being every networked entity's every replicated component, is the
/// primitive that per peer delta, late join and relevancy all build on.
///
/// A snapshot is: VarU32 entityCount, then per entity { U32 networkId, U8 flags, [Guid prefab
/// if spawn], VarU32 componentCount, then per component { string SerializationTypeId, VarU32
/// blobBytes, blob } }. The per component length prefix is what lets a peer that lacks a
/// component type SKIP it rather than desync its reader, which is what makes the format
/// forward compatible.
class StateReplication : IReplicationModel
{
	/// The client's prefab spawn seam: resolve a network spawned prefab into a local entity.
	/// Unset, or a nil prefab id, creates a bare entity instead: enough to round trip state,
	/// but with no prefab structure or visuals.
	public typealias SpawnHandler = delegate EntityHandle(Scene scene, Guid prefab, NetworkId id);

	/// Per peer relevancy: true if `id` should be replicated to `peerId`.
	///
	/// Fog of war is SECURITY, not only bandwidth. Unset means everything is relevant to
	/// everyone. When an entity leaves a peer's relevance its next delta actively REMOVES it
	/// on that client, so hidden state cannot be read out of the client's memory: the server
	/// never sends what a peer may not see.
	public typealias RelevanceFn = delegate bool(uint32 peerId, NetworkId id, EntityHandle entity);

	private class ComponentBaseline
	{
		public uint32 TypeHash;
		public uint8[] Blob ~ delete _;
	}

	private class EntityBaseline
	{
		public List<ComponentBaseline> Components = new .() ~ DeleteContainerAndItems!(_);
	}

	private class PeerBaseline
	{
		public Dictionary<uint32, EntityBaseline> Entities = new .() ~ DeleteDictionaryAndValues!(_);
	}

	/// One component's changed bytes, waiting to be written.
	private class DeltaComponent
	{
		public String TypeId = new .() ~ delete _;
		public List<uint8> Blob = new .() ~ delete _;
	}

	/// One entity's delta: a change, a spawn, or a removal.
	private class DeltaEntry
	{
		public uint32 Id;
		public bool Removed;
		public bool Spawn;
		public Guid Prefab;
		public List<DeltaComponent> Components = new .() ~ DeleteContainerAndItems!(_);

		public this(uint32 id, bool removed, bool spawn, Guid prefab)
		{
			Id = id;
			Removed = removed;
			Spawn = spawn;
			Prefab = prefab;
		}

		public void Add(StringView typeId, Span<uint8> blob)
		{
			let record = new DeltaComponent();
			record.TypeId.Set(typeId);
			record.Blob.AddRange(blob);
			Components.Add(record);
		}
	}

	/// The server side monotonic allocator. Nought stays "unassigned".
	private uint32 mNextNetworkId = 0;
	private Dictionary<uint32, EntityHandle> mNetIdToEntity = new .() ~ delete _;
	private Dictionary<uint32, PeerBaseline> mPeerBaselines = new .() ~ DeleteDictionaryAndValues!(_);
	private SpawnHandler mSpawnHandler ~ delete _;
	private RelevanceFn mRelevance ~ delete _;

	/// OWNERSHIP transfers; setting a second one deletes the first.
	public void SetSpawnHandler(SpawnHandler handler)
	{
		delete mSpawnHandler;
		mSpawnHandler = handler;
	}

	/// Whether a spawn handler is installed. The network controller re-applies its injected
	/// resolver to each fresh endpoint, and this lets that wiring be asserted.
	public bool HasSpawnHandler => mSpawnHandler != null;

	/// OWNERSHIP transfers; setting a second one deletes the first.
	public void SetRelevance(RelevanceFn relevance)
	{
		delete mRelevance;
		mRelevance = relevance;
	}

	public int NetworkedCount => mNetIdToEntity.Count;

	/// The local entity for a NetworkId, or an invalid handle.
	public EntityHandle FindEntity(NetworkId id)
	{
		if (mNetIdToEntity.TryGetValue(id.Value, let entity))
			return entity;
		return EntityHandle.Invalid;
	}

	// ---- Identity ----------------------------------------------------------------------------

	/// Server: give an entity a NetworkId, adding the NetworkComponent if absent. A re
	/// registered entity KEEPS its id. `prefab` records the source prefab so a client can
	/// network spawn it.
	public NetworkId AssignNetworkId(Scene scene, EntityHandle entity, Guid prefab = default)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
			return NetworkId.Invalid;

		var component = manager.Get(entity);
		if (component == null)
			component = manager.Add(entity);

		if (!component.Id.IsValid)
			component.Id = .(++mNextNetworkId);
		if (prefab.IsSet)
			component.Prefab = prefab;

		mNetIdToEntity[component.Id.Value] = entity;
		return component.Id;
	}

	/// Server: give every authored networked entity a NetworkId derived from its authored
	/// Guid, and register the mapping.
	///
	/// A designer just adds a NetworkComponent in the editor and the server replicates the
	/// entity on start, with no hand authored ids. Idempotent.
	public void AssignSceneNetworkIds(Scene scene)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
			return;

		// Safe during ForEach: only existing components are mutated, so the pool does not
		// change shape underneath the walk.
		manager.ForEach(scope [&](component, entity) =>
			{
				if (!component.Id.IsValid)
					component.Id = ReplicationWire.DeterministicNetworkId(scene.GetEntityId(entity));

				mNetIdToEntity[component.Id.Value] = entity;
				// Keep freshly minted ids clear of the derived ones.
				if (component.Id.Value > mNextNetworkId)
					mNextNetworkId = component.Id.Value;
			});
	}

	/// Client: compute the SAME Guid derived id the server did, so incoming replication
	/// UPDATES the client's own authored entity instead of creating a duplicate beside it.
	public void RegisterAuthoredEntities(Scene scene)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
			return;

		manager.ForEach(scope [&](component, entity) =>
			{
				if (!component.Id.IsValid)
					component.Id = ReplicationWire.DeterministicNetworkId(scene.GetEntityId(entity));
				mNetIdToEntity[component.Id.Value] = entity;
			});
	}

	// ---- Capture -----------------------------------------------------------------------------

	public void CaptureSnapshot(Scene scene, BitWriter outWriter)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
		{
			outWriter.WriteVarU32(0);
			return;
		}

		let ids = scope List<uint32>();
		let prefabs = scope List<Guid>();
		let handles = scope List<EntityHandle>();
		manager.ForEach(scope [&](component, entity) =>
			{
				if (!component.Id.IsValid)
					return;
				ids.Add(component.Id.Value);
				prefabs.Add(component.Prefab);
				handles.Add(entity);
			});

		outWriter.WriteVarU32((uint32)ids.Count);
		let replicating = scope List<ComponentManagerBase>();

		for (int i < ids.Count)
		{
			let entity = handles[i];
			outWriter.WriteU32(ids[i]);
			// A full snapshot is "everything, as a spawn": a late joining client reconstructs
			// each entity from its prefab id, then applies the state on top.
			outWriter.WriteU8(ReplicationWire.cFlagSpawn);
			ReplicationWire.WriteGuid(outWriter, prefabs[i]);

			replicating.Clear();
			CollectReplicatingManagers(scene, entity, replicating);

			outWriter.WriteVarU32((uint32)replicating.Count);
			for (let componentManager in replicating)
			{
				let fields = scope BitWriter();
				FieldCodec.WriteState(fields, componentManager.ComponentType,
					componentManager.GetComponentAddress(entity));

				// Length prefixed so a peer lacking the type can skip the blob whole.
				let blob = fields.Data;
				ReplicationWire.WriteString(outWriter, componentManager.SerializationTypeId);
				outWriter.WriteVarU32((uint32)blob.Length);
				outWriter.WriteBytes(blob);
			}
		}
	}

	/// Server: write the DELTA for one peer, being only what changed since that peer's last
	/// delta plus what was removed. Returns the entry count, nought meaning nothing changed.
	///
	/// The baseline is "what was last sent to this peer", so this rides RELIABLE ORDERED
	/// delivery. Send the output reliably or the baseline diverges from what the peer holds.
	public int CaptureDelta(Scene scene, uint32 peerId, BitWriter outWriter)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
		{
			outWriter.WriteVarU32(0);
			return 0;
		}

		PeerBaseline baseline;
		if (!mPeerBaselines.TryGetValue(peerId, out baseline))
		{
			baseline = new PeerBaseline();
			mPeerBaselines[peerId] = baseline;
		}

		let entries = scope List<DeltaEntry>();
		defer { ClearAndDeleteItems!(entries); }
		// Every value here is TRANSFERRED to the peer baseline below, so this owns nothing
		// by the time it goes out of scope.
		let nextBaseline = scope Dictionary<uint32, EntityBaseline>();
		/// Every present networked id, so a despawn can be told from an irrelevancy.
		let present = scope HashSet<uint32>();

		manager.ForEach(scope [&](component, entity) =>
			{
				if (!component.Id.IsValid)
					return;

				let networkId = component.Id.Value;
				present.Add(networkId);
				baseline.Entities.TryGetValue(networkId, let previous);

				// Relevancy: an irrelevant entity is NEVER sent, and if the peer currently
				// holds it, it is REMOVED. Leaving it in place would leave hidden state in a
				// client's memory for anyone willing to read it.
				if ((mRelevance != null) && !mRelevance(peerId, component.Id, entity))
				{
					if (previous != null)
						entries.Add(new DeltaEntry(networkId, true, false, default));
					// Deliberately NOT added to the next baseline: the peer must not know it.
					return;
				}

				let entry = new DeltaEntry(networkId, false, previous == null, component.Prefab);
				let nextEntity = new EntityBaseline();

				let replicating = scope List<ComponentManagerBase>();
				CollectReplicatingManagers(scene, entity, replicating);

				for (let componentManager in replicating)
				{
					let fields = scope BitWriter();
					FieldCodec.WriteState(fields, componentManager.ComponentType,
						componentManager.GetComponentAddress(entity));
					let blob = fields.Data;
					let typeId = componentManager.SerializationTypeId;
					let typeHash = ReplicationWire.HashTypeId(typeId);

					uint8[] sent = null;
					if (previous != null)
					{
						for (let record in previous.Components)
						{
							if (record.TypeHash == typeHash)
							{
								sent = record.Blob;
								break;
							}
						}
					}

					// Changed if the component is new to this peer, or its bytes differ from
					// what was last sent.
					if ((sent == null) || !BlobsEqual(sent, blob))
						entry.Add(typeId, blob);

					let record = new ComponentBaseline();
					record.TypeHash = typeHash;
					record.Blob = CopyBlob(blob);
					nextEntity.Components.Add(record);
				}

				// A new entity is a spawn even with nothing changed, because the peer has
				// never heard of it.
				if ((previous == null) || !entry.Components.IsEmpty)
					entries.Add(entry);
				else
					delete entry;

				nextBaseline[networkId] = nextEntity;
			});

		// True despawns: baseline entities no longer PRESENT in the scene. A relevance removal
		// was already emitted above and its entity is still present, so it is not repeated.
		for (let pair in baseline.Entities)
		{
			if (!present.Contains(pair.key))
				entries.Add(new DeltaEntry(pair.key, true, false, default));
		}

		outWriter.WriteVarU32((uint32)entries.Count);
		for (let entry in entries)
		{
			outWriter.WriteU32(entry.Id);
			var flags = (uint8)0;
			if (entry.Removed)
				flags |= ReplicationWire.cFlagRemoved;
			if (entry.Spawn)
				flags |= ReplicationWire.cFlagSpawn;
			outWriter.WriteU8(flags);

			if (entry.Removed)
				continue;
			if (entry.Spawn)
				ReplicationWire.WriteGuid(outWriter, entry.Prefab);

			outWriter.WriteVarU32((uint32)entry.Components.Count);
			for (let record in entry.Components)
			{
				ReplicationWire.WriteString(outWriter, record.TypeId);
				outWriter.WriteVarU32((uint32)record.Blob.Count);
				outWriter.WriteBytes(.(record.Blob.Ptr, record.Blob.Count));
			}
		}

		// Commit last sent. Reliable ordered delivery is what makes this safe to assume.
		DeleteDictionaryAndValues!(baseline.Entities);
		baseline.Entities = new .();
		for (let pair in nextBaseline)
			baseline.Entities[pair.key] = pair.value;

		return entries.Count;
	}

	/// Drops a peer's baseline on disconnect. Its next CaptureDelta re-sends everything as new.
	public void ForgetPeer(uint32 peerId)
	{
		if (mPeerBaselines.GetAndRemove(peerId) case .Ok(let entry))
			delete entry.value;
	}

	// ---- Apply -------------------------------------------------------------------------------

	/// Both the full snapshot and the per peer delta share the entry payload. The only
	/// difference is what the CAPTURE side emits, all-spawn-and-full against changed-only, so
	/// apply is one path.
	public void ApplySnapshot(Scene scene, BitReader reader) => ApplyEntries(scene, reader, null, 0.0);

	public void ApplyDelta(Scene scene, BitReader reader) => ApplyEntries(scene, reader, null, 0.0);

	/// As ApplyDelta, but also RECORDS each applied interpolatable component at `timestampMs`,
	/// being the server's capture time, for smooth playback. Components with no interpolatable
	/// field are applied directly rather than buffered.
	public void ApplyDelta(Scene scene, BitReader reader, InterpolationBuffer interpolation,
		double timestampMs) => ApplyEntries(scene, reader, interpolation, timestampMs);

	private void ApplyEntries(Scene scene, BitReader reader, InterpolationBuffer interpolation,
		double timestampMs)
	{
		let entryCount = reader.ReadVarU32();
		for (uint32 i = 0; (i < entryCount) && reader.Ok; i++)
		{
			let networkId = reader.ReadU32();
			let flags = reader.ReadU8();
			if (!reader.Ok)
				break;

			if ((flags & ReplicationWire.cFlagRemoved) != 0)
			{
				if (mNetIdToEntity.TryGetValue(networkId, let handle))
				{
					if (scene.IsValid(handle))
						scene.DestroyEntity(handle);
				}
				mNetIdToEntity.Remove(networkId);
				if (interpolation != null)
					interpolation.Forget(.(networkId));
				continue;
			}

			let spawn = (flags & ReplicationWire.cFlagSpawn) != 0;
			let prefab = spawn ? ReplicationWire.ReadGuid(reader) : Guid();
			if (!reader.Ok)
				break;

			let entity = FindOrCreateEntity(scene, networkId, prefab, spawn);
			let componentCount = reader.ReadVarU32();
			ApplyComponentRecords(scene, entity, .(networkId), componentCount, reader,
				interpolation, timestampMs);
		}
	}

	private void ApplyComponentRecords(Scene scene, EntityHandle entity, NetworkId id,
		uint32 count, BitReader reader, InterpolationBuffer interpolation, double timestampMs)
	{
		let typeId = scope String();
		for (uint32 i = 0; (i < count) && reader.Ok; i++)
		{
			ReplicationWire.ReadString(reader, typeId);
			let blobBytes = reader.ReadVarU32();
			let blob = scope List<uint8>();
			blob.Resize((int)blobBytes);
			if (blobBytes > 0)
				reader.ReadBytes(.(blob.Ptr, blob.Count));
			if (!reader.Ok)
				break;

			let manager = scene.FindManagerBySerializationId(typeId);
			// Unknown on this peer. The blob has already been consumed, so the reader stays
			// aligned and the rest of the entry still applies.
			if (manager == null)
				continue;

			if (!manager.HasComponent(entity))
				manager.AddDefaultComponent(entity);

			let address = manager.GetComponentAddress(entity);
			if (address == null)
				continue;

			let fields = scope BitReader(.(blob.Ptr, blob.Count));
			FieldCodec.ReadState(fields, manager.ComponentType, address);

			// Buffered for smooth playback only when there is something to smooth; the rest
			// stay directly applied.
			if ((interpolation != null)
				&& ReplicatedLayout.HasInterpolatableField(manager.ComponentType))
			{
				interpolation.Record(id, ReplicationWire.HashTypeId(typeId), timestampMs,
					manager.ComponentType, address);
			}
		}
	}

	/// Client, per render frame: write each networked interpolatable component's value at
	/// `renderTimeMs`, being synced network time minus the interpolation delay, from the
	/// buffer onto the live scene.
	public void SampleInterpolation(Scene scene, InterpolationBuffer interpolation,
		double renderTimeMs)
	{
		let manager = scene.GetSystem<NetworkComponentManager>();
		if (manager == null)
			return;

		manager.ForEach(scope [&](component, entity) =>
			{
				// Inactive: no sampling, because the state is frozen.
				if (!component.Id.IsValid || !scene.IsEffectivelyActive(entity))
					return;

				let id = component.Id;
				scene.ForEachManager(scope [&](componentManager) =>
					{
						if (!componentManager.IsSerializable
							|| componentManager.SerializationTypeId.IsEmpty)
							return;
						if (!componentManager.HasComponent(entity))
							return;
						if (!ReplicatedLayout.HasInterpolatableField(componentManager.ComponentType))
							return;

						interpolation.Sample(id,
							ReplicationWire.HashTypeId(componentManager.SerializationTypeId),
							renderTimeMs, componentManager.ComponentType,
							componentManager.GetComponentAddress(entity));
					});
			});
	}

	// ---- Helpers -----------------------------------------------------------------------------

	/// Client: the entity for this id. The first sight of a spawn record carrying a prefab id
	/// routes through the spawn handler; otherwise a bare tagged entity is created.
	private EntityHandle FindOrCreateEntity(Scene scene, uint32 networkId, Guid prefab, bool spawn)
	{
		if (mNetIdToEntity.TryGetValue(networkId, let found))
		{
			if (scene.IsValid(found))
				return found;
		}

		var entity = EntityHandle.Invalid;
		if (spawn && prefab.IsSet && (mSpawnHandler != null))
			entity = mSpawnHandler(scene, prefab, .(networkId));
		if (!scene.IsValid(entity))
			entity = scene.CreateEntity();

		if (let manager = scene.GetSystem<NetworkComponentManager>())
		{
			var component = manager.Get(entity);
			if (component == null)
				component = manager.Add(entity);
			component.Id = .(networkId);
			// The client's view: the server owns this entity.
			component.Authority = .Server;
			component.Prefab = prefab;
		}

		mNetIdToEntity[networkId] = entity;
		return entity;
	}

	/// The entity's serializable component pools that carry replicated fields. A pool with no
	/// wire tag is skipped: a record a peer cannot name is a record it cannot route.
	private static void CollectReplicatingManagers(Scene scene, EntityHandle entity,
		List<ComponentManagerBase> outManagers)
	{
		scene.ForEachManager(scope [&](manager) =>
			{
				if (!manager.IsSerializable || manager.SerializationTypeId.IsEmpty)
					return;
				if (!manager.HasComponent(entity))
					return;
				if (ReplicatedLayout.Fields(manager.ComponentType).IsEmpty)
					return;
				outManagers.Add(manager);
			});
	}

	private static bool BlobsEqual(uint8[] a, Span<uint8> b)
	{
		if (a.Count != b.Length)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	private static uint8[] CopyBlob(Span<uint8> bytes)
	{
		let copy = new uint8[bytes.Length];
		if (bytes.Length > 0)
			Internal.MemCpy(&copy[0], bytes.Ptr, bytes.Length);
		return copy;
	}
}
