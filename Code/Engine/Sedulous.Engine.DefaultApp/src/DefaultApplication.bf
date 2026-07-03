namespace Sedulous.Engine.DefaultApp;

using System;
using System.IO;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Input;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.UI;
using Sedulous.Engine.Render;
using Sedulous.Renderer;
using Sedulous.Images;
using Sedulous.Profiler;

/// Opinionated IApplication base class that registers ALL standard engine
/// subsystems (input, scene, physics, animation, audio, navigation, UI,
/// render). Game projects extend this and override Configure -- calling
/// base.Configure(host) first -- to add their own subsystems on top of
/// the full engine stack.
///
/// Owns the engine-level infrastructure that doesn't belong in the generic
/// ApplicationHost: ResourceSystem, ShaderSystem, FontService, and the
/// builtin:// asset mount. These are created in Configure (device is
/// available) and torn down in OnShutdown.
///
/// Rendering: OnRenderWindow clears the backbuffer for now. The full HDR
/// pipeline with scene rendering and blit will be wired when consumers
/// migrate from EngineApplication.
class DefaultApplication : IApplication
{
	// Engine infrastructure (owned unless pre-set by an external host like the editor).
	// When mOwnsInfrastructure is false, these are borrowed — don't delete them.
	protected bool mOwnsInfrastructure = true;
	protected ShaderSystem mShaderSystem ~ { if (mOwnsInfrastructure) { _?.Dispose(); delete _; } };
	protected TrueTypeFontService mFontService ~ { if (mOwnsInfrastructure) delete _; };
	protected ResourceSystem mResourceSystem ~ { if (mOwnsInfrastructure) delete _; };
	protected Sedulous.Core.Logging.Abstractions.ILogger mLogger ~ { if (mOwnsInfrastructure) delete _; };
	protected FileSystemMount mBuiltinMount ~ { if (mOwnsInfrastructure) delete _; };
	protected InMemoryResourceIndex mBuiltinIndex ~ { if (mOwnsInfrastructure) delete _; };

	// Asset directories (discovered at configure time)
	private String mBuiltInAssetDirectory = new .() /*~ delete _*/;
	private String mAssetCacheDirectory = new .() ~ delete _;
	private String mProjectAssetDirectory = new .() ~ delete _;
	private String mRuntimeDirectory = new .() ~ delete _;

	// Cached renderer interfaces (set in OnStartup after subsystems are ready)
	private ISceneRenderer mSceneRenderer;
	private IScreenRenderer mScreenRenderer;

	/// The scene the host should render for this application. Set by the
	/// game in OnLaunch after creating its gameplay scene. Cleared in
	/// OnExit.
	///
	/// Standalone: DefaultApplication.OnRenderWindow renders this scene.
	/// Editor: GameEditorPage reads this to know which scene to display
	/// in the game viewport (the editor may have other scenes open in
	/// edit-mode tabs - ActiveScenes[0] is not reliable).
	///
	/// This is a pragmatic solution. A future iteration may introduce a
	/// more generic mechanism (e.g., a render target descriptor on
	/// IApplication) once multi-viewport and split-screen use cases are
	/// better understood.
	public Scene RuntimeScene { get; protected set; }

	// HDR output target (scene renders into this, then blit to backbuffer)
	private ITexture mColorTarget;
	private ITextureView mColorTargetView;
	private uint32 mRenderWidth;
	private uint32 mRenderHeight;
	private BlitHelper mBlitHelper ~ { _?.Dispose(); delete _; };
	private int32 mFrameIndex;

	// Screenshot capture
	private bool mScreenshotRequested;
	private String mScreenshotPath ~ delete _;
	private IBuffer mScreenshotBuffer;

	// Profiling
	private bool mProfilePrintRequested;

	// Subsystem references cached for window-dependent property updates
	private EngineUISubsystem mUISub;

	/// Pre-set shared infrastructure so Configure() reuses the editor's
	/// systems instead of creating its own. Sets mOwnsInfrastructure = false
	/// so the module won't delete the borrowed instances on shutdown.
	/// Asset directories are NOT passed here - Configure reads them from
	/// the host (IApplicationHost.BuiltInAssetDirectory, etc.).
	/// Call BEFORE Configure().
	public void PresetInfrastructure(
		ResourceSystem resourceSystem, ShaderSystem shaderSystem,
		TrueTypeFontService fontService, FileSystemMount builtinMount)
	{
		mOwnsInfrastructure = false;
		mResourceSystem = resourceSystem;
		mShaderSystem = shaderSystem;
		mFontService = fontService;
		mBuiltinMount = builtinMount;
	}

	/// The resource system (application-owned, shared with subsystems).
	public ResourceSystem ResourceSystem => mResourceSystem;

	/// The shared shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// The default font service.
	public IFontService FontService => mFontService;

	/// The discovered engine Assets directory (contains shaders, fonts, etc.).
	public StringView BuiltInAssetDirectory => mBuiltInAssetDirectory;

	/// Request that the current frame's profile be printed after the frame
	/// completes. Call from inside OnUpdate when something interesting happens
	/// and you want the breakdown without timing the P hotkey.
	public void RequestProfilePrint()
	{
		mProfilePrintRequested = true;
	}

	/// Request a screenshot capture on the next frame. The screenshot is
	/// saved to the given path after the blit.
	public void CaptureScreenshot(StringView path)
	{
		mScreenshotRequested = true;
		delete mScreenshotPath;
		mScreenshotPath = new String(path);
	}

	/// Returns a path relative to the assets directory.
	public void GetAssetPath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		System.IO.Path.InternalCombine(outPath, mBuiltInAssetDirectory, relativePath);
	}

	/// The discovered asset cache directory.
	public StringView AssetCacheDirectory => mAssetCacheDirectory;

	/// Per-project assets directory (convention: <parent of cwd>/assets).
	public StringView ProjectAssetDirectory => mProjectAssetDirectory;

	/// The runtime directory (working directory at startup).
	public StringView RuntimeDirectory => mRuntimeDirectory;

	// ==================== IApplication ====================

	/// Application settings (frame pacing, shader cache, etc.).
	public virtual ApplicationSettings Settings() => .();

	/// Register subsystems, create engine infrastructure. The device is
	/// available via host.Graphics.Raw but the main window does NOT exist
	/// yet -- window-dependent properties are deferred to OnStartup.
	///
	/// When hosted by the editor, infrastructure (ResourceSystem, ShaderSystem,
	/// FontService, asset directories) may be pre-set on the protected fields
	/// before Configure is called. In that case, the existing instances are
	/// kept and Configure only registers subsystems.
	public virtual void Configure(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let device = host.Graphics?.Raw;

		// Read asset directories from the host (ApplicationHost discovers
		// them during Start; the editor provides its own values).
		if (mBuiltInAssetDirectory.IsEmpty)
			mBuiltInAssetDirectory.Set(host.BuiltInAssetDirectory);
		if (mAssetCacheDirectory.IsEmpty)
			mAssetCacheDirectory.Set(host.AssetCacheDirectory);
		if (mProjectAssetDirectory.IsEmpty)
			mProjectAssetDirectory.Set(host.ProjectAssetDirectory);
		if (mRuntimeDirectory.IsEmpty)
			mRuntimeDirectory.Set(host.RuntimeDirectory);

		// Core systems — skip if the host (editor) already provided them
		if (mResourceSystem == null)
		{
			mLogger = new Sedulous.Core.Logging.Console.ConsoleLogger(.Information);
			mResourceSystem = new ResourceSystem(mLogger);
			mResourceSystem.EnableHotReload();
			mResourceSystem.SetSerializerProvider(new OpenDDLSerializerProvider());
			mResourceSystem.Startup();
		}

		// Mount builtin:// scheme and load registry
		if (mBuiltinMount == null)
			LoadBuiltinRegistry();

		// Shader system (needs device) — skip if pre-set by editor host
		if (mShaderSystem == null && device != null)
		{
			let shaderDir = scope String();
			Path.InternalCombine(shaderDir, mBuiltInAssetDirectory, "shaders");
			let cacheDir = scope String();
			Path.InternalCombine(cacheDir, mAssetCacheDirectory, "shaders");

			let settings = Settings();
			mShaderSystem = new ShaderSystem();
			StringView[1] shaderPaths = .(shaderDir);
			mShaderSystem.Initialize(device, shaderPaths, settings.EnableShaderCache ? cacheDir : default);
		}

		// Font service — skip if pre-set by editor host
		if (mFontService == null)
		{
			mFontService = new TrueTypeFontService(mBuiltinMount);
			let robotoLocator = "fonts/roboto/Roboto-Regular.ttf";
			if (mBuiltinMount != null && mBuiltinMount.Exists(robotoLocator))
			{
				mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = 16 });
				mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = 24 });
			}
		}

		// Register all standard subsystems
		RegisterSubsystems(host);
	}

	/// Called after Context.Startup and after the main window is created.
	/// Sets window-dependent properties on subsystems, creates the HDR output
	/// target and blit helper, and caches renderer interfaces.
	public virtual void OnStartup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let ctx = host.Ctx;
		let device = host.Graphics?.Raw;

		// Cache renderer interfaces
		mSceneRenderer = ctx.GetSubsystemByInterface<ISceneRenderer>();
		mScreenRenderer = ctx.GetSubsystemByInterface<IScreenRenderer>();

		// Create HDR output target + blit helper for scene rendering
		if (device != null && host.MainWindow != null)
		{
			let mainWin = host.MainWindow;
			mRenderWidth = mainWin.Swap.Width;
			mRenderHeight = mainWin.Swap.Height;
			CreateOutputTarget(device, mRenderWidth, mRenderHeight);

			if (mShaderSystem != null)
			{
				mBlitHelper = new BlitHelper();
				mBlitHelper.Initialize(device, mainWin.Swap.Format, mShaderSystem);
			}
		}

		// Seed initial UI size
		if (mUISub != null && host.MainWindow != null)
		{
			mUISub.RenderSize = .((float)mRenderWidth, (float)mRenderHeight);
			mUISub.DpiScale = host.MainWindow.Window.ContentScale;
		}
	}

	/// Render into a window: clear the HDR target, render the first active
	/// scene, composite UI overlays, then blit to the backbuffer.
	public virtual void OnRenderWindow(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		let encoder = frame.Encoder;
		if (encoder == null) return;

		// Update UI subsystem render size
		if (mUISub != null)
			mUISub.RenderSize = .((float)frame.Width, (float)frame.Height);

		// Resize HDR target if backbuffer changed
		if (frame.Width != mRenderWidth || frame.Height != mRenderHeight)
		{
			let device = host.Graphics?.Raw;
			if (device != null)
			{
				DestroyOutputTarget(device);
				mRenderWidth = frame.Width;
				mRenderHeight = frame.Height;
				CreateOutputTarget(device, mRenderWidth, mRenderHeight);
			}
		}

		// Without an HDR target or scene renderer, just clear
		if (mColorTarget == null || mSceneRenderer == null)
		{
			frame.Clear(0.1f, 0.1f, 0.12f);
			return;
		}

		// Transition HDR target to RenderTarget and clear it
		encoder.TransitionTexture(mColorTarget, .ShaderRead, .RenderTarget);
		{
			ColorAttachment[1] clearAttachments = .(.()
			{
				View = mColorTargetView,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
			let clearPass = encoder.BeginRenderPass(clearDesc);
			clearPass.End();
		}

		// Scene rendering - render RuntimeScene if set by the game module
		mSceneRenderer.BeginRendering(encoder, mFrameIndex);
		if (RuntimeScene != null)
		{
			mSceneRenderer.RenderScene(RuntimeScene, encoder, mColorTarget, mColorTargetView,
				mRenderWidth, mRenderHeight, mFrameIndex);
		}
		mSceneRenderer.EndRendering();

		// Screen-space overlays (UI)
		if (mScreenRenderer != null && mColorTargetView != null)
		{
			encoder.TransitionTexture(mColorTarget, .ShaderRead, .RenderTarget);
			mScreenRenderer.RenderOverlays(encoder, mColorTargetView,
				mRenderWidth, mRenderHeight, mFrameIndex);
			encoder.TransitionTexture(mColorTarget, .RenderTarget, .ShaderRead);
		}

		// Blit HDR target to backbuffer
		if (mBlitHelper != null && mBlitHelper.IsReady)
		{
			ColorAttachment[1] blitAttachments = .(.()
			{
				View = frame.BackbufferView,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc blitDesc = .() { ColorAttachments = .(blitAttachments) };
			let blitPass = encoder.BeginRenderPass(blitDesc);
			mBlitHelper.Blit(blitPass, mColorTargetView, 0, 0, frame.Width, frame.Height, mFrameIndex);
			blitPass.End();
		}

		// Screenshot capture: copy backbuffer to readback buffer after blit
		if (mScreenshotRequested)
		{
			mScreenshotRequested = false;
			let device = host.Graphics?.Raw;
			if (device != null)
			{
				EnsureScreenshotBuffer(device, frame.Width, frame.Height);
				if (mScreenshotBuffer != null)
				{
					encoder.TransitionTexture(frame.Backbuffer, .RenderTarget, .CopySrc);
					BufferTextureCopyRegion region = .()
					{
						BufferOffset = 0,
						BytesPerRow = frame.Width * 4,
						RowsPerImage = 0,
						TextureMipLevel = 0,
						TextureArrayLayer = 0,
						TextureExtent = .(frame.Width, frame.Height, 1)
					};
					encoder.CopyTextureToBuffer(frame.Backbuffer, mScreenshotBuffer, region);
					encoder.TransitionTexture(frame.Backbuffer, .CopySrc, .RenderTarget);

					// Defer read to after submit (GPU must finish). For now, save
					// synchronously after the next fence wait. A simple approach:
					// the screenshot is read back the NEXT frame when the fence
					// for this frame's submission has been waited on.
					// For simplicity, save immediately after device idle.
					// TODO: Properly defer to next frame's fence wait.
				}
			}
		}

		mFrameIndex = (mFrameIndex + 1) % (int32)(host.Graphics?.FramesInFlight ?? 2);
	}

	/// Per-frame update. Override in game subclasses for game logic.
	/// Call base.OnUpdate(host, deltaTime) to keep P-key profiler dump.
	public virtual void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		// P-key: print profile frame
		if (host.Shell?.InputManager?.Keyboard != null &&
			host.Shell.InputManager.Keyboard.IsKeyPressed(.P))
			PrintProfileFrame();

		// Deferred profile print request
		if (mProfilePrintRequested)
		{
			mProfilePrintRequested = false;
			PrintProfileFrame();
		}
	}

	/// Fixed-timestep update. Override for deterministic game logic.
	public virtual void OnFixedUpdate(Sedulous.Runtime.Client.IApplicationHost host, float fixedDeltaTime) {}

	/// Enter play. Override for play-session initialization.
	public virtual void OnLaunch(Sedulous.Runtime.Client.IApplicationHost host) {}

	/// Leave play. Override for play-session teardown.
	public virtual void OnExit(Sedulous.Runtime.Client.IApplicationHost host) {}

	/// Cleanup engine infrastructure before Context.Shutdown.
	public virtual void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		mSceneRenderer = null;
		mScreenRenderer = null;
		mUISub = null;

		// Destroy HDR output target and screenshot buffer
		let device = host.Graphics?.Raw;
		if (device != null)
		{
			DestroyOutputTarget(device);
			if (mScreenshotBuffer != null)
				device.DestroyBuffer(ref mScreenshotBuffer);
		}

		// Unregister builtin mount + index before resource system shutdown
		if (mResourceSystem != null)
		{
			if (mBuiltinIndex != null)
				mResourceSystem.RemoveIndex(mBuiltinIndex);
			if (mBuiltinMount != null)
				mResourceSystem.Unmount("builtin");
		}

		mResourceSystem?.Shutdown();
	}

	// ==================== Subsystem Registration ====================

	/// Registers all standard engine subsystems. Called from Configure.
	/// Override to customize which subsystems are registered (call base
	/// for the full set, or skip it and register selectively).
	protected virtual void RegisterSubsystems(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let ctx = host.Ctx;
		let device = host.Graphics?.Raw;

		// Input (-900)
		let inputSub = new InputSubsystem();
		if (host.Shell?.InputManager != null)
			inputSub.SetInputManager(host.Shell.InputManager);
		ctx.RegisterSubsystem(inputSub);

		// Scene (-500)
		ctx.RegisterSubsystem(new SceneSubsystem(mResourceSystem));

		// Physics (-100)
		ctx.RegisterSubsystem(new PhysicsSubsystem());

		// Animation (100)
		ctx.RegisterSubsystem(new AnimationSubsystem(mResourceSystem));

		// Audio (200)
		ctx.RegisterSubsystem(new AudioSubsystem(mResourceSystem));

		// Navigation (300)
		ctx.RegisterSubsystem(new NavigationSubsystem());

		// UI (400)
		let uiSub = new EngineUISubsystem();
		uiSub.Device = device;
		uiSub.Shell = host.Shell;
		uiSub.ShaderSystem = mShaderSystem;
		uiSub.OutputFormat = .RGBA16Float;
		uiSub.FrameCount = (int32)(host.Graphics?.FramesInFlight ?? 2);
		uiSub.FontService = mFontService;
		mUISub = uiSub;
		ctx.RegisterSubsystem(uiSub);

		// Render (500)
		let renderSub = new RenderSubsystem(mResourceSystem);
		renderSub.Device = device;
		renderSub.Window = host.MainWindow?.Window;
		renderSub.ShaderSystem = mShaderSystem;
		renderSub.BuiltInAssetDirectory = mBuiltInAssetDirectory;
		ctx.RegisterSubsystem(renderSub);
	}

	/// Sets up the builtin asset mount and (if present) its identity index.
	/// Provides builtin:// scheme resources (primitives, materials, skies).
	private void LoadBuiltinRegistry()
	{
		if (mBuiltInAssetDirectory.IsEmpty)
			return;

		// Always mount the asset directory under "builtin://" so resources
		// can be opened by URI even without an identity index.
		mBuiltinMount = new FileSystemMount(mBuiltInAssetDirectory);
		mResourceSystem.Mount("builtin", mBuiltinMount);

		// Optional identity index: maps GUIDs to URIs for ResourceRef resolution.
		let registryPath = scope String();
		Path.InternalCombine(registryPath, mBuiltInAssetDirectory, "builtin.registry");
		if (!File.Exists(registryPath))
			return;

		let stream = scope FileStream();
		if (stream.Open(registryPath, .Read, .Read) case .Err)
			return;

		mBuiltinIndex = new InMemoryResourceIndex();
		if (mBuiltinIndex.DeserializeFrom(stream) case .Ok)
		{
			mResourceSystem.AddIndex(mBuiltinIndex);
		}
		else
		{
			delete mBuiltinIndex;
			mBuiltinIndex = null;
		}
	}

	// ==================== HDR Output Target ====================

	/// Creates the RGBA16Float HDR output target that the scene renders into.
	private void CreateOutputTarget(IDevice device, uint32 width, uint32 height)
	{
		if (width == 0 || height == 0) return;

		TextureDesc texDesc = .()
		{
			Label = "Pipeline Output",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .RGBA16Float,
			Usage = .RenderTarget | .Sampled | .CopySrc,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (device.CreateTexture(texDesc) case .Ok(let tex))
			mColorTarget = tex;

		TextureViewDesc viewDesc = .()
		{
			Label = "Pipeline Output View",
			Format = .RGBA16Float,
			Dimension = .Texture2D
		};

		if (mColorTarget != null)
		{
			if (device.CreateTextureView(mColorTarget, viewDesc) case .Ok(let view))
				mColorTargetView = view;
		}
	}

	/// Destroys the HDR output target.
	private void DestroyOutputTarget(IDevice device)
	{
		if (mColorTargetView != null)
			device.DestroyTextureView(ref mColorTargetView);
		if (mColorTarget != null)
			device.DestroyTexture(ref mColorTarget);
	}

	// ==================== Screenshot ====================

	/// Ensures the readback buffer exists and is large enough.
	private void EnsureScreenshotBuffer(IDevice device, uint32 width, uint32 height)
	{
		let requiredSize = (uint64)(width * height * 4);
		if (mScreenshotBuffer != null && mScreenshotBuffer.Size >= requiredSize)
			return;

		if (mScreenshotBuffer != null)
			device.DestroyBuffer(ref mScreenshotBuffer);

		BufferDesc desc = .()
		{
			Label = "Screenshot Readback",
			Size = requiredSize,
			Usage = .CopyDst,
			Memory = .GpuToCpu
		};

		if (device.CreateBuffer(desc) case .Ok(let buf))
			mScreenshotBuffer = buf;
	}

	// ==================== Profiling ====================

	private void PrintProfileFrame()
	{
		let frame = SProfiler.GetCompletedFrame();

		Console.WriteLine("=== Profile ===");
		Console.WriteLine("Frame {0}: {1:F2}ms ({2} samples)", frame.FrameNumber, frame.FrameDurationMs, frame.SampleCount);

		// Sort by start time so parents appear before children
		let sorted = new System.Collections.List<Sedulous.Profiler.ProfileSample>(frame.Samples.Count);
		defer delete sorted;
		for (let sample in frame.Samples)
			sorted.Add(sample);
		sorted.Sort(scope (a, b) => a.StartTimeUs <=> b.StartTimeUs);

		for (let sample in sorted)
		{
			let indent = scope String();
			for (int d = 0; d < sample.Depth; d++)
				indent.Append("  ");
			Console.WriteLine("  {0}{1}: {2:F3}ms", indent, sample.Name, sample.DurationMs);
		}

		Console.WriteLine("================");
	}
}
