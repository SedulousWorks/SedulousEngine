namespace Sedulous.Editor.Core;

using System;
using System.IO;
using Sedulous.UI;
using Sedulous.Engine.App;
using Sedulous.Serialization;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.RuntimeGraphics;

/// Editor page for the per-project settings stored at
/// `<ProjectAssetDirectory>/project_settings.oddl`. Holds a working copy
/// that the user mutates through the form; Save applies it back to
/// EditorContext.ProjectSettings and writes the file. Acts as the
/// canonical authoring surface for fields the standalone EngineApplication
/// consumes at Boot.
///
/// Singleton page (PageId `project://settings`) - the menu item activates
/// the existing tab rather than opening a second copy. SaveFileExtension
/// is non-empty so the standard Save / Save All wiring picks it up; the
/// path is fixed and SaveAs is treated as Save.
class ProjectSettingsPage : IEditorPage
{
	private String mPageId = new .("project://settings") ~ delete _;
	private String mTitle = new .("Project Settings") ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private EditorContext mEditorContext;

	/// Working copy mutated by the form. On Save we publish it back to
	/// EditorContext.ProjectSettings + disk. Init from EditorContext so the
	/// form starts on the project's current values, not the struct defaults.
	private ProjectSettings mWorking;
	/// Snapshot of mWorking at the last successful Save (or page open).
	/// IsDirty compares against this so type-then-undo round trips to clean.
	private ProjectSettings mSavedBaseline;

	public Event<delegate void(ProjectSettingsPage)> OnDirtyChanged ~ _.Dispose();
	private bool mIsDirty;

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;
		mWorking = editorContext?.ProjectSettings ?? .();
		mSavedBaseline = mWorking;

		// Fixed path inside the project's asset dir. Computed once at
		// construction; if no project is loaded the path stays empty and
		// Save becomes a no-op (the host shouldn't open the page in that
		// state, but defensive in case it does).
		if (editorContext?.Project != null && editorContext.Project.ProjectDirectory.Length > 0)
			Path.InternalCombine(mFilePath, editorContext.Project.ProjectDirectory, ProjectSettingsIO.FileName);
	}

	public ProjectSettings Working
	{
		get => mWorking;
		set
		{
			mWorking = value;
			UpdateDirty();
		}
	}

	public void SetTargetWidth(int32 w)
	{
		if (mWorking.TargetWidth == w) return;
		mWorking.TargetWidth = w;
		UpdateDirty();
	}

	public void SetTargetHeight(int32 h)
	{
		if (mWorking.TargetHeight == h) return;
		mWorking.TargetHeight = h;
		UpdateDirty();
	}

	public void SetFitMode(FitMode mode)
	{
		if (mWorking.FitMode == mode) return;
		mWorking.FitMode = mode;
		UpdateDirty();
	}

	private void UpdateDirty()
	{
		let dirty = mWorking.TargetWidth != mSavedBaseline.TargetWidth
			|| mWorking.TargetHeight != mSavedBaseline.TargetHeight
			|| mWorking.FitMode != mSavedBaseline.FitMode;
		if (dirty == mIsDirty) return;
		mIsDirty = dirty;
		OnDirtyChanged(this);
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mIsDirty;
	public EditorCommandStack CommandStack => mCommandStack;

	/// Non-empty so the standard Save / Save All wiring treats this page
	/// as savable. The path is fixed (project_settings.oddl in the asset
	/// dir) - SaveAs is intentionally folded onto Save.
	public StringView SaveFileExtension => ".oddl";

	public void SetContentView(View view) { mContentView = view; }
	public EditorContext EditorContext => mEditorContext;

	public void Save()
	{
		let logger = mEditorContext?.Logger;

		if (mEditorContext?.Project == null || !mEditorContext.Project.IsLoaded)
		{
			logger?.Log(.Warning, "Project Settings: no project loaded - save skipped.");
			return;
		}
		if (mEditorContext.ResourceSystem == null)
		{
			logger?.Log(.Warning, "Project Settings: no resource system - save skipped.");
			return;
		}

		let dir = mEditorContext.Project.ProjectDirectory;
		if (ProjectSettingsIO.Save(dir, mEditorContext.ResourceSystem.SerializerProvider, mWorking) case .Err)
		{
			logger?.Log(.Error, scope $"Project Settings: failed to write {ProjectSettingsIO.FileName} to {dir}.");
			return;
		}

		// Publish into the editor's shared copy so the running Game page's
		// ProjectTarget preview-size lookup picks up the new values on its
		// next GetEffectivePreviewSize call. Open pages that cached fit
		// mode at construction (GameEditorPage) won't auto-refresh; that's
		// acceptable for the MVP - close + reopen the Game tab to pick up
		// the new default.
		mEditorContext.ProjectSettings = mWorking;
		mSavedBaseline = mWorking;
		UpdateDirty();

		// Status-bar message at the bottom of the editor shell is the
		// immediate "your click landed" signal; the log line is the
		// durable record (visible in the LogView panel).
		mEditorContext.SetStatus(scope $"Project Settings saved: {mFilePath}");
		logger?.Log(.Information, scope $"Project Settings saved: {mFilePath}");
	}

	/// SaveAs has no meaning for the singleton settings file - the path is
	/// fixed by the project layout. Treated as Save.
	public void SaveAs(StringView path) { Save(); }

	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}
}
