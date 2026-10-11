using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// ContentFit head on, rather than only indirectly through Input and UI.Viewport.
///
/// The fixture throughout is a 16:9 region holding 4:3 content, so the aspect-preserving
/// modes have something real to do. A square-in-square fixture would let Letterbox and
/// Stretch agree and hide most of the behaviour.
class ContentFitTests
{
	private const float cRegionW = 1600.0f;
	private const float cRegionH = 900.0f;    // 16:9
	private const float cContentW = 800.0f;
	private const float cContentH = 600.0f;   // 4:3

	private static ContentFit Fit(FitMode mode) =>
		.(Rectangle(0.0f, 0.0f, cRegionW, cRegionH), Float2(cContentW, cContentH), mode);

	[Test]
	public static void StretchFillsTheRegionAndSamplesEverything()
	{
		let f = Fit(.Stretch);
		let dst = f.DstRect();
		let src = f.SrcRect();

		Test.Assert(NearlyEqual(dst.X, 0.0f) && NearlyEqual(dst.Y, 0.0f));
		Test.Assert(NearlyEqual(dst.Width, cRegionW) && NearlyEqual(dst.Height, cRegionH));
		Test.Assert(NearlyEqual(src.Width, cContentW) && NearlyEqual(src.Height, cContentH));

		// The scale differs per axis, which is exactly the distortion Stretch allows.
		let s = f.Scale();
		Test.Assert(NearlyEqual(s.X, cContentW / cRegionW));
		Test.Assert(NearlyEqual(s.Y, cContentH / cRegionH));
		Test.Assert(!NearlyEqual(s.X, s.Y));
	}

	/// 4:3 content in a 16:9 region fits by height, leaving pillarbox bars either side.
	[Test]
	public static void LetterboxPreservesAspectAndCentres()
	{
		let f = Fit(.Letterbox);
		let dst = f.DstRect();

		// Height is the limiting axis: 900/600 = 1.5, against 1600/800 = 2.0.
		let expectedW = cContentW * 1.5f;   // 1200
		Test.Assert(NearlyEqual(dst.Height, cRegionH));
		Test.Assert(NearlyEqual(dst.Width, expectedW));

		// Centred, so the bars are equal.
		Test.Assert(NearlyEqual(dst.X, (cRegionW - expectedW) * 0.5f));   // 200
		Test.Assert(NearlyEqual(dst.Y, 0.0f));

		// Aspect is preserved.
		Test.Assert(NearlyEqual(dst.Width / dst.Height, cContentW / cContentH, 1.0e-4f));

		// The whole content is sampled: the bars are empty region, not cropped content.
		let src = f.SrcRect();
		Test.Assert(NearlyEqual(src.Width, cContentW) && NearlyEqual(src.Height, cContentH));

		// Both axes scale equally.
		let s = f.Scale();
		Test.Assert(NearlyEqual(s.X, s.Y, 1.0e-4f));
	}

	/// Crop fills the region and slices the source instead, which is the mirror image of
	/// Letterbox and the pair most easily swapped.
	[Test]
	public static void CropFillsTheRegionAndSlicesTheSource()
	{
		let f = Fit(.Crop);
		let dst = f.DstRect();
		let src = f.SrcRect();

		// The destination is the whole region: no bars.
		Test.Assert(NearlyEqual(dst.Width, cRegionW) && NearlyEqual(dst.Height, cRegionH));
		Test.Assert(NearlyEqual(dst.X, 0.0f) && NearlyEqual(dst.Y, 0.0f));

		// Width is the limiting axis now, so the source loses height.
		Test.Assert(NearlyEqual(src.Width, cContentW));
		Test.Assert(src.Height < cContentH);
		Test.Assert(NearlyEqual(src.Height, cRegionH / 2.0f));   // s = 1600/800 = 2

		// The slice is centred, so equal amounts are lost top and bottom.
		Test.Assert(NearlyEqual(src.X, 0.0f));
		Test.Assert(NearlyEqual(src.Y, (cContentH - src.Height) * 0.5f));

		let s = f.Scale();
		Test.Assert(NearlyEqual(s.X, s.Y, 1.0e-4f));
	}

	/// IntegerScale floors the letterbox scale, which is the whole reason it exists.
	[Test]
	public static void IntegerScaleFloorsTheScale()
	{
		// A region 2.5x the content in the limiting axis must scale by 2, not 2.5.
		let f = ContentFit(Rectangle(0.0f, 0.0f, 1000.0f, 500.0f), Float2(320.0f, 200.0f),
			.IntegerScale);
		let dst = f.DstRect();

		// 1000/320 = 3.125, 500/200 = 2.5; the smaller is 2.5, floored to 2.
		Test.Assert(NearlyEqual(dst.Width, 640.0f));
		Test.Assert(NearlyEqual(dst.Height, 400.0f));
		Test.Assert(NearlyEqual(dst.X, (1000.0f - 640.0f) * 0.5f));
		Test.Assert(NearlyEqual(dst.Y, (500.0f - 400.0f) * 0.5f));

		// Letterbox on the same inputs would use the unfloored 2.5.
		var letter = f;
		letter.Mode = .Letterbox;
		Test.Assert(NearlyEqual(letter.DstRect().Width, 800.0f));
	}

	/// A region smaller than the content would floor to zero, which would draw nothing.
	/// The scale clamps to 1 instead, overflowing the region rather than vanishing.
	[Test]
	public static void IntegerScaleNeverFloorsBelowOne()
	{
		let f = ContentFit(Rectangle(0.0f, 0.0f, 100.0f, 100.0f), Float2(320.0f, 200.0f),
			.IntegerScale);
		let dst = f.DstRect();
		Test.Assert(NearlyEqual(dst.Width, 320.0f));
		Test.Assert(NearlyEqual(dst.Height, 200.0f));
	}

	/// The round trip is the contract input relies on: a point mapped into content space
	/// and back must land where it started.
	[Test]
	public static void ToContentAndFromContentRoundTrip()
	{
		FitMode[?] modes = .(.Stretch, .Letterbox, .Crop, .IntegerScale);
		for (let mode in modes)
		{
			let f = Fit(mode);
			let dst = f.DstRect();

			// Sample points inside the drawn area, including its corners.
			Float2[?] points = .(
				Float2(dst.X + 1.0f, dst.Y + 1.0f),
				Float2(dst.X + dst.Width * 0.5f, dst.Y + dst.Height * 0.5f),
				Float2(dst.X + dst.Width - 1.0f, dst.Y + dst.Height - 1.0f));

			for (let pt in points)
			{
				Float2 content = ?;
				Test.Assert(f.ToContent(pt, out content));
				let back = f.FromContent(content);
				Test.Assert(NearlyEqual(back, pt, 1.0e-2f));
			}
		}
	}

	/// The no-hit contract: a point on a letterbox bar is outside the content, and input
	/// must be told so rather than given a clamped or extrapolated coordinate.
	[Test]
	public static void ToContentRejectsPointsOnTheBars()
	{
		let f = Fit(.Letterbox);
		let dst = f.DstRect();
		Float2 content = ?;

		// Inside the left bar.
		Test.Assert(!f.ToContent(Float2(dst.X - 10.0f, cRegionH * 0.5f), out content));
		// Inside the right bar.
		Test.Assert(!f.ToContent(Float2(dst.X + dst.Width + 10.0f, cRegionH * 0.5f), out content));
		// Outside the region entirely.
		Test.Assert(!f.ToContent(Float2(-100.0f, -100.0f), out content));
		Test.Assert(!f.ToContent(Float2(cRegionW + 100.0f, cRegionH + 100.0f), out content));

		// And a point on the content itself is accepted.
		Test.Assert(f.ToContent(Float2(dst.X + 1.0f, cRegionH * 0.5f), out content));
	}

	/// Under Crop the destination is the whole region, so nothing inside the region is
	/// rejected. The centred slice means the content coordinate is offset, not zero.
	[Test]
	public static void CropAcceptsTheWholeRegionAndOffsetsTheContent()
	{
		let f = Fit(.Crop);
		Float2 content = ?;

		Test.Assert(f.ToContent(Float2(0.0f, 0.0f), out content));
		// The top-left of the region maps to the top-left of the SLICE, which is inset.
		Test.Assert(NearlyEqual(content.X, 0.0f));
		Test.Assert(content.Y > 0.0f);
		Test.Assert(NearlyEqual(content.Y, f.SrcRect().Y, 1.0e-3f));

		// A point outside the region is still rejected.
		Test.Assert(!f.ToContent(Float2(-1.0f, 0.0f), out content));
	}

	/// The standard fixture is a wide region, so Crop only ever slices vertically and
	/// src.X stays zero. A tall region slices the other axis, which is the only way to
	/// exercise the horizontal offset in the source rect and in FromContent.
	[Test]
	public static void CropSlicesHorizontallyForATallRegion()
	{
		// A 2:3 region holding 4:3 content: height is the limiting axis now.
		let f = ContentFit(Rectangle(0.0f, 0.0f, 600.0f, 900.0f), Float2(800.0f, 600.0f), .Crop);
		let src = f.SrcRect();

		// s = max(600/800, 900/600) = 1.5, so the visible width is 600/1.5 = 400.
		Test.Assert(NearlyEqual(src.Width, 400.0f));
		Test.Assert(NearlyEqual(src.Height, 600.0f));

		// The slice is centred horizontally: 200 lost from each side.
		Test.Assert(NearlyEqual(src.X, 200.0f));
		Test.Assert(NearlyEqual(src.Y, 0.0f));

		// The left edge of the region maps to the left edge of the slice, not to zero.
		Float2 content = ?;
		Test.Assert(f.ToContent(Float2(0.0f, 450.0f), out content));
		Test.Assert(NearlyEqual(content.X, 200.0f, 1.0e-3f));

		// And FromContent inverts that, which it cannot do if it ignores src.X.
		let back = f.FromContent(content);
		Test.Assert(NearlyEqual(back.X, 0.0f, 1.0e-2f));
		Test.Assert(NearlyEqual(f.FromContent(Float2(600.0f, 300.0f)).X, 600.0f, 1.0e-2f));
	}

	/// The centre of the region maps to the centre of the content in every mode. This is
	/// the invariant a mis-centred slice or destination breaks first.
	[Test]
	public static void RegionCentreMapsToContentCentre()
	{
		FitMode[?] modes = .(.Stretch, .Letterbox, .Crop, .IntegerScale);
		for (let mode in modes)
		{
			let f = Fit(mode);
			Float2 content = ?;
			Test.Assert(f.ToContent(Float2(cRegionW * 0.5f, cRegionH * 0.5f), out content));
			Test.Assert(NearlyEqual(content, Float2(cContentW * 0.5f, cContentH * 0.5f), 1.0e-2f));
		}
	}

	/// Degenerate inputs return the region unchanged rather than dividing by zero.
	[Test]
	public static void DegenerateSizesAreHandled()
	{
		let noContent = ContentFit(Rectangle(0.0f, 0.0f, 100.0f, 100.0f), Float2(0.0f, 0.0f),
			.Letterbox);
		Test.Assert(NearlyEqual(noContent.DstRect().Width, 100.0f));
		Test.Assert(NearlyEqual(noContent.SrcRect().Width, 0.0f));

		// Scale has no meaningful value, and must not be a NaN or an infinity.
		let s = noContent.Scale();
		Test.Assert(s.X == 0.0f);

		let noRegion = ContentFit(Rectangle(0.0f, 0.0f, 0.0f, 0.0f), Float2(320.0f, 200.0f),
			.Letterbox);
		Float2 content = ?;
		Test.Assert(!noRegion.ToContent(Float2(0.0f, 0.0f), out content));
	}

	/// The region is not assumed to start at the origin: an offset region has to shift
	/// the destination with it.
	[Test]
	public static void RegionOffsetIsRespected()
	{
		let f = ContentFit(Rectangle(50.0f, 30.0f, cRegionW, cRegionH),
			Float2(cContentW, cContentH), .Letterbox);
		let dst = f.DstRect();

		Test.Assert(NearlyEqual(dst.Y, 30.0f));
		Test.Assert(NearlyEqual(dst.X, 50.0f + (cRegionW - dst.Width) * 0.5f));

		// And the mapping follows the offset.
		Float2 content = ?;
		Test.Assert(f.ToContent(Float2(50.0f + cRegionW * 0.5f, 30.0f + cRegionH * 0.5f),
			out content));
		Test.Assert(NearlyEqual(content, Float2(cContentW * 0.5f, cContentH * 0.5f), 1.0e-2f));
	}

	// ---- Turned (the content presented in quarter turns: a landscape game on a portrait screen) ----

	/// Near, relative to the size of what is compared (as doctest's Approx), for the screen-sized
	/// values of the turned cases.
	private static bool Near(float a, float b, float relative = 1.0e-5f) =>
		Math.Abs(a - b) <= relative * Math.Max(1.0f, Math.Max(Math.Abs(a), Math.Abs(b)));

	private static bool RectIs(Rectangle r, float x, float y, float w, float h) =>
		Near(r.X, x) && Near(r.Y, y) && Near(r.Width, w) && Near(r.Height, h);

	private static bool PointIs(Float2 p, float x, float y) => Near(p.X, x) && Near(p.Y, y);

	[Test]
	public static void UnturnedFitsAsItAlwaysDidAndTakesDeltas()
	{
		// 320x180 letterboxed into a 1280x1080 region at (100, 50): scale 4, bars of 180 above
		// and below.
		let fit = ContentFit(.(100, 50, 1280, 1080), .(320, 180), .Letterbox);
		Test.Assert(RectIs(fit.DstRect(), 100, 50 + 180, 1280, 720));
		Test.Assert(RectIs(fit.SrcRect(), 0, 0, 320, 180));
		Test.Assert(fit.ToContent(.(100 + 640, 50 + 540), let c));
		Test.Assert(PointIs(c, 160, 90));
		Test.Assert(!fit.ToContent(.(100 + 640, 50 + 90), ?), "in a bar");
		Test.Assert(PointIs(fit.FromContent(.(0, 0)), 100, 50 + 180));
		Test.Assert(PointIs(fit.Scale(), 0.25f, 0.25f));
		Test.Assert(PointIs(fit.ToContentDelta(.(8, -4)), 2, -1));

		// Crop: the whole region shows a centred slice of the content.
		let crop = ContentFit(.(0, 0, 100, 100), .(200, 100), .Crop);
		Test.Assert(RectIs(crop.DstRect(), 0, 0, 100, 100));
		Test.Assert(RectIs(crop.SrcRect(), 50, 0, 100, 100));
	}

	[Test]
	public static void ALandscapeGameTurnedAQuarterFillsAPortraitScreen()
	{
		// 1920x1080 content on a 1080x1920 portrait region: the turned-back region is 1920x1080,
		// so it fits exactly whichever way it is turned a quarter.
		for (let rotation in ContentRotation[2](.Quarter, .ThreeQuarter))
		{
			let fit = ContentFit(.(0, 0, 1080, 1920), .(1920, 1080), .Letterbox, rotation);
			Test.Assert(RectIs(fit.DstRect(), 0, 0, 1080, 1920));
			Test.Assert(RectIs(fit.SrcRect(), 0, 0, 1920, 1080));
			Test.Assert(PointIs(fit.Scale(), 1, 1));
		}

		// Three quarters (the phone held upright, the game's top on the screen's left): the
		// content's top-left corner is the screen's bottom-left, its top-right the screen's
		// top-left.
		let fit = ContentFit(.(0, 0, 1080, 1920), .(1920, 1080), .Letterbox, .ThreeQuarter);
		Test.Assert(PointIs(fit.FromContent(.(0, 0)), 0, 1920));
		Test.Assert(PointIs(fit.FromContent(.(1920, 0)), 0, 0));
		Test.Assert(PointIs(fit.FromContent(.(1920, 1080)), 1080, 0));
		Test.Assert(fit.ToContent(.(1, 1919), let c), "near the screen's bottom-left: the content's top-left");
		Test.Assert(PointIs(c, 1, 1));
		// Moving a finger up the screen moves right across the content; right across the
		// screen, down.
		Test.Assert(PointIs(fit.ToContentDelta(.(0, -10)), 10, 0));
		Test.Assert(PointIs(fit.ToContentDelta(.(10, 0)), 0, 10));

		// A quarter: the content's top-left is the screen's top-right.
		let quarter = ContentFit(.(0, 0, 1080, 1920), .(1920, 1080), .Letterbox, .Quarter);
		Test.Assert(PointIs(quarter.FromContent(.(0, 0)), 1080, 0));
		Test.Assert(PointIs(quarter.ToContentDelta(.(0, 10)), 10, 0));
	}

	[Test]
	public static void PointsRoundTripThroughEveryTurnAndMode()
	{
		// An offset region of another shape than the content: bars, crops and a floored scale in
		// every turn. A point of the content maps to the region and back to itself, inside the
		// drawn rectangle, which sits inside the region.
		let region = Rectangle(30, 20, 700, 1300);
		for (let rotation in ContentRotation[4](.None, .Quarter, .Half, .ThreeQuarter))
		{
			for (let mode in FitMode[4](.Stretch, .Letterbox, .Crop, .IntegerScale))
			{
				let fit = ContentFit(region, .(640, 360), mode, rotation);
				let src = fit.SrcRect();
				let dst = fit.DstRect();
				let inside = Float2[3](
					.(src.X + src.Width * 0.5f, src.Y + src.Height * 0.5f),
					.(src.X + src.Width * 0.2f, src.Y + src.Height * 0.7f),
					.(src.X + src.Width * 0.9f, src.Y + src.Height * 0.1f));
				for (let point in inside)
				{
					let there = fit.FromContent(point);
					Test.Assert(fit.ToContent(there, let back), scope $"{rotation} {mode}: maps back");
					Test.Assert(Near(back.X, point.X, 0.001f) && Near(back.Y, point.Y, 0.001f), scope $"{rotation} {mode}: round trip");
					Test.Assert(dst.Contains(there), scope $"{rotation} {mode}: inside the drawn rectangle");
					// The unclamped map agrees wherever the clamped one maps.
					let free = fit.ToContentUnclamped(there);
					Test.Assert(Near(free.X, back.X) && Near(free.Y, back.Y), scope $"{rotation} {mode}: unclamped agrees");
				}
				Test.Assert((dst.X >= region.X - 0.01f) && (dst.Y >= region.Y - 0.01f)
					&& (dst.X + dst.Width <= region.X + region.Width + 0.01f)
					&& (dst.Y + dst.Height <= region.Y + region.Height + 0.01f), scope $"{rotation} {mode}: inside the region");
			}
		}
	}

	[Test]
	public static void AHalfTurnAndTheBarsOfATurnedLetterbox()
	{
		// A half turn: the content's top-left is the region's bottom-right.
		let half = ContentFit(.(0, 0, 200, 100), .(200, 100), .Stretch, .Half);
		Test.Assert(PointIs(half.FromContent(.(0, 0)), 200, 100));
		Test.Assert(PointIs(half.ToContentDelta(.(3, 4)), -3, -4));

		// 300x180 in a 1080x1920 portrait region turned a quarter: the turned-back region is
		// 1920x1080, the content letterboxed in it at scale 6, so there are bars along what is
		// the screen's top and bottom (the turned-back region's sides).
		let bars = ContentFit(.(0, 0, 1080, 1920), .(300, 180), .Letterbox, .Quarter);
		let dst = bars.DstRect();
		Test.Assert(Near(dst.Width, 1080));
		Test.Assert(Near(dst.Height, 1800)); // 300 x 6
		Test.Assert(Near(dst.Y, 60));        // bars of 60 above and below
		Test.Assert(!bars.ToContent(.(540, 30), ?), "in a bar");
		// Unclamped, the bar maps past the content's edge: turned a quarter, the screen's top is
		// the content's left.
		let free = bars.ToContentUnclamped(.(540, 30));
		Test.Assert(free.X < 0.0f);
		Test.Assert(Near(free.Y, 90.0f));
	}

	[Test]
	public static void AnOrientationTurnsOnlyAWindowOfTheOtherShape()
	{
		// Only a mismatched shape turns, and always three quarters (the game's top on the
		// screen's left); a square window or Any never turns.
		Test.Assert(ContentFit.TurnFor(.Landscape, 1080, 1920) == .ThreeQuarter);
		Test.Assert(ContentFit.TurnFor(.Landscape, 1920, 1080) == .None);
		Test.Assert(ContentFit.TurnFor(.Portrait, 1920, 1080) == .ThreeQuarter);
		Test.Assert(ContentFit.TurnFor(.Portrait, 1080, 1920) == .None);
		Test.Assert(ContentFit.TurnFor(.Landscape, 800, 800) == .None);
		Test.Assert(ContentFit.TurnFor(.Any, 1080, 1920) == .None);
		Test.Assert(ContentFit.TurnFor(.Any, 1920, 1080) == .None);
	}
}
