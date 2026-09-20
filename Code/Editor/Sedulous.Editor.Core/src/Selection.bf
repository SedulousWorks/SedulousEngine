using System;
using System.Collections;

namespace Sedulous.Editor.Core;

/// An ordered, deduplicated selection set with a primary element, Items[0], the gizmo pivot
/// and transform anchor, and a change event the inspector, hierarchy and gizmos subscribe
/// to. Selection is deliberately NOT undoable; Lumix and Traktor agree.
class Selection<T> where bool : operator T == T
{
	private List<T> mItems = new .() ~ delete _;

	/// Fired after any change to the set.
	public delegate void() OnChanged ~ delete _;

	public Span<T> Items => mItems;
	public bool IsEmpty => mItems.IsEmpty;
	public int Count => mItems.Count;

	/// The primary element, the pivot: the first item. Empty is the caller's to check.
	public T Primary => mItems[0];

	public bool Contains(T item)
	{
		for (let existing in mItems)
			if (existing == item)
				return true;
		return false;
	}

	public void Set(T item)
	{
		mItems.Clear();
		mItems.Add(item);
		Notify();
	}

	/// Replaces the selection; duplicates removed, the first occurrence stays primary.
	public void Set(Span<T> items)
	{
		mItems.Clear();
		for (let item in items)
			if (!Contains(item))
				mItems.Add(item);
		Notify();
	}

	public void Add(T item)
	{
		if (Contains(item))
			return;
		mItems.Add(item);
		Notify();
	}

	public void Remove(T item)
	{
		for (int i < mItems.Count)
		{
			if (mItems[i] == item)
			{
				mItems.RemoveAt(i);
				Notify();
				return;
			}
		}
	}

	/// Adds when absent, removes when present: a ctrl click.
	public void Toggle(T item)
	{
		if (Contains(item))
			Remove(item);
		else
			Add(item);
	}

	public void Clear()
	{
		if (mItems.IsEmpty)
			return;
		mItems.Clear();
		Notify();
	}

	private void Notify()
	{
		if (OnChanged != null)
			OnChanged();
	}
}
