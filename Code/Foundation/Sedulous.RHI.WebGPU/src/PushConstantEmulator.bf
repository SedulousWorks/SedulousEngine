using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;

namespace Sedulous.RHI.WebGPU;

/// The uniform buffer push constant fallback, shared by the pass encoders.
///
/// Where a device has no immediates path, which is a browser or the fallback forced for
/// testing, the block binds as an ordinary uniform buffer at the pipeline's group,
/// binding zero, which is the shape the WGSL cook emits.
///
/// It keeps a CPU shadow of the block and, before each draw, uploads a FRESH uniform
/// buffer and binds it. Fresh rather than reused, so two consecutive draws never alias
/// the same memory and the second cannot overwrite what the first has not issued yet.
/// Everything created that way lives until the pass ends; the recorded commands retain
/// what the GPU needs, so releasing the wrappers after End is safe.
sealed class PushConstantEmulator
{
	/// The RHI's push constant contract is 128 bytes; this pads past it.
	public const uint32 cMaxBlockSize = 256;

	private WGPUDevice mDevice = null;
	private int32 mGroup = -1;
	private WGPUBindGroupLayout mLayout = null;
	private uint32 mBlockSize = 0;
	private bool mDirty = false;

	private uint8[cMaxBlockSize] mShadow = .();
	private List<WGPUBuffer> mBuffers = new .() ~ delete _;
	private List<WGPUBindGroup> mBindGroups = new .() ~ delete _;

	/// Called when a pass opens: rebinds the device and clears any residual state.
	public void Begin(WGPUDevice device)
	{
		mDevice = device;
		mGroup = -1;
		mLayout = null;
		mBlockSize = 0;
		mDirty = false;
		mBuffers.Clear();
		mBindGroups.Clear();

		// The SHADOW is cleared too. Push data is undefined until set, per pass, so a
		// reused pass encoder must not carry the previous pass's bytes into a draw that
		// never called SetPushConstants. Vulkan immediates would not.
		mShadow = .();
	}

	/// On SetPipeline: adopt the pipeline's emulated binding. A group below zero means
	/// the pipeline issues native immediates, and this helper stays inert for it.
	public void SetPipeline(PushConstantEmulation pushConstants)
	{
		mGroup = pushConstants.Group;
		mLayout = pushConstants.Layout;

		if (pushConstants.BlockSize > mBlockSize)
			mBlockSize = pushConstants.BlockSize;

		// A freshly bound pipeline needs its group set before anything draws.
		if (mGroup >= 0)
			mDirty = true;
	}

	/// On SetPushConstants: folds the sub range into the shadow.
	///
	/// Returns FALSE when the current pipeline is not emulating, which is the caller's
	/// signal to take the native immediates path instead.
	public bool Write(uint32 offset, uint32 size, void* data)
	{
		if (mGroup < 0)
			return false;

		if ((data != null) && ((uint64)offset + size <= cMaxBlockSize))
		{
			let source = (uint8*)data;
			for (uint32 i = 0; i < size; i++)
				mShadow[offset + i] = source[i];

			if (offset + size > mBlockSize)
				mBlockSize = offset + size;
		}

		mDirty = true;
		return true;
	}

	/// Before a draw or dispatch: when a fresh block is pending, uploads it to a NEW
	/// uniform buffer and hands back the group and bind group to set.
	///
	/// Returns false when nothing needs binding, either because this is not emulating or
	/// because the current block is already bound.
	public bool FlushBeforeDraw(out int32 group, out WGPUBindGroup bindGroup)
	{
		group = -1;
		bindGroup = null;

		if ((mGroup < 0) || !mDirty || (mLayout == null) || (mDevice == null))
			return false;

		var size = (mBlockSize > 0) ? mBlockSize : 16;
		size = (size + 15) & ~(uint32)15; // a uniform buffer rounds to sixteen
		if (size > cMaxBlockSize)
			size = cMaxBlockSize;

		WGPUBufferDescriptor bufferDesc = .();
		bufferDesc.size = size;
		bufferDesc.usage = WGPUBufferUsage_Uniform | WGPUBufferUsage_CopyDst;

		let buffer = wgpuDeviceCreateBuffer(mDevice, &bufferDesc);
		if (buffer == null)
			return false;

		let queue = wgpuDeviceGetQueue(mDevice);
		wgpuQueueWriteBuffer(queue, buffer, 0, &mShadow, size);
		wgpuQueueRelease(queue);

		WGPUBindGroupEntry entry = .();
		entry.binding = 0;
		entry.buffer = buffer;
		entry.offset = 0;
		entry.size = size;

		WGPUBindGroupDescriptor groupDesc = .();
		groupDesc.layout = mLayout;
		groupDesc.entryCount = 1;
		groupDesc.entries = &entry;

		let created = wgpuDeviceCreateBindGroup(mDevice, &groupDesc);
		if (created == null)
		{
			wgpuBufferRelease(buffer);
			return false;
		}

		mBuffers.Add(buffer);
		mBindGroups.Add(created);
		mDirty = false;

		group = mGroup;
		bindGroup = created;
		return true;
	}

	/// On pass End, and AFTER the pass encoder's own End: frees everything this pass made.
	public void Release()
	{
		for (let group in mBindGroups)
			wgpuBindGroupRelease(group);

		for (let buffer in mBuffers)
			wgpuBufferRelease(buffer);

		mBindGroups.Clear();
		mBuffers.Clear();
		mGroup = -1;
		mLayout = null;
		mDirty = false;
	}
}
