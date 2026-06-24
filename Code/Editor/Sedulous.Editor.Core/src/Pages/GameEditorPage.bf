namespace Sedulous.Editor.Core;

using System;
using Sedulous.UI;

/// Hosts a running instance of the loaded IApplicationModule's game inside
/// the editor as a docked tab. Distinct from per-scene Simulate (the toolbar
/// Play button on SceneEditorPage), which runs the *currently edited* scene
/// with snapshot/restore. GameEditorPage runs the *whole game flow* end to
/// end - it fires module.OnLaunch on construction and module.OnExit on
/// disposal, hosts the scene the module spawns, and draws the game's screen
/// UI in its viewport. Phase 6A is the skeleton: the page exists with an
/// empty viewport and a Stop button. Phase 6B wires OnLaunch/OnExit.
class GameEditorPage : IEditorPage
{
	private String mPageId = new .("game://main") ~ delete _;
	private String mTitle = new .("Game") ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private EditorContext mEditorContext;

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;

	/// Empty extension marks the page as read-only - Save / Save As / Save All
	/// menu items skip it. The game tab doesn't represent a serialisable
	/// document; persistence happens through whatever the module writes.
	public StringView SaveFileExtension => "";

	public void SetContentView(View view) { mContentView = view; }
	public EditorContext EditorContext => mEditorContext;

	public void Save() { }
	public void SaveAs(StringView path) { }

	public void OnActivated() { }
	public void OnDeactivated() { }

	public void Update(float deltaTime) { }

	public void Dispose()
	{
		// Phase 6B: call module.OnExit here.
		delete mContentView;
		mContentView = null;
	}
}
