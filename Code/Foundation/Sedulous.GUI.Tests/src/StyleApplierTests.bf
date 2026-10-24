using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// CSS value parsers + typed property application: parse value strings into Color/length/bool/
// Thickness, and apply a resolved (or parsed) stylesheet onto a widget.

/// The CSS value parsers, and a resolved style applied onto a widget's box, layout and states.
class StyleApplierTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// `css` resolved for `w` (the pseudo-classes applied when `applyPseudo`), into `outStyle`.
	private static ResolvedStyle ResolveFor(StringView css, UIWidget w, ResolvedStyle outStyle, bool applyPseudo = true)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		sheet.Resolve(w, MediaContext(), applyPseudo, default, null, outStyle);
		return outStyle;
	}

	// === value parsers ===

	[Test]
	public static void CssValuesParseLength()
	{
		Test.Assert(Near(ParseLength("4").Value, 4.0f));
		Test.Assert(Near(ParseLength("2.5").Value, 2.5f));
		Test.Assert(Near(ParseLength("10px").Value, 10.0f)); // unit ignored
		Test.Assert(Near(ParseLength("-3").Value, -3.0f));
		Test.Assert(!ParseLength("abc").HasValue);
		Test.Assert(!ParseLength("").HasValue);
	}

	[Test]
	public static void CssValuesParseColorHexNamedRgb()
	{
		Test.Assert(Near(ParseColor("#ff0000").Value.R, 1.0f));
		Test.Assert(Near(ParseColor("#00ff00").Value.G, 1.0f));
		Test.Assert(Near(ParseColor("#f00").Value.R, 1.0f)); // shorthand
		Test.Assert(Near(ParseColor("#0000ff80").Value.A, 128.0f / 255.0f)); // alpha
		Test.Assert(Near(ParseColor("white").Value.R, 1.0f));
		Test.Assert(Near(ParseColor("blue").Value.B, 1.0f));
		Test.Assert(Near(ParseColor("rgb(0,0,255)").Value.B, 1.0f));
		Test.Assert(Near(ParseColor("rgba(255,0,0,0.5)").Value.A, 0.5f));
		Test.Assert(!ParseColor("#zz").HasValue);
		Test.Assert(!ParseColor("notacolor").HasValue);
	}

	[Test]
	public static void CssValuesParseBool()
	{
		Test.Assert(ParseBool("true").Value == true);
		Test.Assert(ParseBool("false").Value == false);
		Test.Assert(ParseBool("1").Value == true);
		Test.Assert(ParseBool("0").Value == false);
		Test.Assert(!ParseBool("maybe").HasValue);
	}

	[Test]
	public static void CssValuesParseThicknessShorthandTopRightBottomLeft()
	{
		let one = ParseThickness("4").Value;
		Test.Assert(one.Left == 4.0f);
		Test.Assert(one.Top == 4.0f);
		Test.Assert(one.Right == 4.0f);
		Test.Assert(one.Bottom == 4.0f);

		let two = ParseThickness("2 6").Value; // vertical=2, horizontal=6
		Test.Assert(two.Top == 2.0f);
		Test.Assert(two.Bottom == 2.0f);
		Test.Assert(two.Left == 6.0f);
		Test.Assert(two.Right == 6.0f);

		let four = ParseThickness("1 2 3 4").Value; // top right bottom left
		Test.Assert(four.Top == 1.0f);
		Test.Assert(four.Right == 2.0f);
		Test.Assert(four.Bottom == 3.0f);
		Test.Assert(four.Left == 4.0f);
	}

	// === application ===

	[Test]
	public static void StyleApplierBackgroundColorPaddingOpacity()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		ApplyStyle(w, ResolveFor("button { background-color: #0000ff; padding: 4; opacity: 0.5; }", w, scope .()));

		Test.Assert(Near(w.Box.BackgroundColor.B, 1.0f)); // blue
		Test.Assert(w.IsBoxFromStyle);
		Test.Assert(Near(w.Padding.Left, 4.0f));
		Test.Assert(Near(w.Alpha, 0.5f));
	}

	[Test]
	public static void StyleApplierWidthHeightEnabledVisibilityMargin()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		ApplyStyle(w, ResolveFor("button { width: 120; height: 40; enabled: false; visibility: hidden; margin: 1 2 3 4; }", w, scope .(), false));
		w.UpdateLayout(); // the size is the layout's, from the style

		Test.Assert(Near(w.Size.X, 120.0f));
		Test.Assert(Near(w.Size.Y, 40.0f));
		Test.Assert(!w.Enabled);
		Test.Assert(!w.Visible);
		Test.Assert(Near(w.Margin.Top, 1.0f));
		Test.Assert(Near(w.Margin.Left, 4.0f));
	}

	[Test]
	public static void StyleApplierCascadeDrivesTheAppliedValue()
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		w.AddClass("primary");
		ApplyStyle(w, ResolveFor("button { background-color: black; } .primary { background-color: red; }", w, scope .()));

		Test.Assert(Near(w.Box.BackgroundColor.R, 1.0f)); // .primary (red) beats button (black)
		Test.Assert(Near(w.Box.BackgroundColor.G, 0.0f));
	}

	[Test]
	public static void StyleApplierSizesMinAndMaxPercentagesAndAutoReachTheLayoutStyle()
	{
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		ApplyStyle(w, ResolveFor("box { min-width: 50; max-width: 100; min-height: 20; max-height: 80; width: 50%; height: auto; }", w, scope .(), false));
		let s = w.LayoutStyle;
		Test.Assert(s.Width.Kind == .Percent);
		Test.Assert(Near(s.Width.Value, 50.0f));
		Test.Assert(s.Height.IsAuto);
		Test.Assert(Near(s.MinWidth.Value, 50.0f));
		Test.Assert(Near(s.MaxHeight.Value, 80.0f));
	}

	[Test]
	public static void NodeASizeFromCodeIsItsWidthAndHeightMinAndMaxKeepItWithinThem()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.EditLayoutStyle(scope (s) =>
			{
				s.MaxWidth = LayoutLength.Px(100.0f);
				s.MinHeight = LayoutLength.Px(60.0f);
			});
		w.Size = .(200.0f, 50.0f);
		w.UpdateLayout();
		Test.Assert(Near(w.LayoutStyle.Width.Value, 200.0f));
		Test.Assert(Near(w.Size.X, 100.0f)); // within max
		Test.Assert(Near(w.Size.Y, 60.0f)); // within min
	}

	[Test]
	public static void CssValuesParseCornerRadiiOneAndFourValues()
	{
		let one = ParseCornerRadii("6");
		Test.Assert(one.HasValue);
		Test.Assert(Near(one.Value.TopLeft, 6.0f));
		Test.Assert(Near(one.Value.BottomRight, 6.0f));

		let four = ParseCornerRadii("1 2 3 4");
		Test.Assert(four.HasValue);
		Test.Assert(Near(four.Value.TopLeft, 1.0f));
		Test.Assert(Near(four.Value.TopRight, 2.0f));
		Test.Assert(Near(four.Value.BottomRight, 3.0f));
		Test.Assert(Near(four.Value.BottomLeft, 4.0f));
	}

	[Test]
	public static void CssValuesParseBorderWidthStyleColorAnyOrder()
	{
		let b = ParseBorder("2 solid #ff0000");
		Test.Assert(b.HasValue);
		Test.Assert(Near(b.Value.Width, 2.0f));
		Test.Assert(Near(b.Value.LineColor.R, 1.0f));

		let reordered = ParseBorder("red 3");
		Test.Assert(reordered.HasValue);
		Test.Assert(Near(reordered.Value.Width, 3.0f));
		Test.Assert(Near(reordered.Value.LineColor.R, 1.0f));

		let none = ParseBorder("none");
		Test.Assert(none.HasValue);
		Test.Assert(Near(none.Value.Width, 0.0f));
	}

	[Test]
	public static void StyleApplierBorderAndBorderRadiusMakeTheNodesBox()
	{
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		ApplyStyle(w, ResolveFor("box { background-color: #ffffff; border-radius: 6; border: 2 solid #ff0000; }", w, scope .(), false));
		let area = w.Box;
		Test.Assert(Near(area.BackgroundColor.R, 1.0f));
		Test.Assert(Near(area.Radii.TopLeft, 6.0f));
		Test.Assert(Near(area.Radii.BottomRight, 6.0f));
		Test.Assert(Near(area.BorderWidths.Top, 2.0f));
		Test.Assert(Near(area.BorderWidths.Left, 2.0f));
		Test.Assert(Near(area.BorderColors.Top.R, 1.0f));
		Test.Assert(area.BorderColors.IsUniform);
	}

	[Test]
	public static void StyleApplierBorderLonghandsOverrideTheShorthandAndABorderWithNoStyleDrawsNone()
	{
		let css = "box { border-width: 4; border-color: blue; } .styled { border-style: solid; border-left-color: red; }";
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		ApplyStyle(w, ResolveFor(css, w, scope .(), false));
		Test.Assert(w.Box.BorderWidths.IsZero); // no border-style: none (CSS)

		w.AddClass("styled");
		ApplyStyle(w, ResolveFor(css, w, scope .(), false));
		Test.Assert(Near(w.Box.BorderWidths.Top, 4.0f));
		Test.Assert(Near(w.Box.BorderColors.Top.B, 1.0f));
		Test.Assert(Near(w.Box.BorderColors.Left.R, 1.0f)); // its own colour
	}

	[Test]
	public static void CssValuesParseLengthValueRecognizesUnits()
	{
		Test.Assert(ParseLengthValue("12").Value.Unit == .Px);
		Test.Assert(Near(ParseLengthValue("12px").Value.Value, 12.0f));
		Test.Assert(ParseLengthValue("1.5rem").Value.Unit == .Rem);
		Test.Assert(ParseLengthValue("2em").Value.Unit == .Em);
		Test.Assert(ParseLengthValue("50vw").Value.Unit == .Vw);
		Test.Assert(ParseLengthValue("80vh").Value.Unit == .Vh);
		Test.Assert(ParseLengthValue("25%").Value.Unit == .Percent);
		Test.Assert(!ParseLengthValue("10pt").HasValue); // unknown unit
	}

	[Test]
	public static void CssValuesResolveLengthResolvesUnitsAgainstAContext()
	{
		var ctx = LengthContext();
		ctx.RootFontSize = 10.0f;
		ctx.ElementFontSize = 20.0f;
		ctx.ViewportWidth = 1000.0f;
		ctx.ViewportHeight = 400.0f;

		Test.Assert(Near(ResolveLength("3rem", ctx).Value, 30.0f)); // 3 * root(10)
		Test.Assert(Near(ResolveLength("2em", ctx).Value, 40.0f)); // 2 * elem(20)
		Test.Assert(Near(ResolveLength("50vw", ctx).Value, 500.0f)); // 50% of 1000
		Test.Assert(Near(ResolveLength("25vh", ctx).Value, 100.0f)); // 25% of 400
		Test.Assert(Near(ResolveLength("50%", ctx, 200.0f).Value, 100.0f)); // percentBase
		Test.Assert(Near(ResolveLength("12", ctx).Value, 12.0f)); // px passthrough
	}

	[Test]
	public static void StyleApplierWidthHeightResolveRemAndVhViaTheLengthContext()
	{
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		var ctx = LengthContext();
		ctx.RootFontSize = 10.0f; // 2rem -> 20
		ctx.ViewportHeight = 200.0f; // 50vh -> 100
		ApplyStyle(w, ResolveFor("box { width: 2rem; height: 50vh; }", w, scope .(), false), null, null, ctx);
		w.UpdateLayout();
		Test.Assert(Near(w.Size.X, 20.0f));
		Test.Assert(Near(w.Size.Y, 100.0f));
	}

	[Test]
	public static void TextAlignAndVerticalAlignReachALabel()
	{
		let l = new Label(); // Label's constructor tags it "label"
		defer l.ReleaseRef();
		ApplyStyle(l, ResolveFor("label { text-align: center; vertical-align: bottom; }", l, scope .(), false));
		Test.Assert(l.TextAlignH == .Center);
		Test.Assert(l.TextAlignV == .Bottom);

		ApplyStyle(l, ResolveFor("label { text-align: right; }", l, scope .(), false));
		Test.Assert(l.TextAlignH == .Right);
		Test.Assert(l.TextAlignV == .Middle); // no longer set: the label's own again
	}
}
