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
/// It records that by snapshotting the registry either side of OnLoad rather than by
/// asking the plugin to declare it. A plugin that forgets to declare something is exactly
/// the plugin that crashes on unload, so the host does not rely on being told.
class PluginHost
{
	private Context mContext;
	private List<PluginEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	public this(Context context)
	{
		mContext = context;
	}

	public ~this()
	{
		UnloadAll();
	}

	public int Count => mEntries.Count;

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
			for (let id in entry.RegisteredIds)
				SerializableRegistry.Unregister(id);

			if (closeLibraries && (entry.Library != null))
				Platform.BfpDynLib_Release((Platform.BfpDynLib*)entry.Library);

			delete entry;
			mEntries.RemoveAt(i);
		}
	}

	/// Calls OnLoad with the registry snapshotted either side, so whatever the plugin
	/// added is known without the plugin having to say.
	private void LoadRecording(PluginEntry entry)
	{
		let before = scope List<uint64>();
		SerializableRegistry.CopyIds(before);

		entry.Plugin.OnLoad(mContext);

		let after = scope List<uint64>();
		SerializableRegistry.CopyIds(after);

		for (let id in after)
		{
			if (!before.Contains(id))
				entry.RegisteredIds.Add(id);
		}
	}
}
