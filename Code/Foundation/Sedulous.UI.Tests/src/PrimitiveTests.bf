using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The layout primitives everything else rests on: Unit, SizeSpec, Thickness, BoxConstraints,
/// ViewId and ViewTransform.
class PrimitiveTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	// ---- Unit -------------------------------------------------------------------------------

	/// Dp is the LOGICAL unit, so it resolves to itself whatever the scale: the root applies
	/// the DPI once at draw, and layout never sees it.
	[Test]
	public static void DpIsTheLogicalIdentityAtEveryScale()
	{
		Test.Assert(Unit.Dp(100.0f).Resolve(1.0f) == 100.0f);
		Test.Assert(Unit.Dp(100.0f).Resolve(2.0f) == 100.0f);
		Test.Assert(Near(Unit.Dp(100.0f).Resolve(1.5f), 100.0f));
	}

	/// Px is PHYSICAL, so it divides out the scale: fifty physical pixels is twenty five
	/// logical at 2x, and the draw scale multiplies it back to exactly fifty device pixels.
	[Test]
	public static void PxMeansPhysicalPixels()
	{
		let unit = Unit.Px(50.0f);

		Test.Assert(unit.Resolve(1.0f) == 50.0f);
		Test.Assert(unit.Resolve(2.0f) == 25.0f);
		Test.Assert(unit.Resolve(0.5f) == 100.0f);
	}

	/// A point is a seventy second of an inch against ninety six per inch, and like dp it is
	/// logical, so the scale does not enter into it.
	[Test]
	public static void PtConvertsAtNinetySixOverSeventyTwoAndStaysLogical()
	{
		Test.Assert(Near(Unit.Pt(14.0f).Resolve(1.0f), 14.0f * (96.0f / 72.0f)));
		Test.Assert(Near(Unit.Pt(14.0f).Resolve(2.0f), 14.0f * (96.0f / 72.0f)));
	}

	/// The raw value is what was WRITTEN, before any conversion, which is what a property
	/// inspector shows back to the person who typed it.
	[Test]
	public static void RawValueIsUnscaledAndUnconverted()
	{
		Test.Assert(Unit.Dp(42.0f).RawValue == 42.0f);
		Test.Assert(Unit.Pt(14.0f).RawValue == 14.0f);
		Test.Assert(Unit.Px(7.0f).RawValue == 7.0f);
	}

	// ---- SizeSpec ---------------------------------------------------------------------------

	[Test]
	public static void AFixedSpecCarriesItsUnit()
	{
		let spec = SizeSpec.Fixed(Unit.Dp(120.0f));

		Test.Assert(spec.IsFixed);
		Test.Assert(Near(spec.ResolveFixed(1.0f), 120.0f));
		Test.Assert(Near(spec.ResolveFixed(2.0f), 120.0f), "dp is logical");
	}

	[Test]
	public static void AFixedSpecInPxDividesOutTheScale()
	{
		let spec = SizeSpec.Fixed(Unit.Px(50.0f));

		Test.Assert(spec.IsFixed);
		Test.Assert(spec.ResolveFixed(1.0f) == 50.0f);
		Test.Assert(spec.ResolveFixed(2.0f) == 25.0f);
	}

	/// Match and Wrap carry no length at all: what they mean is decided by the container, so
	/// resolving one as a fixed size is nought rather than a guess.
	[Test]
	public static void MatchAndWrapAreNotFixed()
	{
		Test.Assert(!SizeSpec.Match().IsFixed);
		Test.Assert(SizeSpec.Match().ResolveFixed(1.0f) == 0.0f);
		Test.Assert(!SizeSpec.Wrap().IsFixed);
		Test.Assert(SizeSpec.Wrap().ResolveFixed(1.0f) == 0.0f);
	}

	// ---- Thickness --------------------------------------------------------------------------

	[Test]
	public static void ADefaultThicknessIsZero()
	{
		let thickness = Thickness();

		Test.Assert(thickness.IsZero);
		Test.Assert((thickness.Left == 0.0f) && (thickness.Top == 0.0f)
			&& (thickness.Right == 0.0f) && (thickness.Bottom == 0.0f));
	}

	[Test]
	public static void TheShorthandConstructorsFillTheSides()
	{
		let uniform = Thickness(10.0f);
		Test.Assert((uniform.Left == 10.0f) && (uniform.Top == 10.0f)
			&& (uniform.Right == 10.0f) && (uniform.Bottom == 10.0f));
		Test.Assert(!uniform.IsZero);

		let pairs = Thickness(8.0f, 4.0f);
		Test.Assert((pairs.Left == 8.0f) && (pairs.Right == 8.0f));
		Test.Assert((pairs.Top == 4.0f) && (pairs.Bottom == 4.0f));

		let explicitSides = Thickness(1.0f, 2.0f, 3.0f, 4.0f);
		Test.Assert((explicitSides.Left == 1.0f) && (explicitSides.Top == 2.0f)
			&& (explicitSides.Right == 3.0f) && (explicitSides.Bottom == 4.0f));
	}

	[Test]
	public static void TheTotalsSumOppositeSides()
	{
		Test.Assert(Thickness(10.0f, 5.0f, 20.0f, 5.0f).TotalHorizontal == 30.0f);
		Test.Assert(Thickness(10.0f, 5.0f, 10.0f, 15.0f).TotalVertical == 20.0f);
	}

	// ---- BoxConstraints ---------------------------------------------------------------------

	[Test]
	public static void TightSetsTheMinimumEqualToTheMaximum()
	{
		let constraints = BoxConstraints.Tight(100.0f, 50.0f);

		Test.Assert(constraints.MinWidth == 100.0f);
		Test.Assert(constraints.MaxWidth == 100.0f);
		Test.Assert(constraints.MinHeight == 50.0f);
		Test.Assert(constraints.MaxHeight == 50.0f);
		Test.Assert(constraints.IsTight);
	}

	[Test]
	public static void LooseSetsTheMinimumToZero()
	{
		let constraints = BoxConstraints.Loose(200.0f, 100.0f);

		Test.Assert(constraints.MinWidth == 0.0f);
		Test.Assert(constraints.MaxWidth == 200.0f);
		Test.Assert(constraints.MinHeight == 0.0f);
		Test.Assert(constraints.MaxHeight == 100.0f);
		Test.Assert(constraints.IsLoose);
		Test.Assert(!constraints.IsTight);
	}

	[Test]
	public static void ExpandIsUnbounded()
	{
		let constraints = BoxConstraints.Expand();

		Test.Assert(constraints.MinWidth == 0.0f);
		Test.Assert(constraints.MaxWidth == FloatMax);
		Test.Assert(constraints.MinHeight == 0.0f);
		Test.Assert(constraints.MaxHeight == FloatMax);
	}

	[Test]
	public static void DeflateShrinksByThePadding()
	{
		let deflated = BoxConstraints.Tight(200.0f, 100.0f).Deflate(.(10.0f, 5.0f, 10.0f, 5.0f));

		Test.Assert(Near(deflated.MinWidth, 180.0f));
		Test.Assert(Near(deflated.MaxWidth, 180.0f));
		Test.Assert(Near(deflated.MinHeight, 90.0f));
		Test.Assert(Near(deflated.MaxHeight, 90.0f));
	}

	/// Padding larger than the box gives nought, not a negative box: a negative constraint
	/// would propagate into every measurement below it.
	[Test]
	public static void DeflateClampsToZero()
	{
		let deflated = BoxConstraints.Tight(10.0f, 10.0f).Deflate(.(20.0f, 20.0f, 20.0f, 20.0f));

		Test.Assert(deflated.MinWidth == 0.0f);
		Test.Assert(deflated.MaxWidth == 0.0f);
		Test.Assert(deflated.MinHeight == 0.0f);
		Test.Assert(deflated.MaxHeight == 0.0f);
	}

	[Test]
	public static void ConstrainClampsIntoTheRange()
	{
		let width = BoxConstraints(50.0f, 200.0f, 0.0f, 100.0f);
		Test.Assert(width.ConstrainWidth(30.0f) == 50.0f, "below the minimum");
		Test.Assert(width.ConstrainWidth(100.0f) == 100.0f, "inside the range");
		Test.Assert(width.ConstrainWidth(300.0f) == 200.0f, "above the maximum");

		let height = BoxConstraints(0.0f, 100.0f, 25.0f, 75.0f);
		Test.Assert(height.ConstrainHeight(10.0f) == 25.0f);
		Test.Assert(height.ConstrainHeight(50.0f) == 50.0f);
		Test.Assert(height.ConstrainHeight(100.0f) == 75.0f);
	}

	[Test]
	public static void LoosenKeepsTheMaximumAndZeroesTheMinimum()
	{
		let loosened = BoxConstraints(50.0f, 200.0f, 30.0f, 100.0f).Loosen();

		Test.Assert(loosened.MinWidth == 0.0f);
		Test.Assert(loosened.MaxWidth == 200.0f);
		Test.Assert(loosened.MinHeight == 0.0f);
		Test.Assert(loosened.MaxHeight == 100.0f);
	}

	[Test]
	public static void TightenToMaxPullsTheMinimumUp()
	{
		let tightened = BoxConstraints.Loose(300.0f, 150.0f).TightenToMax();

		Test.Assert(tightened.MinWidth == 300.0f);
		Test.Assert(tightened.MaxWidth == 300.0f);
		Test.Assert(tightened.MinHeight == 150.0f);
		Test.Assert(tightened.MaxHeight == 150.0f);
		Test.Assert(tightened.IsTight);
	}

	// ---- ViewId -----------------------------------------------------------------------------

	[Test]
	public static void CreateReturnsAValidUniqueId()
	{
		let a = ViewId.Create();
		let b = ViewId.Create();

		Test.Assert(a.IsValid);
		Test.Assert(a.RawValue > 0);
		Test.Assert(a != b);
	}

	/// Nought is reserved for "no view", which is what lets a manager hold an id for something
	/// that has gone and simply stop resolving.
	[Test]
	public static void TheInvalidIdIsZeroAndNotValid()
	{
		Test.Assert(!ViewId.Invalid.IsValid);
		Test.Assert(ViewId.Invalid.RawValue == 0);
	}

	[Test]
	public static void EqualIdsCompareAndHashAlike()
	{
		let a = ViewId.Create();
		let b = a;
		let other = ViewId.Create();

		Test.Assert(a == b);
		Test.Assert(a.Equals(b));
		Test.Assert(a.GetHashCode() == b.GetHashCode());
		Test.Assert(a != other);
		Test.Assert(!a.Equals(other));
	}

	[Test]
	public static void ToStringNamesTheType()
	{
		let text = scope String();
		ViewId.Create().ToString(text);

		Test.Assert(text.Contains("ViewId("));
	}

	// ---- ViewTransform ----------------------------------------------------------------------

	[Test]
	public static void ADefaultTransformIsTheIdentity()
	{
		Test.Assert(ViewTransform().IsIdentity);
		Test.Assert(ViewTransform.Identity.IsIdentity);
	}

	/// The default origin is the CENTRE, so a scale or a rotation with nothing else set turns
	/// about the middle of the view rather than its corner.
	[Test]
	public static void TheDefaultOriginIsTheCentre()
	{
		let transform = ViewTransform();

		Test.Assert(transform.Origin.X == 0.5f);
		Test.Assert(transform.Origin.Y == 0.5f);
	}

	[Test]
	public static void AnyNonDefaultComponentBreaksTheIdentity()
	{
		var translated = ViewTransform();
		translated.Translation = .(10.0f, 20.0f);
		Test.Assert(!translated.IsIdentity);

		var rotated = ViewTransform();
		rotated.Rotation = 0.5f;
		Test.Assert(!rotated.IsIdentity);

		var scaled = ViewTransform();
		scaled.Scale = .(2.0f, 2.0f);
		Test.Assert(!scaled.IsIdentity);
	}
}
