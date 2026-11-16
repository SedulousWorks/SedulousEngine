using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.Render;

/// A renderer's per view uniforms (camera matrices and the like), one dynamic offset slot per
/// distinct view a frame.
///
/// A renderer resolves several runs per view, and a slot per run used up a fixed ring within one
/// view. The same bytes asked for again this frame get the slot already written. A frame that
/// asks for more views than the ring holds gets no slot for the rest, and the next frame's ring
/// holds that many (the first time logged): the ring cannot grow while the frame's draws already
/// name its buffer.
class ViewUniformRing
{
	private struct Written
	{
		/// The bytes' start in mBytes, a CPU copy: the mapping may be write combined.
		public uint32 At;
		public uint32 Size;
		public uint32 ByteOffset;
	}

	private DynamicUniformRing mRing ~ delete _;
	private String mLabel = new .() ~ delete _;
	private uint64 mSlotSize;
	/// Slots the next BeginFrame reserves.
	private uint32 mWanted;
	/// Distinct views asked for this frame.
	private uint32 mAsked = 0;
	private bool mOverflowLogged = false;
	private List<Written> mWritten = new .() ~ delete _;
	private List<uint8> mBytes = new .() ~ delete _;

	/// `slotSize` is the dynamic uniform stride (aligned as the adapter demands); `minViews` what
	/// the ring holds from the start.
	public this(IDevice device, uint32 framesInFlight, uint64 slotSize, uint32 minViews, StringView label)
	{
		mRing = new .(device, framesInFlight, slotSize, .Uniform | .CopyDst, label);
		mLabel.Set(label);
		mSlotSize = slotSize;
		mWanted = Math.Max(minViews, (uint32)1);
	}

	public void SetRetireQueue(GpuRetireQueue retire) => mRing.SetRetireQueue(retire);

	/// Starts a frame: the ring holds every view the last frame asked for, and `extraViews` this
	/// frame adds on top (a probe capture's faces, which cannot wait a frame for their slots).
	public bool BeginFrame(uint32 frameIndex, uint32 extraViews = 0)
	{
		if (!mRing.Reserve(mWanted + extraViews))
			return false;
		mRing.BeginFrame(frameIndex);
		mWritten.Clear();
		mBytes.Clear();
		mAsked = 0;
		return true;
	}

	/// The byte offset of the slot holding `size` bytes at `data` this frame: the one already
	/// written with them, else a new one. False when the frame's slots are exhausted.
	public bool SlotFor(void* data, uint32 size, out uint32 byteOffset)
	{
		byteOffset = 0;
		for (let written in mWritten)
		{
			if ((written.Size == size) && (Internal.MemCmp(&mBytes[(int)written.At], data, (int)size) == 0))
			{
				byteOffset = written.ByteOffset;
				return true;
			}
		}

		mAsked++;
		if (mAsked > mWanted)
		{
			if (!mOverflowLogged)
			{
				GlobalLog(.Warning, "{}: {} views this frame, the ring holds {}; it grows next frame", mLabel, mAsked, mWanted);
				mOverflowLogged = true;
			}
			mWanted = mAsked;
		}

		let range = ((uint64)size <= mSlotSize) ? mRing.Allocate() : DynamicUniformRange();
		if (!range.Ok)
			return false;

		Internal.MemCpy(range.Ptr, data, (int)size);
		let at = mBytes.Count;
		mBytes.Resize(at + (int)size);
		Internal.MemCpy(&mBytes[at], data, (int)size);
		mWritten.Add(.() { At = (uint32)at, Size = size, ByteOffset = range.ByteOffset });
		byteOffset = range.ByteOffset;
		return true;
	}

	public void EndFrame() => mRing.EndFrame();

	public IBuffer Buffer => mRing.Buffer;
	/// Bumps on growth.
	public uint32 Generation => mRing.Generation;
	public uint32 SlotsPerFrame => mRing.SlotsPerFrame;
	public uint32 FrameSlots => mRing.FrameAllocatedSlots;
}
