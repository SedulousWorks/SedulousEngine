namespace Sedulous.Engine.Core;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core.Resources;
using Sedulous.Core.Mathematics;

/// Instantiates a prefab's entities into a scene with PrefabInstanceTag.
/// Static utility — no state. Used by both the editor (drag-drop) and
/// SceneSerializer (loading prefab instances from scene files).
static class PrefabSpawner
{
	/// Result of a successful spawn operation.
	public struct SpawnResult
	{
		/// Root entity of the spawned prefab instance.
		public EntityHandle RootEntity;

		/// Map from prefab source entity GUIDs to live entity handles.
		public Dictionary<Guid, EntityHandle> GuidMap;
	}

	/// Instantiate a prefab into the scene under the given parent.
	/// Creates entities from the template, tags them with PrefabInstanceTag,
	/// and sets the root transform. Returns the root entity and guid map.
	///
	/// The caller owns the returned GuidMap and must delete it.
	public static Result<SpawnResult> Spawn(
		Scene scene, ResourceRef prefabRef, Guid prefabId,
		EntityHandle parent,
		ComponentTypeRegistry typeRegistry, ISerializerProvider serializerProvider,
		ResourceSystem resourceSystem)
	{
		StringView uri = prefabRef.HasPath ? StringView(prefabRef.Path) : StringView();
		if (uri.IsEmpty) return .Err;

		var resolvedPrefabId = prefabId;

		// Load the prefab resource through the resource system so it's
		// cached and tracked for hot-reload detection.
		if (resourceSystem.LoadResource<PrefabResource>(uri) case .Ok(var handle))
		{
			if (resolvedPrefabId == .Empty && handle.Resource != null)
				resolvedPrefabId = handle.Resource.Id;
			handle.Release();
		}

		// Parse URI to open file for instantiation
		let schemeSep = uri.IndexOf("://");
		if (schemeSep <= 0) return .Err;
		let scheme = uri[0..<schemeSep];
		let locator = uri[(schemeSep + 3)...];

		let mount = resourceSystem.GetMount(scheme);
		if (mount == null) return .Err;

		// Read prefab file for entity instantiation
		let openResult = mount.Open(locator);
		if (openResult case .Err) return .Err;
		let stream = openResult.Value;
		defer delete stream;

		let text = scope String();
		let len = (int)stream.Length;
		if (len > 0)
		{
			let bytes = scope uint8[len];
			if (stream.TryRead(.(&bytes[0], len)) case .Err) return .Err;
			text.Append((char8*)&bytes[0], len);
		}

		let reader = serializerProvider.CreateReader(text);
		if (reader == null) return .Err;
		defer delete reader;

		// Instantiate via PrefabSerializer
		let prefabSerializer = scope PrefabSerializer(typeRegistry);
		let result = prefabSerializer.Instantiate(scene, parent, reader);
		if (result case .Err) return .Err;

		let guidMap = result.Value;

		// Find the root entity (entities parented directly to `parent`)
		EntityHandle rootEntity = .Invalid;
		for (let kv in guidMap)
		{
			let entity = kv.value;
			if (scene.GetParent(entity) == parent)
			{
				rootEntity = entity;
				break;
			}
		}

		// Template transform is preserved from PrefabSerializer.Instantiate.
		// Callers set the transform on RootEntity after spawn if needed.

		// Tag all instantiated entities with PrefabInstanceTag
		let tagMgr = GetOrCreateTagManager(scene);
		if (tagMgr != null)
		{
			for (let kv in guidMap)
			{
				let tagHandle = tagMgr.CreateComponent(kv.value);
				if (let tag = tagMgr.Get(tagHandle))
				{
					tag.PrefabId = resolvedPrefabId;
					tag.SourceEntityId = kv.key;
					tag.InstanceRoot = rootEntity;
					if (prefabRef.HasPath)
						tag.SetPrefabPath(prefabRef.Path);
				}
			}
		}

		return .Ok(.() { RootEntity = rootEntity, GuidMap = guidMap });
	}

	private static PrefabInstanceTagManager GetOrCreateTagManager(Scene scene)
	{
		let existing = scene.GetModule<PrefabInstanceTagManager>();
		if (existing != null) return existing;

		let mgr = new PrefabInstanceTagManager();
		scene.AddModule(mgr);
		return mgr;
	}
}
