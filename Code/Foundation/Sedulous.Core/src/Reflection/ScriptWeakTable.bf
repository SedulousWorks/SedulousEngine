using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Core;

/// The one weak table for the process: what a script names a scene by, and the scene's systems
/// and facades. A script's entity value carries its scene as a slot and a generation here, four
/// bytes each, which is how an entity stays sixteen bytes: there is no room for a table in it,
/// so there is one table. An object takes its slot the first time a script names it
/// (ScriptWeakSlot) and frees it as it goes, so a handle kept past it answers null.
///
/// Generation 0 is never a live one: a zeroed slot and generation name nothing. Locked, since
/// scenes are made and destroyed on cook workers as well as the main thread.
sealed class ScriptWeakTable : IScriptWeakTable
{
	/// The table. Never deleted: an object freed in another type's static teardown still frees
	/// its slot here, and the process's end takes it.
	public static readonly ScriptWeakTable Shared = new .();

	private List<Object> mObjects = new .() ~ delete _;
	private List<uint32> mGenerations = new .() ~ delete _;
	private List<uint32> mFree = new .() ~ delete _;
	private Monitor mLock = new .() ~ delete _;

	/// Nothing to count: the table lives as long as the process.
	public void AddRef() {}
	public void ReleaseRef() {}

	public Object ResolveWeak(uint32 slot, uint32 generation)
	{
		if (generation == 0)
			return null;
		using (mLock.Enter())
		{
			if ((slot >= (uint32)mObjects.Count) || (mGenerations[(int)slot] != generation))
				return null;
			return mObjects[(int)slot];
		}
	}

	/// The handle to `owner`: the slot `slot` and `generation` hold when generation is not 0,
	/// else a new one, written there. Checked and taken under the lock, so two threads naming
	/// one object first at once take one slot.
	public ScriptWeakRef TakeOnce(Object owner, ref uint32 slot, ref uint32 generation)
	{
		using (mLock.Enter())
		{
			if (generation == 0)
			{
				if (!mFree.IsEmpty)
				{
					slot = mFree.PopBack();
				}
				else
				{
					slot = (uint32)mObjects.Count;
					mObjects.Add(null);
					mGenerations.Add(1);
				}
				mObjects[(int)slot] = owner;
				generation = mGenerations[(int)slot];
			}
			return .(this, slot, generation);
		}
	}

	/// Empties the slot when it still holds `generation`: its generation moves on (past 0 when it
	/// wraps), so no handle taken before resolves. Generation 0 frees nothing.
	public void Free(uint32 slot, uint32 generation)
	{
		if (generation == 0)
			return;
		using (mLock.Enter())
		{
			if ((slot >= (uint32)mObjects.Count) || (mGenerations[(int)slot] != generation))
				return;
			mObjects[(int)slot] = null;
			var next = generation + 1;
			if (next == 0)
				next = 1;
			mGenerations[(int)slot] = next;
			mFree.Add(slot);
		}
	}

	/// Whether a handle is one of this table's.
	public bool Holds(ScriptWeakRef handle)
	{
		IScriptWeakTable table = this;
		return handle.Table === table;
	}

	/// How many objects hold a slot now.
	public int LiveCount
	{
		get
		{
			using (mLock.Enter())
				return mObjects.Count - mFree.Count;
		}
	}
}

/// An object's place in ScriptWeakTable.Shared: a field of the object, taken the first time a
/// script names it and freed in its destructor. Zeroed, it holds none.
struct ScriptWeakSlot
{
	private uint32 mSlot;
	private uint32 mGeneration;

	/// The handle to `owner`, the object this is a field of, its slot taken now when it has none.
	public ScriptWeakRef Take(Object owner) mut
	{
		return ScriptWeakTable.Shared.TakeOnce(owner, ref mSlot, ref mGeneration);
	}

	/// Frees the slot: every handle to the object reads null from here.
	public void Free() mut
	{
		ScriptWeakTable.Shared.Free(mSlot, mGeneration);
		mGeneration = 0;
	}
}
