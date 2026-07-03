namespace DrawingSandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Drawing;
using Sedulous.Drawing.Renderer;
using RuntimeSampleFramework;

/// Drawing sandbox sample demonstrating Sedulous.Drawing capabilities.
class DrawingSandboxApp : RuntimeSampleApp
{
	// Drawing context (created after font service)
	private DrawContext mDrawContext;

	// GPU renderer
	private DrawingRenderer mDrawingRenderer;
	private DrawingRenderSlice mDrawingSlice;

	// Font size used for labels
	private const float FONT_SIZE = 20;

	// FPS tracking
	private int mFrameCount = 0;
	private float mFpsTimer = 0;
	private int mCurrentFps = 0;

	// Cached screen dimensions
	private uint32 mWidth;
	private uint32 mHeight;

	public override ApplicationSettings Settings() => .()
	{
		Title = "Drawing Sandbox",
		Width = 1280, Height = 720,
	};

	protected override void OnInit(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let rw = host.MainWindow;

		// Create draw context with font service
		mDrawContext = new DrawContext(FontService as Sedulous.Fonts.TTF.TrueTypeFontService);

		// Create and initialize the drawing renderer
		mDrawingRenderer = new DrawingRenderer();
		if (mDrawingRenderer.Initialize(Device, rw.Swap.Format, (int32)rw.Swap.BufferCount, ShaderSystem) case .Err)
		{
			Console.WriteLine("Failed to initialize DrawingRenderer");
			return;
		}

		Console.WriteLine("DrawingSandbox initialized with DrawingRenderer");
	}

	protected override void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime, float totalTime)
	{
		// FPS calculation
		mFrameCount++;
		mFpsTimer += deltaTime;
		if (mFpsTimer >= 1.0f)
		{
			mCurrentFps = mFrameCount;
			mFrameCount = 0;
			mFpsTimer -= 1.0f;
		}
	}

	protected override void OnRender(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		if (mDrawingRenderer == null || !mDrawingRenderer.IsInitialized)
			return;

		mWidth = frame.Width;
		mHeight = frame.Height;

		// Build drawing commands
		BuildDrawCommands();

		// Prepare batch data for GPU
		let fi = (int32)frame.FrameIndex;
		mDrawingRenderer.BeginFrame(fi);
		let batch = mDrawContext.GetBatch();
		if (batch != null)
			mDrawingSlice = mDrawingRenderer.Prepare(batch, fi, frame.Width, frame.Height);
		else
			mDrawingSlice = .Invalid;

		// Create render pass targeting swap chain (no depth for 2D drawing)
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = frame.BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.1f, 0.1f, 0.15f, 1.0f)
		});
		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };

		let renderPass = frame.Encoder.BeginRenderPass(passDesc);
		if (renderPass != null)
		{
			mDrawingRenderer.Render(renderPass, frame.Width, frame.Height, fi, mDrawingSlice);
			renderPass.End();
		}
	}

	private void BuildDrawCommands()
	{
		mDrawContext.Clear();

		float screenWidth = (float)mWidth;
		float screenHeight = (float)mHeight;
		float margin = 20;
		float columnWidth = (screenWidth - margin * 4) / 3;

		// === COLUMN 1: Basic Shapes ===
		float col1X = margin;
		float y = margin;

		DrawLabel("BASIC SHAPES", col1X, y, Color.Yellow);
		y += 30;

		DrawLabel("Rectangle", col1X, y, Color.White);
		y += 20;
		mDrawContext.FillRect(.(col1X, y, 100, 60), Color.Red);
		y += 80;

		DrawLabel("Rounded Rect", col1X, y, Color.White);
		y += 20;
		mDrawContext.FillRoundedRect(.(col1X, y, 100, 60), 15, Color.Green);
		y += 80;

		DrawLabel("Circle", col1X, y, Color.White);
		y += 20;
		mDrawContext.FillCircle(.(col1X + 50, y + 40), 40, Color.Blue);
		y += 100;

		DrawLabel("Ellipse", col1X, y, Color.White);
		y += 20;
		mDrawContext.FillEllipse(.(col1X + 60, y + 30), 60, 30, Color.Purple);
		y += 80;

		DrawLabel("Arc (animated)", col1X, y, Color.White);
		y += 20;
		float arcSweep = (Math.Sin(TotalTime * 2) * 0.5f + 0.5f) * Math.PI_f * 1.8f + 0.2f;
		mDrawContext.FillArc(.(col1X + 50, y + 50), 45, -Math.PI_f / 2, arcSweep, Color.Orange);
		y += 120;

		// === COLUMN 2: Strokes & Lines ===
		float col2X = margin * 2 + columnWidth;
		y = margin;

		DrawLabel("STROKES & LINES", col2X, y, Color.Yellow);
		y += 30;

		DrawLabel("Stroked Rect", col2X, y, Color.White);
		y += 20;
		mDrawContext.DrawRect(.(col2X, y, 100, 60), Color.Cyan, 3.0f);
		y += 80;

		DrawLabel("Stroked Circle", col2X, y, Color.White);
		y += 20;
		mDrawContext.DrawCircle(.(col2X + 50, y + 40), 40, Color.Magenta, 3.0f);
		y += 100;

		DrawLabel("Lines", col2X, y, Color.White);
		y += 20;
		mDrawContext.DrawLine(.(col2X, y), .(col2X + 100, y + 50), Color.Red, 2.0f);
		mDrawContext.DrawLine(.(col2X + 100, y), .(col2X, y + 50), Color.Green, 2.0f);
		y += 70;

		DrawLabel("Polyline", col2X, y, Color.White);
		y += 20;
		Vector2[] polylinePoints = scope .(
			.(col2X, y + 40),
			.(col2X + 30, y),
			.(col2X + 60, y + 40),
			.(col2X + 90, y),
			.(col2X + 120, y + 40)
		);
		mDrawContext.DrawPolyline(polylinePoints, Color.Yellow, 3.0f);
		y += 60;

		DrawLabel("Polygon Outline", col2X, y, Color.White);
		y += 20;
		Vector2[] pentagonPoints = scope .(
			.(col2X + 50, y),
			.(col2X + 100, y + 35),
			.(col2X + 80, y + 90),
			.(col2X + 20, y + 90),
			.(col2X, y + 35)
		);
		mDrawContext.DrawPolygon(pentagonPoints, Color.Lime, 2.0f);
		y += 110;

		// === COLUMN 3: Advanced Features ===
		float col3X = margin * 3 + columnWidth * 2;
		y = margin;

		DrawLabel("ADVANCED FEATURES", col3X, y, Color.Yellow);
		y += 30;

		DrawLabel("Filled Polygon", col3X, y, Color.White);
		y += 20;
		Vector2[] trianglePoints = scope .(
			.(col3X + 50, y),
			.(col3X + 100, y + 70),
			.(col3X, y + 70)
		);
		mDrawContext.FillPolygon(trianglePoints, Color.Coral);
		y += 90;

		DrawLabel("Linear Gradient", col3X, y, Color.White);
		y += 20;
		let linearBrush = scope LinearGradientBrush(.(col3X, y), .(col3X + 120, y + 60), Color.Red, Color.Blue);
		mDrawContext.FillRect(.(col3X, y, 120, 60), linearBrush);
		y += 80;

		DrawLabel("Radial Gradient", col3X, y, Color.White);
		y += 25;
		let radialBrush = scope RadialGradientBrush(.(col3X + 50, y + 50), 50, Color.White, Color.DarkBlue);
		mDrawContext.FillCircle(.(col3X + 50, y + 50), 50, radialBrush);
		y += 115;

		DrawLabel("Transforms (rotating)", col3X, y, Color.White);
		y += 20;
		float centerX = col3X + 60;
		float centerY = y + 60;

		mDrawContext.PushState();
		mDrawContext.Translate(centerX, centerY);
		mDrawContext.Rotate(TotalTime);
		mDrawContext.FillRect(.(-30, -30, 60, 60), Color(255, 100, 100, 200));
		mDrawContext.PopState();

		mDrawContext.PushState();
		mDrawContext.Translate(centerX, centerY);
		mDrawContext.Rotate(-TotalTime * 0.7f);
		mDrawContext.FillRect(.(-25, -25, 50, 50), Color(100, 255, 100, 200));
		mDrawContext.PopState();

		mDrawContext.PushState();
		mDrawContext.Translate(centerX, centerY);
		mDrawContext.Rotate(TotalTime * 1.3f);
		mDrawContext.FillRect(.(-20, -20, 40, 40), Color(100, 100, 255, 200));
		mDrawContext.PopState();
		y += 140;

		DrawLabel("Scale Animation", col3X, y, Color.White);
		y += 20;
		float scale = 0.5f + Math.Sin(TotalTime * 3) * 0.3f;
		mDrawContext.PushState();
		mDrawContext.Translate(col3X + 50, y + 30);
		mDrawContext.Scale(scale, scale);
		mDrawContext.FillCircle(.(0, 0), 30, Color.Gold);
		mDrawContext.PopState();
		y += 80;

		DrawLabel("Transformed Text", col3X, y, Color.White);
		y += 25;

		mDrawContext.PushState();
		mDrawContext.Translate(col3X + 60, y + 20);
		mDrawContext.Rotate(TotalTime * 0.5f);
		DrawLabel("Spinning!", -30, -10, Color.Cyan);
		mDrawContext.PopState();

		mDrawContext.PushState();
		mDrawContext.Translate(col3X + 160, y + 20);
		let textScale = 0.8f + Math.Sin(TotalTime * 2) * 0.4f;
		mDrawContext.Scale(textScale, textScale);
		DrawLabel("Pulsing", -25, -10, Color.Magenta);
		mDrawContext.PopState();

		DrawLabel("Ålign Ôrigin", 0, 0, Color.Red);
		DrawLabel(scope $"FPS: {mCurrentFps}", screenWidth - 100, 30, Color.Lime);
		DrawLabel("Press Escape to exit", screenWidth / 2 - 80, screenHeight - 30, Color.Gray);
	}

	private void DrawLabel(StringView text, float x, float y, Color color)
	{
		mDrawContext.DrawText(text, FONT_SIZE, .(x, y), color);
	}

	protected override void OnCleanup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		if (mDrawingRenderer != null)
		{
			mDrawingRenderer.Dispose();
			delete mDrawingRenderer;
		}

		if (mDrawContext != null) delete mDrawContext;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		return RuntimeSampleApp.Run<DrawingSandboxApp>();
	}
}
