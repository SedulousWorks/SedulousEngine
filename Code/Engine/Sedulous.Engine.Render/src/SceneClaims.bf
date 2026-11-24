using System;
using System.Collections;

namespace Sedulous.Engine.Render;

/// Claims on something one per scene that several holders may want at once (the view's camera,
/// its fade), each a value. Of the claims held, the highest order wins (a sequence's play begun
/// last), and of equal orders the one claimed last (the shot cut to); when it lets go the next
/// wins. A holder claiming again changes its value and keeps its place. Runtime state only: never
/// saved with the scene.
class SceneClaims<T> where T : struct
{
	private struct Entry
	{
		/// Compared, never dereferenced.
		public Object Holder;
		public uint64 Order;
		/// When it was claimed.
		public uint64 Serial;
		public T Value;
	}

	private List<Entry> mEntries = new .() ~ delete _;
	private uint64 mNextSerial = 1;

	public void Claim(Object holder, uint64 order, T value)
	{
		for (var entry in ref mEntries)
		{
			if (entry.Holder == holder)
			{
				entry.Order = order;
				entry.Value = value;
				return;
			}
		}
		mEntries.Add(.() { Holder = holder, Order = order, Serial = mNextSerial++, Value = value });
	}

	public void Release(Object holder)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Holder == holder)
			{
				mEntries.RemoveAt(i);
				return;
			}
		}
	}

	/// The winning claim's value; false when none is held.
	public bool Winning(out T value)
	{
		int best = -1;
		for (int i < mEntries.Count)
		{
			let entry = mEntries[i];
			if ((best < 0) || (entry.Order > mEntries[best].Order) ||
				((entry.Order == mEntries[best].Order) && (entry.Serial > mEntries[best].Serial)))
				best = i;
		}
		value = (best >= 0) ? mEntries[best].Value : default;
		return best >= 0;
	}
}
