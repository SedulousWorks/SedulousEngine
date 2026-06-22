namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;

/// Shared CpuToGpu storage buffer for all per-skeleton bone matrices.
/// Each GPUBoneBuffer gets a sub-range instead of its own VkBuffer; the
/// animation system writes into (pool.Buffer, offset + localOffset) and
/// the skinning compute pass binds (pool.Buffer, offset, size) as its
/// bone-matrix descriptor entry.
///
/// Step A.2 of the mega-dispatch rework. By itself this is plumbing - the
/// per-character bind group still rebinds; only the underlying buffer
/// reference becomes uniform across all instances. A.4 reaps the win.
class BoneMatrixPool : IDisposable
{
	/// Granularity for allocations - matches the most conservative Vulkan
	/// minStorageBufferOffsetAlignment so the same offset can drive both
	/// storage descriptor binds and mapped CPU writes.
	public const uint64 Alignment = 256;

	private IDevice mDevice;
	private IBuffer mBuffer;
	private uint64 mBufferSize;
	private uint64 mBumpHead;

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
			Label = "Bone Matrix Pool",
			Size = mBufferSize,
			Usage = .StorageRead,
			Memory = .CpuToGpu
		};
		if (device.CreateBuffer(desc) case .Ok(let buf))
		{
			mBuffer = buf;
			return .Ok;
		}
		return .Err;
	}

	public bool Allocate(uint64 size, out uint64 offset, out uint64 alignedSize)
	{
		alignedSize = AlignUp(size);

		if (mFreeBySize.TryGetValue(alignedSize, var list) && list.Count > 0)
		{
			offset = list.PopBack();
			return true;
		}

		if (mBumpHead + alignedSize > mBufferSize)
		{
			if (!mWarnedOnOverflow)
			{
				Console.WriteLine("[BoneMatrixPool] Pool exhausted at {0} MB. Bump head {1} + request {2} > size {3}. Skipping further bone allocations until slots free.",
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
