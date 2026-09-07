using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;

namespace Sedulous.Runtime;

/// Loads plugins into a context and, more importantly, gets them back out.
///
/// Unloading is the hard half. A plugin registers a serializable factory, which is a
/// FUNCTION POINTER into its library; if the library closes with that pointer still in the
/// registry, the next load of that type jumps into unmapped memory. So the host records
/// what each plugin added and takes it back before closing anything.
///
/// It records that by OBSERVING the registry across OnLoad rather than by asking the
/// plugin to declare it. A plugin that forgets to declare something is exactly the plugin
/// that crashes on unload, so the host does not rely on being told.
///
/// Observing rather than comparing snapshots either side, because a snapshot cannot tell
/// WHO added an id. Anything else that registered while OnLoad ran would be attributed to
/// the plugin and torn out with it, and an id the plugin re-registered over one that
/// already existed would be reversed although another party still owns it. The observer
/// fires only on a real insert, which is exactly the set that has to come back out.
///
/// Raptor reverses a runtime type registry as well. Beef resolves types at compile time
/// and ids are hashed from names, so there is no such table to reverse here: that half is
/// a difference in what the languages need, not a decision. What is NOT a difference is
/// the extension point. Anything a plugin registers in a layer ABOVE Runtime (a scene
/// manager's contributions being the case that exists today) plugs in through AddRecorder,
/// so one unload still reverses everything the plugin did.
class PluginHost
{
	private Context mContext;
	private List<PluginEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: each recorder belongs to the layer that supplied it and must outlive the
	/// host.
	private List<IRegistrationRecorder> mRecorders = new .() ~ delete _;

	public this(Context context)
	{
		mContext = context;
	}

	public ~this()
	{
		UnloadAll();
	}

	public int Count => mEntries.Count;

	/// Adds a recorder. BORROWED; it must outlive the host.
	///
	/// Add before loading anything: a plugin already loaded was not recorded through this
	/// recorder and unloading it will not reverse what it added there.
	public void AddRecorder(IRegistrationRecorder recorder)
	{
		if (recorder != null)
			mRecorders.Add(recorder);
	}

	/// Adds a statically linked plugin. THE CALLER OWNS the plugin object; the host only
	/// drives it.
	public void Add(IRuntimePlugin plugin)
	{
		if (plugin == null)
			return;

		let entry = new PluginEntry();
		entry.Plugin = plugin;
		entry.Library = null;
		entry.Name.Set(plugin.Name);
		mEntries.Add(entry);

		LoadRecording(entry);
	}

	/// Loads a plugin from a shared library and brings it up.
	///
	/// The library stays open until UnloadAll, because the plugin's code, its vtables and
	/// anything it registered all live there.
	public Result<void, ErrorCode> Load(StringView path)
	{
		let terminated = scope String(path);
		let library = Platform.BfpDynLib_Load(terminated);
		if (library == null)
		{
			GlobalLog(.Error, "PluginHost: could not open '{}'", path);
			return .Err(.NotFound);
		}

		let create = (function IRuntimePlugin())Platform.BfpDynLib_GetProcAddress(library, "CreatePlugin");
		if (create == null)
		{
			GlobalLog(.Error, "PluginHost: '{}' exports no CreatePlugin", path);
			Platform.BfpDynLib_Release(library);
			return .Err(.NotSupported);
		}

		let plugin = create();
		if (plugin == null)
		{
			GlobalLog(.Error, "PluginHost: CreatePlugin returned nothing in '{}'", path);
			Platform.BfpDynLib_Release(library);
			return .Err(.Internal);
		}

		let entry = new PluginEntry();
		entry.Plugin = plugin;
		entry.Library = library;
		entry.Name.Set(plugin.Name);
		mEntries.Add(entry);

		LoadRecording(entry);
		return .Ok;
	}

	/// Unloads everything in REVERSE load order, so a plugin built on another comes down
	/// before the one it was built on.
	public void UnloadAll(bool closeLibraries = true)
	{
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let entry = mEntries[i];

			// While the library is still open: the plugin's own teardown, then the
			// registrations that point into it.
			entry.Plugin.OnUnload(mContext);
			ReverseRecorded(entry);

			if (closeLibraries && (entry.Library != null))
				Platform.BfpDynLib_Release((Platform.BfpDynLib*)entry.Library);

			delete entry;
			mEntries.RemoveAt(i);
		}
	}

	/// Runs OnLoad with every registry observed, so whatever the plugin added is known
	/// without the plugin having to say.
	private void LoadRecording(PluginEntry entry)
	{
		GlobalSerializableRegistry.SetRegistrationObserver(new (id) => entry.RegisteredIds.Add(id));

		// One sink per recorder, in recorder order, so ReverseRecorded can pair them up.
		entry.Recorded.Clear();
		for (int i < mRecorders.Count)
			entry.Recorded.Add(new List<uint64>());
		for (int i < mRecorders.Count)
			mRecorders[i].Arm(entry.Recorded[i]);

		entry.Plugin.OnLoad(mContext);

		// Disarmed in reverse, and unconditionally: a recorder left armed would attribute
		// the NEXT plugin's registrations to this one.
		for (int i = mRecorders.Count - 1; i >= 0; i--)
			mRecorders[i].Disarm();
		GlobalSerializableRegistry.SetRegistrationObserver(null);
	}

	/// Takes back everything this plugin registered, in the reverse of the order it was
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
