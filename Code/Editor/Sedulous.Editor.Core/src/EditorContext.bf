namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.UI;
using Sedulous.Engine.Core.Resources;
using Sedulous.Resources;

/// Central access point for all editor services.
/// Passed to plugins during initialization so they can register extensions.
class EditorContext : IDisposable
{
	// Embedded runtime (engine instance for preview)
	public Context RuntimeContext;

	// Editor services (owned)
	public EditorPageManager PageManager ~ delete _;
	public EditorSceneManager SceneEditor ~ delete _;
	public AssetSelection AssetSelection ~ delete _;
	public EditorPluginRegistry PluginRegistry ~ delete _;
	public EditorProject Project;

	// Scene serialization
	public SceneResourceManager SceneManager;

	// UI (editor shell)
	public DockManager DockManager;
	public MenuBar MenuBar;

	// Platform services
	public IDialogService DialogService;
	public IShell Shell;
	public ResourceSystem ResourceSystem;

	// Registries (owned)
	private List<IComponentInspector> mInspectors = new .() ~ delete _;
	private Dictionary<Type, IComponentInspector> mInspectorMap = new .() ~ delete _;
	private List<IAssetImporter> mImporters = new .() ~ delete _;
	private List<IAssetCreator> mCreators = new .() ~ delete _;
	private Dictionary<String, IAssetThumbnailGenerator> mThumbnailGens = new .() ~ {
		for (let kv in _) delete kv.key;
		delete _;
	};
	private List<IGizmoRenderer> mGizmos = new .() ~ delete _;
	private Dictionary<Type, IGizmoRenderer> mGizmoMap = new .() ~ delete _;
	private List<IEditorPanelFactory> mPanelFactories = new .() ~ delete _;
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

	/// Register a component inspector for a specific component type.
	public void RegisterComponentInspector(Type componentType, IComponentInspector inspector)
	{
		mInspectors.Add(inspector);
		mInspectorMap[componentType] = inspector;
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

	/// Register a thumbnail generator for a file extension.
	public void RegisterThumbnailGenerator(StringView @extension, IAssetThumbnailGenerator generator)
	{
		mThumbnailGens[new String(@extension)] = generator;
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

	// === Queries ===

	/// Find the inspector for a component type. Returns null if none registered.
	public IComponentInspector GetInspector(Type componentType)
	{
		if (mInspectorMap.TryGetValue(componentType, let inspector))
			return inspector;
		return null;
	}

	/// Find the gizmo renderer for a component type.
	public IGizmoRenderer GetGizmoRenderer(Type componentType)
	{
		if (mGizmoMap.TryGetValue(componentType, let renderer))
			return renderer;
		return null;
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
		for (let inspector in mInspectors)
		{
			inspector.Dispose();
			delete inspector;
		}
		mInspectors.Clear();
		mInspectorMap.Clear();

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

		for (let kv in mThumbnailGens)
			delete kv.value;
		mThumbnailGens.Clear();

		for (let factory in mPanelFactories)
			delete factory;
		mPanelFactories.Clear();
	}
}
