namespace Sedulous.Engine.UI;

using System;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Renderer;

/// Unified engine UI subsystem handling screen-space and world-space UI.
/// Screen-space: ScreenUIView renders as IRenderOverlay after 3D scene blit.
/// World-space: UIComponentManager per scene, renders to textures displayed as sprites.
class EngineUISubsystem : Subsystem, ISceneAware, IWindowAware, IOverlayRenderer
{
	public override int32 UpdateOrder => 400;

	// Set by EngineApplication before Startup.
	public IDevice Device;
	public IWindow Window;
	public IShell Shell;
	public ShaderSystem ShaderSystem;
	public String AssetDirectory ~ delete _;
	public TextureFormat SwapChainFormat = .BGRA8UnormSrgb;
	public int32 FrameCount = 2;

	// Owned.
	private UIContext mUIContext;
	private FontService mFontService;
	private ScreenUIView mScreenView;
	private WorldUIPass mWorldUIPass;
	private bool mWorldUIPassRegistered;
	private UIInputHelper mInputHelper;
	private ShellClipboardAdapter mClipboardAdapter;

	// World UI input state.
	private UIComponent mHoveredWorldComp;

	// Public access.
	public UIContext UIContext => mUIContext;
	public FontService FontService => mFontService;
	public ScreenUIView ScreenView => mScreenView;

	/// Returns true if the mouse is over a UI element (screen or world).
	/// Use to block scene input when UI is handling the mouse.
	public bool IsMouseOverUI
	{
		get
		{
			if (mHoveredWorldComp != null) return true;
			if (mUIContext == null || mScreenView?.Root == null) return false;
			let hit = mUIContext.HitTest(.(mUIContext.InputManager.MouseX, mUIContext.InputManager.MouseY));
			return hit != null && hit !== mScreenView.Root;
		}
	}

	// === IOverlayRenderer ===

	public int32 OverlayOrder => 0;

	public void RenderOverlay(ICommandEncoder encoder, ITextureView target,
		uint32 w, uint32 h, int32 frameIndex)
	{
		mScreenView?.RenderOverlay(encoder, target, w, h, frameIndex);
	}

	// === Lifecycle ===

	protected override void OnInit()
	{
		// Font service.
		mFontService = new FontService();

		// UIContext (shared across screen + world views).
		mUIContext = new UIContext();
		mUIContext.FontService = mFontService;
		mUIContext.SetTheme(DarkTheme.Create(), true);

		// Clipboard bridge.
		if (Shell?.Clipboard != null)
		{
			mClipboardAdapter = new ShellClipboardAdapter(Shell.Clipboard);
			mUIContext.Clipboard = mClipboardAdapter;
		}

		// Input bridge.
		if (Shell?.InputManager != null)
			mInputHelper = new UIInputHelper();

		// Screen UI view - needs Device + SwapChain format.
		if (Device != null)
		{
			mScreenView = new ScreenUIView(mUIContext, Device, SwapChainFormat,
				FrameCount, mFontService, ShaderSystem);

			// Create world UI render pass (registered with pipeline in OnReady).
			mWorldUIPass = new WorldUIPass();
		}

		// Load default font if asset directory is available.
		if (AssetDirectory != null && AssetDirectory.Length > 0)
		{
			let fontPath = scope String();
			System.IO.Path.InternalCombine(fontPath, AssetDirectory, "fonts/roboto/Roboto-Regular.ttf");
			if (System.IO.File.Exists(fontPath))
			{
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = 16 });
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = 24 });
			}
		}
	}

	protected override void OnReady()
	{
	}

	public override void Update(float deltaTime)
	{
		if (mUIContext == null) return;

		// Sync DPI scale from window.
		if (Window != null && mScreenView != null)
			mScreenView.Root.DpiScale = Window.ContentScale;

		// Route screen UI input.
		if (mInputHelper != null && Shell?.InputManager != null)
			mInputHelper.Update(Shell.InputManager, mUIContext, deltaTime);

		// Route world UI input (only if screen UI didn't consume it).
		if (Shell?.InputManager != null && !IsMouseOverScreenUI)
			RouteWorldUIInput(deltaTime);

		// Drain mutations, tick animations/tooltips.
		mUIContext.BeginFrame(deltaTime);

		// Tick per-component UIContexts.
		TickWorldUIContexts(deltaTime);

		// Layout screen view.
		if (mScreenView != null)
			mUIContext.UpdateRootView(mScreenView.Root);
	}

	/// Whether the mouse is over a screen-space UI element (not root/layout).
	private bool IsMouseOverScreenUI
	{
		get
		{
			if (mUIContext == null || mScreenView?.Root == null) return false;
			let hit = mUIContext.HitTest(.(mUIContext.InputManager.MouseX, mUIContext.InputManager.MouseY));
			return hit != null && hit !== mScreenView.Root;
		}
	}

	// === World UI Input Raycasting ===

	/// Tick per-component UIContexts (drain mutations, animations).
	private void TickWorldUIContexts(float deltaTime)
	{
		let sceneSub = Context?.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
		if (sceneSub == null) return;

		for (let scene in sceneSub.ActiveScenes)
		{
			let uiMgr = scene.GetModule<UIComponentManager>();
			if (uiMgr == null) continue;

			for (let comp in uiMgr.ActiveComponents)
			{
				if (comp.UIContext != null)
					comp.UIContext.BeginFrame(deltaTime);
			}
		}
	}

	/// Route mouse input to world-space UI panels via raycasting.
	private void RouteWorldUIInput(float deltaTime)
	{
		let sceneRenderer = Context?.GetSubsystemByInterface<ISceneRenderer>();
		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneRenderer == null || sceneSub == null) return;

		// Get viewport dimensions from first active scene's pipeline.
		Sedulous.Renderer.Pipeline activePipeline = null;
		for (let scene in sceneSub.ActiveScenes)
		{
			activePipeline = sceneRenderer.GetPipeline(scene);
			if (activePipeline != null) break;
		}
		if (activePipeline == null) return;

		let viewportWidth = activePipeline.OutputWidth;
		let viewportHeight = activePipeline.OutputHeight;
		if (viewportWidth == 0 || viewportHeight == 0) return;

		let inputMgr = Shell.InputManager;
		let mouse = inputMgr.Mouse;
		if (mouse == null) return;

		let sceneSub = Context?.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
		if (sceneSub == null) return;

		// Find the active camera.
		CameraComponent activeCamera = null;
		Scene cameraScene = null;
		for (let scene in sceneSub.ActiveScenes)
		{
			let cameraMgr = scene.GetModule<CameraComponentManager>();
			if (cameraMgr != null)
			{
				let cam = cameraMgr.GetActiveCamera();
				if (cam != null)
				{
					activeCamera = cam;
					cameraScene = scene;
					break;
				}
			}
		}
		if (activeCamera == null || cameraScene == null) return;

		let viewportAspect = (float)viewportWidth / (float)viewportHeight;
		let viewMatrix = activeCamera.GetViewMatrix(cameraScene);
		let projMatrix = activeCamera.GetProjectionMatrix(viewportAspect);
		let cameraPos = cameraScene.GetWorldMatrix(activeCamera.Owner).Translation;
		let cameraWorld = cameraScene.GetWorldMatrix(activeCamera.Owner);
		// Camera forward/right/up from the world matrix columns.
		let camForward = Vector3.Normalize(.(cameraWorld.M31, cameraWorld.M32, cameraWorld.M33));
		let camRight = Vector3.Normalize(.(cameraWorld.M11, cameraWorld.M12, cameraWorld.M13));
		let camUp = Vector3.Normalize(.(cameraWorld.M21, cameraWorld.M22, cameraWorld.M23));

		let ray = ScreenPointToRay(mouse.X, mouse.Y, viewMatrix, projMatrix, viewportWidth, viewportHeight);

		// Find closest hit world UI component.
		UIComponent closestComp = null;
		float closestDist = float.MaxValue;
		float closestPixelX = 0;
		float closestPixelY = 0;

		for (let scene in sceneSub.ActiveScenes)
		{
			let uiMgr = scene.GetModule<UIComponentManager>();
			if (uiMgr == null) continue;

			for (let comp in uiMgr.ActiveComponents)
			{
				if (!comp.IsInteractive || !comp.IsVisible) continue;
				if (comp.Root == null || comp.UIContext == null) continue;

				let entityWorld = scene.GetWorldMatrix(comp.Owner);
				let panelPos = entityWorld.Translation;

				// Compute plane normal and local axes based on orientation.
				Vector3 planeNormal;
				Vector3 localRight;
				Vector3 localUp;

				switch (comp.Orientation)
				{
				case .CameraFacing:
					planeNormal = -camForward;
					localRight = camRight;
					localUp = camUp;
				case .CameraFacingY:
					// Face camera horizontally, stay upright.
					var toCamera = cameraPos - panelPos;
					toCamera.Y = 0;
					if (toCamera.LengthSquared() < 0.0001f)
						continue;
					planeNormal = Vector3.Normalize(toCamera);
					localUp = .(0, 1, 0);
					localRight = Vector3.Normalize(Vector3.Cross(localUp, planeNormal));
				case .WorldAligned:
					// Use entity's orientation.
					localRight = Vector3.Normalize(.(entityWorld.M11, entityWorld.M12, entityWorld.M13));
					localUp = Vector3.Normalize(.(entityWorld.M21, entityWorld.M22, entityWorld.M23));
					planeNormal = Vector3.Normalize(.(entityWorld.M31, entityWorld.M32, entityWorld.M33));
				}

				// Intersect ray with panel plane.
				let planeD = -Vector3.Dot(planeNormal, panelPos);
				let plane = Plane(planeNormal, planeD);
				let hitDist = ray.Intersects(plane);
				if (hitDist == null || hitDist.Value <= 0) continue;
				if (hitDist.Value >= closestDist) continue;

				// Convert hit point to local 2D coordinates.
				let hitPoint = ray.Position + ray.Direction * hitDist.Value;
				let relative = hitPoint - panelPos;
				let hitX = Vector3.Dot(relative, localRight);
				let hitY = Vector3.Dot(relative, localUp);

				// Convert to pixel coordinates (origin top-left).
				let pixelX = (hitX / comp.WorldWidth + 0.5f) * (float)comp.PixelWidth;
				let pixelY = (-hitY / comp.WorldHeight + 0.5f) * (float)comp.PixelHeight;

				// Bounds check.
				if (pixelX < 0 || pixelX >= (float)comp.PixelWidth) continue;
				if (pixelY < 0 || pixelY >= (float)comp.PixelHeight) continue;

				closestDist = hitDist.Value;
				closestComp = comp;
				closestPixelX = pixelX;
				closestPixelY = pixelY;
			}
		}

		// Send mouse-leave to previously hovered component if it changed.
		if (mHoveredWorldComp != null && mHoveredWorldComp != closestComp)
		{
			mHoveredWorldComp.UIContext.InputManager.ProcessMouseMove(-1, -1);
			mHoveredWorldComp.MarkDirty();
			mHoveredWorldComp.WasHovered = false;
		}
		mHoveredWorldComp = closestComp;

		// Route input to the closest hit component.
		if (closestComp != null)
		{
			closestComp.InputTotalTime += deltaTime;
			let ctx = closestComp.UIContext;

			ctx.InputManager.ProcessMouseMove(closestPixelX, closestPixelY);

			RouteWorldMouseButton(closestComp, mouse, .Left, ref closestComp.PrevLeftDown,
				closestPixelX, closestPixelY);
			RouteWorldMouseButton(closestComp, mouse, .Right, ref closestComp.PrevRightDown,
				closestPixelX, closestPixelY);
			RouteWorldMouseButton(closestComp, mouse, .Middle, ref closestComp.PrevMiddleDown,
				closestPixelX, closestPixelY);

			if (mouse.ScrollX != 0 || mouse.ScrollY != 0)
				ctx.InputManager.ProcessMouseWheel(closestPixelX, closestPixelY, mouse.ScrollX, mouse.ScrollY);

			closestComp.WasHovered = true;
			closestComp.MarkDirty();
		}
	}

	private void RouteWorldMouseButton(UIComponent comp, Sedulous.Shell.Input.IMouse mouse,
		Sedulous.Shell.Input.MouseButton shellBtn, ref bool prevDown, float px, float py)
	{
		let down = mouse.IsButtonDown(shellBtn);
		let uiBtn = InputMapping.MapMouseButton(shellBtn);

		if (down && !prevDown)
			comp.UIContext.InputManager.ProcessMouseDown(uiBtn, px, py, comp.InputTotalTime);
		else if (!down && prevDown)
			comp.UIContext.InputManager.ProcessMouseUp(uiBtn, px, py);

		prevDown = down;
	}

	private static Ray ScreenPointToRay(float screenX, float screenY,
		Matrix viewMatrix, Matrix projMatrix, uint32 viewportWidth, uint32 viewportHeight)
	{
		float ndcX = (screenX / (float)viewportWidth) * 2.0f - 1.0f;
		float ndcY = 1.0f - (screenY / (float)viewportHeight) * 2.0f;

		Vector4 nearPoint = .(ndcX, ndcY, 0.0f, 1.0f);
		Vector4 farPoint = .(ndcX, ndcY, 1.0f, 1.0f);

		let vpMatrix = viewMatrix * projMatrix;
		let invViewProj = Matrix.Invert(vpMatrix);

		var nearWorld = Vector4.Transform(nearPoint, invViewProj);
		var farWorld = Vector4.Transform(farPoint, invViewProj);

		if (Math.Abs(nearWorld.W) > 0.0001f)
			nearWorld /= nearWorld.W;
		if (Math.Abs(farWorld.W) > 0.0001f)
			farWorld /= farWorld.W;

		let rayPos = Vector3(nearWorld.X, nearWorld.Y, nearWorld.Z);
		let rayDir = Vector3.Normalize(.(farWorld.X - nearWorld.X, farWorld.Y - nearWorld.Y, farWorld.Z - nearWorld.Z));
		return .(rayPos, rayDir);
	}

	// === IWindowAware ===

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		// ScreenUIView gets its viewport from RenderOverlay parameters,
		// so no explicit handling needed here.
	}

	// === ISceneAware ===

	public void OnSceneCreated(Scene scene)
	{
		let sceneRenderer = Context.GetSubsystemByInterface<ISceneRenderer>();
		let uiMgr = new UIComponentManager();
		uiMgr.Device = Device;
		uiMgr.SharedTheme = mUIContext?.Theme;
		uiMgr.FontService = mFontService;
		uiMgr.ShaderSystem = ShaderSystem;
		uiMgr.RenderPass = mWorldUIPass;
		uiMgr.RenderContext = sceneRenderer?.RenderContext;
		scene.AddModule(uiMgr);
	}

	public void OnSceneReady(Scene scene)
	{
		// Register WorldUIPass with the scene's pipeline (created by RenderSubsystem.OnSceneCreated).
		if (mWorldUIPass != null && !mWorldUIPassRegistered)
		{
			let sceneRenderer = Context.GetSubsystemByInterface<ISceneRenderer>();
			if (sceneRenderer != null)
			{
				let pipeline = sceneRenderer.GetPipeline(scene);
				if (pipeline != null)
				{
					pipeline.AddPass(mWorldUIPass);
					mWorldUIPassRegistered = true;
				}
			}
		}
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}

	// === Shutdown ===

	protected override void OnPrepareShutdown()
	{
		// Null out SharedTheme on scene modules before screen UIContext (which owns the theme) is deleted.
		// Per-component UIContexts use SetSharedTheme so they don't own it - but they hold a pointer.
		let sceneSub = Context?.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
		if (sceneSub != null)
		{
			for (let scene in sceneSub.ActiveScenes)
			{
				let uiMgr = scene.GetModule<UIComponentManager>();
				if (uiMgr != null)
					uiMgr.SharedTheme = null;
			}
		}
	}

	protected override void OnShutdown()
	{
		if (mInputHelper != null)
		{
			delete mInputHelper;
			mInputHelper = null;
		}

		if (mClipboardAdapter != null)
		{
			if (mUIContext != null) mUIContext.Clipboard = null;
			delete mClipboardAdapter;
			mClipboardAdapter = null;
		}

		if (mScreenView != null)
		{
			delete mScreenView;
			mScreenView = null;
		}

		if (mFontService != null)
		{
			delete mFontService;
			mFontService = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}
	}
}
