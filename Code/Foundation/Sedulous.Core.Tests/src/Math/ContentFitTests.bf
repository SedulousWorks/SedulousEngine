using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// ContentFit has no direct unit tests in Raptor: it is exercised only indirectly,
/// through Input and UI.Viewport. These cover it head on.
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

		Test.Assert(NearlyEqual(dst.x, 0.0f) && NearlyEqual(dst.y, 0.0f));
		Test.Assert(NearlyEqual(dst.width, cRegionW) && NearlyEqual(dst.height, cRegionH));
		Test.Assert(NearlyEqual(src.width, cContentW) && NearlyEqual(src.height, cContentH));

		// The scale differs per axis, which is exactly the distortion Stretch allows.
		let s = f.Scale();
		Test.Assert(NearlyEqual(s.x, cContentW / cRegionW));
		Test.Assert(NearlyEqual(s.y, cContentH / cRegionH));
		Test.Assert(!NearlyEqual(s.x, s.y));
	}

	/// 4:3 content in a 16:9 region fits by height, leaving pillarbox bars either side.
	[Test]
	public static void LetterboxPreservesAspectAndCentres()
	{
		let f = Fit(.Letterbox);
		let dst = f.DstRect();

		// Height is the limiting axis: 900/600 = 1.5, against 1600/800 = 2.0.
		let expectedW = cContentW * 1.5f;   // 1200
		Test.Assert(NearlyEqual(dst.height, cRegionH));
		Test.Assert(NearlyEqual(dst.width, expectedW));

		// Centred, so the bars are equal.
		Test.Assert(NearlyEqual(dst.x, (cRegionW - expectedW) * 0.5f));   // 200
		Test.Assert(NearlyEqual(dst.y, 0.0f));

		// Aspect is preserved.
		Test.Assert(NearlyEqual(dst.width / dst.height, cContentW / cContentH, 1.0e-4f));

		// The whole content is sampled: the bars are empty region, not cropped content.
		let src = f.SrcRect();
		Test.Assert(NearlyEqual(src.width, cContentW) && NearlyEqual(src.height, cContentH));

		// Both axes scale equally.
		let s = f.Scale();
		Test.Assert(NearlyEqual(s.x, s.y, 1.0e-4f));
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
		Test.Assert(NearlyEqual(dst.width, cRegionW) && NearlyEqual(dst.height, cRegionH));
		Test.Assert(NearlyEqual(dst.x, 0.0f) && NearlyEqual(dst.y, 0.0f));

		// Width is the limiting axis now, so the source loses height.
		Test.Assert(NearlyEqual(src.width, cContentW));
		Test.Assert(src.height < cContentH);
		Test.Assert(NearlyEqual(src.height, cRegionH / 2.0f));   // s = 1600/800 = 2

		// The slice is centred, so equal amounts are lost top and bottom.
		Test.Assert(NearlyEqual(src.x, 0.0f));
		Test.Assert(NearlyEqual(src.y, (cContentH - src.height) * 0.5f));

		let s = f.Scale();
		Test.Assert(NearlyEqual(s.x, s.y, 1.0e-4f));
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
		Test.Assert(NearlyEqual(dst.width, 640.0f));
		Test.Assert(NearlyEqual(dst.height, 400.0f));
		Test.Assert(NearlyEqual(dst.x, (1000.0f - 640.0f) * 0.5f));
		Test.Assert(NearlyEqual(dst.y, (500.0f - 400.0f) * 0.5f));

		// Letterbox on the same inputs would use the unfloored 2.5.
		var letter = f;
		letter.mode = .Letterbox;
		Test.Assert(NearlyEqual(letter.DstRect().width, 800.0f));
	}

	/// A region smaller than the content would floor to zero, which would draw nothing.
	/// The scale clamps to 1 instead, overflowing the region rather than vanishing.
	[Test]
	public static void IntegerScaleNeverFloorsBelowOne()
	{
		let f = ContentFit(Rectangle(0.0f, 0.0f, 100.0f, 100.0f), Float2(320.0f, 200.0f),
			.IntegerScale);
		let dst = f.DstRect();
		Test.Assert(NearlyEqual(dst.width, 320.0f));
		Test.Assert(NearlyEqual(dst.height, 200.0f));
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
				Float2(dst.x + 1.0f, dst.y + 1.0f),
				Float2(dst.x + dst.width * 0.5f, dst.y + dst.height * 0.5f),
				Float2(dst.x + dst.width - 1.0f, dst.y + dst.height - 1.0f));

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
		Test.Assert(!f.ToContent(Float2(dst.x - 10.0f, cRegionH * 0.5f), out content));
		// Inside the right bar.
		Test.Assert(!f.ToContent(Float2(dst.x + dst.width + 10.0f, cRegionH * 0.5f), out content));
		// Outside the region entirely.
		Test.Assert(!f.ToContent(Float2(-100.0f, -100.0f), out content));
		Test.Assert(!f.ToContent(Float2(cRegionW + 100.0f, cRegionH + 100.0f), out content));

		// And a point on the content itself is accepted.
		Test.Assert(f.ToContent(Float2(dst.x + 1.0f, cRegionH * 0.5f), out content));
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
		Test.Assert(NearlyEqual(content.x, 0.0f));
		Test.Assert(content.y > 0.0f);
		Test.Assert(NearlyEqual(content.y, f.SrcRect().y, 1.0e-3f));

		// A point outside the region is still rejected.
		Test.Assert(!f.ToContent(Float2(-1.0f, 0.0f), out content));
	}

	/// The standard fixture is a wide region, so Crop only ever slices vertically and
	/// src.x stays zero. A tall region slices the other axis, which is the only way to
	/// exercise the horizontal offset in the source rect and in FromContent.
	[Test]
	public static void CropSlicesHorizontallyForATallRegion()
	{
		// A 2:3 region holding 4:3 content: height is the limiting axis now.
		let f = ContentFit(Rectangle(0.0f, 0.0f, 600.0f, 900.0f), Float2(800.0f, 600.0f), .Crop);
		let src = f.SrcRect();

		// s = max(600/800, 900/600) = 1.5, so the visible width is 600/1.5 = 400.
		Test.Assert(NearlyEqual(src.width, 400.0f));
		Test.Assert(NearlyEqual(src.height, 600.0f));

		// The slice is centred horizontally: 200 lost from each side.
		Test.Assert(NearlyEqual(src.x, 200.0f));
		Test.Assert(NearlyEqual(src.y, 0.0f));

		// The left edge of the region maps to the left edge of the slice, not to zero.
		Float2 content = ?;
		Test.Assert(f.ToContent(Float2(0.0f, 450.0f), out content));
		Test.Assert(NearlyEqual(content.x, 200.0f, 1.0e-3f));

		// And FromContent inverts that, which it cannot do if it ignores src.x.
		let back = f.FromContent(content);
		Test.Assert(NearlyEqual(back.x, 0.0f, 1.0e-2f));
		Test.Assert(NearlyEqual(f.FromContent(Float2(600.0f, 300.0f)).x, 600.0f, 1.0e-2f));
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
		Test.Assert(NearlyEqual(noContent.DstRect().width, 100.0f));
		Test.Assert(NearlyEqual(noContent.SrcRect().width, 0.0f));

		// Scale has no meaningful value, and must not be a NaN or an infinity.
		let s = noContent.Scale();
		Test.Assert(s.x == 0.0f);

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

		Test.Assert(NearlyEqual(dst.y, 30.0f));
		Test.Assert(NearlyEqual(dst.x, 50.0f + (cRegionW - dst.width) * 0.5f));

		// And the mapping follows the offset.
		Float2 content = ?;
		Test.Assert(f.ToContent(Float2(50.0f + cRegionW * 0.5f, 30.0f + cRegionH * 0.5f),
			out content));
		Test.Assert(NearlyEqual(content, Float2(cContentW * 0.5f, cContentH * 0.5f), 1.0e-2f));
	}
}
