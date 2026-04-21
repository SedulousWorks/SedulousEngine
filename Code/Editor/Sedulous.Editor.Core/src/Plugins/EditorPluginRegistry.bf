namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Discovers, initializes, and manages editor plugins.
/// Scans Type.Types for [EditorPlugin]-attributed classes at startup.
class EditorPluginRegistry
{
	private List<IEditorPlugin> mPlugins = new .() ~ delete _;
	private bool mInitialized;

	/// Discover all [EditorPlugin]-attributed classes via reflection.
	/// Call once at startup before InitializeAll.
	public void DiscoverPlugins()
	{
		for (let type in Type.Types)
		{
			if (type.HasCustomAttribute<EditorPluginAttribute>())
			{
				if (type.CreateObject() case .Ok(let obj))
				{
					if (let plugin = obj as IEditorPlugin)
						mPlugins.Add(plugin);
					else
						delete obj;
				}
			}
		}

		// Sort by priority (lower = init first).
		mPlugins.Sort(scope (a, b) =>
		{
			int32 pa = 0, pb = 0;
			let ta = a.GetType();
			let tb = b.GetType();
			if (ta.HasCustomAttribute<EditorPluginAttribute>())
				if (ta.GetCustomAttribute<EditorPluginAttribute>() case .Ok(let attr))
					pa = attr.Priority;
			if (tb.HasCustomAttribute<EditorPluginAttribute>())
				if (tb.GetCustomAttribute<EditorPluginAttribute>() case .Ok(let attr))
					pb = attr.Priority;
			return pa <=> pb;
		});
	}

	/// Initialize all discovered plugins. Call after UI is ready.
	public void InitializeAll(EditorContext context)
	{
		for (let plugin in mPlugins)
			plugin.Initialize(context);
		mInitialized = true;
	}

	/// Update all plugins. Call once per frame.
	public void UpdateAll(float deltaTime)
	{
		for (let plugin in mPlugins)
			plugin.Update(deltaTime);
	}

	/// Shutdown all plugins in reverse order.
	public void ShutdownAll()
	{
		for (int i = mPlugins.Count - 1; i >= 0; i--)
		{
			mPlugins[i].Shutdown();
			mPlugins[i].Dispose();
			delete mPlugins[i];
		}
		mPlugins.Clear();
		mInitialized = false;
	}

	/// Number of discovered plugins.
	public int Count => mPlugins.Count;
}
