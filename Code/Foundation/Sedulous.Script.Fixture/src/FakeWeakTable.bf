using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Script.Fixture;

/// A weak table in the shape a real owner's is: slots with generations, a freed slot reused
/// with its generation bumped, so a handle taken before answers null. Not on the surface: a
/// script reaches it only through the handles it resolves. Counted, so a test can see every
/// handle a script kept come back.
class FakeWeakTable : RefCounted, IScriptWeakTable
{
	private List<Object> mObjects = new .() ~ delete _;
	private List<uint32> mGenerations = new .() ~ delete _;
	private List<uint32> mFree = new .() ~ delete _;
	private bool mClosed = false;

	/// A slot for `obj`, a freed one first.
	public uint32 Take(Object obj)
	{
		if (!mFree.IsEmpty)
		{
			let slot = mFree.PopBack();
			mObjects[slot] = obj;
			return slot;
		}
		mObjects.Add(obj);
		mGenerations.Add(0);
		return (uint32)(mObjects.Count - 1);
	}

	public uint32 GenerationOf(uint32 slot) => mGenerations[slot];

	/// Empties the slot: its generation moves on, so no handle taken before resolves.
	public void Free(uint32 slot)
	{
		if ((slot >= (uint32)mObjects.Count) || (mObjects[slot] == null))
			return;
		mObjects[slot] = null;
		mGenerations[slot]++;
		mFree.Add(slot);
	}

	/// What an owner going does: nothing resolves any more, whatever handles are out.
	public void Close()
	{
		mClosed = true;
		for (int i < mObjects.Count)
			mObjects[i] = null;
	}

	public Object ResolveWeak(uint32 slot, uint32 generation)
	{
		if (mClosed || (slot >= (uint32)mObjects.Count) || (mGenerations[slot] != generation))
			return null;
		return mObjects[slot];
	}
}
