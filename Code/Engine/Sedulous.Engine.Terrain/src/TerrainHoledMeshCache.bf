using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain;

/// The holed chunks' index buffers, cached per heightfield.
///
/// A chunk whose sample block holds a cut sample cannot draw the shared grid, so it gets its
/// own index buffer per level, built by the terrain mesh's holed walk and rebuilt in place
/// when the heightfield's version moves: a cut, a fill or a sculpt.
///
/// Keyed by the heightfield's UID rather than its reference, the way every other terrain cache
/// is, and the buffers retire through the frame aged queue as the height texture's do.
class TerrainHoledMeshCache
{
	private class Entry
	{
		public uint64 Key = 0;
		public uint64 Version = 0;
		public List<HoledChunkMesh> Meshes = new .() ~ delete _;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED from the subsystem.
	private GpuRetireQueue mRetire = null;

	public void SetRetireQueue(GpuRetireQueue retire) => mRetire = retire;

	public int Count => mEntries.Count;

	/// The holed chunk records held for a heightfield, nought meaning none: the test's
	/// observable.
	public int MeshCount(uint64 uid)
	{
		for (let entry in mEntries)
		{
			if (entry.Key == uid)
				return entry.Meshes.Count;
		}
		return 0;
	}

	/// The holed chunks' meshes for a field at a version, empty when it has no holes at all:
	/// built on a miss or a stale version, else the cached set.
	///
	/// The span is the CACHE's own storage; the extraction copies it into the frame arena.
	public Span<HoledChunkMesh> GetOrBuild(IDevice device, Heightfield field,
		Span<TerrainChunk> chunks, uint64 version)
	{
		for (let entry in mEntries)
		{
			if (entry.Key != field.Uid)
				continue;

			if (entry.Version != version)
			{
				Release(device, entry);
				Build(device, field, chunks, entry);
				entry.Version = version;
			}
			return .(entry.Meshes.Ptr, entry.Meshes.Count);
		}

		// The common terrain: no entry and no allocation.
		if (!field.HasHoles)
			return .();

		let fresh = new Entry();
		fresh.Key = field.Uid;
		fresh.Version = version;
		Build(device, field, chunks, fresh);
		mEntries.Add(fresh);
		return .(fresh.Meshes.Ptr, fresh.Meshes.Count);
	}

	/// Drops every entry, which a scene destroy or a shutdown does; the buffers retire when a
	/// queue is wired.
	public void Clear(IDevice device)
	{
		for (let entry in mEntries)
			Release(device, entry);
		ClearAndDeleteItems!(mEntries);
	}

	private static void Build(IDevice device, Heightfield field, Span<TerrainChunk> chunks,
		Entry entry)
	{
		entry.Meshes.Clear();

		let indices = scope List<uint32>();
		for (int i < chunks.Length)
		{
			let chunk = chunks[i];
			// The shared grid, or nothing at all.
			if (!chunk.HasHoles || chunk.AllCut)
				continue;

			var mesh = HoledChunkMesh();
			mesh.ChunkIndex = (uint32)i;
			for (uint32 lod = 0; lod <= TerrainMesh.MaxChunkLod; lod++)
			{
				TerrainMesh.BuildHoledChunkIndices(field, chunk.GridX0, chunk.GridZ0, lod,
					indices, let surface);
				mesh.IndexCounts[lod] = (uint32)indices.Count;
				mesh.SurfaceIndexCounts[lod] = surface;
				// This level's quads all went: no buffer, and so no draw.
				if (indices.IsEmpty)
					continue;

				var desc = BufferDesc();
				desc.Size = (uint64)indices.Count * sizeof(uint32);
				desc.Usage = .Index | .CopyDst;
				desc.Memory = .CpuToGpu;
				desc.Label = "terrain.holed.indices";
				if (!(device.CreateBuffer(desc) case .Ok(let buffer)))
				{
					mesh.IndexCounts[lod] = 0;
					continue;
				}
				let mapped = buffer.Map();
				if (mapped != null)
				{
					Internal.MemCpy(mapped, indices.Ptr, indices.Count * sizeof(uint32));
					buffer.Unmap();
				}
				mesh.IndexBuffers[lod] = buffer;
			}
			entry.Meshes.Add(mesh);
		}
	}

	private void Release(IDevice device, Entry entry)
	{
		for (var mesh in ref entry.Meshes)
		{
			for (uint32 lod = 0; lod <= TerrainMesh.MaxChunkLod; lod++)
			{
				if (mesh.IndexBuffers[lod] == null)
					continue;

				if (mRetire != null)
					mRetire.Retire(mesh.IndexBuffers[lod]);
				else
					device.DestroyBuffer(ref mesh.IndexBuffers[lod]);
				mesh.IndexBuffers[lod] = null;
			}
		}
		entry.Meshes.Clear();
	}
}
