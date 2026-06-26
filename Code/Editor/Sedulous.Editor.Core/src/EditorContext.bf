namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.UI;
using Sedulous.Engine;
using Sedulous.Engine.App;
using Sedulous.Engine.Core.Resources;
using Sedulous.Resources;
using Sedulous.Core.Logging.Abstractions;

/// Central access point for all editor services.
/// Passed to plugins during initialization so they can register extensions.
class EditorContext : IDisposable
{
	// Editor's own context (from Application base, for editor-side subsystems)
	public Context EditorAppContext;

	// Embedded runtime (engine instance for preview)
	public Context RuntimeContext;

	// Editor services (owned)
	public EditorPageManager PageManager ~ delete _;
	public EditorSceneManager SceneEditor ~ delete _;
	public AssetSelection AssetSelection ~ delete _;
	public EditorPluginRegistry PluginRegistry ~ delete _;
	public EditorProject Project;
	public EditorAssetCache AssetCache ~ delete _;

	/// Per-project render settings loaded from
	/// `<ProjectAssetDirectory>/project_settings.oddl` at project open.
	/// Drives the GameEditorPage "Project Target" preview mode and the
	/// editor Project Settings panel.
	public ProjectSettings ProjectSettings;

	// Scene serialization
	public SceneResourceManager SceneManager;
	public PrefabResourceManager PrefabManager;

	// UI (editor shell)
	public DockManager DockManager;
	public MenuBar MenuBar;

	/// Bottom-of-shell status section the editor draws below the dock.
	/// Pages call SetStatus to post transient messages ("Project Settings
	/// saved", "Scene reloaded", etc.). Null in headless contexts and
	/// before the editor shell has been built; SetStatus is a safe no-op
	/// in that case so pages don't need to null-check.
	public Label StatusLabel;

	// Platform services
	public IDialogService DialogService;
	public IShell Shell;
	public ResourceSystem ResourceSystem;

	/// The application module the editor is hosting (TowerDefense, an
	/// asset-only project, etc.) or null when running module-less - the
	/// editor fully supports the asset-only path. Game-mode features
	/// (Play Game, future game-bake actions) gate on this being non-null.
	public IApplicationModule Module;

	/// Host adapter passed to module.OnLaunch / OnExit. Routes Context to
	/// the editor's embedded RuntimeContext rather than the editor's own
	/// Application context. Null exactly when Module is null.
	public IApplicationHost ApplicationHost;

	/// Application-wide logger. Routes through EditorLogger so output appears in
	/// the LogView panel (and the console) at the configured minimum level.
	/// Prefer this over Console.WriteLine in editor code.
	public ILogger Logger;

	/// Async thumbnail dispatch + in-memory + disk cache. Owned and lifecycled
	/// by EditorApplication (created at startup, pumped each frame). Cells
	/// that want thumbnails for their bound asset call `Thumbnails.Request(...)`;
	/// per-extension generators registered via RegisterThumbnailGenerator are
	/// dispatched on demand. The destructor frees it - Dispose also nulls it
	/// for symmetry but skipping Dispose still cleans up.
	public ThumbnailService Thumbnails ~ delete _;

	/// Asset-browser-facing list of registered (scheme, mount, index) bundles.
	/// EditorApplication populates this when builtin/project mounts are set up
	/// and when the user mounts/unmounts extras through the asset browser.
	public List<MountEntry> MountEntries = new .() ~ DeleteContainerAndItems!(_);

	// Registries (owned). Each destructor block both deletes owned items AND
	// frees the container, so if Dispose() is skipped the items don't leak.
	// Dispose() Clear()s the containers first, so the destructor loops are
	// no-ops when Dispose did run - no double-free either way.
	private List<IAssetImporter> mImporters = new .() ~ {
		for (let item in _) delete item;
		delete _;
	};
	private List<IAssetCreator> mCreators = new .() ~ {
		for (let item in _) delete item;
		delete _;
	};
	private Dictionary<String, IAssetThumbnailGenerator> mThumbnailGens = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};
	private List<IGizmoRenderer> mGizmos = new .() ~ {
		for (let g in _) { g.Dispose(); delete g; }
		delete _;
	};
	private Dictionary<Type, IGizmoRenderer> mGizmoMap = new .() ~ delete _; // non-owning - mirrors mGizmos
	private List<IEditorPanelFactory> mPanelFactories = new .() ~ {
		for (let f in _) delete f;
		delete _;
	};
	private List<(String name, ContextMenu menu)> mMenuLookup = new .() ~ {
		for (let entry in _) delete entry.name;
		delete _;
	};

	// === Registration - plugins call these during Initialize() ===

	/// Register a panel factory for global panels (Console, Assets, plugin panels).
	public void RegisterPanelFactory(IEditorPanelFactory factory)
	{
		mPanelFactories.Add(factory);
	}

	/// Register an editor page factory for file types.
	public void RegisterPageFactory(IEditorPageFactory factory)
	{
		PageManager?.RegisterFactory(factory);
	}

	/// Register an asset importer.
	public void RegisterAssetImporter(IAssetImporter importer)
	{
		mImporters.Add(importer);
	}

	/// Register an asset creator (populates Create menus).
	public void RegisterAssetCreator(IAssetCreator creator)
	{
		mCreators.Add(creator);
	}

	/// Register a thumbnail generator for a file extension. Re-registering an
	/// extension replaces (and disposes) the prior generator while reusing
	/// the existing String key - the indexer assignment would otherwise
	/// silently leak a fresh String allocation per call.
	public void RegisterThumbnailGenerator(StringView @extension, IAssetThumbnailGenerator generator)
	{
		String key = new String(@extension);
		IAssetThumbnailGenerator* valPtr = ?;
		if (mThumbnailGens.TryAdd(key, ?, out valPtr))
		{
			*valPtr = generator;
		}
		else
		{
			// Key already in dictionary; free our just-allocated copy and
			// delete the prior generator before swapping in the new one.
			delete key;
			delete *valPtr;
			*valPtr = generator;
		}
	}

	/// Register a gizmo renderer for a component type.
	public void RegisterGizmoRenderer(Type componentType, IGizmoRenderer renderer)
	{
		mGizmos.Add(renderer);
		mGizmoMap[componentType] = renderer;
	}

	/// Add a menu item to the editor menu bar.
	/// Path format: "Physics/Bake NavMesh" -> menu "Physics", item "Bake NavMesh".
	public void AddMenuItem(StringView menuPath, delegate void() action)
	{
		if (MenuBar == null) return;

		let separatorIdx = menuPath.IndexOf('/');
		if (separatorIdx < 0) return;

		let menuName = menuPath[0..<separatorIdx];
		let itemName = menuPath[(separatorIdx + 1)...];

		// Find or create the top-level menu.
		ContextMenu targetMenu = null;
		for (int i = 0; i < mMenuLookup.Count; i++)
		{
			if (mMenuLookup[i].name == menuName)
			{
				targetMenu = mMenuLookup[i].menu;
				break;
			}
		}

		if (targetMenu == null)
		{
			targetMenu = MenuBar.AddMenu(menuName);
			mMenuLookup.Add((new String(menuName), targetMenu));
		}

		targetMenu.AddItem(itemName, action);
	}

	/// Post a transient message to the editor shell's status bar. No-op
	/// when the shell hasn't built one yet (early startup, headless).
	public void SetStatus(StringView text)
	{
		StatusLabel?.SetText(text);
	}

	// === Queries ===

	/// Find the gizmo renderer for a component type.
	public IGizmoRenderer GetGizmoRenderer(Type componentType)
	{
		if (mGizmoMap.TryGetValue(componentType, let renderer))
			return renderer;
		return null;
	}

	/// Find the importer that handles a file extension. Returns null if none registered.
	/// When more than one importer claims the extension, returns the first - use
	/// `GetImportersForExtension` if you need to disambiguate (e.g. show a chooser).
	public IAssetImporter GetImporterForExtension(StringView @extension)
	{
		let exts = scope List<String>();
		for (let importer in mImporters)
		{
			ClearAndDeleteItems(exts);
			importer.GetSupportedExtensions(exts);
			for (let ext in exts)
			{
				if (ext.Equals(@extension, .OrdinalIgnoreCase))
				{
					ClearAndDeleteItems(exts);
					return importer;
				}
			}
		}
		ClearAndDeleteItems(exts);
		return null;
	}

	/// Collect every importer that claims a file extension. Caller-owned list;
	/// importer references are borrowed (registry retains ownership).
	public void GetImportersForExtension(StringView @extension, List<IAssetImporter> outImporters)
	{
		let exts = scope List<String>();
		for (let importer in mImporters)
		{
			ClearAndDeleteItems(exts);
			importer.GetSupportedExtensions(exts);
			for (let ext in exts)
			{
				if (ext.Equals(@extension, .OrdinalIgnoreCase))
				{
					outImporters.Add(importer);
					break;
				}
			}
		}
		ClearAndDeleteItems(exts);
	}

	/// Collects all file extension filters from all registered importers.
	public void GetAllImportExtensions(List<String> outExtensions)
	{
		for (let importer in mImporters)
			importer.GetSupportedExtensions(outExtensions);
	}

	/// Get all registered asset creators.
	public void GetAssetCreators(List<IAssetCreator> outCreators)
	{
		for (let c in mCreators)
			outCreators.Add(c);
	}

	/// Find a thumbnail generator for a file extension.
	public IAssetThumbnailGenerator GetThumbnailGenerator(StringView @extension)
	{
		if (mThumbnailGens.TryGetValueAlt(@extension, let gen))
			return gen;
		return null;
	}

	/// Get all registered panel factories.
	public void GetPanelFactories(List<IEditorPanelFactory> outFactories)
	{
		for (let f in mPanelFactories)
			outFactories.Add(f);
	}

	// === Cleanup ===

	public void Dispose()
	{
		for (let gizmo in mGizmos)
		{
			gizmo.Dispose();
			delete gizmo;
		}
		mGizmos.Clear();
		mGizmoMap.Clear();

		for (let importer in mImporters)
			delete importer;
		mImporters.Clear();

		for (let creator in mCreators)
			delete creator;
		mCreators.Clear();

		// Delete both the owned String keys and the owned generators here;
		// after Clear() the field's destructor block sees an empty dict and
		// can't clean up. Doing both in one pass avoids leaking the keys.
		for (let kv in mThumbnailGens)
		{
			delete kv.key;
			delete kv.value;
		}
		mThumbnailGens.Clear();

		for (let factory in mPanelFactories)
			delete factory;
		mPanelFactories.Clear();

		if (Thumbnails != null)
		{
			delete Thumbnails;
			Thumbnails = null;
		}
	}
}
