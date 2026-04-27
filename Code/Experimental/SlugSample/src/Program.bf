namespace SlugSample;

using System;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Runtime.Client;
using Sedulous.Runtime;
using Sedulous.Slug;
using Sedulous.Slug.TTF;
using Sedulous.Slug.Renderer;

/// Slug GPU font rendering sample.
/// Demonstrates resolution-independent text rendering directly from
/// quadratic Bezier curves using the Slug algorithm.
class SlugSampleApp : Application
{
	private SlugFont mFont;
	private SlugTextRenderer mRenderer;
	private ShaderSystem mShaderSystem;

	private float mTime = 0;
	private int mFrameCount = 0;
	private float mFpsTimer = 0;
	private int mCurrentFps = 0;

	public this() : base()
	{
	}

	protected override void OnInitialize(Context context)
	{
		// 1. Load TTF font
		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);

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
		GetAssetPath("shaders", shaderPath);
		if (mShaderSystem.Initialize(Device, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		// 4. Initialize renderer (loads shaders, uploads textures, creates pipeline)
		mRenderer = new SlugTextRenderer(Device);
		switch (mRenderer.Initialize(mFont, textureData, (int32)SwapChain.BufferCount, SwapChain.Format, mShaderSystem))
		{
		case .Ok:
			Console.WriteLine("Slug renderer initialized!");
		case .Err:
			Console.WriteLine("Failed to initialize Slug renderer");
			return;
		}
	}

	protected override void OnUpdate(FrameContext frame)
	{
		mTime = frame.TotalTime;
		mFrameCount++;
		mFpsTimer += frame.DeltaTime;
		if (mFpsTimer >= 1.0f)
		{
			mCurrentFps = mFrameCount;
			mFrameCount = 0;
			mFpsTimer -= 1.0f;
		}
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		float w = (float)SwapChain.Width;
		float h = (float)SwapChain.Height;
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
		mRenderer.Prepare(frame.FrameIndex, SwapChain.Width, SwapChain.Height);
	}

	protected override void OnRender(IRenderPassEncoder renderPass, FrameContext frame)
	{
		let frameIndex = (int32)SwapChain.CurrentImageIndex;
		mRenderer.Render(renderPass, frameIndex);
	}

	protected override void OnShutdown()
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
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope SlugSampleApp();
		return app.Run(.() { Title = "Slug Font Rendering", Width = 1280, Height = 720, ClearColor = .(0.08f, 0.08f, 0.12f, 1.0f), EnableDepth = false });
	}
}
