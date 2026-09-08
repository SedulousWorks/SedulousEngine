using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Samples.VGSandbox;

/// Everything the sandbox draws, and the content it draws with.
///
/// Separate from the application because none of it touches a device: a scene is a series
/// of calls into a VGContext, which is what makes the whole demo testable and what keeps
/// the application to bringing a window and a renderer up.
class SandboxScene
{
	private TrueTypeFontService mFontService = null ~ delete _;
	private Image mChecker = null ~ delete _;
	private SVGDocument mBadge = null ~ delete _;
	private SVGDocument mIcon = null ~ delete _;

	private CachedFont mFontSmall;
	private CachedFont mFontMedium;
	private CachedFont mFontLarge;
	/// A distance field atlas baked once, sampled crisp at any scale.
	private CachedFont mFontDistanceField;

	public IFontService FontService => mFontService;
	/// False when this checkout has no font asset, which only costs the text panels.
	public bool HasFonts => mFontSmall != null;

	public ~this()
	{
		// The service's faces go before the backends that made them are unregistered.
		delete mFontService;
		mFontService = null;
		DistanceFieldFonts.Shutdown();
	}

	/// Loads what it can find. MISSING CONTENT IS SKIPPED rather than fatal: the geometry
	/// panels are the point of the sandbox, and they need nothing off disk.
	public void Initialize()
	{
		mFontService = new TrueTypeFontService();

		let fontPath = scope String();
		if (SandboxContent.FindFile(SandboxContent.cFontFile, fontPath))
		{
			LoadSize(fontPath, 14.0f);
			LoadSize(fontPath, 20.0f);
			LoadSize(fontPath, 36.0f);
			mFontSmall = mFontService.GetFont("Roboto", 14.0f);
			mFontMedium = mFontService.GetFont("Roboto", 20.0f);
			mFontLarge = mFontService.GetFont("Roboto", 36.0f);

			DistanceFieldFonts.Initialize();
			var options = FontLoadOptions.DistanceField();
			options.PixelHeight = 48.0f;
			options.AtlasWidth = 1024;
			options.AtlasHeight = 1024;
			if (mFontService.LoadFont("RobotoDF", fontPath, options) == .Success)
				mFontDistanceField = mFontService.GetFont("RobotoDF", 48.0f);
		}
		else
		{
			Console.Error.WriteLine(scope $"VGSandbox: '{SandboxContent.cFontFile}' was not found, so the text panels are skipped");
		}

		mChecker = Image.CreateCheckerboard(128, .(230, 230, 230, 255), .(60, 60, 70, 255), 16);

		// The badge disc is filled from an SVG radial gradient declared in a defs block and
		// referenced by url(), which is the gradient pass through's visible proof: the
		// tinted copy beside it must come out FLAT.
		mBadge = LoadDocument("""
			<svg viewBox="0 0 100 100">
			<defs><radialGradient id="disc" cx="0.35" cy="0.3" r="0.8">
			<stop offset="0%" stop-color="#5A9BE8"/>
			<stop offset="100%" stop-color="#1E4E96"/>
			</radialGradient></defs>
			<circle cx="50" cy="50" r="45" fill="url(#disc)" stroke="#1A4A90" stroke-width="3"/>
			<circle cx="50" cy="50" r="30" fill="none" stroke="#4A9AFF" stroke-width="1.5" opacity="0.6"/>
			<text x="50" y="58" text-anchor="middle" font-size="28" font-weight="bold" fill="#FFFFFF">VG</text>
			</svg>
			""");

		mIcon = LoadDocument("""
			<svg viewBox="0 0 24 24">
			<path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" fill="#FFD700" stroke="#B8960F" stroke-width="0.8"/>
			<text x="12" y="14" text-anchor="middle" font-size="6" fill="#8B6914">5</text>
			</svg>
			""");
	}

	private void LoadSize(StringView path, float pixelHeight)
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = pixelHeight;
		if (mFontService.LoadFont("Roboto", path, options) != .Success)
			Console.Error.WriteLine(scope $"VGSandbox: Roboto at {pixelHeight}px did not load");
	}

	private static SVGDocument LoadDocument(StringView markup)
	{
		if (SVGLoader.Load(markup) case .Ok(let document))
			return document;
		return null;
	}

	/// An sRGB authored byte colour, which is how every colour in this scene is written.
	private static Color GC(uint8 r, uint8 g, uint8 b, uint8 a = 255) => ToColor(Color32(r, g, b, a));

	// ---- the scene ----

	public void Draw(VGContext vg, float w, float h, float t)
	{
		DrawLineWidths(vg, 10, 10);
		DrawLineCaps(vg, 10, 230);
		DrawEyes(vg, w - 250, 10, 150, 100, t);
		DrawLineJoins(vg, 10, 290, 500, 50, t);
		DrawColorWheel(vg, w - 280, 120, 250, 250, t);
		DrawGraph(vg, 0, h - 180, w, 180, t);
		DrawScissor(vg, 20, h - 220, t);
		DrawImages(vg, 150, 20, t);
		DrawTextPanel(vg, 150, 170, t);
		DrawUIConvenience(vg, 150, 340);
		DrawImmediatePath(vg, 150, 410, t);
		DrawSVG(vg, 150, 470);
		DrawDistanceFieldText(vg, w - 280, 390, t);
		DrawFillCorrectness(vg, 560, 340, t);
	}

	// ---- helpers over the builder, which hands back a path the caller owns ----

	private static void FillBuilt(VGContext vg, PathBuilder builder, Color color,
		FillRule fillRule = .EvenOdd)
	{
		let path = builder.ToPath();
		defer delete path;
		vg.FillPath(path, color, fillRule);
	}

	private static void FillBuilt(VGContext vg, PathBuilder builder, IVGFill fill,
		FillRule fillRule = .EvenOdd)
	{
		let path = builder.ToPath();
		defer delete path;
		vg.FillPath(path, fill, fillRule);
	}

	private static void StrokeBuilt(VGContext vg, PathBuilder builder, Color color,
		StrokeStyle style)
	{
		let path = builder.ToPath();
		defer delete path;
		vg.StrokePath(path, color, style);
	}

	/// Twenty hairlines from a tenth of a pixel up, which is where a stroker either holds
	/// its width or collapses.
	private void DrawLineWidths(VGContext vg, float x, float y)
	{
		for (int i < 20)
		{
			let width = ((float)i + 0.5f) * 0.1f;
			let builder = scope PathBuilder();
			builder.MoveTo(x, y + (float)i * 10.0f);
			builder.LineTo(x + 100.0f, y + (float)i * 10.0f);
			StrokeBuilt(vg, builder, GC(255, 255, 255), StrokeStyle(width));
		}
	}

	/// Each cap over a hairline of the same line, so the overhang a square or round cap
	/// adds is visible against where the geometry actually ends.
	private void DrawLineCaps(VGContext vg, float x, float y)
	{
		let caps = VGLineCap[3](.Butt, .Round, .Square);
		for (int i < 3)
		{
			let lineY = y + (float)i * 14.0f;

			let thick = scope PathBuilder();
			thick.MoveTo(x, lineY);
			thick.LineTo(x + 80.0f, lineY);
			StrokeBuilt(vg, thick, GC(255, 255, 255, 160), StrokeStyle(8.0f, caps[i], .Miter));

			let hairline = scope PathBuilder();
			hairline.MoveTo(x, lineY);
			hairline.LineTo(x + 80.0f, lineY);
			StrokeBuilt(vg, hairline, GC(0, 192, 255), StrokeStyle(1.0f));
		}
	}

	/// Two eyes tracking a moving point: nested ellipses, radial and linear gradients, and
	/// the convenience circles.
	private void DrawEyes(VGContext vg, float x, float y, float w, float h, float t)
	{
		let ex = w * 0.23f;
		let ey = h * 0.5f;
		let br = Min(ex, ey) * 0.5f;
		let lookX = x + w * 0.5f + Cos(t * 0.8f) * w * 0.3f;
		let lookY = y + h * 0.5f + Sin(t * 0.6f) * h * 0.4f;

		for (int side < 2)
		{
			let cx = x + ex + (float)side * (w - ex * 2.0f);
			let cy = y + ey;

			// Shadow.
			{
				let builder = scope PathBuilder();
				ShapeBuilder.BuildEllipse(.(cx + 1.0f, cy + 2.0f), ex + 1.0f, ey + 1.0f, builder);
				let fill = scope VGRadialGradientFill(.(cx, cy), Max(ex, ey));
				fill.AddStop(0.0f, GC(0, 0, 0, 40));
				fill.AddStop(1.0f, GC(0, 0, 0, 0));
				FillBuilt(vg, builder, fill);
			}
			// White.
			{
				let builder = scope PathBuilder();
				ShapeBuilder.BuildEllipse(.(cx, cy), ex, ey, builder);
				let fill = scope VGLinearGradientFill(.(cx, cy - ey * 0.5f), .(cx, cy + ey * 0.5f));
				fill.AddStop(0.0f, GC(255, 255, 255));
				fill.AddStop(1.0f, GC(220, 220, 220));
				FillBuilt(vg, builder, fill);
			}
			// Iris, which tracks the look at point.
			{
				var dx = lookX - cx;
				var dy = lookY - cy;
				let distance = Sqrt(dx * dx + dy * dy);
				if (distance > 1.0f)
				{
					dx /= distance;
					dy /= distance;
				}
				let irisX = cx + dx * (ex - br) * 0.4f;
				let irisY = cy + dy * (ey - br) * 0.5f;

				let builder = scope PathBuilder();
				ShapeBuilder.BuildCircle(.(irisX, irisY), br, builder);
				let fill = scope VGRadialGradientFill(.(irisX, irisY), br);
				fill.AddStop(0.0f, GC(60, 90, 160));
				fill.AddStop(0.7f, GC(30, 50, 90));
				fill.AddStop(1.0f, GC(20, 30, 60));
				FillBuilt(vg, builder, fill);

				vg.FillCircle(.(irisX, irisY), br * 0.45f, GC(20, 20, 20));
				vg.FillCircle(.(irisX - br * 0.25f, irisY - br * 0.2f), br * 0.15f,
					GC(255, 255, 255, 200));
			}
		}
	}

	/// Every join over every cap, on a hinge that keeps moving so the miter limit is
	/// crossed and recrossed.
	private void DrawLineJoins(VGContext vg, float x, float y, float w, float h, float t)
	{
		let s = 30.0f;
		let joins = VGLineJoin[3](.Miter, .Round, .Bevel);
		let caps = VGLineCap[3](.Butt, .Round, .Square);

		for (int i < 3)
		{
			for (int j < 3)
			{
				let fx = x + ((float)i * 3.0f + (float)j) * (w / 9.0f) + s * 0.5f;
				let fy = y + h * 0.5f;

				let builder = scope PathBuilder();
				builder.MoveTo(fx + (-s * 0.25f + Cos(t * 0.3f) * s * 0.5f), fy + Sin(t * 0.3f) * s * 0.5f);
				builder.LineTo(fx - s * 0.25f, fy);
				builder.LineTo(fx + s * 0.25f, fy);
				builder.LineTo(fx + (s * 0.25f + Cos(-t * 0.3f) * s * 0.5f), fy + Sin(-t * 0.3f) * s * 0.5f);

				let path = builder.ToPath();
				defer delete path;
				vg.StrokePath(path, GC(0, 0, 0, 160), StrokeStyle(s * 0.3f, caps[j], joins[i]));
				vg.StrokePath(path, GC(0, 192, 255), StrokeStyle(1.0f, .Butt, .Miter));
			}
		}
	}

	/// Thirty six gradient wedges around a ring, with a selector and the saturation
	/// triangle: many small gradient fills in one frame.
	private void DrawColorWheel(VGContext vg, float x, float y, float w, float h, float t)
	{
		let cx = x + w * 0.5f;
		let cy = y + h * 0.5f;
		let outer = Min(w, h) * 0.5f - 5.0f;
		let inner = outer - 20.0f;
		let hue = Sin(t * 0.12f) * TwoPi;

		let segmentCount = 36;
		let segmentAngle = TwoPi / (float)segmentCount;
		for (int i < segmentCount)
		{
			let a0 = (float)i * segmentAngle - segmentAngle * 0.5f;
			let a1 = a0 + segmentAngle;

			let builder = scope PathBuilder();
			let steps = 4;
			for (int s = 0; s <= steps; s++)
			{
				let a = a0 + (a1 - a0) * ((float)s / (float)steps);
				let px = cx + Cos(a) * outer;
				let py = cy + Sin(a) * outer;
				if (s == 0)
					builder.MoveTo(px, py);
				else
					builder.LineTo(px, py);
			}
			for (int s = steps; s >= 0; s--)
			{
				let a = a0 + (a1 - a0) * ((float)s / (float)steps);
				builder.LineTo(cx + Cos(a) * inner, cy + Sin(a) * inner);
			}
			builder.Close();

			let mid = (inner + outer) * 0.5f;
			let fill = scope VGLinearGradientFill(
				.(cx + Cos(a0) * mid, cy + Sin(a0) * mid),
				.(cx + Cos(a1) * mid, cy + Sin(a1) * mid));
			fill.AddStop(0.0f, HSLToColor(a0 / TwoPi, 1.0f, 0.5f));
			fill.AddStop(1.0f, HSLToColor(a1 / TwoPi, 1.0f, 0.5f));
			FillBuilt(vg, builder, fill);
		}

		// The selector on the ring.
		{
			vg.PushState();
			vg.Translate(cx, cy);
			vg.Rotate(hue);

			let builder = scope PathBuilder();
			builder.MoveTo(inner - 1.0f, -3.0f);
			builder.LineTo(outer + 1.0f, -3.0f);
			builder.LineTo(outer + 1.0f, 3.0f);
			builder.LineTo(inner - 1.0f, 3.0f);
			builder.Close();
			StrokeBuilt(vg, builder, GC(255, 255, 255, 192), StrokeStyle(2.0f));

			vg.PopState();
		}

		// The saturation triangle, filled twice: the hue ramp, then a darkening ramp over it.
		{
			let r = inner - 6.0f;
			let ax = cx + Cos(hue + TwoPi / 3.0f) * r;
			let ay = cy + Sin(hue + TwoPi / 3.0f) * r;
			let bx = cx + Cos(hue - TwoPi / 3.0f) * r;
			let by = cy + Sin(hue - TwoPi / 3.0f) * r;
			let hx = cx + Cos(hue) * r;
			let hy = cy + Sin(hue) * r;
			let hueColor = HSLToColor(hue / TwoPi, 1.0f, 0.5f);

			let builder = scope PathBuilder();
			builder.MoveTo(ax, ay);
			builder.LineTo(bx, by);
			builder.LineTo(hx, hy);
			builder.Close();
			let path = builder.ToPath();
			defer delete path;

			let toHue = scope VGLinearGradientFill(.(ax, ay), .(hx, hy));
			toHue.AddStop(0.0f, GC(255, 255, 255));
			toHue.AddStop(1.0f, hueColor);
			vg.FillPath(path, toHue);

			let toBlack = scope VGLinearGradientFill(.((ax + bx) * 0.5f, (ay + by) * 0.5f), .(hx, hy));
			toBlack.AddStop(0.0f, GC(0, 0, 0, 128));
			toBlack.AddStop(1.0f, GC(0, 0, 0, 0));
			vg.FillPath(path, toBlack);

			vg.StrokePath(path, GC(0, 0, 0, 64), StrokeStyle(2.0f));

			let selX = ax + (hx - ax) * 0.3f + (bx - ax) * 0.4f;
			let selY = ay + (hy - ay) * 0.3f + (by - ay) * 0.4f;
			vg.StrokeCircle(.(selX, selY), 5.0f, GC(255, 255, 255, 192), 2.0f);
			vg.FillCircle(.(selX, selY), 3.5f, hueColor);
		}
	}

	/// An area chart: a curved ribbon under a stroked spline, with shadowed dots.
	private void DrawGraph(VGContext vg, float x, float y, float w, float h, float t)
	{
		float[6] samples = default;
		for (int i < 6)
		{
			let raw = (1.0f
				+ Sin(t * 1.2345f + (float)i * 0.33457f + (float)i * (float)i * 0.12f)
				+ Sin(t * 0.68363f + (float)i * 1.3f)
				+ Sin(t * 1.1642f + (float)i * (float)i * 0.54f)) * 0.25f;
			// Clamped at zero. The raw value reaches -0.5, and a negative sample puts the
			// curve BELOW the baseline, so the ribbon self intersects and ear clipping
			// emits slivers: the stray lines the original sample drew.
			samples[i] = Max(0.0f, raw);
		}

		let dx = w / 5.0f;

		// The filled area under the curve.
		{
			let builder = scope PathBuilder();
			builder.MoveTo(x, y + h);
			for (int i < 6)
			{
				let sx = x + (float)i * dx;
				let sy = y + h * (1.0f - samples[i] * 0.8f);
				if (i == 0)
				{
					builder.LineTo(sx, sy);
					continue;
				}
				let px = x + (float)(i - 1) * dx;
				let py = y + h * (1.0f - samples[i - 1] * 0.8f);
				builder.CubicTo(px + dx * 0.5f, py, sx - dx * 0.5f, sy, sx, sy);
			}
			builder.LineTo(x + w, y + h);
			builder.Close();

			let fill = scope VGLinearGradientFill(.(x, y), .(x, y + h));
			fill.AddStop(0.0f, GC(0, 160, 192, 128));
			fill.AddStop(1.0f, GC(0, 160, 192, 16));
			FillBuilt(vg, builder, fill);
		}

		// The curve itself, with a dropped shadow copy under it.
		{
			let builder = scope PathBuilder();
			for (int i < 6)
			{
				let sx = x + (float)i * dx;
				let sy = y + h * (1.0f - samples[i] * 0.8f);
				if (i == 0)
				{
					builder.MoveTo(sx, sy);
					continue;
				}
				let px = x + (float)(i - 1) * dx;
				let py = y + h * (1.0f - samples[i - 1] * 0.8f);
				builder.CubicTo(px + dx * 0.5f, py, sx - dx * 0.5f, sy, sx, sy);
			}
			let path = builder.ToPath();
			defer delete path;

			vg.PushState();
			vg.Translate(0, 2);
			vg.StrokePath(path, GC(0, 0, 0, 32), StrokeStyle(3.0f, .Round, .Round));
			vg.PopState();
			vg.StrokePath(path, GC(0, 160, 192), StrokeStyle(3.0f, .Round, .Round));
		}

		for (int i < 6)
		{
			let sx = x + (float)i * dx;
			let sy = y + h * (1.0f - samples[i] * 0.8f);

			let builder = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(sx, sy + 2.0f), 4.0f, builder);
			let shadow = scope VGRadialGradientFill(.(sx, sy + 2.0f), 6.0f);
			shadow.AddStop(0.0f, GC(0, 0, 0, 32));
			shadow.AddStop(1.0f, GC(0, 0, 0, 0));
			FillBuilt(vg, builder, shadow);

			vg.FillCircle(.(sx, sy), 4.0f, GC(0, 160, 192));
			vg.FillCircle(.(sx, sy), 2.0f, GC(220, 240, 255));
		}
	}

	/// Rectangular clipping under a rotation: a clip is in the space it was pushed in, and
	/// popping one restores exactly what was clipped before.
	private void DrawScissor(VGContext vg, float x, float y, float t)
	{
		vg.PushState();
		vg.Translate(x, y);
		vg.Rotate(5.0f * Pi / 180.0f);
		vg.FillRect(.(-20, -20, 60, 40), GC(255, 0, 0));

		vg.PushClipRect(.(-20, -20, 60, 40));
		vg.Translate(40, 0);
		vg.Rotate(Sin(t) * 0.15f);

		vg.PopClip();
		vg.FillRect(.(-20, -10, 60, 30), GC(255, 128, 0, 64));

		vg.PushClipRect(.(-60, -30, 60, 40));
		vg.FillRect(.(-20, -10, 60, 30), GC(255, 128, 0));
		vg.PopClip();

		vg.PopState();
	}

	/// Every image draw: at its own size, stretched, tinted, a sub rectangle, and rotated.
	private void DrawImages(VGContext vg, float x, float y, float t)
	{
		let tw = (float)mChecker.Width;
		let th = (float)mChecker.Height;

		vg.DrawImage(mChecker, Float2(x, y));
		vg.DrawImage(mChecker, Rectangle(x + 140, y, 80, 50));
		vg.DrawImage(mChecker, Rectangle(x + 230, y, 80, 80), Rectangle(0, 0, tw, th),
			GC(255, 120, 120, 220));
		vg.DrawImage(mChecker, Rectangle(x + 320, y, 80, 80), Rectangle(0, 0, 64, 64), Color.White);

		vg.PushState();
		vg.Translate(x + 450, y + 40);
		vg.Rotate(t * 0.6f);
		vg.DrawImage(mChecker, Rectangle(-40, -40, 80, 80));
		vg.PopState();
	}

	private void DrawTextPanel(VGContext vg, float x, float y, float t)
	{
		if (!HasFonts)
			return;

		vg.DrawText("VG text rendering", mFontLarge, Float2(x, y + 30), GC(240, 240, 245));
		vg.DrawText("Medium size - the quick brown fox", mFontMedium, Float2(x, y + 60),
			GC(180, 200, 255));
		vg.DrawText("small caption @ 14px", mFontSmall, Float2(x, y + 82), GC(160, 170, 180));

		let pulse = (uint8)(160.0f + Sin(t * 2.0f) * 60.0f);
		vg.DrawText("pulsing tint", mFontMedium, Float2(x, y + 108), GC(255, pulse, 80));

		let boxRect = Rectangle(x + 350, y + 50, 200, 60);
		vg.StrokeRect(boxRect, GC(80, 100, 120), 1.0f);
		vg.DrawText("centered", mFontMedium, boxRect, .Center, .Middle, GC(220, 220, 220));

		vg.PushState();
		vg.Translate(x + 280, y + 130);
		vg.Rotate(Sin(t * 0.7f) * 0.3f);
		vg.DrawText("rotated!", mFontLarge, Float2(-60, 10), GC(120, 255, 160));
		vg.PopState();
	}

	/// One distance field atlas at three scales. A rasterised atlas blurs when it is scaled;
	/// this one stays sharp, which is the whole reason for the mode.
	private void DrawDistanceFieldText(VGContext vg, float x, float y, float t)
	{
		if (mFontDistanceField == null)
			return;

		if (mFontSmall != null)
		{
			vg.DrawText("Distance Field Text (one atlas, multiple scales):", mFontSmall,
				Float2(x, y + 12), GC(180, 180, 190));
		}

		let metrics = mFontDistanceField.Font.Metrics;
		let ascent = metrics.Ascent;
		let lineHeight = metrics.LineHeight;

		// Native size, which is where the baseline and the descenders have to land.
		vg.DrawText("Typography", mFontDistanceField, Float2(x, y + 20 + ascent), GC(255, 220, 100));

		// Minified.
		vg.PushState();
		vg.Translate(x, y + 20 + ascent + lineHeight + 4.0f);
		vg.Scale(0.6f, 0.6f);
		vg.DrawText("Typography", mFontDistanceField, Float2(0, ascent), GC(200, 255, 200));
		vg.PopState();

		// Magnified, and moving, so the resolution independence is visible rather than
		// asserted.
		vg.PushState();
		vg.Translate(x, y + 20 + ascent + lineHeight * 2.0f + 12.0f);
		let zoom = 1.3f + Sin(t * 0.8f) * 0.5f;
		vg.Scale(zoom, zoom);
		vg.DrawText("Typography", mFontDistanceField, Float2(0, ascent), GC(180, 235, 255));
		vg.PopState();
	}

	/// The primitives a UI actually calls: lines, an ellipse outline, and the two border
	/// rectangles beside the stroked ones they are easy to confuse with.
	private void DrawUIConvenience(VGContext vg, float x, float y)
	{
		vg.DrawLine(.(x, y + 5), .(x + 120, y + 5), GC(200, 220, 255), 1.0f);
		vg.DrawLine(.(x, y + 15), .(x + 120, y + 15), GC(200, 220, 255), 2.5f);
		vg.DrawLine(.(x, y + 30), .(x + 120, y + 30), GC(200, 220, 255), 5.0f);

		vg.StrokeEllipse(.(x + 180, y + 20), 40, 18, GC(255, 200, 140), 2.0f);

		let compare = Rectangle(x + 250, y, 60, 40);
		vg.DrawBorderRect(compare, GC(120, 255, 160), 4.0f);
		vg.StrokeRect(compare, GC(255, 255, 255, 60), 1.0f);

		vg.DrawBorderRoundedRect(.(x + 330, y, 80, 40), 10.0f, GC(180, 160, 255), 3.0f);
		vg.DrawBorderRoundedRect(.(x + 430, y, 80, 40), CornerRadii(2, 12, 2, 12),
			GC(255, 180, 220), 2.0f);
	}

	/// The immediate mode path: begin, emit, fill or stroke, with no path object in sight.
	private void DrawImmediatePath(VGContext vg, float x, float y, float t)
	{
		// An animated signature curve.
		vg.BeginPath();
		vg.MoveTo(x, y + 25);
		vg.CubicTo(x + 30, y + 25 - Sin(t * 1.5f) * 15, x + 60, y + 25 + Sin(t * 1.5f) * 15,
			x + 90, y + 25);
		vg.CubicTo(x + 120, y + 25 - Sin(t * 1.5f + 1) * 15, x + 150,
			y + 25 + Sin(t * 1.5f + 1) * 15, x + 180, y + 25);
		vg.Stroke(GC(120, 200, 255), 3.0f);

		// A filled star.
		let cx = x + 230;
		let cy = y + 25;
		let outer = 22.0f;
		let inner = 10.0f;
		let points = 5;
		vg.BeginPath();
		for (int i < points * 2)
		{
			let r = ((i % 2) == 0) ? outer : inner;
			let angle = (float)i * Pi / (float)points - Pi * 0.5f;
			let px = cx + Cos(angle) * r;
			let py = cy + Sin(angle) * r;
			if (i == 0)
				vg.MoveTo(px, py);
			else
				vg.LineTo(px, py);
		}
		vg.ClosePath();
		vg.Fill(GC(255, 220, 120));

		// A teardrop from two quadratics, filled and then outlined.
		vg.BeginPath();
		vg.MoveTo(x + 290, y + 5);
		vg.QuadTo(x + 320, y + 25, x + 290, y + 45);
		vg.QuadTo(x + 260, y + 25, x + 290, y + 5);
		vg.ClosePath();
		vg.Fill(GC(220, 140, 255));
		vg.Stroke(GC(255, 255, 255, 120), 1.0f);
	}

	/// The SVG panel: one document at three sizes, one of them tinted flat, and an icon
	/// down to twenty pixels.
	private void DrawSVG(VGContext vg, float x, float y)
	{
		if (HasFonts)
			vg.DrawText("SVG Rendering", mFontMedium, Float2(x, y + 16), GC(240, 240, 245));

		if (mBadge != null)
		{
			SVGRenderer.Render(vg, mBadge, .(x, y + 24, 80, 80));
			SVGRenderer.Render(vg, mBadge, .(x + 90, y + 34, 48, 48));
			SVGRenderer.Render(vg, mBadge, .(x + 148, y + 34, 48, 48), GC(255, 120, 80));
		}
		if (mIcon != null)
		{
			SVGRenderer.Render(vg, mIcon, .(x + 210, y + 30, 56, 56));
			SVGRenderer.Render(vg, mIcon, .(x + 272, y + 38, 40, 40));
			SVGRenderer.Render(vg, mIcon, .(x + 318, y + 46, 28, 28));
			SVGRenderer.Render(vg, mIcon, .(x + 352, y + 50, 20, 20));
		}
	}

	/// The block that says whether the fills are RIGHT rather than merely pretty.
	///
	/// A donut whose hole must be a hole; a self intersecting star that must fill its core
	/// under the non zero rule and leave it open under even odd; the three gradient spreads
	/// side by side; a solid block butted against a gradient of the same colour, where a
	/// seam means the two colour paths disagree about what an authored byte means; the
	/// blend modes over a light strip; and a rotating star shaped clip over stripes.
	private void DrawFillCorrectness(VGContext vg, float x, float y, float t)
	{
		vg.PushState();
		vg.Translate(x, y);

		// The donut: two circles in ONE path, the inner one carving the hole.
		{
			let builder = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(30.0f, 30.0f), 28.0f, builder);
			ShapeBuilder.BuildCircle(.(30.0f, 30.0f), 14.0f, builder);
			FillBuilt(vg, builder, GC(255, 160, 60), .EvenOdd);
		}

		// The stars spin, so the multisampling shows on edges that are neither axis aligned
		// nor still.
		let spin = t * 0.3f;
		DrawStar(vg, 105.0f, 30.0f, spin, .NonZero, GC(120, 200, 120));
		DrawStar(vg, 180.0f, 30.0f, spin, .EvenOdd, GC(120, 160, 220));

		DrawGradientSpreads(vg);
		DrawBlendModes(vg);
		DrawStarClip(vg, t);

		vg.PopState();
	}

	/// A five pointed star drawn as every second vertex of a pentagon, which is what makes
	/// it self intersecting and therefore a fill rule test.
	private void DrawStar(VGContext vg, float cx, float cy, float spin, FillRule fillRule,
		Color color)
	{
		vg.PushState();
		vg.Translate(cx, cy);
		vg.Rotate(spin);

		let builder = scope PathBuilder();
		let r = 30.0f;
		for (int i < 5)
		{
			let a = (float)i * (4.0f * Pi / 5.0f) - Pi * 0.5f;
			let px = Cos(a) * r;
			let py = Sin(a) * r;
			if (i == 0)
				builder.MoveTo(px, py);
			else
				builder.LineTo(px, py);
		}
		builder.Close();
		FillBuilt(vg, builder, color, fillRule);

		vg.PopState();
	}

	/// One ramp over a gradient line spanning a THIRD of each square: pad clamps to blue
	/// after the first third, repeat shows three hard seamed bands, and reflect ping pongs.
	private void DrawGradientSpreads(VGContext vg)
	{
		SpreadRect(vg, 0.0f, .Pad);
		SpreadRect(vg, 75.0f, .Repeat);
		SpreadRect(vg, 150.0f, .Reflect);

		{
			let builder = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(245.0f, 95.0f), 24.0f, builder);
			let rings = scope VGRadialGradientFill(.(245.0f, 95.0f), 8.0f);
			rings.AddStop(0.0f, GC(220, 60, 60));
			rings.AddStop(1.0f, GC(60, 90, 220));
			rings.Spread = .Repeat;
			FillBuilt(vg, builder, rings, .NonZero);
		}

		// Colour pipeline consistency: a SOLID fill, which goes down the vertex colour path,
		// butted against a two stop gradient of the SAME colour, which goes through the ramp
		// texture. One seamless block means both paths agree on what an authored byte means;
		// a visible seam is a decode regression.
		{
			let solid = scope PathBuilder();
			HalfRect(280.0f, solid);
			FillBuilt(vg, solid, GC(180, 60, 40), .NonZero);

			let ramped = scope PathBuilder();
			HalfRect(310.0f, ramped);
			let flat = scope VGLinearGradientFill(.(310.0f, 75.0f), .(340.0f, 75.0f));
			flat.AddStop(0.0f, GC(180, 60, 40));
			flat.AddStop(1.0f, GC(180, 60, 40));
			FillBuilt(vg, ramped, flat, .NonZero);
		}
	}

	private void SpreadRect(VGContext vg, float cx, VGGradientSpread spread)
	{
		let gradient = scope VGLinearGradientFill(.(cx, 75.0f), .(cx + 20.0f, 75.0f));
		gradient.AddStop(0.0f, GC(220, 60, 60));
		gradient.AddStop(1.0f, GC(60, 90, 220));
		gradient.Spread = spread;

		let builder = scope PathBuilder();
		builder.MoveTo(cx, 75.0f);
		builder.LineTo(cx + 60.0f, 75.0f);
		builder.LineTo(cx + 60.0f, 115.0f);
		builder.LineTo(cx, 115.0f);
		builder.Close();
		FillBuilt(vg, builder, gradient, .NonZero);
	}

	private static void HalfRect(float cx, PathBuilder builder)
	{
		builder.MoveTo(cx, 75.0f);
		builder.LineTo(cx + 30.0f, 75.0f);
		builder.LineTo(cx + 30.0f, 115.0f);
		builder.LineTo(cx, 115.0f);
		builder.Close();
	}

	/// The blend modes over a LIGHT strip, which has to be bright in linear space or
	/// additive and screen look the same: the difference between them is how much of the
	/// destination survives, and a mid grey decodes to about 0.15 linear.
	private void DrawBlendModes(VGContext vg)
	{
		let strip = scope PathBuilder();
		strip.MoveTo(0.0f, 135.0f);
		strip.LineTo(270.0f, 135.0f);
		strip.LineTo(270.0f, 165.0f);
		strip.LineTo(0.0f, 165.0f);
		strip.Close();
		FillBuilt(vg, strip, GC(220, 220, 225), .NonZero);

		BlendCircle(vg, 40.0f, .Additive, GC(180, 60, 40));
		BlendCircle(vg, 110.0f, .Multiply, GC(220, 160, 90));
		BlendCircle(vg, 180.0f, .Screen, GC(180, 60, 40));
		// A normal one to eyeball the others against.
		BlendCircle(vg, 245.0f, .Normal, GC(180, 60, 40));
	}

	private void BlendCircle(VGContext vg, float cx, VGBlendMode mode, Color color)
	{
		vg.SetBlendMode(mode);

		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(cx, 150.0f), 18.0f, builder);
		FillBuilt(vg, builder, color, .NonZero);

		vg.SetBlendMode(.Normal);
	}

	/// A rotating star shaped CLIP over a grid of stripes: they must appear only inside the
	/// star, with a hard edge, including where a complex fill is drawn while clipped.
	private void DrawStarClip(VGContext vg, float t)
	{
		vg.PushState();
		vg.Translate(320.0f, 30.0f);
		vg.Rotate(t * 0.2f);

		let starBuilder = scope PathBuilder();
		ShapeBuilder.BuildStar(.(0.0f, 0.0f), 30.0f, 12.0f, 5, starBuilder);
		let star = starBuilder.ToPath();
		defer delete star;
		vg.PushClipPath(star);

		for (int i = -3; i <= 3; i++)
		{
			let builder = scope PathBuilder();
			let sy = (float)i * 9.0f - 3.0f;
			builder.MoveTo(-32.0f, sy);
			builder.LineTo(32.0f, sy);
			builder.LineTo(32.0f, sy + 6.0f);
			builder.LineTo(-32.0f, sy + 6.0f);
			builder.Close();
			FillBuilt(vg, builder, ((i % 2) == 0) ? GC(240, 200, 60) : GC(60, 160, 220), .NonZero);
		}

		vg.PopClipPath();
		vg.PopState();
	}

	// ---- colour ----

	public static Color HSLToColor(float h, float s, float l)
	{
		var hue = h - (float)(int)h;
		if (hue < 0.0f)
			hue += 1.0f;

		if (s <= 0.0f)
			return GC((uint8)(l * 255.0f), (uint8)(l * 255.0f), (uint8)(l * 255.0f));

		let q = (l < 0.5f) ? (l * (1.0f + s)) : (l + s - l * s);
		let p = 2.0f * l - q;
		return GC(
			(uint8)(HueToRGB(p, q, hue + 1.0f / 3.0f) * 255.0f),
			(uint8)(HueToRGB(p, q, hue) * 255.0f),
			(uint8)(HueToRGB(p, q, hue - 1.0f / 3.0f) * 255.0f));
	}

	private static float HueToRGB(float p, float q, float t)
	{
		var hue = t;
		if (hue < 0.0f)
			hue += 1.0f;
		if (hue > 1.0f)
			hue -= 1.0f;

		if (hue < 1.0f / 6.0f)
			return p + (q - p) * 6.0f * hue;
		if (hue < 1.0f / 2.0f)
			return q;
		if (hue < 2.0f / 3.0f)
			return p + (q - p) * (2.0f / 3.0f - hue) * 6.0f;
		return p;
	}
}
