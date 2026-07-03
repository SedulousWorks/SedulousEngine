namespace SlugSample;

using System;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Slug;
using Sedulous.Slug.TTF;
using Sedulous.Slug.Renderer;
using Sedulous.Shell.SDL3;

/// Slug GPU font rendering sample.
/// Demonstrates resolution-independent text rendering directly from
/// quadratic Bezier curves using the Slug algorithm.
class SlugSampleApp : IApplication
{
	private SlugFont mFont;
	private SlugTextRenderer mRenderer;
	private ShaderSystem mShaderSystem;

	private float mTime = 0;
	private float mTotalTime = 0;
	private int mFrameCount = 0;
	private float mFpsTimer = 0;
	private int mCurrentFps = 0;

	// Cached device reference
	private IDevice mDevice;

	// Asset directory
	private String mBuiltInAssetDirectory = new .() ~ delete _;

	public ApplicationSettings Settings()
	{
		return .()
		{
			Title = "Slug Font Rendering",
			Width = 1280, Height = 720
		};
	}

	public void Configure(IApplicationHost host)
	{
		DiscoverAssets();
		mDevice = host.Graphics.Raw;
	}

	public void OnStartup(IApplicationHost host)
	{
		let rw = host.MainWindow;

		// 1. Load TTF font
		String fontPath = scope .();
		Path.InternalCombine(fontPath, mBuiltInAssetDirectory, "fonts/roboto/Roboto-Regular.ttf");

		if (!File.Exists(fontPath))
		{
			Console.WriteLine(scope $"Font not found: {fontPath}");
			return;
		}

		switch (SlugTTFLoader.LoadFromFile(fontPath, 32, 126))
		{
		case .Ok(let font):
			mFont = font;
			Console.WriteLine(scope $"Font loaded: {mFont.GlyphCount} glyphs");
		case .Err(let err):
			Console.WriteLine(scope $"Failed to load font: {err}");
			return;
		}

		// 2. Build curve + band textures
		SlugTextureBuilder.BuildResult textureData;
		switch (SlugTextureBuilder.Build(mFont))
		{
		case .Ok(let result):
			textureData = result;
			Console.WriteLine(scope $"Textures built: curve={textureData.CurveTextureSize.x}x{textureData.CurveTextureSize.y}");
		case .Err:
			Console.WriteLine("Failed to build textures");
			return;
		}
		defer { delete textureData.CurveTextureData; delete textureData.BandTextureData; }

		// 3. Initialize shader system
		mShaderSystem = new ShaderSystem();

		String shaderPath = scope .();
		Path.InternalCombine(shaderPath, mBuiltInAssetDirectory, "shaders");
		if (mShaderSystem.Initialize(mDevice, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		// 4. Initialize renderer (loads shaders, uploads textures, creates pipeline)
		mRenderer = new SlugTextRenderer(mDevice);
		switch (mRenderer.Initialize(mFont, textureData, (int32)rw.Swap.BufferCount, rw.Swap.Format, mShaderSystem))
		{
		case .Ok:
			Console.WriteLine("Slug renderer initialized!");
		case .Err:
			Console.WriteLine("Failed to initialize Slug renderer");
			return;
		}
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		mTotalTime += deltaTime;
		mTime = mTotalTime;
		mFrameCount++;
		mFpsTimer += deltaTime;
		if (mFpsTimer >= 1.0f)
		{
			mCurrentFps = mFrameCount;
			mFrameCount = 0;
			mFpsTimer -= 1.0f;
		}
	}

	public void OnRenderWindow(IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		if (mRenderer == null)
			return;

		float w = (float)frame.Width;
		float h = (float)frame.Height;
		float margin = 30;

		// Build text geometry on CPU
		mRenderer.Begin();

		mRenderer.DrawText("Slug Font Rendering", margin, 50, 48.0f);
		mRenderer.DrawText("GPU Bezier curve rendering - no atlas needed", margin, 110, 24.0f, .(150, 150, 170, 255));

		float y = 170;
		mRenderer.DrawText("Resolution independent at any scale:", margin, y, 20.0f, .(255, 230, 100, 255));

		y += 40;
		mRenderer.DrawText("ABCDEFGHIJKLMNOPQRSTUVWXYZ", margin, y, 16.0f, .(100, 220, 255, 255));
		y += 30;
		mRenderer.DrawText("ABCDEFGHIJKLMNOPQRSTUVWXYZ", margin, y, 24.0f, .(100, 220, 255, 255));
		y += 40;
		mRenderer.DrawText("ABCDEFGHIJKLMNOPQRSTUVWXYZ", margin, y, 36.0f, .(100, 220, 255, 255));

		y += 55;
		mRenderer.DrawText("abcdefghijklmnopqrstuvwxyz  0123456789", margin, y, 28.0f);
		y += 50;
		mRenderer.DrawText("!@#$%^&*()_+-=[]{}|;':\",./<>?", margin, y, 28.0f);

		y += 100;
		mRenderer.DrawText("Slug", margin, y, 96.0f, .(100, 255, 150, 255));

		y += 120;
		mRenderer.DrawText("Tiny text at 10px is still crisp.", margin, y, 10.0f, .(150, 150, 170, 255));
		y += 20;
		mRenderer.DrawText("Even at 8px the curves are mathematically precise.", margin, y, 8.0f, .(150, 150, 170, 255));

		String fpsStr = scope $"FPS: {mCurrentFps}";
		let fpsWidth = mRenderer.MeasureText(fpsStr, 20.0f);
		mRenderer.DrawText(fpsStr, w - fpsWidth - margin, 30, 20.0f, .(100, 255, 150, 255));

		mRenderer.DrawText("Press Escape to exit", margin, h - 40, 16.0f, .(150, 150, 170, 255));

		// Upload to per-frame GPU buffers via WriteMappedBuffer (no sync stall)
		let fi = (int32)frame.FrameIndex;
		mRenderer.Prepare(fi, frame.Width, frame.Height);

		// Render pass
		let rp = frame.BeginBackbufferPass(ClearColor(0.08f, 0.08f, 0.12f, 1.0f));
		if (rp != null)
		{
			mRenderer.Render(rp, fi);
		}
		frame.EndBackbufferPass();
	}

	public void OnShutdown(IApplicationHost host)
	{
		if (mRenderer != null)
		{
			mRenderer.Dispose();
			delete mRenderer;
			mRenderer = null;
		}

		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
			mShaderSystem = null;
		}

		if (mFont != null)
		{
			delete mFont;
			mFont = null;
		}
	}

	private void DiscoverAssets()
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		var searchDir = scope String(cwd);
		while (true)
		{
			let assetsPath = scope String();
			Path.InternalCombine(assetsPath, searchDir, "Assets");
			if (Directory.Exists(assetsPath))
			{
				let marker = scope String();
				Path.InternalCombine(marker, assetsPath, ".assets");
				if (File.Exists(marker)) { mBuiltInAssetDirectory.Set(assetsPath); return; }
			}
			let parent = Path.GetDirectoryPath(searchDir, .. scope .());
			if (parent.IsEmpty || parent == searchDir) { mBuiltInAssetDirectory.Set(cwd); return; }
			searchDir.Set(parent);
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let shell = scope SDL3Shell();
		if (shell.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize shell");
			return 1;
		}
		defer shell.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = true });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope SlugSampleApp();
		return ApplicationHost.RunApplication(app, shell, graphics);
	}
}
