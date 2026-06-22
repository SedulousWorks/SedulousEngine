namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;

/// Shared output buffer for compute skinning. Every visible skinned-mesh
/// instance gets a sub-range of this single VkBuffer instead of its own
/// IBuffer. The compute pass writes into the range via a storage descriptor
/// with offset; the forward / depth / shadow / pick passes read via
/// SetVertexBuffer(buffer, offset).
///
/// Replacing per-instance buffers with sub-allocations is step A.1 of the
/// mega-dispatch rework. By itself it does not reduce CPU overhead - it
/// just moves the GPU storage into one shared buffer so subsequent phases
/// (single bind group, single dispatch) have a stable backing buffer to
/// reference.
class SkinnedVertexPool : IDisposable
{
	/// Granularity for allocations. Matches the most conservative Vulkan
	/// minStorageBufferOffsetAlignment so the same offset can drive both
	/// storage descriptor binds (compute) and vertex buffer binds (raster).
	public const uint64 Alignment = 256;

	private IDevice mDevice;
	private IBuffer mBuffer;
	private uint64 mBufferSize;
	private uint64 mBumpHead;

	/// Free-list bucketed by exact allocation size. Skinned meshes are
	/// shared across instances, so the common case is "same vertex count,
	/// repeated N times" - an exact-size free list reuses freed slots
	/// without fragmenting the bump head.
	private Dictionary<uint64, List<uint64>> mFreeBySize = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	private bool mWarnedOnOverflow;

	public Result<void> Initialize(IDevice device, uint64 initialSize)
	{
		mDevice = device;
		mBufferSize = AlignUp(initialSize);

		BufferDesc desc = .()
		{
			Label = "Skinned Vertex Pool",
			Size = mBufferSize,
			Usage = .Storage | .Vertex,
			Memory = .GpuOnly
		};
		if (device.CreateBuffer(desc) case .Ok(let buf))
		{
			mBuffer = buf;
			return .Ok;
		}
		return .Err;
	}

	/// Allocates `size` bytes from the pool. Returns false if the pool is
	/// exhausted; the caller should skip skinning that instance for the
	/// frame (it would have been black before A.1 too if its CreateBuffer
	/// failed).
	public bool Allocate(uint64 size, out uint64 offset, out uint64 alignedSize)
	{
		alignedSize = AlignUp(size);

		// Exact-size reuse before bumping. Skinned characters in a herd
		// share the same mesh -> same vertex count -> same alignedSize, so
		// the free list does most of the work past the initial fill.
		if (mFreeBySize.TryGetValue(alignedSize, var list) && list.Count > 0)
		{
			offset = list.PopBack();
			return true;
		}

		if (mBumpHead + alignedSize > mBufferSize)
		{
			if (!mWarnedOnOverflow)
			{
				Console.WriteLine("[SkinnedVertexPool] Pool exhausted at {0} MB. Bump head {1} + request {2} > size {3}. Skipping further skinning until slots free.",
					mBufferSize / (1024 * 1024), mBumpHead, alignedSize, mBufferSize);
				mWarnedOnOverflow = true;
			}
			offset = 0;
			return false;
		}

		offset = mBumpHead;
		mBumpHead += alignedSize;
		return true;
	}

	public void Free(uint64 offset, uint64 alignedSize)
	{
		if (!mFreeBySize.TryGetValue(alignedSize, var list))
		{
			list = new .();
			mFreeBySize[alignedSize] = list;
		}
		list.Add(offset);
	}

	public IBuffer Buffer => mBuffer;
	public uint64 SizeBytes => mBufferSize;

	private static uint64 AlignUp(uint64 v) => (v + Alignment - 1) & ~(Alignment - 1);

	public void Dispose()
	{
		if (mBuffer != null && mDevice != null)
		{
			mDevice.DestroyBuffer(ref mBuffer);
			mBuffer = null;
		}
	}
}
