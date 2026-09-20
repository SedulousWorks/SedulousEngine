using System;
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
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Runtime;
using Sedulous.UI.Viewport;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The Game tab: plays the project's default scene through its OWN game instance, with the
/// startup script, the default input map and bus layout, a play/pause/stop/restart toolbar,
/// a fixed resolution cycle, and the script debugger beside the viewport.
///
/// The context, host, UI host and embedded application are borrowed. The game instance is
/// borrowed from the application and released back to it on close.
class GameEditorPage : UIEditorPage
{
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private DefaultApplication mApp;
	/// THIS tab's running game: its own run host and scenes.
	private GameInstance mGameInstance;
	/// Tracks dock and float moves.
	private RenderWindow mHostWindow = null;
	private SceneSubsystem mScenes = null;
	private RenderSubsystem mRender = null;
	private Sedulous.Scene.Scene mScene = null;
	private InputSubsystem mInput = null;
	private IInputManager mShellInput = null;
	private GameViewportInputSource mViewportSource = new .() ~ delete _;

	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private Toolbar mToolbar;
	private ToolbarButton mPlayButton;
	private ToolbarButton mStopButton;
	private ToolbarToggle mPauseToggle;
	private ToolbarButton mRestartButton;
	private ToolbarButton mResolutionButton;
	private uint32 mResolutionMode = 0;
	private DebuggerPanel mDebuggerPanel = new .() ~ delete _;
	private GameDebugListener mDebugListener = new .() ~ delete _;
	/// The simulation was frozen for a breakpoint.
	private bool mSimPausedByDebugger = false;
	/// The breakpoints mirrored onto the debugger.
	private List<ScriptBreakpoint> mAppliedBreakpoints = new .() ~ DeleteContainerAndItems!(_);
	private Label mStatusLabel;
	private ViewportView mViewport;
	/// Gates the viewport surface: hover and focus.
	private InputRouter mRouter = null ~ delete _;
	/// The placeholder scene group when there is no game instance.
	private SceneManager mFallbackScenes = new .() ~ delete _;

	private String mSceneTitle = new .() ~ delete _;
	private bool mRunning = false;
	/// Play latched, waiting for the cook to go idle.
	private bool mPendingPlay = false;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, DefaultApplication embeddedApp,
		GameInstance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mApp = embeddedApp;
		mGameInstance = instance;

		mScenes = host.Context.GetSubsystem<SceneSubsystem>();
		mRender = host.Context.GetSubsystem<RenderSubsystem>();
		mInput = host.Context.GetSubsystem<InputSubsystem>();
		mShellInput = (host.Shell != null) ? host.Shell.Input : null;

		mViewport = new ViewportView();
		mViewport.ClearColor = .(0.05f, 0.05f, 0.06f, 1.0f);

		delete context.StopGameRun;
		context.StopGameRun = new [=this]() => { Stop(); };

		mToolbar = new Toolbar();
		mPlayButton = mToolbar.AddButton("Play");
		mPlayButton.OnClick.Add(new [=this](b) => { Play(); });
		mPauseToggle = mToolbar.AddToggle("Pause");
		mPauseToggle.OnCheckedChanged.Add(new [=this](t, paused) =>
		{
			if ((mScene != null) && mRunning)
				mScene.SetSimulationEnabled(!paused);
		});
		mStopButton = mToolbar.AddButton("Stop");
		mStopButton.OnClick.Add(new [=this](b) => { Stop(); });
		mRestartButton = mToolbar.AddButton("Restart");
		mRestartButton.OnClick.Add(new [=this](b) => { Stop(); Play(); });
		mResolutionButton = mToolbar.AddButton("Res: Auto");
		mResolutionButton.OnClick.Add(new [=this](b) => { CycleResolution(); });
		mStatusLabel = new Label("");
		mStatusLabel.FontSize.Value = 13.0f;
		mToolbar.AddItem(mStatusLabel);

		let column = new FlexLayout();
		column.Direction = .Vertical;
		var toolbarStyle = LayoutStyle();
		toolbarStyle.Width = SizeSpec.Match();
		toolbarStyle.Height = SizeSpec.Fixed(Unit.Dp(30));
		column.AddView(mToolbar, toolbarStyle);
		let stage = new FlexLayout();
		stage.Direction = .Horizontal;
		var viewportStyle = LayoutStyle();
		viewportStyle.FlexGrow = 1.0f;
		viewportStyle.Height = SizeSpec.Match();
		stage.AddView(mViewport, viewportStyle);
		var debugStyle = LayoutStyle();
		debugStyle.Width = SizeSpec.Fixed(Unit.Dp(300));
		debugStyle.Height = SizeSpec.Match();
		stage.AddView(mDebuggerPanel.RootView, debugStyle);
		var stageStyle = LayoutStyle();
		stageStyle.Width = SizeSpec.Match();
		stageStyle.FlexGrow = 1.0f;
		column.AddView(stage, stageStyle);
		mContent = column;
		RefreshToolbar();
	}

	public override StringView Title => "Game";
	/// Nothing here is a document.
	public override Result<void, ErrorCode> Save() => .Ok;
	public override View ContentView => mContent;

	public bool IsRunning => mRunning;
	public Sedulous.Scene.Scene RunningScene => mScene;

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
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mPendingPlay && !mContext.IsCookBusy)
		{
			mPendingPlay = false;
			StartRunNow();
		}
		FollowInstanceScene();
		EnsureViewportBound();
		mViewport.SyncInputRegion();
		if (mRouter != null)
		{
			// Hover gates the mouse, a click the keyboard focus.
			mRouter.SetExternalCapture(false, mViewport.HostKeyboardFocusElsewhere);
			mRouter.Update();
		}
		mViewport.SetHostedTextInputWanted((mApp != null) && (mApp.UI != null) && mApp.UI.UiContext.WantsTextInput());
		DrainDebuggerState();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (!mViewport.IsReady || !frame.Valid)
			return;
		if (mScene == null)
		{
			mViewport.ClearContent(frame.Encoder);
			return;
		}
		if ((mRender == null) || !mRender.IsReady)
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0) || !mViewport.IsEffectivelyVisible())
			return;

		if ((mApp != null) && (mApp.UI != null))
			mApp.UI.RenderCanvasTextures(frame.Encoder, (int32)frame.FrameIndex);

		let targetState = TargetState(mViewport.ColorTexture, mViewport.ColorState, .ShaderRead);
		mRender.RenderScene(mScene, mViewport.ColorTargetView, mViewport.ColorFormat, w, h, .(0, 0, w, h),
			null, targetState);
		mViewport.ColorState = .ShaderRead;
	}

	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		if (!mRunning || (mScene == null) || !mViewport.IsReady || !frame.Valid || (mRender == null))
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0))
			return;
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, mViewport.ColorState, .RenderTarget);
		mRender.RenderOverlays(frame.Encoder, mViewport.ColorTargetView, mViewport.ColorFormat, w, h, frame.FrameIndex);
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, .RenderTarget, .ShaderRead);
		mViewport.ColorState = .ShaderRead;
	}

	public override void OnClose()
	{
		Stop();
		if (mInput != null)
			mInput.ClearSourceProviderIf(mViewportSource);
		if (mGameInstance != null)
			mGameInstance.SetInputSource((mInput != null) ? mInput.ShellSource : null);
		if ((mApp != null) && (mGameInstance != null))
			mApp.ReleaseInstance(mGameInstance);
		mGameInstance = null;
		delete mContext.StopGameRun;
		mContext.StopGameRun = null;
		mViewport.Shutdown();
	}

	/// Binds on the first frame the view has a window, and re-binds when its panel moves to
	/// another window, once that window's renderer exists.
	private void EnsureViewportBound()
	{
		let root = mViewport.Root();
		if (root == null)
			return;
		let window = mUiHost.WindowForRoot(root);
		if ((window == null) || (window == mHostWindow))
			return;
		let renderer = mUiHost.RendererFor(window);
		if (renderer == null)
			return; // the float's AttachWindow has not run yet
		if (mHostWindow == null)
		{
			mViewport.Initialize(mHost.Graphics.Raw, renderer, mHost.Shell.Input, window.Window.Id);
			mViewportSource.Viewport = mViewport;
			mViewportSource.ShellInput = mShellInput;
			if (mRouter == null)
				mRouter = new InputRouter(mHost.Shell.Input);
			if (mViewport.Surface != null)
				mRouter.AddSurface(mViewport.Surface);
			if (mInput != null)
				mInput.SetSourceProvider(mViewportSource, mRunning ? Internal.UnsafeCastToPtr(mScene) : null);
		}
		else
		{
			mViewport.AttachToWindow(renderer, window.Window.Id);
		}
		mHostWindow = window;
	}

	private void CycleResolution()
	{
		mResolutionMode = (mResolutionMode + 1) % 3;
		switch (mResolutionMode)
		{
		case 0:
			mViewport.SetFixedResolution(0, 0);
			mViewport.FitMode = .Stretch;
			mResolutionButton.SetText("Res: Auto");
		case 1:
			mViewport.SetFixedResolution(1280, 800);
			mViewport.FitMode = .Letterbox;
			mResolutionButton.SetText("Res: 1280x800");
		default:
			mViewport.SetFixedResolution(1920, 1080);
			mViewport.FitMode = .Letterbox;
			mResolutionButton.SetText("Res: 1920x1080");
		}
	}

	private void RefreshToolbar()
	{
		if (mStatusLabel == null)
			return;
		if (mRunning)
			mStatusLabel.SetText(scope $"  Running: {mSceneTitle}");
		else
			mStatusLabel.SetText("  Stopped");
	}
}
