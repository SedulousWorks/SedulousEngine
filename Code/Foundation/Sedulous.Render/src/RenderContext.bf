using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Render;

/// The per worker extraction state: one arena and one item list per slot.
///
/// Parallel extraction fills the slots independently, each worker touching only its own, and
/// the merge then gathers them into the snapshot ON ONE THREAD. That is what lets extraction
/// run wide without a lock anywhere in the hot path.
///
/// The slots are separate allocations rather than list elements, so growing the pool never
/// moves an arena a worker is holding a reference to.
class RenderContext
{
	private List<FrameArena> mArenas = new .() ~ DeleteContainerAndItems!(_);
	private List<List<RenderData>> mLists = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mSlots = 0;

	/// Makes sure the slots exist, then resets every arena and list for a new frame. Once at
	/// the start of a frame, before any extraction.
	public void BeginFrame(uint32 slotCount)
	{
		let slots = Max(slotCount, (uint32)1);

		while ((uint32)mArenas.Count < slots)
		{
			mArenas.Add(new FrameArena());
			mLists.Add(new List<RenderData>());
		}

		mSlots = slots;
		for (uint32 slot = 0; slot < mSlots; slot++)
		{
			mArenas[(int)slot].Reset();
			mLists[(int)slot].Clear();
		}
	}

	/// Clears the item lists for a fresh extraction while the ARENAS keep what they hold: a
	/// second extraction in one frame reuses the memory rather than the items.
	public void ResetItems()
	{
		for (uint32 slot = 0; slot < mSlots; slot++)
			mLists[(int)slot].Clear();
	}

	public FrameArena Arena(uint32 slot) => mArenas[(int)slot];
	public List<RenderData> Items(uint32 slot) => mLists[(int)slot];
	public uint32 SlotCount => mSlots;

	/// Gathers every slot's items into the snapshot, on ONE thread, after the parallel fill.
	public void MergeInto(ExtractedScene outScene)
	{
		for (uint32 slot = 0; slot < mSlots; slot++)
		{
			for (let item in mLists[(int)slot])
				outScene.AddExternal(item);
		}
	}
}
