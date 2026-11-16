using System;
using System.Collections;

namespace Sedulous.Render;

/// A pass's per-view state, one entry for each (view, frame in flight): a frame's views each get
/// their own, however many a frame has (split screen, render-texture cameras, probe faces), and
/// the table grows when a frame has more than it has seen. A fixed table indexed modulo its size
/// gave two views one entry, and the second destroyed a bind group the first's commands, recorded
/// earlier in the frame, still used.
class ViewSlots<T> where T : struct
{
	private List<T> mEntries = new .() ~ delete _;
	private uint32 mFrames = 1;

	/// How many frames are in flight (each view has that many entries). Set before first use.
	public void SetFramesInFlight(uint32 frames)
	{
		mFrames = (frames == 0) ? 1 : frames;
	}

	/// `view`'s entry for frame `frame`, the table grown to hold the view.
	public ref T At(uint32 view, uint32 frame)
	{
		let index = (int)view * (int)mFrames + (int)(frame % mFrames);
		if (index >= mEntries.Count)
		{
			let grown = ((int)view + 1) * (int)mFrames;
			while (mEntries.Count < grown)
				mEntries.Add(default);
		}
		return ref mEntries[index];
	}

	/// How many views the table holds now.
	public uint32 Views => (uint32)(mEntries.Count / (int)mFrames);

	/// Every entry, for the owner to release what each holds.
	public Span<T> All => mEntries;

	public void Clear() => mEntries.Clear();
}
