namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// A submesh within a GPU mesh.
public struct GPUSubMesh
{
	/// Start index in the index buffer.
	public uint32 IndexStart;

	/// Number of indices.
	public uint32 IndexCount;

	/// Base vertex offset.
	public int32 BaseVertex;

	/// Material slot index.
	public uint32 MaterialSlot;
}

/// LOD level descriptor within a GPU mesh.
public struct GPUMeshLOD
{
	/// First submesh index for this LOD.
	public uint32 SubMeshStart;

	/// Number of submeshes in this LOD.
	public uint32 SubMeshCount;
}

/// GPU-side mesh data. Managed by GPUResourceManager.
public class GPUMesh
{
	public IBuffer VertexBuffer;
	public IBuffer IndexBuffer;
	public uint32 VertexCount;
	public uint32 IndexCount;
	public uint32 VertexStride;
	public IndexFormat IndexFormat;
	public GPUSubMesh[] SubMeshes ~ delete _;
	public GPUMeshLOD[] LODLevels ~ delete _;
	public uint32 LODCount;
	public BoundingBox Bounds;
	public int32 RefCount;
	public uint32 Generation;
	public bool IsActive;
	public bool IsSkinned;

	/// Number of bones required by this skinned mesh (max joint index + 1).
	/// Only valid when IsSkinned is true. Determined from vertex joint indices at upload.
	public uint16 RequiredBoneCount;

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		if (device != null)
		{
			device.DestroyBuffer(ref VertexBuffer);
			device.DestroyBuffer(ref IndexBuffer);
		}
		DeleteAndNullify!(SubMeshes);
		DeleteAndNullify!(LODLevels);
		LODCount = 0;
		IsActive = false;
	}
}

/// GPU-side texture data. Managed by GPUResourceManager.
public class GPUTexture
{
	public ITexture Texture;
	public ITextureView DefaultView;
	public uint32 Width;
	public uint32 Height;
	public uint32 DepthOrArrayLayers;
	public uint32 MipLevels;
	public TextureFormat Format;
	public int32 RefCount;
	public uint32 Generation;
	public bool IsActive;

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		if (device != null)
		{
			device.DestroyTextureView(ref DefaultView);
			device.DestroyTexture(ref Texture);
		}
		IsActive = false;
	}
}

/// GPU-side bone buffer for skinned mesh animation.
/// Backing storage is a sub-range of GPUResourceManager's shared BoneMatrixPool;
/// (Offset, Size) locate the per-skeleton matrices in pool.Buffer.
public class GPUBoneBuffer
{
	public uint64 Offset;
	public uint64 Size;
	public uint16 BoneCount;
	public int32 RefCount;
	public uint32 Generation;
	public bool IsActive;

	/// Returns the sub-range to the pool. Caller passes the pool that
	/// originally allocated it.
	public void Release(BoneMatrixPool pool)
	{
		if (pool != null && Size > 0)
		{
			pool.Free(Offset, Size);
			Size = 0;
		}
		IsActive = false;
	}
}
