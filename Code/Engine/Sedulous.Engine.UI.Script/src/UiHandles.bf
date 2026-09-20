using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Script;

/// The identity behind every UI handle a script holds.
///
/// A handle is a view's id and nothing else, so a script may copy it freely and a VM may
/// carry it by value; this table resolves it to the live view. An entry holds one
/// reference on its view, and is SWEPT once that is the only reference left, the tree
/// having let the view go: from then on the handle reads null but valid, the loud null a
/// script sees rather than a dangling pointer. What a view's script bindings own, its click
/// callbacks, dies with the entry.
static class UiHandles
{
	private class Entry
	{
		public View View;
		public List<ScriptDelegate> Owned = null ~ { if (_ != null) DeleteContainerAndItems!(_); };
	}

	private static Dictionary<uint32, Entry> sEntries = new .() ~ DeleteDictionaryAndValues!(_);

	/// The handle id for a live view, registering it if new. Nought for null.
	public static uint32 IdOf(View view)
	{
		if (view == null)
			return 0;
		let id = view.Id.RawValue;
		if (!sEntries.ContainsKey(id))
		{
			let entry = new Entry();
			entry.View = view;
			view.AddRef();
			sEntries[id] = entry;
		}
		return id;
	}

	/// The live view behind a handle, null once the tree has dropped it.
	public static View Resolve(uint32 id)
	{
		if (id == 0)
			return null;
		if (!sEntries.TryGetValue(id, let entry))
			return null;
		if (entry.View.RefCount <= 1)
		{
			// Ours is the last reference: the view is out of every tree. Let it go.
			Drop(id, entry);
			return null;
		}
		return entry.View;
	}

	public static T Resolve<T>(uint32 id) where T : View => Resolve(id) as T;

	/// Parks a delegate with the view it is bound to, to die with the view.
	public static void Own(View view, ScriptDelegate d)
	{
		let id = IdOf(view);
		if ((id == 0) || (d == null))
			return;
		let entry = sEntries[id];
		if (entry.Owned == null)
			entry.Owned = new .();
		entry.Owned.Add(d);
	}

	/// Releases every view the trees have dropped. Cheap; a host may call it per frame, and
	/// a resolve does its own.
	public static void Sweep()
	{
		// Dropping a parent releases its children, which may then be ours alone: again
		// until nothing moves.
		let dropped = scope List<uint32>();
		repeat
		{
			dropped.Clear();
			for (let kv in sEntries)
			{
				if (kv.value.View.RefCount <= 1)
					dropped.Add(kv.key);
			}
			for (let id in dropped)
				Drop(id, sEntries[id]);
		}
		while (!dropped.IsEmpty);
	}

	/// Everything, whatever its references: process teardown.
	public static void Clear()
	{
		for (let kv in sEntries)
		{
			kv.value.View.ReleaseRef();
			delete kv.value;
		}
		sEntries.Clear();
	}

	public static int Count => sEntries.Count;

	private static void Drop(uint32 id, Entry entry)
	{
		sEntries.Remove(id);
		let view = entry.View;
		delete entry; // the owned delegates first: a callback must not outlive its button
		view.ReleaseRef();
	}
}
