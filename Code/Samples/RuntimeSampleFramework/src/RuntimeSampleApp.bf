namespace RuntimeSampleFramework;

using System;
using System.IO;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Platform;
using Sedulous.Platform.SDL3;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// Base class for runtime samples that use the ApplicationHost infrastructure.
/// Handles the common boilerplate: asset discovery, builtin mount, shader
/// system, font service, device caching. Subclasses override OnInit, OnUpdate,
/// OnRender, OnCleanup.
///
/// Mirrors GraphicsFramework.SampleApp for the RHI samples, but runs on top
/// of ApplicationHost + IApplication instead of raw SDL3.
public abstract class RuntimeSampleApp : IApplication
{
	// Infrastructure (owned, cleaned up in OnShutdown)
	private ShaderSystem mShaderSystem ~ { _?.Dispose(); delete _; };
	private TrueTypeFontService mFontService ~ delete _;
	private FileSystemMount mBuiltinMount ~ delete _;
	private String mBuiltInAssetDirectory = new .() ~ delete _;

	// Cached from host (not owned)
	private IDevice mDevice;
	private IPlatform mPlatform;
	private Sedulous.Runtime.Client.IApplicationHost mHost;

	// Timing
	private float mTotalTime;
	private float mDeltaTime;

	// --- Public accessors for subclasses ---

	/// The RHI device.
	protected IDevice Device => mDevice;

	/// The platform.
	protected IPlatform Platform => mPlatform;

	/// The application host.
	protected Sedulous.Runtime.Client.IApplicationHost Host => mHost;

	/// The shared shader system.
	protected ShaderSystem ShaderSystem => mShaderSystem;

	/// The default font service (Roboto loaded at common sizes).
	protected IFontService FontService => mFontService;

	/// The builtin VFS mount (Assets directory).
	protected FileSystemMount BuiltinMount => mBuiltinMount;

	/// The discovered engine Assets directory.
	protected StringView BuiltInAssetDirectory => mBuiltInAssetDirectory;

	/// Accumulated time since startup.
	protected float TotalTime => mTotalTime;

	/// Delta time for the current frame.
	protected float DeltaTime => mDeltaTime;

	/// Combines a relative path with the builtin asset directory.
	protected void GetAssetPath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		Path.InternalCombine(outPath, mBuiltInAssetDirectory, relativePath);
	}

	// --- IApplication ---

	public virtual ApplicationSettings Settings() => .();

	public void Configure(Sedulous.Runtime.Client.IApplicationHost host)
	{
		mHost = host;
		mDevice = host.Graphics?.Raw;
		mPlatform = host.Platform;
		mBuiltInAssetDirectory.Set(host.BuiltInAssetDirectory);

		// Builtin mount for VFS font loading
		if (!mBuiltInAssetDirectory.IsEmpty)
			mBuiltinMount = new FileSystemMount(mBuiltInAssetDirectory);

		// Shader system
		if (mDevice != null && !mBuiltInAssetDirectory.IsEmpty)
		{
			let shaderPath = scope String();
			Path.InternalCombine(shaderPath, mBuiltInAssetDirectory, "shaders");
			mShaderSystem = new ShaderSystem();
			mShaderSystem.Initialize(mDevice, scope StringView[](shaderPath));
		}

		// Font service with Roboto
		mFontService = new TrueTypeFontService(mBuiltinMount);
		let robotoLocator = "fonts/roboto/Roboto-Regular.ttf";
		if (mBuiltinMount != null && mBuiltinMount.Exists(robotoLocator))
		{
			for (let size in float[?](11, 12, 14, 16, 18, 20, 24, 28, 32))
				mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = size });
		}
	}

	public void OnStartup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		OnInit(host);
	}

	public void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
		OnUpdate(host, deltaTime, mTotalTime);
	}

	public void OnRenderWindow(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		OnRender(host, ref frame);
	}

	public void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		OnCleanup(host);
	}

	// --- Overridable hooks ---

	/// Called after infrastructure is created. Create your resources here.
	/// Device, ShaderSystem, FontService, BuiltinMount are all available.
	protected virtual void OnInit(Sedulous.Runtime.Client.IApplicationHost host) {}

	/// Called once per frame. DeltaTime and TotalTime are updated before this.
	protected virtual void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime, float totalTime) {}

	/// Called once per window per frame. Use frame.BeginBackbufferPass/EndBackbufferPass
	/// for simple rendering, or frame.Encoder for advanced usage.
	protected virtual void OnRender(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame) {}

	/// Called before shutdown. Clean up your resources here.
	protected virtual void OnCleanup(Sedulous.Runtime.Client.IApplicationHost host) {}

	// --- Convenience runner ---

	/// Create platform + device + host and run the app. Typical Program.Main body.
	public static int32 Run<T>() where T : RuntimeSampleApp, new, delete
	{
		let platform = scope SDL3Platform();
		if (platform.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize platform");
			return 1;
		}
		defer platform.Shutdown();

		let gfxResult = GraphicsDevice.Create(.());
		if (gfxResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let gfx = gfxResult.Value;
		defer delete gfx;

		let app = scope T();
		return ApplicationHost.RunApplication(app, platform, gfx);
	}
}
