using System;
using Sedulous.Input;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Shell;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Engine.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.Input;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.DefaultApp;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Play;

/// What the Game tab asks of the editor.
class GameEditorPageServices
{
	/// Hosts its viewport; null: none (a test). Not owned.
	public GuiHost Gui = null;
	/// Its markup by its path under the data root, a node with one reference the page takes; null:
	/// a bare panel (a test).
	public delegate Node(StringView path) LoadMarkup ~ delete _;
}

/// The Game tab: plays the project's default scene through its OWN game instance, with the
/// startup script, the default input map and bus layout, the resolution it draws at (the project's
/// by default), and the script debugger beside the game (hidden until its toggle, or a breakpoint,
/// shows it).
///
/// On the GUI, from its markup (Data/Editor/
/// Game.xml): the kit's transport (Restart, Play, Pause, Stop, the state named beside them and the
/// scene it runs, a Play waiting for the cook said so), the resolution and the phone, the debugger's
/// toggle; the game on GUI.Viewport, which the GUI host binds, places and routes, and which keeps
/// every key while it runs and has the focus (Shift+F1 gives them back).
///
/// The context, host and embedded application are borrowed. The game instance is borrowed from
/// the application and released back to it on close.
class GameEditorPage : UIEditorPage, IPieInstancePage
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Game.xml";

	/// The tab's PIE id (IPieInstancePage.PieId).
	private String mPieId = new .() ~ delete _;
	/// TitleFor(mPieId).
	private String mTitle = new .() ~ delete _;
	private EditorContext mContext;
	private IApplicationHost mHost;
	private GameEditorPageServices mServices ~ delete _;
	private DefaultApplication mApp;
	/// THIS tab's running game: its own run host and scenes.
	private GameInstance mGameInstance;
	private SceneSubsystem mScenes = null;
	private RenderSubsystem mRender = null;
	private Sedulous.Scene.Scene mScene = null;
	private InputSubsystem mInput = null;
	private IInputManager mShellInput = null;
	private GameViewportInputSource mViewportSource = new .() ~ delete _;

	/// One reference, the page's.
	private Node mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	// The content's: the tree holds them.
	private ButtonBase mRestartButton = null;
	private ButtonBase mPlayButton = null;
	private ButtonBase mPauseToggle = null;
	private ButtonBase mStopButton = null;
	/// The transport's state: Stopped, Playing, Paused, Script error.
	private Sedulous.GUI.Label mStateLabel = null;
	/// The scene it runs.
	private Sedulous.GUI.Label mSceneLabel = null;
	/// Shown while a Play waits for the cook.
	private Sedulous.GUI.Label mCookBadge = null;
	/// Shows the script debugger beside the game. Off by default: it takes room the game wants,
	/// and is opened when needed (and by a breakpoint that pauses the run).
	private ButtonBase mDebuggerToggle = null;
	/// Held while it is out of the split.
	private Node mDebuggerPane = null ~ _?.ReleaseRef();
	/// The game beside the debugger (the markup's).
	private Splitter mStage = null;
	/// The debugger's share of the split, kept while it is off.
	private float mDebuggerShare = 0.22f;
	/// After the content: the trees it binds let go of its models first.
	private DebuggerPanel mDebuggerPanel = new .() ~ delete _;
	private GameDebugListener mDebugListener = new .() ~ delete _;
	/// The simulation was frozen for a breakpoint.
	private bool mSimPausedByDebugger = false;
	/// The breakpoints mirrored onto the debugger.
	private List<ScriptBreakpoint> mAppliedBreakpoints = new .() ~ DeleteContainerAndItems!(_);
	/// One reference, the page's: its pane holds its own.
	private Sedulous.GUI.Viewport mViewport ~ _.ReleaseRef();
	/// The placeholder scene group when there is no game instance.
	private SceneManager mFallbackScenes = new .() ~ delete _;

	private String mSceneTitle = new .() ~ delete _;
	private bool mRunning = false;
	/// Play latched, waiting for the cook to go idle.
	private bool mPendingPlay = false;
	/// The game asked to exit (Run.RequestExit); the run stops on the next OnUpdate.
	private bool mExitRequested = false;
	/// Frames rendered since the run started, and the run time a stopped run ended at.
	private uint64 mFrameCount = 0;
	private double mStoppedRunTime = 0;
	/// The PIE capture (pie_screenshot): armed by RequestViewportCapture, recorded in
	/// OnAfterSceneRender after the overlays, completed in the next OnUpdate.
	private ViewportCaptureRecorder mCapture = new .() ~ delete _;
	/// The scene rendered into the viewport this frame, and at what size.
	private bool mRenderedThisFrame = false;
	/// Where in the target the capture starts: the fitted image's corner, past the bars.
	private uint32 mCaptureX = 0;
	private uint32 mCaptureY = 0;
	private uint32 mCaptureWidth = 0;
	private uint32 mCaptureHeight = 0;

	/// `services` it takes; `pieId` names the tab: the id its dock panel persists under and the PIE
	/// tools address it by (`game-page`, then `game-page-1`, ...).
	public this(EditorContext context, IApplicationHost host, GameEditorPageServices services, DefaultApplication embeddedApp,
		GameInstance instance, StringView pieId)
	{
		mPieId.Set(pieId);
		TitleFor(pieId, mTitle);
		mContext = context;
		mHost = host;
		mServices = services;
		mApp = embeddedApp;
		mGameInstance = instance;

		mScenes = host.Subsystems.GetSubsystem<SceneSubsystem>();
		mRender = host.Subsystems.GetSubsystem<RenderSubsystem>();
		mInput = host.Subsystems.GetSubsystem<InputSubsystem>();
		mShellInput = (host.Shell != null) ? host.Shell.Input : null;

		mViewport = new Sedulous.GUI.Viewport();
		mViewport.AddClass("game-view");
		mViewport.ClearColor = .(0.248f, 0.248f, 0.272f, 1.0f); // sRGB, like every UI colour
		// The finished game, as the player draws it into its sRGB window: 8-bit sRGB rather than the
		// viewports' float default, so the Game tab matches the player and its screen UI can blend
		// encoded values through the target's UNORM view (RenderOverlays).
		mViewport.SetFormats(.RGBA8UnormSrgb, mViewport.DepthFormat);
		// Shift+F1 (the GUI's capture release) gives the keyboard back to the editor: the game view
		// lets the focus go too, as the game reads its keys while the view has it; a click in the
		// view takes it, and the capture, again.
		{
			let view = mViewport;
			mViewport.AddNamedListener("keysreleased", new [=view] (e) =>
				{
					let dispatcher = view.EventDispatcher;
					if ((dispatcher != null) && (dispatcher.FocusNode == view))
						dispatcher.FocusNode = null;
				});
		}
		// The game's input is the viewport's surface, gated to it (hover the mouse, focus the keys).
		mViewportSource.Viewport = mViewport;
		mViewportSource.ShellInput = mShellInput;
		if (mInput != null)
			mInput.SetSourceProvider(ActiveSource, null);

		// THIS instance's exit request stops THIS tab's run, whichever tab it is: the script
		// asking fires inside the embedded app's update, which runs before the pages, so the
		// stop is deferred to this page's next OnUpdate, no script call on the stack.
		if (mGameInstance != null)
			mGameInstance.SetExitRequest(new [=this](code) =>
				{
					GlobalLog(.Information, "Editor: Game: '{}' requested exit({})", mPieId, code);
					mExitRequested = true;
				});

		// The tab from its markup: the bar over the stage, the game beside the debugger.
		mContent = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(cMarkupPath) : null;
		if (mContent == null)
			mContent = new Panel(); // no markup: still a tab, with its viewport
		let stage = Find<Node>("game-view-pane");
		((stage != null) ? stage : mContent).AddChildAt(mViewport, 0);
		if (mServices.Gui != null)
			mViewport.HostIn(mServices.Gui);
		mStage = Find<Splitter>("game-stage");
		mDebuggerPane = Find<Node>("game-debugger");
		if (mDebuggerPane != null)
		{
			mDebuggerPane.AddRef();
			mDebuggerPanel.Bind(mDebuggerPane);
			ShowDebugger(false); // it takes room the game wants: opened by its toggle or a break
		}
		BindBar();
		RefreshToolbar();
	}

	public override StringView Title => mTitle;

	/// A Game tab's name from its play id, into `outTitle`: the first "Game", Play New Instance's
	/// "Game 2", "Game 3" (its id's number and one), so tabs side by side are told apart.
	public static void TitleFor(StringView pieId, String outTitle)
	{
		const String cNewInstance = "game-page-";
		if (!pieId.StartsWith(cNewInstance))
		{
			outTitle.Append("Game");
			return;
		}
		if (int64.Parse(pieId.Substring(cNewInstance.Length)) case .Ok(let number))
			outTitle.AppendF("Game {}", number + 1);
		else
			outTitle.Append(pieId);
	}

	/// The game's view (for tests: its focus and capture).
	public Sedulous.GUI.Viewport View => mViewport;
	/// Nothing here is a document.
	public override Result<void, ErrorCode> Save() => .Ok;
	public override Node Content => mContent;

	public bool IsRunning => mRunning;
	public Sedulous.Scene.Scene RunningScene => mScene;

	public StringView PieId => mPieId;
	public bool IsStarting => mPendingPlay;
	public StringView SceneName => (mScene != null) ? mScene.Name : "";
	public uint64 FrameCount => mFrameCount;
	public double RunTime => (mRunning && (mGameInstance != null)) ? mGameInstance.RunTime : mStoppedRunTime;

	public PieScriptState ScriptState
	{
		get
		{
			if (mGameInstance == null)
				return .None;
			if (mGameInstance.ScriptRunning)
				return .Running;
			return mGameInstance.ScriptFault.IsEmpty ? .None : .Faulted;
		}
	}

	public StringView ScriptFault => (mGameInstance != null) ? mGameInstance.ScriptFault : "";

	public void RequestViewportCapture(StringView path) => mCapture.Request(path);
	public ViewportCapture LastViewportCapture => mCapture.State;

	/// The instance's scenes, or the page's own placeholder group without an instance.
	public SceneManager SceneGroup => (mGameInstance != null) ? mGameInstance.Scenes : mFallbackScenes;

	/// Asks for a cook and starts once it is idle.
	public void Play()
	{
		if (mRunning || mPendingPlay)
			return;
		mContext.RequestCook(false);
		mPendingPlay = true;
		if (mContext.IsCookBusy)
			mContext.SetStatus("Game: waiting for cook...");
		RefreshToolbar();
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		// A capture recorded last frame: the GPU has to finish the copy.
		mCapture.Complete((host.Graphics != null) ? host.Graphics.Raw : null);
		if (mExitRequested)
		{
			mExitRequested = false;
			Stop();
		}
		if (mPendingPlay && !mContext.IsCookBusy)
		{
			mPendingPlay = false;
			StartRunNow();
		}
		FollowInstanceScene();
		AdvanceScriptedInput();
		TickResolution(dt);
		SyncGameFit(); // the target may have changed shape: the turn, and so the pointer's map
		// A running game owns every key while its view has the focus (the editor's focus moves and
		// its bindings stay out of it); Shift+F1 gives the keyboard back, the focus with it, until a
		// click in the view. Armed only while focused: armed whenever it ran, the release was undone
		// the next frame and the game kept the keys.
		let capture = mRunning && mViewport.IsFocused;
		if (mViewport.CapturesAllKeys != capture)
			mViewport.CapturesAllKeys = capture;
		RefreshToolbar();
		// The game UI's input (one pump for every Game tab) goes to the tab a playtest is
		// scripting, or failing that to the tab the keyboard is in; with neither, it stays with
		// the tab that took it last, so a lone tab keeps it from Play on. A focused tab leaves
		// another tab's playtest its input. Each run's screens are its own (run screens), so the
		// claim decides only whose menus the keys and clicks reach.
		if (mRunning && (mInput != null))
		{
			let anotherPlaytest = (mInput.ActiveSource is ScriptedInputSource) && (mInput.ActiveSource !== mScripted);
			let focused = mViewport.IsFocused && (mViewport.HostedSurface != null) && mViewport.HostedSurface.Focused;
			if (IsScripted || (focused && !anotherPlaytest))
				mInput.SetSourceProvider(ActiveSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		}
		// The window's text input follows the game GUI's focus: the viewport (the editor GUI's focused
		// node while playing) says the game's GUI wants text, and the editor GUI's bridge starts it.
		mViewport.SetHostedTextInputWanted((mApp != null) && (mApp.Gui != null) && mApp.Gui.WantsTextInput);
		DrainDebuggerState();
		SyncRunAudio();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (!mViewport.IsReady || !frame.Valid)
			return;
		// Idle (no run): the viewport keeps what it was cleared to (Stop asks for the clear).
		if (mScene == null)
			return;
		if ((mRender == null) || !mRender.IsReady)
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0) || !mViewport.IsTreeVisible)
			return;

		if ((mApp != null) && (mApp.Gui != null))
			mApp.Gui.RenderTextures(frame.Encoder, (uint32)frame.FrameIndex);

		let targetState = TargetState(mViewport.ColorTexture, mViewport.ColorState, .ShaderRead);
		mCaptureX = 0;
		mCaptureY = 0;
		mCaptureWidth = w;
		mCaptureHeight = h;
		let fit = GameFitIn(w, h);
		if (GameFitted(fit))
		{
			// At the render resolution (or turned), fitted into the panel as the player fits its
			// window; the capture is the game's image, without the bars.
			let dst = fit.DstRect();
			let viewport = ViewportRect((int32)dst.X, (int32)dst.Y, (uint32)Math.Max(dst.Width, 1.0f), (uint32)Math.Max(dst.Height, 1.0f));
			mRender.RenderScene(mScene, mViewport.ColorView, mViewport.ColorFormat, w, h, viewport,
				null, targetState, null, null, null, SceneSize.FromFit(fit));
			mCaptureX = (uint32)Math.Max(viewport.X, 0);
			mCaptureY = (uint32)Math.Max(viewport.Y, 0);
			mCaptureWidth = (uint32)Math.Min(viewport.Width, w - mCaptureX);
			mCaptureHeight = (uint32)Math.Min(viewport.Height, h - mCaptureY);
		}
		else
		{
			mRender.RenderScene(mScene, mViewport.ColorView, mViewport.ColorFormat, w, h, .(0, 0, w, h),
				null, targetState);
		}
		mViewport.ColorState = .ShaderRead;
		if (mRunning)
			mFrameCount++;
		mRenderedThisFrame = true;
	}

	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		let rendered = mRenderedThisFrame;
		mRenderedThisFrame = false;
		if (!mRunning || (mScene == null) || !mViewport.IsReady || !frame.Valid || (mRender == null))
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0))
			return;
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, mViewport.ColorState, .RenderTarget);
		// The GUI is shared between the Game tabs; each draws its own run's screen tier, laid out
		// at its own render resolution (the shared tier's global overlays draw above it).
		if ((mApp != null) && (mApp.Gui != null))
		{
			mApp.Gui.SetScreenResolution(mGameInstance, mRenderWidth, mRenderHeight, mRenderFit);
			mApp.Gui.SetScreenOrientation(mGameInstance, mOrientation);
			mApp.Gui.SetRenderRun(mGameInstance);
		}
		// Through the viewport's UNORM view: the screen UI blends encoded values, as in the player.
		mRender.RenderOverlays(frame.Encoder, mViewport.ColorView, mViewport.ColorFormat, w, h, frame.FrameIndex,
			mViewport.ColorAlternateView);
		if ((mApp != null) && (mApp.Gui != null))
			mApp.Gui.SetRenderRun(null);
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, .RenderTarget, .ShaderRead);
		mViewport.ColorState = .ShaderRead;
		// The capture, once the frame is whole: the scene, then the game's overlays over it.
		if (rendered && mCapture.Armed && (host.Graphics != null))
			mCapture.Record(host.Graphics.Raw, frame.Encoder, mViewport.ColorTexture, mViewport.ColorFormat, mCaptureWidth, mCaptureHeight, .ShaderRead,
				mCaptureX, mCaptureY, mRenderWidth, mRenderHeight);
	}

	public override void OnClose()
	{
		DropScriptedInput(); // before the sources it replaced are torn down
		Stop();
		if (mInput != null)
			mInput.ClearSourceProviderIf(mViewportSource);
		if (mGameInstance != null)
			mGameInstance.SetInputSource((mInput != null) ? mInput.ShellSource : null);
		if (mGameInstance != null)
			mGameInstance.SetExitRequest(null); // it points at this page, which is going
		if ((mApp != null) && (mGameInstance != null))
			mApp.ReleaseInstance(mGameInstance);
		mGameInstance = null;
		if (mHost.Graphics != null)
		{
			// A copy recorded last frame completes first: freeing its buffer in flight is the
			// device's error (the scene viewport's, 2026-10-25).
			mCapture.Complete(mHost.Graphics.Raw);
			mCapture.Release(mHost.Graphics.Raw); // the readback buffer, while the device lives
		}
	}

	/// The content's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	/// The bar from the markup: the transport, the resolutions and the phone, the debugger.
	private void BindBar()
	{
		mRestartButton = Find<ButtonBase>("game-restart");
		mPlayButton = Find<ButtonBase>("game-play");
		mPauseToggle = Find<ButtonBase>("game-pause");
		mStopButton = Find<ButtonBase>("game-stop");
		mStateLabel = Find<Sedulous.GUI.Label>("game-state");
		mSceneLabel = Find<Sedulous.GUI.Label>("game-scene");
		mCookBadge = Find<Sedulous.GUI.Label>("game-cook");
		mDebuggerToggle = Find<ButtonBase>("game-debugger-toggle");
		if (mRestartButton != null)
			mRestartButton.SetOnClick(new [=this] () =>
				{
					Stop();
					Play();
				});
		if (mPlayButton != null)
			mPlayButton.SetOnClick(new [=this] () => { Play(); });
		if (mPauseToggle != null)
			mPauseToggle.SetOnToggled(new [=this] (paused) =>
				{
					if ((mScene != null) && mRunning)
						mScene.SetSimulationEnabled(!paused);
					RefreshToolbar();
				});
		if (mStopButton != null)
			mStopButton.SetOnClick(new [=this] () => { Stop(); });
		if (mDebuggerToggle != null)
			mDebuggerToggle.SetOnToggled(new [=this] (shown) => { ShowDebugger(shown); });
		BindResolution();
	}

	private void ShowDebugger(bool shown)
	{
		if (mDebuggerPane == null)
			return;
		if (mStage == null)
		{
			mDebuggerPane.Displayed = shown; // no split: the stage gives the game the room back
			return;
		}
		// In the split while it is on, at the share it was last given; out of it while it is off,
		// the game taking the whole stage (a hidden pane would keep its share empty).
		let inSplit = mDebuggerPane.Parent == mStage;
		if (shown && !inSplit)
		{
			mStage.AddChild(mDebuggerPane);
			float[2] weights = .(1.0f - mDebuggerShare, mDebuggerShare);
			mStage.SetWeights(Span<float>(&weights[0], 2));
		}
		else if (!shown && inSplit)
		{
			let weights = scope List<float>();
			mStage.GetWeights(weights);
			if ((weights.Count == 2) && (weights[1] > 0.0f))
				mDebuggerShare = weights[1];
			mStage.RemoveChild(mDebuggerPane);
		}
	}

	/// Whether the script debugger is beside the game now.
	public bool DebuggerShown
	{
		get
		{
			if (mDebuggerPane == null)
				return false;
			return (mStage != null) ? (mDebuggerPane.Parent == mStage) : mDebuggerPane.Displayed;
		}
	}

	/// The kit's transport as the run is now: Play while stopped, Pause and Stop while it runs (or
	/// waits for the cook), Restart either way; its state named beside it (Playing, Paused, a
	/// script's fault) and the scene it runs.
	private void RefreshToolbar()
	{
		let faulted = mRunning && (ScriptState == .Faulted);
		let paused = mRunning && (mSimPausedByDebugger || ((mPauseToggle != null) && mPauseToggle.Checked));
		if (mPlayButton != null)
			mPlayButton.Enabled = !mRunning && !mPendingPlay;
		if (mPauseToggle != null)
			mPauseToggle.Enabled = mRunning;
		if (mStopButton != null)
			mStopButton.Enabled = mRunning || mPendingPlay;
		if ((mCookBadge != null) && (mCookBadge.Displayed != mPendingPlay))
			mCookBadge.Displayed = mPendingPlay;
		if (mStateLabel != null)
		{
			let state = !mRunning ? "Stopped" : (faulted ? "Script error" : (paused ? "Paused" : "Playing"));
			let kind = !mRunning ? "stopped" : (faulted ? "faulted" : (paused ? "paused" : "playing"));
			if (mStateLabel.Text != state)
			{
				mStateLabel.Text = state;
				StringView[4] kinds = .("stopped", "faulted", "paused", "playing");
				for (let old in kinds)
					mStateLabel.RemoveClass(old);
				mStateLabel.AddClass(kind);
				mStateLabel.Tooltip = faulted ? ScriptFault : "";
			}
		}
		if (mSceneLabel != null)
		{
			let scene = mRunning ? (StringView)mSceneTitle : "";
			if (mSceneLabel.Text != scene)
				mSceneLabel.Text = scene;
		}
	}
}
