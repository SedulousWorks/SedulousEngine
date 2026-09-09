using System;
using Sedulous.RHI;

namespace Sedulous.Render;

/// A per frame ring of uniform or storage slots.
///
/// The buffer is divided into one region per frame in flight, and a frame writes only into
/// its own: the GPU may still be reading the region two frames back, and a single region
/// would be rewritten under it.
class DynamicUniformRing
{
	private IDevice mDevice;
	private BufferUsage mUsage;
	private String mLabel = new .() ~ delete _;
	/// BORROWED. Null means growing DRAINS the device instead, which is what standalone and
	/// test use does.
	private GpuRetireQueue mRetire = null;

	private IBuffer mBuffer = null;
	private uint8* mMapped = null;

	private uint32 mFramesInFlight;
	private uint64 mSlotSize;
	private uint32 mSlotsPerFrame = 0;
	private uint32 mFrameBase = 0;
	private uint32 mCursor = 0;
	private uint32 mGeneration = 0;

	/// `slotSize` is the per allocation stride, which a dynamic offset uniform needs aligned
	/// to what the adapter demands and a storage ring can leave as the struct's own size.
	public this(IDevice device, uint32 framesInFlight, uint64 slotSize,
		BufferUsage usage = .Uniform | .CopyDst, StringView label = "ring")
	{
		mDevice = device;
		mUsage = usage;
		mLabel.Set(label);
		mFramesInFlight = Math.Max(framesInFlight, (uint32)1);
		mSlotSize = slotSize;
	}

	public ~this()
	{
		Release();
	}

	/// Makes sure each frame's region holds at least this many slots. Grows by REALLOCATING,
	/// and never shrinks.
	public bool Reserve(uint32 slotsPerFrame)
	{
		if ((slotsPerFrame <= mSlotsPerFrame) && (mBuffer != null))
			return true;

		let wanted = Math.Max(slotsPerFrame, (uint32)1);

		// A frame in flight may still be reading the old buffer. With a queue wired it is
		// retired, which is the web safe path; without one the device is drained.
		if (mRetire != null)
		{
			mRetire.Retire(mBuffer);
			mBuffer = null;
			mMapped = null;
		}
		else
		{
			mDevice.WaitIdle();
		}
		Release();

		var desc = BufferDesc();
		desc.Size = (uint64)mFramesInFlight * (uint64)wanted * mSlotSize;
		desc.Usage = mUsage;
		desc.Memory = .CpuToGpu;
		desc.Label = mLabel;

		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
		{
			mBuffer = null;
			return false;
		}

		mBuffer = buffer;
		mSlotsPerFrame = wanted;
		mGeneration++;
		return true;
	}

	/// Selects this frame's region and maps it for writing.
	public void BeginFrame(uint32 frameIndex)
	{
		mFrameBase = (frameIndex % mFramesInFlight) * mSlotsPerFrame;
		mCursor = 0;
		mMapped = (mBuffer != null) ? (uint8*)mBuffer.Map() : null;
	}

	/// A run of contiguous slots in this frame's region.
	///
	/// A refusal when the region is exhausted: the ring NEVER grows mid frame, since that
	/// would move the buffer out from under the draws already recorded against it.
	public DynamicUniformRange AllocateRange(uint32 count)
	{
		if ((mMapped == null) || (count == 0) || ((mCursor + count) > mSlotsPerFrame))
			return .();

		let slot = mFrameBase + mCursor;
		mCursor += count;

		let byteOffset = (uint64)slot * mSlotSize;
		return .(slot, (uint32)byteOffset, mMapped + byteOffset);
	}

	public DynamicUniformRange Allocate() => AllocateRange(1);

	public void EndFrame()
	{
		if ((mMapped != null) && (mBuffer != null))
			mBuffer.Unmap();
		mMapped = null;
	}

	public IBuffer Buffer => mBuffer;
	public uint64 SlotSize => mSlotSize;
	public uint64 ByteCapacity => (uint64)mFramesInFlight * (uint64)mSlotsPerFrame * mSlotSize;
	/// Bumped on every reallocation, which is what a cache over this buffer keys on.
	public uint32 Generation => mGeneration;
	public uint32 SlotsPerFrame => mSlotsPerFrame;

	/// Wires the retire queue, which makes growing web safe. Null drains instead.
	public void SetRetireQueue(GpuRetireQueue retire) => mRetire = retire;

	private void Release()
	{
		if (mBuffer != null)
			mDevice.DestroyBuffer(ref mBuffer);
		mMapped = null;
	}
}
