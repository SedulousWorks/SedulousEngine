using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Uploads a mesh's streams on first use and keeps them while the mesh lives.
///
/// A mesh that is gone (Tick finds its life token dead) or rebuilt in place (its
/// ContentVersion moved) has its streams retired: they wait out the frames in flight, which
/// may still draw from them, and then go back to the pools for later uploads to reuse.
///
/// The streams are SUB ALLOCATED from shared pools rather than given buffers of their own, so
/// a scene of a thousand meshes is a handful of buffers: a mesh records its pool buffer and
/// its offsets, and a draw binds with those.
///
/// Part of the scene agnostic renderer: it consumes geometry rather than a scene.
class GpuMeshCache
{
	private const uint64 cVertexChunk = 4 * 1024 * 1024;
	private const uint64 cIndexChunk = 1 * 1024 * 1024;
	/// A safe offset alignment for a vertex stream.
	private const uint64 cVertexAlign = 16;
	/// Covers both index widths.
	private const uint64 cIndexAlign = 4;

	/// How many times an unusable mesh is complained about before it goes quiet.
	private const int cWarnLimit = 8;
	private static int sWarned = 0;

	private struct Entry
	{
		public GpuMesh Gpu;
		/// Retained while the entry exists; dead once the mesh is destroyed.
		public WeakRef<StaticMeshLife> Life;
		/// The mesh's ContentVersion this upload was made from.
		public uint32 Version;
		public GpuBufferAlloc Vertex;
		public GpuBufferAlloc Index;
		public GpuBufferAlloc Skin;
		public uint64 VertexSize;
		public uint64 IndexSize;
		public uint64 SkinSize;
	}

	private struct Retired
	{
		public GpuBufferAlloc Vertex;
		public GpuBufferAlloc Index;
		public GpuBufferAlloc Skin;
		public uint64 VertexSize;
		public uint64 IndexSize;
		public uint64 SkinSize;
		public uint32 FramesLeft;
	}

	private IQueue mQueue;
	private uint32 mFramesInFlight;
	private GpuBufferPool mVertexPool ~ delete _;
	private GpuBufferPool mIndexPool ~ delete _;
	private GpuBufferPool mSkinPool ~ delete _;

	/// Keyed by the mesh's IDENTITY, never its address: a freed mesh's address comes back
	/// attached to a new one, which would then inherit the dead mesh's geometry.
	private Dictionary<uint64, Entry> mCache = new .() ~ delete _;
	/// Streams of meshes gone or rebuilt, waiting out the frames in flight before reuse.
	private List<Retired> mRetired = new .() ~ delete _;

	/// `framesInFlight` is how many Ticks a retired mesh's streams are kept for before they are
	/// reused, since the frames still in flight may draw from them.
	public this(IDevice device, uint32 framesInFlight = 3)
	{
		mQueue = device.GetQueue(.Graphics, 0);
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
		mVertexPool = new GpuBufferPool(device, .Vertex | .CopyDst, cVertexChunk, "mesh.vertexPool");
		mIndexPool = new GpuBufferPool(device, .Index | .CopyDst, cIndexChunk, "mesh.indexPool");
		mSkinPool = new GpuBufferPool(device, .Vertex | .CopyDst, cVertexChunk, "mesh.skinPool");
	}

	public ~this()
	{
		Clear();
	}

	public int Size => mCache.Count;
	public int RetiredCount => mRetired.Count;
	/// Bytes of vertex streams given back for reuse.
	public uint64 FreeVertexBytes => mVertexPool.FreeBytes;

	/// Uploads a mesh the first time it is asked for, and again when its geometry was rebuilt
	/// in place (ContentVersion), and answers where it lives.
	///
	/// Null when there is nothing to draw. NO MESH is a normal state and stays silent; a mesh
	/// with an empty stream is not, and says so a few times before going quiet, since a
	/// broken mesh is resubmitted every frame.
	public Result<GpuMesh> GetOrUpload(StaticMesh mesh)
	{
		if (mesh == null)
			return .Err;

		// The draw path is indexed only, so either stream being empty means nothing would be
		// drawn: almost always a construction bug in whatever produced the mesh.
		if ((mesh.VertexCount == 0) || (mesh.IndexCount == 0))
		{
			if (sWarned < cWarnLimit)
			{
				sWarned++;
				let name = mesh.Name.IsEmpty ? "<unnamed>" : mesh.Name;
				Console.Error.WriteLine(scope $"GpuMeshCache: mesh '{name}' has {mesh.VertexCount} vertices and {mesh.IndexCount} indices, so there is nothing to draw{(sWarned == cWarnLimit) ? "; further such warnings are suppressed" : ""}");
			}
			return .Err;
		}

		if (mCache.TryGetValue(mesh.Uid, var cached))
		{
			if (cached.Version == mesh.ContentVersion)
				return .Ok(cached.Gpu);

			// Rebuilt in place: the old streams go once the GPU is done with them.
			Retire(ref cached);
			mCache.Remove(mesh.Uid);
		}

		let vertices = mVertexPool.Allocate(mesh.VertexDataSize, cVertexAlign);
		let indices = mIndexPool.Allocate(mesh.Indices.DataSize, cIndexAlign);
		if (!vertices.Ok || !indices.Ok)
			return .Err;

		// A skinned mesh carries a parallel stream of joints and weights, in its own pool.
		let skinning = mesh.SkinningStream;
		let hasSkin = mesh.IsSkinned && !skinning.IsEmpty;
		var skin = GpuBufferAlloc();
		if (hasSkin)
		{
			skin = mSkinPool.Allocate((uint64)skinning.Length * sizeof(VertexSkinning), cVertexAlign);
			if (!skin.Ok)
				return .Err;
		}

		var gpuMesh = GpuMesh();
		gpuMesh.VertexBuffer = vertices.Buffer;
		gpuMesh.VertexOffset = vertices.Offset;
		gpuMesh.IndexBuffer = indices.Buffer;
		gpuMesh.IndexOffset = indices.Offset;
		gpuMesh.IndexCount = mesh.IndexCount;
		gpuMesh.IndexFormat = (mesh.Indices.IndexFormat == .U16) ? .UInt16 : .UInt32;
		if (hasSkin)
		{
			gpuMesh.SkinBuffer = skin.Buffer;
			gpuMesh.SkinOffset = skin.Offset;
		}

		Upload(mesh, gpuMesh, skinning, hasSkin);

		var entry = Entry();
		entry.Gpu = gpuMesh;
		entry.Life = mesh.Life;
		entry.Life.Retain();
		entry.Version = mesh.ContentVersion;
		entry.Vertex = vertices;
		entry.VertexSize = mesh.VertexDataSize;
		entry.Index = indices;
		entry.IndexSize = mesh.Indices.DataSize;
		if (hasSkin)
		{
			entry.Skin = skin;
			entry.SkinSize = (uint64)skinning.Length * sizeof(VertexSkinning);
		}
		mCache[mesh.Uid] = entry;
		return .Ok(gpuMesh);
	}

	/// Once a frame: retired streams old enough that no frame in flight reads them go back to
	/// the pools, and the streams of meshes that are gone are retired.
	public void Tick()
	{
		for (int i = mRetired.Count - 1; i >= 0; i--)
		{
			var retired = mRetired[i];
			if (retired.FramesLeft <= 1)
			{
				mVertexPool.Free(retired.Vertex, retired.VertexSize);
				mIndexPool.Free(retired.Index, retired.IndexSize);
				mSkinPool.Free(retired.Skin, retired.SkinSize);
				mRetired.RemoveAt(i);
				continue;
			}
			retired.FramesLeft--;
			mRetired[i] = retired;
		}

		List<uint64> gone = scope .();
		for (let pair in mCache)
		{
			if (!pair.value.Life.IsAlive)
				gone.Add(pair.key);
		}
		for (let uid in gone)
		{
			if (mCache.TryGetValue(uid, var entry))
			{
				Retire(ref entry);
				mCache.Remove(uid);
			}
		}
	}

	/// Frees every pooled buffer and the cache with them.
	public void Clear()
	{
		for (var pair in ref mCache)
			pair.valueRef.Life.Forget();
		mVertexPool.Clear();
		mIndexPool.Clear();
		mSkinPool.Clear();
		mCache.Clear();
		mRetired.Clear();
	}

	/// Queues an entry's streams to wait out the frames in flight, and lets go of its mesh.
	private void Retire(ref Entry entry)
	{
		mRetired.Add(.()
			{
				Vertex = entry.Vertex, Index = entry.Index, Skin = entry.Skin,
				VertexSize = entry.VertexSize, IndexSize = entry.IndexSize, SkinSize = entry.SkinSize,
				FramesLeft = mFramesInFlight
			});
		entry.Life.Forget();
	}

	private void Upload(StaticMesh mesh, GpuMesh gpuMesh, Span<VertexSkinning> skinning, bool hasSkin)
	{
		if (mQueue == null)
			return;

		if (!(mQueue.CreateTransferBatch() case .Ok(var batch)))
			return;
		defer mQueue.DestroyTransferBatch(ref batch);

		batch.WriteBuffer(gpuMesh.VertexBuffer, gpuMesh.VertexOffset,
			.(mesh.VertexData, (int)mesh.VertexDataSize));
		batch.WriteBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexOffset,
			.(mesh.Indices.RawData, (int)mesh.Indices.DataSize));

		if (hasSkin)
		{
			batch.WriteBuffer(gpuMesh.SkinBuffer, gpuMesh.SkinOffset,
				.((uint8*)skinning.Ptr, skinning.Length * sizeof(VertexSkinning)));
		}

		batch.Submit().IgnoreError();
	}
}
