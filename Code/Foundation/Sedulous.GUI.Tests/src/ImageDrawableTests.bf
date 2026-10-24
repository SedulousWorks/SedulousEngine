using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The image drawable (image content: an Image widget's picture, an icon); a node's look is its
/// box. Its tint state, its intrinsic size and the geometry it draws (GPU-free: a VGContext
/// tessellates into a CPU vertex batch).
class ImageDrawableTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A tiny 2x2 RGBA image (owns its pixels). The caller owns what comes back.
	private static OwnedImageData MakeImage()
	{
		uint8[16] pixels = .(255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255);
		return new OwnedImageData(2, 2, .RGBA8, Span<uint8>(&pixels[0], 16));
	}

	[Test]
	public static void ItsTintColourAndAlpha()
	{
		let d = new ImageDrawable();
		defer d.ReleaseRef();
		Test.Assert(Near(d.Color.R, 1.0f)); // white: drawn as it is
		d.Color = Color.Blue;
		Test.Assert(Near(d.Color.B, 1.0f));
		d.Alpha = 0.5f;
		Test.Assert(Near(d.Alpha, 0.5f));
		Test.Assert(Near(d.Color.A, 0.5f));
	}

	[Test]
	public static void NoImageHasNoIntrinsicSizeAndDrawsNothing()
	{
		let d = new ImageDrawable();
		defer d.ReleaseRef();
		Test.Assert(!d.IntrinsicSize.HasValue);
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		d.Draw(dc, Rect(0.0f, 0.0f, 10.0f, 10.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}

	[Test]
	public static void AnImagesIntrinsicSizeAndTheGeometryItDraws()
	{
		let img = MakeImage();
		defer delete img;
		let d = new ImageDrawable(img);
		defer d.ReleaseRef();
		Test.Assert(d.IntrinsicSize.HasValue);
		Test.Assert(Near(d.IntrinsicSize.Value.X, 2.0f));
		Test.Assert(Near(d.IntrinsicSize.Value.Y, 2.0f));
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		d.Draw(dc, Rect(0.0f, 0.0f, 32.0f, 32.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count > 0);
	}
}
