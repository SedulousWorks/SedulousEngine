namespace Sedulous.Editor.Core;

using System;
using Sedulous.UI;
using Sedulous.Engine;

/// Hosts a running instance of the loaded IApplicationModule's game inside
/// the editor as a docked tab. Distinct from per-scene Simulate (the toolbar
/// Play button on SceneEditorPage), which runs the *currently edited* scene
/// with snapshot/restore. GameEditorPage runs the *whole game flow* end to
/// end via the page's own Play / Stop controls.
///
/// Page presence and game-running state are decoupled: opening the page
/// from the Game menu lands in an idle state, and the user explicitly
/// presses Play on the page toolbar to fire module.OnLaunch. This keeps
/// editor-layout restore (which re-opens persisted pages on startup) from
/// auto-launching gameplay just because a Game tab was open last session.
class GameEditorPage : IEditorPage
{
	private String mPageId = new .("game://main") ~ delete _;
	private String mTitle = new .("Game") ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private EditorContext mEditorContext;

	// Module + host captured at construction so a hypothetical mid-session
	// module swap doesn't leave Dispose calling OnExit on the wrong module.
	// Asset-only sessions construct the page with null module / host; the
	// page sits idle and the toolbar's Play button is a no-op.
	private IApplicationModule mModule;
	private IApplicationHost mHost;
	private bool mIsRunning;

	public Event<delegate void(GameEditorPage)> OnGameStateChanged ~ _.Dispose();

	public bool IsRunning => mIsRunning;
	public bool CanPlay => mModule != null && mHost != null && !mIsRunning;

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;
		mModule = editorContext?.Module;
		mHost = editorContext?.ApplicationHost;
	}

	/// Fires module.OnLaunch and flips the page into the running state.
	/// No-op if there's no module loaded or the game is already running.
	public void PlayGame()
	{
		if (!CanPlay) return;

		mModule.OnLaunch(mHost);
		mIsRunning = true;
		OnGameStateChanged(this);
	}

	/// Fires module.OnExit and returns the page to idle. No-op if the
	/// game isn't running.
	public void StopGame()
	{
		if (!mIsRunning) return;

		mModule?.OnExit(mHost);
		mIsRunning = false;
		OnGameStateChanged(this);
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
		// Page tab being closed while the game is still running - make
		// sure OnExit fires so the module can tear down whatever OnLaunch
		// allocated (mounts, scenes, audio, particle effects, etc.).
		if (mIsRunning && mModule != null && mHost != null)
		{
			mModule.OnExit(mHost);
			mIsRunning = false;
		}
		delete mContentView;
		mContentView = null;
	}
}
