namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// Scene editing page. Owns hierarchy, viewport, and inspector layout.
/// Per-scene entity selection with change notifications.
class SceneEditorPage : IEditorPage, IResourceChangeListener
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private bool mDirty;

	// Scene (owned by RuntimeContext.SceneSubsystem - we hold a reference)
	private Scene mScene;

	// Resource GUID from last save (for registry tracking)
	private Guid mLastSavedGuid;

	// Editor context for serialization access
	private EditorContext mEditorContext;

	// Viewport state
	private GizmoMode mGizmoMode = .Translate;
	private bool mWorldSpace = false;

	public GizmoMode GizmoMode
	{
		get => mGizmoMode;
		set => mGizmoMode = value;
	}

	public bool WorldSpace
	{
		get => mWorldSpace;
		set => mWorldSpace = value;
	}

	// Per-scene entity selection
	private List<EntityHandle> mSelectedEntities = new .() ~ delete _;
	public Event<delegate void(SceneEditorPage)> OnSelectionChanged ~ _.Dispose();

	// Owned objects (adapters, controllers, etc.) - deleted on page dispose.
	private List<Object> mOwnedObjects = new .() ~ { for (let obj in _) delete obj; delete _; };

	public this(Scene scene, StringView filePath, EditorContext editorContext = null)
	{
		mScene = scene;
		mFilePath.Set(filePath);
		mEditorContext = editorContext;

		// Generate page ID from path or scene name.
		if (filePath.Length > 0)
			mPageId.Set(filePath);
		else
			mPageId.AppendF("scene_{}", (int)Internal.UnsafeCastToPtr(scene));

		UpdateTitle();

		// Listen for resource hot-reloads to rebuild prefab instances
		mEditorContext?.ResourceSystem?.AddChangeListener(this);
	}

	public ~this()
	{
		mEditorContext?.ResourceSystem?.RemoveChangeListener(this);
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;

	/// SceneEditorPage handles both .scene and .prefab files - the dispatch
	/// lives inside Save(). Match the current FilePath's extension so the
	/// Save As dialog filter is right; default to .scene for untitled pages.
	public StringView SaveFileExtension =>
		mFilePath.EndsWith(".prefab", .OrdinalIgnoreCase) ? ".prefab" : ".scene";

	/// Set the content view (built by ScenePageBuilder).
	public void SetContentView(View view) { mContentView = view; }

	public Scene Scene => mScene;
	public EditorContext EditorContext => mEditorContext;

	public Guid LastSavedGuid => mLastSavedGuid;

	public void Save()
	{
		if (mFilePath.Length == 0) return;

		// Resolve mFilePath (an absolute path) to a (mount, locator) pair by
		// walking the editor's mount entries.
		IWritableMount mount = null;
		let locator = scope String();
		if (mEditorContext == null ||
			!MountResolver.TryResolveAbsoluteWritable(mEditorContext.MountEntries, mFilePath, out mount, locator))
		{
			Console.WriteLine("ERROR: Save target is not inside any writable mount: {}", mFilePath);
			return;
		}

		Result<Guid> result;

		if (mFilePath.EndsWith(".prefab", .OrdinalIgnoreCase))
		{
			let prefabMgr = mEditorContext?.PrefabManager;
			if (prefabMgr == null) { Console.WriteLine("ERROR: No PrefabResourceManager"); return; }
			result = prefabMgr.SavePrefab(mScene, mount, locator);
		}
		else
		{
			if (mEditorContext?.SceneManager == null) return;
			result = mEditorContext.SceneManager.SaveScene(mScene, mount, locator);
		}

		if (result case .Ok(let guid))
		{
			mLastSavedGuid = guid;
			mDirty = false;
			UpdateTitle();
			Console.WriteLine("{} saved: {}", mFilePath.EndsWith(".prefab", .OrdinalIgnoreCase) ? "Prefab" : "Scene", mFilePath);
		}
		else
		{
			Console.WriteLine("ERROR: Failed to save: {}", mFilePath);
		}
	}

	public void SaveAs(StringView path)
	{
		mFilePath.Set(path);
		mPageId.Set(path);
		Save();
		UpdateTitle();
	}

	public void OnActivated() { }
	public void OnDeactivated() { }

	public void Update(float deltaTime) { }

	public void MarkDirty()
	{
		if (!mDirty)
		{
			mDirty = true;
			UpdateTitle();
		}
	}

	// === Entity Selection ===

	public EntityHandle PrimarySelection =>
		mSelectedEntities.Count > 0 ? mSelectedEntities[0] : .Invalid;

	public Span<EntityHandle> SelectedEntities =>
		mSelectedEntities.Count > 0 ? .(mSelectedEntities.Ptr, mSelectedEntities.Count) : .();

	public void SelectEntity(EntityHandle entity)
	{
		mSelectedEntities.Clear();
		if (entity != .Invalid)
			mSelectedEntities.Add(entity);
		OnSelectionChanged(this);
	}

	public void SelectEntities(Span<EntityHandle> entities)
	{
		mSelectedEntities.Clear();
		for (let e in entities)
			mSelectedEntities.Add(e);
		OnSelectionChanged(this);
	}

	public void AddToSelection(EntityHandle entity)
	{
		if (!mSelectedEntities.Contains(entity))
			mSelectedEntities.Add(entity);
		OnSelectionChanged(this);
	}

	public void ClearSelection()
	{
		mSelectedEntities.Clear();
		OnSelectionChanged(this);
	}

	public bool IsSelected(EntityHandle entity) =>
		mSelectedEntities.Contains(entity);

	// === Owned Objects ===

	/// Register an object for cleanup when this page is disposed.
	public void AddOwnedObject(Object obj)
	{
		mOwnedObjects.Add(obj);
	}

	// === Internal ===

	private void UpdateTitle()
	{
		mTitle.Clear();
		if (mFilePath.Length > 0)
		{
			// Extract filename without extension from path.
			let name = scope String();
			System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
			mTitle.Set(name);
		}
		else
		{
			mTitle.Set("Untitled Scene");
		}

		if (mDirty)
			mTitle.Append("*");
	}

	// === IResourceChangeListener ===

	public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
	{
		// Rebuild prefab instances when a .prefab resource is reloaded
		if (resource is PrefabResource)
		{
			let resSys = mEditorContext?.ResourceSystem;
			let provider = resSys?.SerializerProvider;
			if (resSys == null || provider == null) return;

			let sceneSub = mEditorContext?.RuntimeContext?.GetSubsystem<SceneSubsystem>();
			if (sceneSub == null) return;

			var prefabRef = ResourceRef(resource.Id, uri);
			defer prefabRef.Dispose();

			PrefabRebuilder.Rebuild(mScene, resource.Id, prefabRef,
				sceneSub.TypeRegistry, provider, resSys);

			// Refresh editor UI
			OnSelectionChanged(this);
		}
	}

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}
}
