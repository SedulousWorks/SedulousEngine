using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;

namespace Sedulous.Runtime;

/// Loads plugin parts and, more importantly, gets them back out. The PluginHost, which
/// decides what a project enables, loads parts through it; every part is compiled in.
///
/// Unloading is the hard half. A part registers serializable factories and table entries; a
/// plugin no longer enabled must leave none of them behind, or its types stay constructible
/// and its contributions keep joining scenes. So the loader records what each part added and
/// takes it back when the part unloads.
///
/// It records that by OBSERVING the registry across the part's load rather than by asking
/// the part to declare it. A part that forgets to declare something is exactly the part that
/// leaves something behind, so the loader does not rely on being told.
///
/// Observing rather than comparing snapshots either side, because a snapshot cannot tell
/// WHO added an id. Anything else that registered while the load ran would be attributed to
/// the part and torn out with it, and an id the part re-registered over one that already
/// existed would be reversed although another party still owns it. The observer fires only
/// on a real insert, which is exactly the set that has to come back out.
///
/// There is no runtime type registry to reverse: Beef resolves types at compile time and
/// ids are hashed from names. What the extension point does cover is anything a plugin
/// registers in a layer ABOVE Runtime (a scene manager's contributions being the case that
/// exists today), which plugs in through AddRecorder, so one unload still reverses
/// everything the part did.
class PluginLoader
{
	private List<PluginEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: each recorder belongs to the layer that supplied it and must outlive the
	/// loader.
	private List<IRegistrationRecorder> mRecorders = new .() ~ delete _;

	public ~this()
	{
		UnloadAll();
	}

	public int Count => mEntries.Count;

	/// The plugin whose parts' loads registered serializable type `id`, or empty for a type no
	/// loaded part registered (the engine's).
	public StringView OwnerOf(uint64 id)
	{
		for (let entry in mEntries)
		{
			if ((entry.Context != null) && entry.RegisteredIds.Contains(id))
				return entry.Context.PluginId;
		}
		return default;
	}

	/// Appends to `outIds` every serializable type the parts of plugin `pluginId` registered.
	public void TypesOf(StringView pluginId, List<uint64> outIds)
	{
		for (let entry in mEntries)
		{
			if ((entry.Context != null) && (entry.Context.PluginId == pluginId))
				outIds.AddRange(entry.RegisteredIds);
		}
	}

	/// Adds a recorder. BORROWED; it must outlive the loader.
	///
	/// Add before loading anything: a part already loaded was not recorded through this
	/// recorder and unloading it will not reverse what it added there.
	public void AddRecorder(IRegistrationRecorder recorder)
	{
		if (recorder != null)
			mRecorders.Add(recorder);
	}

	/// Loads a plugin part compiled into this binary: calls its Load with `context` under the
	/// recording. Both are BORROWED, and `context` must outlive the part's unload.
	public void AddPart(PluginPart part, PluginContext context)
	{
		if ((part == null) || (context == null))
			return;

		let entry = new PluginEntry();
		entry.Part = part;
		entry.Context = context;
		entry.Name.AppendF("{}.{}", part.PluginId, part.Kind);
		mEntries.Add(entry);

		LoadRecording(entry);
	}

	/// Unloads everything in REVERSE load order, so a part built on another comes down
	/// before the one it was built on: each part's own teardown, then what it registered.
	public void UnloadAll()
	{
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let entry = mEntries[i];
			entry.Part.Unload(entry.Context);
			ReverseRecorded(entry);
			delete entry;
			mEntries.RemoveAt(i);
		}
	}

	/// Runs the part's load with every registry observed, so whatever it added is known
	/// without the part having to say.
	private void LoadRecording(PluginEntry entry)
	{
		GlobalSerializableRegistry.SetRegistrationObserver(new (id) => entry.RegisteredIds.Add(id));

		// One sink per recorder, in recorder order, so ReverseRecorded can pair them up.
		entry.Recorded.Clear();
		for (int i < mRecorders.Count)
			entry.Recorded.Add(new List<uint64>());
		for (int i < mRecorders.Count)
			mRecorders[i].Arm(entry.Recorded[i]);

		entry.Part.Load(entry.Context);

		// Disarmed in reverse, and unconditionally: a recorder left armed would attribute
		// the NEXT part's registrations to this one.
		for (int i = mRecorders.Count - 1; i >= 0; i--)
			mRecorders[i].Disarm();
		GlobalSerializableRegistry.SetRegistrationObserver(null);
	}

	/// Takes back everything this part registered, in the reverse of the order it was
	/// recorded.
	///
	/// The extra recorders go FIRST: a scene manager has to let go of live scenes before
	/// the types those scenes are built out of stop being constructible.
	private void ReverseRecorded(PluginEntry entry)
	{
		for (int r = entry.Recorded.Count - 1; r >= 0; r--)
		{
			if (r < mRecorders.Count)
			{
				let recorded = entry.Recorded[r];
				for (int i = recorded.Count - 1; i >= 0; i--)
					mRecorders[r].Reverse(recorded[i]);
			}
			entry.Recorded[r].Clear();
		}

		for (int i = entry.RegisteredIds.Count - 1; i >= 0; i--)
			GlobalSerializableRegistry.Unregister(entry.RegisteredIds[i]);
		entry.RegisteredIds.Clear();
	}
}
