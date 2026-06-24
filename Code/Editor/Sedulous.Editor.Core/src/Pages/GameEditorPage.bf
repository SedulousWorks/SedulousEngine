namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Shell.Input;
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

	// Owned objects (input handlers, controllers, etc.) - deleted on page dispose.
	private List<Object> mOwnedObjects = new .() ~ { for (let obj in _) delete obj; delete _; };

	// Viewport-scoped input adapters. The editor's IApplicationHost
	// returns these when this page is running so the module's
	// host.Mouse/Keyboard/GetGamepad calls see page-local coords and
	// only fire while the Game tab is the active editor page.
	// Created at construction (once we know the host's shell devices)
	// and torn down with the page.
	private GameMouseAdapter mMouseAdapter ~ delete _;
	private GameKeyboardAdapter mKeyboardAdapter ~ delete _;
	private Dictionary<int32, GameGamepadAdapter> mGamepadAdapters = new .() ~ DeleteDictionaryAndValues!(_);

	/// Register an object for cleanup when this page is disposed.
	public void AddOwnedObject(Object obj)
	{
		mOwnedObjects.Add(obj);
	}

	public Event<delegate void(GameEditorPage)> OnGameStateChanged ~ _.Dispose();

	public bool IsRunning => mIsRunning;
	public bool CanPlay => mModule != null && mHost != null && !mIsRunning;

	/// Viewport-scoped mouse for the running module. The editor's
	/// IApplicationHost returns this in place of `Shell.InputManager.Mouse`
	/// while the page is running. GameInputHandler pumps viewport-local
	/// coords into it on pointer move.
	public GameMouseAdapter MouseAdapter => mMouseAdapter;

	/// Viewport-scoped keyboard. Focus-gated on `mIsActive` so the
	/// module only sees keys while the Game tab is the active page.
	public GameKeyboardAdapter KeyboardAdapter => mKeyboardAdapter;

	/// Returns a focus-gated adapter for the gamepad at `index`. Lazily
	/// created; cached for the page's lifetime so repeat lookups don't
	/// reallocate. Returns null if the host's input manager doesn't
	/// expose a gamepad at this index.
	public GameGamepadAdapter GetGamepadAdapter(int32 index)
	{
		if (mGamepadAdapters.TryGetValue(index, let existing))
			return existing;

		let shellGamepad = mHost?.Shell?.InputManager?.GetGamepad(index);
		if (shellGamepad == null) return null;

		let adapter = new GameGamepadAdapter(shellGamepad);
		adapter.Focused = mIsActive;
		mGamepadAdapters[index] = adapter;
		return adapter;
	}

	private bool mIsActive;

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;
		mModule = editorContext?.Module;
		mHost = editorContext?.ApplicationHost;

		// Build the mouse / keyboard adapters around the host's shell
		// devices. Gamepad adapters are built lazily in GetGamepadAdapter
		// because the editor doesn't know how many pads the game module
		// will poll for and the shell's gamepad list is dynamic.
		let im = mHost?.Shell?.InputManager;
		if (im != null)
		{
			mMouseAdapter = new GameMouseAdapter(im.Mouse);
			mKeyboardAdapter = new GameKeyboardAdapter(im.Keyboard);
		}
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

	public void OnActivated()
	{
		mIsActive = true;
		if (mKeyboardAdapter != null) mKeyboardAdapter.Focused = true;
		for (let kv in mGamepadAdapters)
			kv.value.Focused = true;
	}

	public void OnDeactivated()
	{
		mIsActive = false;
		if (mKeyboardAdapter != null) mKeyboardAdapter.Focused = false;
		for (let kv in mGamepadAdapters)
			kv.value.Focused = false;
	}

	public void Update(float deltaTime)
	{
		// Tick the module's per-frame body in lockstep with the editor's
		// page update. Standalone EngineApplication calls module.OnUpdate
		// from its main loop; in the editor the page is the parallel
		// driver. Skipped while idle so OnLaunch's allocations don't get
		// touched before they exist (and don't get torn down twice if the
		// page tab outlives a Stop).
		if (mIsRunning && mModule != null && mHost != null)
			mModule.OnUpdate(mHost, deltaTime);

		// Drop per-frame mouse state (scroll deltas) so the next frame
		// starts clean unless GameInputHandler refeeds the adapter from
		// a viewport-local event.
		mMouseAdapter?.EndFrame();
	}

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
