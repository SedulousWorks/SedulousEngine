using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The leaf controls: the ones that measure and draw themselves and hold no children.
class LeafControlTests
{
	/// Counts its draws and reports whatever intrinsic size it was built with.
	private class ProbeDrawable : Drawable
	{
		public int Draws = 0;
		private Float2? mIntrinsic;

		public this(Float2? intrinsic = null)
		{
			mIntrinsic = intrinsic;
		}

		public override Float2? IntrinsicSize => mIntrinsic;

		public override void Draw(UIDrawContext ctx, Rectangle bounds)
		{
			Draws++;
		}
	}

	// ---- Spacer -------------------------------------------------------------------------------

	[Test]
	public static void ASpacerMeasuresToTheSizeItWasAskedFor()
	{
		let spacer = new Spacer(20, 10);
		defer spacer.ReleaseRef();

		spacer.Measure(BoxConstraints.Expand());

		Test.Assert(spacer.MeasuredSize.X == 20);
		Test.Assert(spacer.MeasuredSize.Y == 10);
	}

	// ---- ColorView ----------------------------------------------------------------------------

	[Test]
	public static void AColorViewKeepsTheColorItWasBuiltWith()
	{
		let view = new ColorView(Color(1.0f, 0.0f, 0.0f, 1.0f));
		defer view.ReleaseRef();

		Test.Assert(view.Color.Value.R == 1.0f);
		Test.Assert(view.Color.Value.G == 0.0f);
	}

	// ---- Separator ----------------------------------------------------------------------------

	/// Horizontal: thickness across, the parent's width along.
	[Test]
	public static void AHorizontalSeparatorIsThinAndFillsTheWidth()
	{
		let separator = new Separator(.Horizontal);
		defer separator.ReleaseRef();

		separator.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(separator.MeasuredSize.Y == 1);
		Test.Assert(separator.MeasuredSize.X == 400);
	}

	[Test]
	public static void AVerticalSeparatorIsThinAndFillsTheHeight()
	{
		let separator = new Separator(.Vertical);
		defer separator.ReleaseRef();

		separator.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(separator.MeasuredSize.X == 1);
		Test.Assert(separator.MeasuredSize.Y == 300);
	}

	/// Under an UNBOUNDED parent the long axis falls back to a sane default instead of taking
	/// the raw max, which is FloatMax and would measure the separator as effectively infinite.
	[Test]
	public static void AnUnboundedSeparatorFallsBackToADefaultLength()
	{
		let horizontal = new Separator(.Horizontal);
		defer horizontal.ReleaseRef();
		let vertical = new Separator(.Vertical);
		defer vertical.ReleaseRef();

		horizontal.Measure(BoxConstraints.Expand());
		vertical.Measure(BoxConstraints.Expand());

		Test.Assert(horizontal.MeasuredSize.X == 100);
		Test.Assert(horizontal.MeasuredSize.Y == 1);
		Test.Assert(vertical.MeasuredSize.X == 1);
		Test.Assert(vertical.MeasuredSize.Y == 100);
	}

	// ---- ProgressBar --------------------------------------------------------------------------

	/// Out of range values are clamped, and the clamp lands on the property rather than only on
	/// the drawing: a caller reading Value back gets the value the bar will actually paint.
	[Test]
	public static void AProgressBarClampsItsValueToZeroThroughOne()
	{
		let bar = new ProgressBar();
		defer bar.ReleaseRef();

		bar.Value.Value = 0.5f;
		Test.Assert(bar.Value.Value == 0.5f);

		bar.Value.Value = -1.0f;
		Test.Assert(bar.Value.Value == 0.0f);

		bar.Value.Value = 2.0f;
		Test.Assert(bar.Value.Value == 1.0f);
	}

	/// Bounded, it fills the width; unbounded, it falls back rather than taking FloatMax.
	[Test]
	public static void AProgressBarFillsABoundedWidthAndFallsBackOtherwise()
	{
		let bar = new ProgressBar();
		defer bar.ReleaseRef();

		bar.Measure(BoxConstraints.Loose(320, 300));
		Test.Assert(bar.MeasuredSize.X == 320);
		Test.Assert(bar.MeasuredSize.Y == 16);

		bar.Measure(BoxConstraints.Expand());
		Test.Assert(bar.MeasuredSize.X == 200);
	}

	// ---- ImageView ----------------------------------------------------------------------------

	[Test]
	public static void AnImageViewWithNoImageMeasuresToZero()
	{
		let view = new ImageView();
		defer view.ReleaseRef();

		view.Measure(BoxConstraints.Expand());

		Test.Assert(view.MeasuredSize.X == 0);
		Test.Assert(view.MeasuredSize.Y == 0);
	}

	/// With an image it measures to the image's pixel size, clamped by the constraints.
	[Test]
	public static void AnImageViewMeasuresToItsImageAndIsClampedByTheConstraints()
	{
		uint8[8 * 4 * 4] pixels = .();
		let image = scope OwnedImageData(8, 4, .RGBA8, Span<uint8>(&pixels[0], pixels.Count));
		let view = new ImageView(image);
		defer view.ReleaseRef();

		view.Measure(BoxConstraints.Expand());
		Test.Assert(view.MeasuredSize.X == 8);
		Test.Assert(view.MeasuredSize.Y == 4);

		view.Measure(BoxConstraints.Loose(5, 300));
		Test.Assert(view.MeasuredSize.X == 5, "clamped by the constraint");
		Test.Assert(view.MeasuredSize.Y == 4);
	}

	// ---- DrawableView -------------------------------------------------------------------------

	/// The requested size wins over the drawable's intrinsic one, which wins over zero.
	[Test]
	public static void ADrawableViewPrefersItsRequestedSizeThenTheIntrinsicOne()
	{
		let bare = new DrawableView();
		defer bare.ReleaseRef();
		bare.Measure(BoxConstraints.Expand());
		Test.Assert(bare.MeasuredSize.X == 0 && bare.MeasuredSize.Y == 0);

		let intrinsic = new DrawableView(new ProbeDrawable(Float2(24, 12)));
		defer intrinsic.ReleaseRef();
		intrinsic.Measure(BoxConstraints.Expand());
		Test.Assert(intrinsic.MeasuredSize.X == 24);
		Test.Assert(intrinsic.MeasuredSize.Y == 12);

		let requested = new DrawableView(new ProbeDrawable(Float2(24, 12)), 40, 40);
		defer requested.ReleaseRef();
		requested.Measure(BoxConstraints.Expand());
		Test.Assert(requested.MeasuredSize.X == 40);
		Test.Assert(requested.MeasuredSize.Y == 40);
	}

	/// A drawable view OWNS its drawable, so replacing one releases the one held before.
	///
	/// Raptor gets this from RefPtr; we hold the reference by hand, and this is exactly where
	/// the two ownership bugs already found in this port lived.
	[Test]
	public static void ReplacingADrawableReleasesTheOneHeldBefore()
	{
		let first = new ProbeDrawable();
		first.AddRef(); // the test's own reference, so it survives the view releasing its one
		defer first.ReleaseRef();

		let view = new DrawableView(first);
		defer view.ReleaseRef();
		Test.Assert(first.RefCount == 2);

		view.SetDrawable(new ProbeDrawable());
		Test.Assert(first.RefCount == 1, "the view let go of the first");

		// Handing back the drawable already held consumes the reference passed in and leaves
		// the view's own one alone: neither a double release nor a leak.
		let second = view.Drawable;
		second.AddRef();
		view.SetDrawable(second);
		Test.Assert(second.RefCount == 1, "held exactly once, by the view");
	}
}
