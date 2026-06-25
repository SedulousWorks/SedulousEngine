namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;

/// Shared bone matrix storage. Animation writes go into the CpuToGpu staging
/// buffer; CopyToDevice mirrors the populated range into a GpuOnly device
/// buffer once per frame so vertex shaders fetch bones from VRAM instead of
/// streaming over PCIe. Each per-skeleton GPUBoneBuffer is a sub-range
/// (offset, size) inside the pool.
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

	// Device-local mirror for vertex-shader skinning. Vertex skinning across N
	// passes reads bones 4 * verts * passes times; without a DEVICE_LOCAL
	// mirror those reads stream over PCIe and become the dominant cost (~30 ms
	// on a 3060 at herd scales). One vkCmdCopyBuffer per frame moves the
	// working set into VRAM and subsequent reads land at >400 GB/s.
	private IBuffer mDeviceBuffer;

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
			Label = "Bone Matrix Pool (Staging)",
			Size = mBufferSize,
			// CopySrc so we can shovel the populated range into the
			// device-local mirror each frame.
			Usage = .StorageRead | .CopySrc,
			Memory = .CpuToGpu
		};
		if (device.CreateBuffer(desc) case .Ok(let buf))
			mBuffer = buf;
		else
			return .Err;

		BufferDesc deviceDesc = .()
		{
			Label = "Bone Matrix Pool (Device)",
			Size = mBufferSize,
			Usage = .StorageRead | .CopyDst,
			Memory = .GpuOnly
		};
		if (device.CreateBuffer(deviceDesc) case .Ok(let dbuf))
			mDeviceBuffer = dbuf;
		else
			return .Err;

		return .Ok;
	}

	/// Copies the populated range of the staging pool into the device-local
	/// mirror. Call once per frame, before any vertex shader that reads
	/// bones (so before main render + shadow renders). Range = [0, mBumpHead)
	/// covers every live allocation (free-list reuses slots below the bump
	/// head; nothing past it is meaningful).
	public void CopyToDevice(ICommandEncoder encoder)
	{
		if (encoder == null || mBuffer == null || mDeviceBuffer == null) return;
		if (mBumpHead == 0) return;
		encoder.CopyBufferToBuffer(mBuffer, 0, mDeviceBuffer, 0, mBumpHead);
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
	/// Device-local mirror. Bind this (not Buffer) wherever a vertex
	/// shader reads bones - the staging Buffer is for animation writes
	/// and the per-frame CopyToDevice issues the upload.
	public IBuffer DeviceBuffer => mDeviceBuffer;

	private static uint64 AlignUp(uint64 v) => (v + Alignment - 1) & ~(Alignment - 1);

	public void Dispose()
	{
		if (mDevice == null) return;
		if (mBuffer != null)
		{
			mDevice.DestroyBuffer(ref mBuffer);
			mBuffer = null;
		}
		if (mDeviceBuffer != null)
		{
			mDevice.DestroyBuffer(ref mDeviceBuffer);
			mDeviceBuffer = null;
		}
	}
}
