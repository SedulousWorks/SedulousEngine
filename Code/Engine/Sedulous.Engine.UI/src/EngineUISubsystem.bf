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
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Render;

/// Unified engine UI subsystem handling screen-space and world-space UI.
/// Screen-space: ScreenUIView is an `IScreenOverlay` source registered
/// with the engine's `IScreenRenderer` (RenderSubsystem) - it gets
/// invoked from a single shared overlay render pass after the 3D
/// scene blit.
/// World-space: UIComponentManager per scene, renders to textures displayed as sprites.
class EngineUISubsystem : Subsystem, ISceneAware, IWindowAware, IScreenOverlay
{
	public override int32 UpdateOrder => 400;

	// Set by the host before Startup.
	public IDevice Device;
	public IWindow Window;
	public IShell Shell;
	public ShaderSystem ShaderSystem;

	/// Color format the screen view's pipelines are built against.
	/// Standalone (`EngineApplication`) sets this to the swapchain format;
	/// the editor sets it to the format of the GameEditorPage viewport
	/// (`RGBA16Float`) so the screen UI renders into that target without
	/// pipeline-format mismatches. Default value matches the most common
	/// standalone configuration.
	public TextureFormat OutputFormat = .BGRA8UnormSrgb;
	public int32 FrameCount = 2;

	/// IFontService used by the screen + world UI. Non-owning: the host
	/// application creates the concrete service (TrueTypeFontService /
	/// BakedFontService / etc.), pre-loads its fonts, and assigns it here
	/// before subsystem Startup. Required - subsystem will skip its UI
	/// init if this is null.
	public IFontService FontService;

	// Owned.
	private UIContext mUIContext;
	private ScreenUIView mScreenView;
	private WorldUIPass mWorldUIPass;
	private bool mWorldUIPassRegistered;
	private UIInputHelper mInputHelper;
	private ShellClipboardAdapter mClipboardAdapter;

	// World UI input state.
	private UIComponent mHoveredWorldComp;

	// Public access.
	public UIContext UIContext => mUIContext;
	public ScreenUIView ScreenView => mScreenView;

	/// Returns true if the mouse is over a UI element (window-level screen
	/// UI, any scene's `UISceneModule` UI, or a world `UIComponent`).
	/// Use to block scene/camera input when UI is handling the mouse.
	public bool IsMouseOverUI
	{
		get
		{
			if (mHoveredWorldComp != null) return true;

			// Window-level UI.
			if (mUIContext != null && mScreenView?.Root != null)
			{
				let mousePos = Vector2(mUIContext.InputManager.MouseX, mUIContext.InputManager.MouseY);
				let hit = mScreenView.Root.HitTest(mousePos);
				if (hit != null && hit !== mScreenView.Root) return true;
			}

			// Scene-level UI from any active scene's UISceneModule + billboards.
			let sceneSub = Context?.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
			if (sceneSub != null)
			{
				for (let scene in sceneSub.ActiveScenes)
				{
					let uiSceneModule = scene.GetModule<UISceneModule>();
					if (uiSceneModule?.UIContext != null && uiSceneModule.Root != null)
					{
						let mousePos = Vector2(uiSceneModule.UIContext.InputManager.MouseX, uiSceneModule.UIContext.InputManager.MouseY);
						let hit = uiSceneModule.Root.HitTest(mousePos);
						if (hit != null && hit !== uiSceneModule.Root) return true;
					}

					let billboardMgr = scene.GetModule<BillboardUIComponentManager>();
					if (billboardMgr?.UIContext != null && billboardMgr.Root != null)
					{
						let mousePos = Vector2(billboardMgr.UIContext.InputManager.MouseX, billboardMgr.UIContext.InputManager.MouseY);
						let hit = billboardMgr.Root.HitTest(mousePos);
						if (hit != null && hit !== billboardMgr.Root) return true;
					}
				}
			}

			return false;
		}
	}

	// === IScreenOverlay ===

	public int32 OverlayOrder => 0;

	public void Render(IRenderPassEncoder encoder, uint32 w, uint32 h, int32 frameIndex)
	{
		mScreenView?.Render(encoder, w, h, frameIndex);
	}

	// === Lifecycle ===

	protected override void OnInit()
	{
		// UIContext (shared across screen + world views). FontService
		// must have been assigned by the host application before this
		// subsystem started.
		mUIContext = new UIContext();
		mUIContext.FontService = FontService;
		let sheet = DarkTheme.Create();
		mUIContext.StyleSheet = sheet;
		sheet.ReleaseRef();

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
			mScreenView = new ScreenUIView(mUIContext, Device, OutputFormat,
				FrameCount, FontService, ShaderSystem);

			// Set initial viewport size from window so dialogs shown before
			// the first Render call can center correctly.
			if (Window != null)
				mScreenView.Root.ViewportSize = .((float)Window.Width, (float)Window.Height);

			// Create world UI render pass (registered with pipeline in OnReady).
			mWorldUIPass = new WorldUIPass();
		}
	}

	protected override void OnReady()
	{
		// Register this subsystem as the engine's screen UI source. The
		// IScreenRenderer (RenderSubsystem) drives RenderOverlays from
		// EngineApplication's per-frame render path.
		let screenRenderer = Context?.GetSubsystemByInterface<IScreenRenderer>();
		if (screenRenderer != null)
			screenRenderer.RegisterOverlay(this);
	}

	public override void Update(float deltaTime)
	{
		if (mUIContext == null) return;

		// Sync DPI scale from window.
		if (Window != null && mScreenView != null)
			mScreenView.Root.DpiScale = Window.ContentScale;

		// Build the input priority chain: window UI first, then each active
		// scene's UISceneModule UIContext, then each scene's billboard
		// manager UIContext. Input flows window -> scene HUD -> billboards
		// -> world.
		let chain = scope System.Collections.List<UIContext>();
		chain.Add(mUIContext);

		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneSub != null)
		{
			for (let scene in sceneSub.ActiveScenes)
			{
				let uiSceneModule = scene.GetModule<UISceneModule>();
				if (uiSceneModule?.UIContext != null)
					chain.Add(uiSceneModule.UIContext);

				let billboardMgr = scene.GetModule<BillboardUIComponentManager>();
				if (billboardMgr?.UIContext != null)
					chain.Add(billboardMgr.UIContext);
			}
		}

		// Route UI input through the chain.
		if (mInputHelper != null && Shell?.InputManager != null)
			mInputHelper.Update(Shell.InputManager, chain, deltaTime);

		// World UI fallback - only if no UI context in the chain is hovering
		// over interactive content.
		if (Shell?.InputManager != null && !IsMouseOverAnyChainUI(chain))
			RouteWorldUIInput(deltaTime);

		// Drain mutations, tick animations/tooltips.
		mUIContext.BeginFrame(deltaTime);

		// Tick per-component UIContexts.
		TickWorldUIContexts(deltaTime);

		// Tick per-scene UISceneModule UIContexts (UpdateRootView happens
		// per-pipeline in the module's Render to use the active view size).
		TickSceneUIContexts(deltaTime);

		// Layout screen view.
		if (mScreenView != null)
			mUIContext.UpdateRootView(mScreenView.Root);
	}

	/// Drain mutations and tick animations on each active scene's
	/// UISceneModule UIContext. Layout itself runs in the module's
	/// IPipelineOverlay.Render call so it can use the pipeline's view
	/// dimensions.
	private void TickSceneUIContexts(float deltaTime)
	{
		let sceneSub = Context?.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
		if (sceneSub == null) return;

		for (let scene in sceneSub.ActiveScenes)
		{
			let uiSceneModule = scene.GetModule<UISceneModule>();
			if (uiSceneModule?.UIContext != null)
				uiSceneModule.UIContext.BeginFrame(deltaTime);

			let billboardMgr = scene.GetModule<BillboardUIComponentManager>();
			if (billboardMgr?.UIContext != null)
				billboardMgr.UIContext.BeginFrame(deltaTime);
		}
	}

	/// Whether the mouse is over any interactive UI element across the
	/// input chain (window UI or any scene's UISceneModule UI). Used to
	/// gate the world UI fallback so the world doesn't receive input that
	/// a higher-priority UI tier is already hovering.
	private bool IsMouseOverAnyChainUI(System.Collections.List<UIContext> chain)
	{
		for (let ctx in chain)
		{
			let mousePos = Vector2(ctx.InputManager.MouseX, ctx.InputManager.MouseY);
			for (int i = 0; i < ctx.RootViewCount; i++)
			{
				let root = ctx.GetRootView(i);
				let hit = root.HitTest(mousePos);
				if (hit != null && hit !== root)
					return true;
			}
		}
		return false;
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
		Pipeline activePipeline = null;
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

	private void RouteWorldMouseButton(UIComponent comp, IMouse mouse,
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
		// ScreenUIView gets its viewport from each Render call's
		// width/height parameters, so no explicit handling needed here.
	}

	// === ISceneAware ===

	public void OnSceneCreated(Scene scene)
	{
		let sceneRenderer = Context.GetSubsystemByInterface<ISceneRenderer>();
		let uiMgr = new UIComponentManager();
		uiMgr.Device = Device;
		uiMgr.SharedStyleSheet = mUIContext?.StyleSheet;
		uiMgr.FontService = FontService;
		uiMgr.ShaderSystem = ShaderSystem;
		uiMgr.RenderPass = mWorldUIPass;
		// WorldUIPass uses the manager's shared VG resources (Track 3).
		if (mWorldUIPass != null) mWorldUIPass.Manager = uiMgr;
		uiMgr.RenderContext = sceneRenderer?.RenderContext;
		scene.AddModule(uiMgr);

		// Scene HUD module - VG resources are initialized in OnSceneReady
		// once the scene's pipeline (and its OutputFormat) is available.
		scene.AddModule(new UISceneModule());

		// Billboard UI manager - same deferred-init pattern as UISceneModule.
		scene.AddModule(new BillboardUIComponentManager());
	}

	public void OnSceneReady(Scene scene)
	{
		let sceneRenderer = Context.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneRenderer == null) return;

		let pipeline = sceneRenderer.GetPipeline(scene);
		if (pipeline == null) return;

		// Register WorldUIPass with the scene's pipeline (created by RenderSubsystem.OnSceneCreated).
		if (mWorldUIPass != null && !mWorldUIPassRegistered)
		{
			pipeline.AddPass(mWorldUIPass);
			mWorldUIPassRegistered = true;
		}

		// Initialize the scene's UISceneModule with the pipeline's output
		// format, then register it as an IPipelineOverlay so OverlayPass
		// invokes it each frame.
		let uiSceneModule = scene.GetModule<UISceneModule>();
		if (uiSceneModule != null && Device != null && FontService != null && ShaderSystem != null)
		{
			if (uiSceneModule.Initialize(Device, pipeline.OutputFormat, FrameCount,
				FontService, ShaderSystem, mUIContext?.StyleSheet) case .Ok)
			{
				pipeline.RegisterOverlay(uiSceneModule);
			}
		}

		// Same pattern for the billboard manager (Order = 50 - draws under
		// the scene HUD, gets input chain after it).
		let billboardMgr = scene.GetModule<BillboardUIComponentManager>();
		if (billboardMgr != null && Device != null && FontService != null && ShaderSystem != null)
		{
			if (billboardMgr.Initialize(Device, pipeline.OutputFormat, FrameCount,
				FontService, ShaderSystem, mUIContext?.StyleSheet) case .Ok)
			{
				pipeline.RegisterOverlay(billboardMgr);
			}
		}
	}

	public void OnSceneDestroyed(Scene scene)
	{
		let sceneRenderer = Context.GetSubsystemByInterface<ISceneRenderer>();
		let pipeline = sceneRenderer?.GetPipeline(scene);

		let uiSceneModule = scene.GetModule<UISceneModule>();
		if (pipeline != null && uiSceneModule != null)
			pipeline.UnregisterOverlay(uiSceneModule);

		let billboardMgr = scene.GetModule<BillboardUIComponentManager>();
		if (pipeline != null && billboardMgr != null)
			pipeline.UnregisterOverlay(billboardMgr);

		// Modules' own Dispose handles VG / UIContext / RootView cleanup
		// once Scene removes them from its module list.
	}

	// === Shutdown ===

	protected override void OnPrepareShutdown()
	{
		// Null out SharedStyleSheet on scene modules before screen UIContext (which owns the stylesheet) is deleted.
		// Per-component UIContexts use shared StyleSheet so they don't own it - but they hold a pointer.
		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneSub != null)
		{
			for (let scene in sceneSub.ActiveScenes)
			{
				let uiMgr = scene.GetModule<UIComponentManager>();
				if (uiMgr != null)
					uiMgr.SharedStyleSheet = null;
			}
		}
	}

	protected override void OnShutdown()
	{
		// Unregister before deletion so the screen renderer's registry
		// doesn't hold a dangling pointer.
		let screenRenderer = Context?.GetSubsystemByInterface<IScreenRenderer>();
		if (screenRenderer != null)
			screenRenderer.UnregisterOverlay(this);

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

		// FontService is not owned - the host application created it and
		// is responsible for tearing it down.

		// WorldUIPass is owned by the Pipeline once registered (Pipeline.Shutdown
		// deletes its passes). If no scene was ever created, we still own it.
		if (!mWorldUIPassRegistered && mWorldUIPass != null)
		{
			delete mWorldUIPass;
			mWorldUIPass = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}
	}
}
