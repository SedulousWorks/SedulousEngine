namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Engine.Core;

/// Scene editing page. Owns hierarchy, viewport, and inspector layout.
/// Per-scene entity selection with change notifications.
class SceneEditorPage : IEditorPage
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
	}

	public ~this()
	{

	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;

	/// Set the content view (built by ScenePageBuilder).
	public void SetContentView(View view) { mContentView = view; }

	public Scene Scene => mScene;

	public Guid LastSavedGuid => mLastSavedGuid;

	public void Save()
	{
		if (mFilePath.Length == 0) return;
		if (mEditorContext?.SceneManager == null) return;

		if (mEditorContext.SceneManager.SaveSceneToFile(mScene, mFilePath) case .Ok(let guid))
		{
			mLastSavedGuid = guid;
			mDirty = false;
			UpdateTitle();
			Console.WriteLine("Scene saved: {}", mFilePath);
		}
		else
		{
			Console.WriteLine("ERROR: Failed to save scene: {}", mFilePath);
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

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}
}
