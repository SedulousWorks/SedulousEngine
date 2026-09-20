using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Engine.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Viewport;
using Sedulous.VG.Renderer;
using Sedulous.Editor.Camera;

namespace Sedulous.Editor.Preview;

/// The shared 3D-preview substrate for the bespoke asset editor pages (mesh, clip, skeleton,
/// material, particle, animgraph, collision): a ViewportView, a private preview Scene with
/// simulation off in its own SceneManager, an EditorCamera, the InputRouter, and the bind,
/// camera-update and RenderScene loop. A page contains one instead of hand-rolling it:
/// populate Scene with its entities, drive Update from OnUpdate and RenderFrame from
/// OnRenderWindow, mount View in the layout, draw overlays into SceneDebugDraw.
///
/// The view: the layout that mounts View consumes the creation reference; the preview holds
/// one of its own and drops it on Shutdown, so a viewport that was never mounted is freed too.
class PreviewViewport
{
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private SceneSubsystem mScenes = null;
	/// This preview's own scene group.
	private SceneManager mSceneManager = new .() ~ delete _;
	private RenderSubsystem mRender = null;
	private Scene mScene = null;
	private EditorCamera mCamera = new .() ~ delete _;
	private InputRouter mRouter ~ delete _;
	private ViewportView mViewport = null;
	private bool mMounted = false;
	private RenderWindow mHostWindow = null;

	/// Builds the viewport and a private preview scene named `sceneName` ("mesh.preview").
	public this(IApplicationHost host, UIHost uiHost, StringView sceneName)
	{
		mHost = host;
		mUiHost = uiHost;
		mRouter = new InputRouter(host.Shell.Input);
		mScenes = host.Context.GetSubsystem<SceneSubsystem>();
		mRender = host.Context.GetSubsystem<RenderSubsystem>();
		if (mScenes != null)
		{
			mScenes.RegisterManager(mSceneManager);
			mScene = mSceneManager.CreateScene(sceneName);
			mScene.SetSimulationEnabled(false);
		}
		mViewport = new ViewportView();
		mViewport.AddRef();
		mViewport.ClearColor = .(0.10f, 0.11f, 0.13f, 1.0f);
	}

	public ~this()
	{
		Shutdown();
	}

	public bool IsValid => mScene != null;
	public Scene Scene => mScene;
	/// The viewport as a base View, for layout.
	public View View => mViewport;
	public EditorCamera Camera => mCamera;

	/// The overlay draw target for this preview scene; valid only while IsValid and the
	/// render subsystem is present.
	public DebugDraw SceneDebugDraw => mRender.DebugScene(mScene);

	/// The backdrop; a neutral dark grey by default.
	public void SetClearColor(Color color)
	{
		mViewport.ClearColor = .(color.R, color.G, color.B, color.A);
	}

	/// Off by default: static previews pose their content directly. The particle page turns
	/// it on so the effect runs.
	public void SetSimulationEnabled(bool enabled)
	{
		if (mScene != null)
			mScene.SetSimulationEnabled(enabled);
	}

	/// 1 is real time, 0 paused; this preview's own SceneManager only.
	public void SetTimeScale(float scale)
	{
		mSceneManager.TimeScale = scale;
	}

	/// Per-frame input and camera drive, from the page's OnUpdate before anything reads the
	/// camera. A no-op until the viewport is bound.
	public void Update(float dt)
	{
		if (mViewport == null)
			return;
		if (mViewport.Parent != null)
			mMounted = true;
		EnsureViewportBound();
		if (mHostWindow == null)
			return;
		mViewport.SyncInputRegion();
		if (mRouter != null)
		{
			// One app keyboard: while the editor UI's keyboard focus is on any view but this
			// viewport, drop surface focus so the camera's keys never fire while the user
			// types into an editor widget.
			mRouter.SetExternalCapture(false, mViewport.HostKeyboardFocusElsewhere);
			mRouter.Update();
		}
		if (mViewport.IsHovered() || mViewport.IsFocused())
			mCamera.Update(mViewport.Keyboard, mViewport.Mouse, dt);
	}

	/// Renders the preview scene into the viewport, from the page's OnRenderWindow.
	public void RenderFrame(ref FrameContext frame)
	{
		let vp = mViewport;
		if ((vp == null) || !vp.IsReady || !frame.Valid)
			return;
		if ((mRender == null) || !mRender.IsReady || (mScene == null))
			return;
		let w = vp.RenderWidth;
		let h = vp.RenderHeight;
		if ((w == 0) || (h == 0) || !vp.IsEffectivelyVisible())
			return;

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(mCamera.Position, mCamera.Position + mCamera.Forward, mCamera.Up);
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, (float)w / (float)h, 0.05f, 500.0f);
		camera.Position = mCamera.Position;
		camera.FarZ = 500.0f;

		var cameraOverride = CameraOverride();
		cameraOverride.Camera = camera;
		cameraOverride.ClearColor = .(vp.ClearColor.R, vp.ClearColor.G, vp.ClearColor.B, vp.ClearColor.A);

		let targetState = TargetState(vp.ColorTexture, vp.ColorState, .ShaderRead);
		mRender.RenderScene(mScene, vp.ColorTargetView, vp.ColorFormat, w, h, .(0, 0, w, h),
			&cameraOverride, targetState);
		vp.ColorState = .ShaderRead;
	}

	/// Tears down the viewport and destroys the preview scene, from the page's OnClose.
	public void Shutdown()
	{
		if (mViewport != null)
		{
			mViewport.Shutdown();
			if (!mMounted && (mViewport.Parent == null))
				mViewport.ReleaseRef(); // the mount reference nobody took
			mViewport.ReleaseRef();
			mViewport = null;
		}
		if (mScene != null)
		{
			mSceneManager.DestroyScene(mScene);
			mScene = null;
		}
		if (mScenes != null)
		{
			mScenes.UnregisterManager(mSceneManager);
			mScenes = null;
		}
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
			return;
		if (mHostWindow == null)
		{
			mViewport.Initialize(mHost.Graphics.Raw, renderer, mHost.Shell.Input, window.Window.Id);
			if (mViewport.Surface != null)
				mRouter.AddSurface(mViewport.Surface);
		}
		else
		{
			mViewport.AttachToWindow(renderer, window.Window.Id);
		}
		mHostWindow = window;
	}
}
