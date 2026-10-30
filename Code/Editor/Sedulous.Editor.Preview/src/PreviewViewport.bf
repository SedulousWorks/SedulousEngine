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
using Sedulous.GUI;
using Sedulous.Editor.Camera;

namespace Sedulous.Editor.Preview;

/// The shared 3D-preview substrate for the asset pages (mesh, clip, skeleton, material, particle,
/// animgraph, collision; Raptor's editor-gui spec, 5.4, layer 3): a GUI.Viewport the GUI host
/// binds, places and routes, a private preview Scene with simulation off in its own SceneManager,
/// and an EditorCamera flown as the scene view's is (the mouse while it is hovered or holds a
/// press, the keyboard only with the focus), F framing. A page holds one instead of hand-rolling
/// it: populate Scene with its entities, drive Update from OnUpdate and RenderFrame from
/// OnRenderWindow, put View in its markup, draw overlays into SceneDebugDraw.
class PreviewViewport
{
	/// The backdrop every preview shares (sRGB), a page's own only where it must differ.
	public static readonly Color cBackdrop = .(0.349f, 0.366f, 0.396f, 1.0f);

	private SceneSubsystem mScenes = null;
	/// This preview's own scene group.
	private SceneManager mSceneManager = new .() ~ delete _;
	private RenderSubsystem mRender = null;
	private Sedulous.Scene.Scene mScene = null;
	/// A preview looks at one asset close up: a nearer near plane and a shorter reach than the
	/// scene view's.
	private EditorCamera mCamera = new .() { NearZ = 0.05f, FarZ = 500.0f } ~ delete _;
	/// One reference, this one's: the page's markup holds its own.
	private Sedulous.GUI.Viewport mView ~ _.ReleaseRef();

	/// Builds the viewport and a private preview scene named `sceneName` ("mesh.preview"), hosted
	/// by `gui` (null: not hosted, a test: it neither draws nor takes input). `host` and `gui` are
	/// borrowed.
	public this(IApplicationHost host, GuiHost gui, StringView sceneName)
	{
		mScenes = host.Context.GetSubsystem<SceneSubsystem>();
		mRender = host.Context.GetSubsystem<RenderSubsystem>();
		if (mScenes != null)
		{
			mScenes.RegisterManager(mSceneManager);
			mScene = mSceneManager.CreateScene(sceneName);
			mScene.SetSimulationEnabled(false);
		}
		mView = new Sedulous.GUI.Viewport();
		mView.AddClass("preview-view");
		mView.ClearColor = cBackdrop;
		if (gui != null)
			mView.HostIn(gui);
	}

	public ~this()
	{
		Shutdown();
	}

	public bool IsValid => mScene != null;
	public Sedulous.Scene.Scene Scene => mScene;

	/// Starts over with an empty scene, the old one and everything in it destroyed: a page that
	/// previews on other content (a profile on one of the project's scenes) swaps it. Null when
	/// the viewport has no scenes to make one in.
	public Sedulous.Scene.Scene ResetScene()
	{
		if (mScenes == null)
			return null;
		let name = scope String((mScene != null) ? mScene.Name : "preview");
		if (mScene != null)
			mSceneManager.DestroyScene(mScene);
		mScene = mSceneManager.CreateScene(name);
		mScene.SetSimulationEnabled(false);
		return mScene;
	}

	/// The viewport, for a page's markup to hold (it takes its own reference).
	public Sedulous.GUI.Viewport View => mView;
	public EditorCamera Camera => mCamera;

	/// The camera framed on a sphere at `center` of `radius`, eased there.
	public void Frame(Float3 center, float radius)
	{
		mCamera.FrameBounds(center, radius);
	}

	/// The overlay draw target for this preview scene; valid only while IsValid and the render
	/// subsystem is present.
	public DebugDraw SceneDebugDraw => mRender.DebugScene(mScene);

	/// The backdrop (cBackdrop by default). sRGB, as every colour is entered.
	public void SetClearColor(Color color)
	{
		mView.ClearColor = color;
	}

	/// Off by default: static previews pose their content directly. The particle page turns it on
	/// so the effect runs.
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
	/// camera. True when F was pressed over it this frame (the page frames what it shows).
	public bool Update(float dt)
	{
		let surface = mView.HostedSurface;
		var frame = false;
		if (IsActive)
		{
			let keyboard = Keyboard;
			mCamera.Update(keyboard, mView.Mouse, dt);
			// An orbit, look or pan drag: the pointer locked meanwhile, ended with the press.
			if (surface != null)
				surface.SetPointerLock(mCamera.WantsPointerLock);
			// F frames, as the scene view's does (not while the camera flies on WASD).
			frame = (keyboard != null) && keyboard.IsKeyPressed(.F) && !mCamera.WantsPointerLock;
		}
		else
		{
			// Losing the input releases a captured fly at once.
			mCamera.ReleaseCapture(mView.Mouse);
			if (surface != null)
				surface.SetPointerLock(false);
		}
		mCamera.Advance(dt); // a framing glides on either way
		return frame;
	}

	/// Renders the preview scene into the viewport, from the page's OnRenderWindow: nothing while
	/// hidden (a tab not in front) or not placed yet.
	public void RenderFrame(ref FrameContext frame)
	{
		if (!frame.Valid || (mRender == null) || !mRender.IsReady || (mScene == null))
			return;
		if (!mView.IsReady || !mView.IsTreeVisible || (mView.RenderWidth == 0) || (mView.RenderHeight == 0))
			return;
		let w = mView.RenderWidth;
		let h = mView.RenderHeight;

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(mCamera.Position, mCamera.Position + mCamera.Forward, mCamera.Up);
		camera.Projection = mCamera.Projection((float)w / (float)h);
		camera.Position = mCamera.Position;
		camera.FarZ = mCamera.FarZ;

		var cameraOverride = CameraOverride();
		cameraOverride.Camera = camera;
		// The viewport's colour is a UI colour (sRGB); the render view takes linear.
		let clear = mView.LinearClearColor;
		cameraOverride.ClearColor = .(clear.R, clear.G, clear.B, clear.A);

		// The graph imports the colour target and owns its transitions: from the viewport's state
		// to ShaderRead for the GUI to sample.
		let targetState = TargetState(mView.ColorTexture, mView.ColorState, .ShaderRead);
		mRender.RenderScene(mScene, mView.ColorView, mView.ColorFormat, w, h, .(0, 0, w, h), &cameraOverride, targetState);
		mView.ColorState = .ShaderRead;
	}

	/// Destroys the preview scene and lets the camera go, from the page's OnClose.
	public void Shutdown()
	{
		mCamera.ReleaseCapture(mView.Mouse);
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

	/// Its content has the input: hovered, focused, or holding a press (a look drag, its pointer
	/// locked and hidden, may drift off it).
	private bool IsActive
	{
		get
		{
			let surface = mView.HostedSurface;
			return mView.Hovered || mView.IsFocused || ((surface != null) && surface.Captured);
		}
	}

	/// The keyboard while it has the focus or holds a press; null otherwise.
	private IKeyboard Keyboard
	{
		get
		{
			let surface = mView.HostedSurface;
			return (mView.IsFocused || ((surface != null) && surface.Captured)) ? mView.Keyboard : null;
		}
	}
}
