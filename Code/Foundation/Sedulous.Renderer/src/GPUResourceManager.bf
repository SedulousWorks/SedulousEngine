namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// Description for uploading a mesh to the GPU.
struct MeshUploadDesc
{
	/// Raw vertex data.
	public uint8* VertexData;
	/// Total vertex data size in bytes.
	public uint64 VertexDataSize;
	/// Number of vertices.
	public uint32 VertexCount;
	/// Stride per vertex in bytes.
	public uint32 VertexStride;

	/// Raw index data (null for non-indexed).
	public uint8* IndexData;
	/// Total index data size in bytes.
	public uint64 IndexDataSize;
	/// Number of indices.
	public uint32 IndexCount;
	/// Index format.
	public IndexFormat IndexFormat;

	/// Submeshes (null = single submesh covering all indices/vertices).
	public GPUSubMesh* SubMeshes;
	/// Number of submeshes.
	public uint32 SubMeshCount;

	/// Local-space bounding box.
	public BoundingBox Bounds;

	/// Whether this mesh has skinning data (adds Storage usage for compute).
	public bool IsSkinned;

	/// Buffer usage flags beyond the defaults (Vertex|CopyDst for VB, Index|CopyDst for IB).
	public BufferUsage ExtraVertexUsage;
}

/// Description for uploading a texture to the GPU.
struct TextureUploadDesc
{
	/// Raw pixel data.
	public uint8* PixelData;
	/// Total pixel data size in bytes.
	public uint64 PixelDataSize;

	/// Texture dimensions.
	public uint32 Width;
	public uint32 Height;
	public uint32 DepthOrArrayLayers;
	public uint32 MipLevels;

	/// Pixel format.
	public TextureFormat Format;

	/// Texture dimension type.
	public TextureDimension Dimension;

	/// Bytes per row (0 = auto-calculate from width and format).
	public uint32 BytesPerRow;

	/// Rows per image (0 = Height).
	public uint32 RowsPerImage;
}

/// Pending deletion entry.
struct PendingDeletion
{
	public enum Type { Mesh, Texture, BoneBuffer }
	public Type ResourceType;
	public uint32 Index;
	public uint64 FrameNumber;
}

/// Manages GPU resources (meshes, textures, bone buffers) with handle-based access,
/// reference counting, and deferred deletion.
///
/// Scene-independent - takes raw data, returns handles.
/// The engine bridge layer converts CPU resources to upload descriptors.
public class GPUResourceManager : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;

	/// Optional transfer batch for batching GPU uploads.
	public ITransferBatch TransferBatch;

	// Mesh storage
	private List<GPUMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mFreeMeshSlots = new .() ~ delete _;

	// Texture storage
	private List<GPUTexture> mTextures = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mFreeTextureSlots = new .() ~ delete _;

	// Bone buffer storage
	private List<GPUBoneBuffer> mBoneBuffers = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mFreeBoneBufferSlots = new .() ~ delete _;

	// Deferred deletion
	private List<PendingDeletion> mPendingDeletions = new .() ~ delete _;
	private const uint64 DeletionDelay = 4;

	public IDevice Device => mDevice;

	/// Initializes the manager.
	public Result<void> Initialize(IDevice device, IQueue graphicsQueue)
	{
		mDevice = device;
		mQueue = graphicsQueue;
		return .Ok;
	}

	// ==================== Mesh API ====================

	/// Uploads a mesh to the GPU from raw data.
	public Result<GPUMeshHandle> UploadMesh(MeshUploadDesc desc)
	{
		if (desc.VertexData == null || desc.VertexDataSize == 0)
			return .Err;

		// Allocate slot
		let (gpuMesh, index, generation) = AllocMeshSlot();

		// Create vertex buffer
		var vbUsage = BufferUsage.Vertex | .CopyDst | desc.ExtraVertexUsage;
		if (desc.IsSkinned)
			vbUsage |= .Storage;

		var vbDesc = BufferDesc()
		{
			Label = desc.IsSkinned ? "Skinned Mesh VB" : "Mesh VB",
			Size = desc.VertexDataSize,
			Usage = vbUsage
		};

		if (mDevice.CreateBuffer(vbDesc) case .Ok(let vb))
		{
			gpuMesh.VertexBuffer = vb;
			let vbData = Span<uint8>(desc.VertexData, (int)desc.VertexDataSize);
			if (TransferBatch != null)
				TransferBatch.WriteBuffer(vb, 0, vbData);
			else
				TransferHelper.WriteStagedBufferSync(mQueue, mDevice, vb, 0, vbData);
		}
		else
			return .Err;

		// Create index buffer
		if (desc.IndexData != null && desc.IndexDataSize > 0)
		{
			var ibDesc = BufferDesc()
			{
				Label = "Mesh IB",
				Size = desc.IndexDataSize,
				Usage = .Index | .CopyDst
			};

			if (mDevice.CreateBuffer(ibDesc) case .Ok(let ib))
			{
				gpuMesh.IndexBuffer = ib;
				let ibData = Span<uint8>(desc.IndexData, (int)desc.IndexDataSize);
				if (TransferBatch != null)
					TransferBatch.WriteBuffer(ib, 0, ibData);
				else
					TransferHelper.WriteStagedBufferSync(mQueue, mDevice, ib, 0, ibData);
			}
			else
			{
				mDevice.DestroyBuffer(ref gpuMesh.VertexBuffer);
				return .Err;
			}
		}

		// Set properties
		gpuMesh.VertexCount = desc.VertexCount;
		gpuMesh.IndexCount = desc.IndexCount;
		gpuMesh.VertexStride = desc.VertexStride;
		gpuMesh.IndexFormat = desc.IndexFormat;
		gpuMesh.Bounds = desc.Bounds;
		gpuMesh.IsSkinned = desc.IsSkinned;
		gpuMesh.RefCount = 1;
		gpuMesh.Generation = generation;
		gpuMesh.IsActive = true;

		// Copy submeshes
		if (desc.SubMeshes != null && desc.SubMeshCount > 0)
		{
			gpuMesh.SubMeshes = new GPUSubMesh[desc.SubMeshCount];
			for (uint32 i = 0; i < desc.SubMeshCount; i++)
				gpuMesh.SubMeshes[i] = desc.SubMeshes[i];
		}
		else
		{
			gpuMesh.SubMeshes = new GPUSubMesh[1];
			gpuMesh.SubMeshes[0] = .()
			{
				IndexStart = 0,
				IndexCount = desc.IndexCount > 0 ? desc.IndexCount : desc.VertexCount,
				BaseVertex = 0,
				MaterialSlot = 0
			};
		}

		return .Ok(.() { Index = index, Generation = generation });
	}

	/// Gets a GPU mesh by handle.
	public GPUMesh GetMesh(GPUMeshHandle handle)
	{
		if (!handle.IsValid || handle.Index >= mMeshes.Count)
			return null;

		let mesh = mMeshes[(int)handle.Index];
		if (!mesh.IsActive || mesh.Generation != handle.Generation)
			return null;

		return mesh;
	}

	/// Adds a reference to a mesh.
	public void AddMeshRef(GPUMeshHandle handle)
	{
		if (let mesh = GetMesh(handle))
			mesh.RefCount++;
	}

	/// Releases a reference to a mesh. Schedules deferred deletion when refcount hits 0.
	public void ReleaseMesh(GPUMeshHandle handle, uint64 frameNumber)
	{
		if (let mesh = GetMesh(handle))
		{
			mesh.RefCount--;
			if (mesh.RefCount <= 0)
			{
				mPendingDeletions.Add(.()
				{
					ResourceType = .Mesh,
					Index = handle.Index,
					FrameNumber = frameNumber
				});
			}
		}
	}

	// ==================== Texture API ====================

	/// Uploads a texture to the GPU from raw data.
	public Result<GPUTextureHandle> UploadTexture(TextureUploadDesc desc)
	{
		if (desc.PixelData == null || desc.PixelDataSize == 0)
			return .Err;

		let (gpuTexture, index, generation) = AllocTextureSlot();

		var texDesc = TextureDesc()
		{
			Label = "Uploaded Texture",
			Width = desc.Width,
			Height = desc.Height,
			Depth = 1,
			ArrayLayerCount = desc.DepthOrArrayLayers,
			MipLevelCount = desc.MipLevels,
			Format = desc.Format,
			Usage = .Sampled | .CopyDst,
			Dimension = desc.Dimension,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
		{
			gpuTexture.Texture = tex;

			var bytesPerRow = desc.BytesPerRow;
			if (bytesPerRow == 0)
				bytesPerRow = desc.Width * GetBytesPerPixel(desc.Format);

			var rowsPerImage = desc.RowsPerImage;
			if (rowsPerImage == 0)
				rowsPerImage = desc.Height;

			var dataLayout = TextureDataLayout()
			{
				Offset = 0,
				BytesPerRow = bytesPerRow,
				RowsPerImage = rowsPerImage
			};

			var writeSize = Extent3D(desc.Width, desc.Height, desc.DepthOrArrayLayers);
			let texData = Span<uint8>(desc.PixelData, (int)desc.PixelDataSize);

			if (TransferBatch != null)
				TransferBatch.WriteTexture(tex, texData, dataLayout, writeSize, 0, 0);
			else
				TransferHelper.WriteTextureSync(mQueue, mDevice, tex, texData, dataLayout, writeSize, 0, 0);

			// Create default view
			var viewDesc = TextureViewDesc()
			{
				Format = desc.Format,
				Dimension = desc.DepthOrArrayLayers == 6 ? .TextureCube : .Texture2D,
				BaseMipLevel = 0,
				MipLevelCount = desc.MipLevels,
				BaseArrayLayer = 0,
				ArrayLayerCount = desc.DepthOrArrayLayers
			};

			if (mDevice.CreateTextureView(tex, viewDesc) case .Ok(let view))
				gpuTexture.DefaultView = view;
			else
			{
				var texRef = tex;
				mDevice.DestroyTexture(ref texRef);
				return .Err;
			}
		}
		else
			return .Err;

		gpuTexture.Width = desc.Width;
		gpuTexture.Height = desc.Height;
		gpuTexture.DepthOrArrayLayers = desc.DepthOrArrayLayers;
		gpuTexture.MipLevels = desc.MipLevels;
		gpuTexture.Format = desc.Format;
		gpuTexture.RefCount = 1;
		gpuTexture.Generation = generation;
		gpuTexture.IsActive = true;

		return .Ok(.() { Index = index, Generation = generation });
	}

	/// Gets a GPU texture by handle.
	public GPUTexture GetTexture(GPUTextureHandle handle)
	{
		if (!handle.IsValid || handle.Index >= mTextures.Count)
			return null;

		let tex = mTextures[(int)handle.Index];
		if (!tex.IsActive || tex.Generation != handle.Generation)
			return null;

		return tex;
	}

	/// Gets the texture view for a handle.
	public ITextureView GetTextureView(GPUTextureHandle handle)
	{
		if (let tex = GetTexture(handle))
			return tex.DefaultView;
		return null;
	}

	/// Adds a reference to a texture.
	public void AddTextureRef(GPUTextureHandle handle)
	{
		if (let tex = GetTexture(handle))
			tex.RefCount++;
	}

	/// Releases a reference to a texture.
	public void ReleaseTexture(GPUTextureHandle handle, uint64 frameNumber)
	{
		if (let tex = GetTexture(handle))
		{
			tex.RefCount--;
			if (tex.RefCount <= 0)
			{
				mPendingDeletions.Add(.()
				{
					ResourceType = .Texture,
					Index = handle.Index,
					FrameNumber = frameNumber
				});
			}
		}
	}

	// ==================== Bone Buffer API ====================

	/// Creates a bone buffer for skinned mesh animation.
	public Result<GPUBoneBufferHandle> CreateBoneBuffer(uint16 boneCount)
	{
		if (boneCount == 0)
			return .Err;

		let (boneBuffer, index, generation) = AllocBoneBufferSlot();

		// Current + previous frame matrices
		let bufferSize = (uint64)(sizeof(Matrix) * boneCount * 2);

		var bufDesc = BufferDesc()
		{
			Label = "Bone Transforms",
			Size = bufferSize,
			Usage = .Storage,
			Memory = .CpuToGpu
		};

		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buffer))
		{
			boneBuffer.Buffer = buffer;
			boneBuffer.BoneCount = boneCount;
			boneBuffer.Size = bufferSize;
			boneBuffer.RefCount = 1;
			boneBuffer.Generation = generation;
			boneBuffer.IsActive = true;

			return .Ok(.() { Index = index, Generation = generation });
		}

		return .Err;
	}

	/// Gets a bone buffer by handle.
	public GPUBoneBuffer GetBoneBuffer(GPUBoneBufferHandle handle)
	{
		if (!handle.IsValid || handle.Index >= mBoneBuffers.Count)
			return null;

		let buffer = mBoneBuffers[(int)handle.Index];
		if (!buffer.IsActive || buffer.Generation != handle.Generation)
			return null;

		return buffer;
	}

	/// Releases a bone buffer reference.
	public void ReleaseBoneBuffer(GPUBoneBufferHandle handle, uint64 frameNumber)
	{
		if (let buffer = GetBoneBuffer(handle))
		{
			buffer.RefCount--;
			if (buffer.RefCount <= 0)
			{
				mPendingDeletions.Add(.()
				{
					ResourceType = .BoneBuffer,
					Index = handle.Index,
					FrameNumber = frameNumber
				});
			}
		}
	}

	// ==================== Maintenance ====================

	/// Processes pending deletions that have aged out.
	public void ProcessDeletions(uint64 currentFrame)
	{
		for (int i = mPendingDeletions.Count - 1; i >= 0; i--)
		{
			let pending = mPendingDeletions[i];
			if (currentFrame >= pending.FrameNumber + DeletionDelay)
			{
				switch (pending.ResourceType)
				{
				case .Mesh:
					let mesh = mMeshes[(int)pending.Index];
					mesh.Release(mDevice);
					mFreeMeshSlots.Add((int32)pending.Index);
				case .Texture:
					let tex = mTextures[(int)pending.Index];
					tex.Release(mDevice);
					mFreeTextureSlots.Add((int32)pending.Index);
				case .BoneBuffer:
					let buffer = mBoneBuffers[(int)pending.Index];
					buffer.Release(mDevice);
					mFreeBoneBufferSlots.Add((int32)pending.Index);
				}

				mPendingDeletions.RemoveAtFast(i);
			}
		}
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		for (let mesh in mMeshes)
			mesh.Release(mDevice);
		for (let tex in mTextures)
			tex.Release(mDevice);
		for (let buffer in mBoneBuffers)
			buffer.Release(mDevice);
		mPendingDeletions.Clear();
	}

	// ==================== Internal Allocation ====================

	private (GPUMesh mesh, uint32 index, uint32 generation) AllocMeshSlot()
	{
		if (mFreeMeshSlots.Count > 0)
		{
			let index = (uint32)mFreeMeshSlots.PopBack();
			let mesh = mMeshes[(int)index];
			return (mesh, index, mesh.Generation + 1);
		}
		let index = (uint32)mMeshes.Count;
		let mesh = new GPUMesh();
		mMeshes.Add(mesh);
		return (mesh, index, 1);
	}

	private (GPUTexture texture, uint32 index, uint32 generation) AllocTextureSlot()
	{
		if (mFreeTextureSlots.Count > 0)
		{
			let index = (uint32)mFreeTextureSlots.PopBack();
			let tex = mTextures[(int)index];
			return (tex, index, tex.Generation + 1);
		}
		let index = (uint32)mTextures.Count;
		let tex = new GPUTexture();
		mTextures.Add(tex);
		return (tex, index, 1);
	}

	private (GPUBoneBuffer buffer, uint32 index, uint32 generation) AllocBoneBufferSlot()
	{
		if (mFreeBoneBufferSlots.Count > 0)
		{
			let index = (uint32)mFreeBoneBufferSlots.PopBack();
			let buf = mBoneBuffers[(int)index];
			return (buf, index, buf.Generation + 1);
		}
		let index = (uint32)mBoneBuffers.Count;
		let buf = new GPUBoneBuffer();
		mBoneBuffers.Add(buf);
		return (buf, index, 1);
	}

	/// Rough bytes-per-pixel for common formats. Used for auto-calculating BytesPerRow.
	private static uint32 GetBytesPerPixel(TextureFormat format)
	{
		switch (format)
		{
		case .R8Unorm: return 1;
		case .RG8Unorm: return 2;
		case .RGBA8Unorm, .RGBA8UnormSrgb, .BGRA8Unorm, .BGRA8UnormSrgb: return 4;
		case .R16Float: return 2;
		case .RG16Float: return 4;
		case .RGBA16Float: return 8;
		case .R32Float: return 4;
		case .RG32Float: return 8;
		case .RGBA32Float: return 16;
		default: return 4;
		}
	}
}
