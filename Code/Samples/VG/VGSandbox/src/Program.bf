namespace VGSandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Shaders;
using Sedulous.ImageData;
using Sedulous.Imaging;

/// VG Sandbox — NanoVG-inspired demo showcasing Sedulous.VG capabilities.
class VGSandboxApp : Application
{
	private VGContext mVG;
	private VGRenderer mVGRenderer;
	private ShaderSystem mShaderSystem;

	// Checkerboard image used to demonstrate DrawImage.
	private OwnedImageData mCheckerboard ~ delete _;

	private float mTime = 0;

	public this() : base()
	{
	}

	protected override void OnInitialize(Sedulous.Runtime.Context context)
	{
		mShaderSystem = new ShaderSystem();
		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);
		if (mShaderSystem.Initialize(Device, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		mVG = new VGContext();
		mVGRenderer = new VGRenderer();
		if (mVGRenderer.Initialize(Device, SwapChain.Format, (int32)SwapChain.BufferCount, mShaderSystem) case .Err)
		{
			Console.WriteLine("Failed to initialize VGRenderer");
			return;
		}

		// Generate a 128x128 checkerboard and wrap it as IImageData for VG.
		// Sedulous.Imaging is CPU image generation; Sedulous.ImageData is the
		// CPU-to-GPU bridge format VG's renderer understands.
		let img = scope Image(128, 128, .RGBA8);
		for (uint32 y = 0; y < img.Height; y++)
		{
			for (uint32 x = 0; x < img.Width; x++)
			{
				let cell = ((x / 16) + (y / 16)) % 2 == 0;
				img.SetPixel(x, y, cell ? Color(230, 230, 230, 255) : Color(60, 60, 70, 255));
			}
		}
		mCheckerboard = new OwnedImageData(img.Width, img.Height, .RGBA8, img.Data);
	}

	protected override void OnUpdate(FrameContext frame)
	{
		mTime = frame.TotalTime;
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		if (mVGRenderer == null) return;

		mVG.Clear();

		let w = (float)SwapChain.Width;
		let h = (float)SwapChain.Height;

		DrawLineWidths(mVG, 10, 10);
		DrawLineCaps(mVG, 10, 230);
		DrawEyes(mVG, w - 250, 10, 150, 100, mTime);
		DrawLineJoins(mVG, 10, 290, 500, 50, mTime);
		DrawColorWheel(mVG, w - 280, 120, 250, 250, mTime);
		DrawGraph(mVG, 0, h - 180, w, 180, mTime);
		DrawScissor(mVG, 20, h - 220, mTime);
		DrawImages(mVG, 150, 20, mTime);

		let batch = mVG.GetBatch();
		mVGRenderer.Prepare(batch, frame.FrameIndex);
		mVGRenderer.UpdateProjection(SwapChain.Width, SwapChain.Height, frame.FrameIndex);
	}

	/// Animated eyes that follow a virtual point
	private void DrawEyes(VGContext vg, float x, float y, float w, float h, float t)
	{
		let ex = w * 0.23f;
		let ey = h * 0.5f;
		let br = Math.Min(ex, ey) * 0.5f;

		// Animated "look at" position (circular motion)
		let lx = x + w * 0.5f + Math.Cos(t * 0.8f) * w * 0.3f;
		let ly = y + h * 0.5f + Math.Sin(t * 0.6f) * h * 0.4f;

		// Eye whites (ellipses with gradient)
		for (int side = 0; side < 2; side++)
		{
			let cx = x + ex + (float)side * (w - ex * 2);
			let cy = y + ey;

			// Shadow
			{
				let builder = scope PathBuilder();
				ShapeBuilder.BuildEllipse(.(cx + 1, cy + 2), ex + 1, ey + 1, builder);
				let path = builder.ToPath();
				defer delete path;

				let fill = scope VGRadialGradientFill(.(cx, cy), Math.Max(ex, ey));
				fill.AddStop(0.0f, Color(0, 0, 0, 40));
				fill.AddStop(1.0f, Color(0, 0, 0, 0));
				vg.FillPath(path, fill);
			}

			// White
			{
				let builder = scope PathBuilder();
				ShapeBuilder.BuildEllipse(.(cx, cy), ex, ey, builder);
				let path = builder.ToPath();
				defer delete path;

				let fill = scope VGLinearGradientFill(.(cx, cy - ey * 0.5f), .(cx, cy + ey * 0.5f));
				fill.AddStop(0.0f, Color(255, 255, 255, 255));
				fill.AddStop(1.0f, Color(220, 220, 220, 255));
				vg.FillPath(path, fill);
			}

			// Iris (tracks the look-at point)
			{
				var dx = lx - cx;
				var dy = ly - cy;
				let d = Math.Sqrt(dx * dx + dy * dy);
				if (d > 1.0f)
				{
					dx = dx / (float)d;
					dy = dy / (float)d;
				}
				let irisX = cx + dx * (ex - br) * 0.4f;
				let irisY = cy + dy * (ey - br) * 0.5f;

				// Iris fill
				{
					let builder = scope PathBuilder();
					ShapeBuilder.BuildCircle(.(irisX, irisY), br, builder);
					let path = builder.ToPath();
					defer delete path;

					let fill = scope VGRadialGradientFill(.(irisX, irisY), br);
					fill.AddStop(0.0f, Color(60, 90, 160, 255));
					fill.AddStop(0.7f, Color(30, 50, 90, 255));
					fill.AddStop(1.0f, Color(20, 30, 60, 255));
					vg.FillPath(path, fill);
				}

				// Pupil
				vg.FillCircle(.(irisX, irisY), br * 0.45f, Color(20, 20, 20, 255));

				// Glint
				vg.FillCircle(.(irisX - br * 0.25f, irisY - br * 0.2f), br * 0.15f, Color(255, 255, 255, 200));
			}
		}
	}

	/// Animated graph / area chart
	private void DrawGraph(VGContext vg, float x, float y, float w, float h, float t)
	{
		float[6] samples = .();
		for (int i = 0; i < 6; i++)
		{
			samples[i] = (1.0f + Math.Sin(t * 1.2345f + (float)i * 0.33457f + (float)i * (float)i * 0.12f)
				+ Math.Sin(t * 0.68363f + (float)i * 1.3f)
				+ Math.Sin(t * 1.1642f + (float)i * (float)i * 0.54f)) * 0.25f;
		}

		let dx = w / 5.0f;

		// Filled area under curve
		{
			let builder = scope PathBuilder();
			builder.MoveTo(x, y + h);
			for (int i = 0; i < 6; i++)
			{
				let sx = x + (float)i * dx;
				let sy = y + h * (1.0f - samples[i] * 0.8f);
				if (i == 0)
					builder.LineTo(sx, sy);
				else
				{
					let prevSx = x + (float)(i - 1) * dx;
					let prevSy = y + h * (1.0f - samples[i - 1] * 0.8f);
					builder.CubicTo(prevSx + dx * 0.5f, prevSy, sx - dx * 0.5f, sy, sx, sy);
				}
			}
			builder.LineTo(x + w, y + h);
			builder.Close();
			let path = builder.ToPath();
			defer delete path;

			let fill = scope VGLinearGradientFill(.(x, y), .(x, y + h));
			fill.AddStop(0.0f, Color(0, 160, 192, 128));
			fill.AddStop(1.0f, Color(0, 160, 192, 16));
			vg.FillPath(path, fill);
		}

		// Stroke the curve line
		{
			let builder = scope PathBuilder();
			for (int i = 0; i < 6; i++)
			{
				let sx = x + (float)i * dx;
				let sy = y + h * (1.0f - samples[i] * 0.8f);
				if (i == 0)
					builder.MoveTo(sx, sy);
				else
				{
					let prevSx = x + (float)(i - 1) * dx;
					let prevSy = y + h * (1.0f - samples[i - 1] * 0.8f);
					builder.CubicTo(prevSx + dx * 0.5f, prevSy, sx - dx * 0.5f, sy, sx, sy);
				}
			}
			let path = builder.ToPath();
			defer delete path;

			// Shadow line
			let shadowStyle = StrokeStyle() { Width = 3.0f, Cap = .Round, Join = .Round };
			vg.PushState();
			vg.Translate(0, 2);
			vg.StrokePath(path, Color(0, 0, 0, 32), shadowStyle);
			vg.PopState();

			// Main line
			let lineStyle = StrokeStyle() { Width = 3.0f, Cap = .Round, Join = .Round };
			vg.StrokePath(path, Color(0, 160, 192, 255), lineStyle);
		}

		// Sample point dots
		for (int i = 0; i < 6; i++)
		{
			let sx = x + (float)i * dx;
			let sy = y + h * (1.0f - samples[i] * 0.8f);

			// Shadow
			{
				let builder = scope PathBuilder();
				ShapeBuilder.BuildCircle(.(sx, sy + 2), 4.0f, builder);
				let path = builder.ToPath();
				defer delete path;
				let fill = scope VGRadialGradientFill(.(sx, sy + 2), 6.0f);
				fill.AddStop(0.0f, Color(0, 0, 0, 32));
				fill.AddStop(1.0f, Color(0, 0, 0, 0));
				vg.FillPath(path, fill);
			}

			// Outer dot
			vg.FillCircle(.(sx, sy), 4.0f, Color(0, 160, 192, 255));
			// Inner highlight
			vg.FillCircle(.(sx, sy), 2.0f, Color(220, 240, 255, 255));
		}
	}

	/// HSL color wheel with center triangle
	private void DrawColorWheel(VGContext vg, float x, float y, float w, float h, float t)
	{
		let cx = x + w * 0.5f;
		let cy = y + h * 0.5f;
		let r1 = Math.Min(w, h) * 0.5f - 5.0f;
		let r0 = r1 - 20.0f;
		let hue = Math.Sin(t * 0.12f) * Math.PI_f * 2.0f;

		// Draw hue ring segments
		let segCount = 36;
		let segAngle = Math.PI_f * 2.0f / segCount;
		for (int i = 0; i < segCount; i++)
		{
			let a0 = (float)i * segAngle - segAngle * 0.5f;
			let a1 = a0 + segAngle;

			let builder = scope PathBuilder();
			// Outer arc segment as lines
			let steps = 4;
			for (int s = 0; s <= steps; s++)
			{
				let a = a0 + (a1 - a0) * ((float)s / steps);
				let px = cx + Math.Cos(a) * r1;
				let py = cy + Math.Sin(a) * r1;
				if (s == 0)
					builder.MoveTo(px, py);
				else
					builder.LineTo(px, py);
			}
			// Inner arc (reverse)
			for (int s = steps; s >= 0; s--)
			{
				let a = a0 + (a1 - a0) * ((float)s / steps);
				let px = cx + Math.Cos(a) * r0;
				let py = cy + Math.Sin(a) * r0;
				builder.LineTo(px, py);
			}
			builder.Close();
			let path = builder.ToPath();
			defer delete path;

			// Gradient from one hue to the next
			let c0 = HSLToColor(a0 / (Math.PI_f * 2.0f), 1.0f, 0.5f);
			let c1 = HSLToColor(a1 / (Math.PI_f * 2.0f), 1.0f, 0.5f);

			let fill = scope VGLinearGradientFill(
				.(cx + Math.Cos(a0) * (r0 + r1) * 0.5f, cy + Math.Sin(a0) * (r0 + r1) * 0.5f),
				.(cx + Math.Cos(a1) * (r0 + r1) * 0.5f, cy + Math.Sin(a1) * (r0 + r1) * 0.5f)
			);
			fill.AddStop(0.0f, c0);
			fill.AddStop(1.0f, c1);
			vg.FillPath(path, fill);
		}

		// Selector indicator on the ring
		{
			vg.PushState();
			vg.Translate(cx, cy);
			vg.Rotate(hue);

			let style = StrokeStyle() { Width = 2.0f };
			let builder = scope PathBuilder();
			builder.MoveTo(r0 - 1, -3);
			builder.LineTo(r1 + 1, -3);
			builder.LineTo(r1 + 1, 3);
			builder.LineTo(r0 - 1, 3);
			builder.Close();
			let path = builder.ToPath();
			defer delete path;
			vg.StrokePath(path, Color(255, 255, 255, 192), style);

			vg.PopState();
		}

		// Center triangle
		{
			let r = r0 - 6.0f;
			let ax = cx + Math.Cos(hue + Math.PI_f * 2.0f / 3.0f) * r;
			let ay = cy + Math.Sin(hue + Math.PI_f * 2.0f / 3.0f) * r;
			let bx = cx + Math.Cos(hue - Math.PI_f * 2.0f / 3.0f) * r;
			let by = cy + Math.Sin(hue - Math.PI_f * 2.0f / 3.0f) * r;
			let cxx = cx + Math.Cos(hue) * r;
			let cyy = cy + Math.Sin(hue) * r;

			// Fill with hue color
			let hueColor = HSLToColor(hue / (Math.PI_f * 2.0f), 1.0f, 0.5f);

			let builder = scope PathBuilder();
			builder.MoveTo(ax, ay);
			builder.LineTo(bx, by);
			builder.LineTo(cxx, cyy);
			builder.Close();
			let path = builder.ToPath();
			defer delete path;

			// Base hue fill
			let fill1 = scope VGLinearGradientFill(.(ax, ay), .(cxx, cyy));
			fill1.AddStop(0.0f, Color.White);
			fill1.AddStop(1.0f, hueColor);
			vg.FillPath(path, fill1);

			// Overlay black gradient
			let fill2 = scope VGLinearGradientFill(
				.((ax + bx) * 0.5f, (ay + by) * 0.5f),
				.(cxx, cyy)
			);
			fill2.AddStop(0.0f, Color(0, 0, 0, 128));
			fill2.AddStop(1.0f, Color(0, 0, 0, 0));
			vg.FillPath(path, fill2);

			// Triangle outline
			let style = StrokeStyle() { Width = 2.0f };
			vg.StrokePath(path, Color(0, 0, 0, 64), style);

			// Selection dot
			let selX = ax + (cxx - ax) * 0.3f + (bx - ax) * 0.4f;
			let selY = ay + (cyy - ay) * 0.3f + (by - ay) * 0.4f;
			vg.StrokeCircle(.(selX, selY), 5.0f, Color(255, 255, 255, 192), 2.0f);
			vg.FillCircle(.(selX, selY), 3.5f, hueColor);
		}
	}

	/// Demonstrates Phase 2 image rendering: native size, stretched, tinted,
	/// source-rect sub-region, and a rotated draw.
	private void DrawImages(VGContext vg, float x, float y, float t)
	{
		// 1. Native-size draw.
		vg.DrawImage(mCheckerboard, Vector2(x, y));

		// 2. Stretched into a larger rect.
		vg.DrawImage(mCheckerboard, RectangleF(x + 140, y, 80, 50));

		// 3. Tinted draw (semi-transparent red multiplied against the image).
		vg.DrawImage(mCheckerboard,
			.(x + 230, y, 80, 80),
			.(0, 0, mCheckerboard.Width, mCheckerboard.Height),
			Color(255, 120, 120, 220));

		// 4. Sub-region (top-left 64x64 of the atlas) enlarged.
		vg.DrawImage(mCheckerboard,
			.(x + 320, y, 80, 80),
			.(0, 0, 64, 64),
			Color.White);

		// 5. Rotated draw via the transform stack, verifying per-vertex transform.
		vg.PushState();
		vg.Translate(x + 450, y + 40);
		vg.Rotate(t * 0.6f);
		vg.DrawImage(mCheckerboard, RectangleF(-40, -40, 80, 80));
		vg.PopState();
	}

	/// Demonstrates different stroke widths
	private void DrawLineWidths(VGContext vg, float x, float y)
	{
		for (int i = 0; i < 20; i++)
		{
			let w = ((float)i + 0.5f) * 0.1f;
			let style = StrokeStyle() { Width = w };
			let builder = scope PathBuilder();
			builder.MoveTo(x, y + (float)i * 10);
			builder.LineTo(x + 100, y + (float)i * 10);
			let path = builder.ToPath();
			defer delete path;
			vg.StrokePath(path, Color(255, 255, 255, 255), style);
		}
	}

	/// Demonstrates line cap styles
	private void DrawLineCaps(VGContext vg, float x, float y)
	{
		VGLineCap[3] caps = .(.Butt, .Round, .Square);
		for (int i = 0; i < 3; i++)
		{
			let ly = y + (float)i * 14;
			let style = StrokeStyle() { Width = 8.0f, Cap = caps[i] };

			// Thick colored line
			let builder = scope PathBuilder();
			builder.MoveTo(x, ly);
			builder.LineTo(x + 80, ly);
			let path = builder.ToPath();
			defer delete path;
			vg.StrokePath(path, Color(255, 255, 255, 160), style);

			// Thin reference line showing actual endpoints
			let refStyle = StrokeStyle() { Width = 1.0f };
			let refBuilder = scope PathBuilder();
			refBuilder.MoveTo(x, ly);
			refBuilder.LineTo(x + 80, ly);
			let refPath = refBuilder.ToPath();
			defer delete refPath;
			vg.StrokePath(refPath, Color(0, 192, 255, 255), refStyle);
		}
	}

	/// Animated line join styles demo
	private void DrawLineJoins(VGContext vg, float x, float y, float w, float h, float t)
	{
		let s = 30.0f;
		VGLineJoin[3] joins = .(.Miter, .Round, .Bevel);
		VGLineCap[3] caps = .(.Butt, .Round, .Square);

		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				let fx = x + ((float)i * 3 + (float)j) * (w / 9.0f) + s * 0.5f;
				let fy = y + h * 0.5f;

				// Animated polyline points
				float[8] pts = .();
				pts[0] = -s * 0.25f + Math.Cos(t * 0.3f) * s * 0.5f;
				pts[1] = Math.Sin(t * 0.3f) * s * 0.5f;
				pts[2] = -s * 0.25f;
				pts[3] = 0;
				pts[4] = s * 0.25f;
				pts[5] = 0;
				pts[6] = s * 0.25f + Math.Cos(-t * 0.3f) * s * 0.5f;
				pts[7] = Math.Sin(-t * 0.3f) * s * 0.5f;

				let builder = scope PathBuilder();
				builder.MoveTo(fx + pts[0], fy + pts[1]);
				builder.LineTo(fx + pts[2], fy + pts[3]);
				builder.LineTo(fx + pts[4], fy + pts[5]);
				builder.LineTo(fx + pts[6], fy + pts[7]);
				let path = builder.ToPath();
				defer delete path;

				// Thick stroke showing join
				let thickStyle = StrokeStyle() { Width = s * 0.3f, Cap = caps[j], Join = joins[i] };
				vg.StrokePath(path, Color(0, 0, 0, 160), thickStyle);

				// Thin overlay
				let thinStyle = StrokeStyle() { Width = 1.0f, Cap = .Butt, Join = .Miter };
				vg.StrokePath(path, Color(0, 192, 255, 255), thinStyle);
			}
		}
	}

	/// Scissor/clip rectangle demo
	private void DrawScissor(VGContext vg, float x, float y, float t)
	{
		// First rect (establishes clip area)
		vg.PushState();
		vg.Translate(x, y);
		vg.Rotate(5.0f * Math.PI_f / 180.0f);
		vg.FillRect(.(-20, -20, 60, 40), Color(255, 0, 0, 255));

		// Set clip to first rect
		vg.PushClipRect(.(-20, -20, 60, 40));

		// Second rect (clipped by first)
		vg.Translate(40, 0);
		vg.Rotate(Math.Sin(t) * 0.15f);

		// Unclipped preview (semi-transparent)
		vg.PopClip();
		vg.FillRect(.(-20, -10, 60, 30), Color(255, 128, 0, 64));

		// Clipped version
		vg.PushClipRect(.(-60, -30, 60, 40));
		vg.FillRect(.(-20, -10, 60, 30), Color(255, 128, 0, 255));
		vg.PopClip();

		vg.PopState();
	}

	/// Convert HSL to Color
	private static Color HSLToColor(float h, float s, float l)
	{
		var h;
		h = h % 1.0f;
		if (h < 0) h += 1.0f;

		float r, g, b;
		if (s <= 0.0f)
		{
			r = g = b = l;
		}
		else
		{
			let q = l < 0.5f ? l * (1.0f + s) : l + s - l * s;
			let p = 2.0f * l - q;
			r = HueToRGB(p, q, h + 1.0f / 3.0f);
			g = HueToRGB(p, q, h);
			b = HueToRGB(p, q, h - 1.0f / 3.0f);
		}

		return Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), 255);
	}

	private static float HueToRGB(float p, float q, float t)
	{
		var t;
		if (t < 0) t += 1.0f;
		if (t > 1) t -= 1.0f;
		if (t < 1.0f / 6.0f) return p + (q - p) * 6.0f * t;
		if (t < 1.0f / 2.0f) return q;
		if (t < 2.0f / 3.0f) return p + (q - p) * (2.0f / 3.0f - t) * 6.0f;
		return p;
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mVGRenderer == null)
			return false;

		ColorAttachment[1] colorAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.19f, 0.19f, 0.21f, 1.0f)
		});
		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };

		let renderPass = render.Encoder.BeginRenderPass(passDesc);
		if (renderPass != null)
		{
			mVGRenderer.Render(renderPass, render.SwapChain.Width, render.SwapChain.Height, render.Frame.FrameIndex);
			renderPass.End();
		}

		return true;
	}

	protected override void OnShutdown()
	{
		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
		}

		if (mVG != null) delete mVG;

		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope VGSandboxApp();
		return app.Run(.()
		{
			Title = "VG Sandbox",
			Width = 1000, Height = 600,
			EnableDepth = false
		});
	}
}
