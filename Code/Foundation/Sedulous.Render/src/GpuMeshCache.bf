using System;
using System.Collections;
using Sedulous.Geometry;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Uploads a mesh's streams on first use and keeps them.
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

	private IQueue mQueue;
	private GpuBufferPool mVertexPool ~ delete _;
	private GpuBufferPool mIndexPool ~ delete _;
	private GpuBufferPool mSkinPool ~ delete _;

	/// Keyed by the mesh's IDENTITY, never its address: a freed mesh's address comes back
	/// attached to a new one, which would then inherit the dead mesh's geometry.
	private Dictionary<uint64, GpuMesh> mCache = new .() ~ delete _;

	public this(IDevice device)
	{
		mQueue = device.GetQueue(.Graphics, 0);
		mVertexPool = new GpuBufferPool(device, .Vertex | .CopyDst, cVertexChunk, "mesh.vertexPool");
		mIndexPool = new GpuBufferPool(device, .Index | .CopyDst, cIndexChunk, "mesh.indexPool");
		mSkinPool = new GpuBufferPool(device, .Vertex | .CopyDst, cVertexChunk, "mesh.skinPool");
	}

	public ~this()
	{
		Clear();
	}

	public int Size => mCache.Count;

	/// Uploads a mesh the first time it is asked for, and answers where it lives.
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

		if (mCache.TryGetValue(mesh.Uid, let cached))
			return .Ok(cached);

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

		mCache[mesh.Uid] = gpuMesh;
		return .Ok(gpuMesh);
	}

	/// Frees every pooled buffer and the cache with them.
	public void Clear()
	{
		mVertexPool.Clear();
		mIndexPool.Clear();
		mSkinPool.Clear();
		mCache.Clear();
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
