using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The typed style values: colours in each notation, lengths and their units' resolution, the
/// style slot sets and the layout changes they name, values parsed by grammar, interpolation
/// between two values, and the shorthands' expansion into longhands.
class StyleValuesTests
{
	private const float cPi = 3.14159265358979f;

	private static bool Near(float a, float b, float epsilon = 1e-5f) => Math.Abs(a - b) <= epsilon;

	private static bool SameColor(Color? c, float r, float g, float b, float a) =>
		c.HasValue && Near(c.Value.R, r) && Near(c.Value.G, g) && Near(c.Value.B, b) && Near(c.Value.A, a);

	private static void CheckLonghand(List<StyleLonghand> list, int index, StringView name, StringView text)
	{
		Test.Assert(index < list.Count, scope $"no longhand {index} ({name})");
		Test.Assert(list[index].Name == name, scope $"longhand {index}: {list[index].Name}, expected {name}");
		Test.Assert(list[index].Text == text, scope $"{name}: '{list[index].Text}', expected '{text}'");
	}

	// === Colours ===

	[Test]
	public static void NamedColorsParse()
	{
		Test.Assert(ParseColor("red").Value == Color.Red);
		Test.Assert(ParseColor(" transparent ").Value == Color.Transparent);
		Test.Assert(ParseColor("orange").Value == Color(1.0f, 0.647f, 0.0f, 1.0f));
		Test.Assert(ParseColor("grey").Value == Color(0.5f, 0.5f, 0.5f, 1.0f));
		Test.Assert(!ParseColor("chartreuse").HasValue);
		Test.Assert(!ParseColor("").HasValue);
	}

	[Test]
	public static void HexColorsParseInEachLength()
	{
		Test.Assert(ParseColor("#f00").Value == Color(1.0f, 0.0f, 0.0f, 1.0f));
		Test.Assert(ParseColor("#0080ff").Value == Color(0.0f, 128.0f / 255.0f, 1.0f, 1.0f));
		Test.Assert(ParseColor("#11223344").Value == Color(17.0f / 255.0f, 34.0f / 255.0f, 51.0f / 255.0f, 68.0f / 255.0f));
		Test.Assert(ParseColor("#ABCDEF").Value == Color(171.0f / 255.0f, 205.0f / 255.0f, 239.0f / 255.0f, 1.0f));
		Test.Assert(!ParseColor("#12").HasValue);
		Test.Assert(!ParseColor("#ggg").HasValue);
		Test.Assert(!ParseColor("#12345").HasValue);
	}

	[Test]
	public static void RgbAndHslFunctionsParse()
	{
		Test.Assert(ParseColor("rgb(255, 0, 0)").Value == Color(1.0f, 0.0f, 0.0f, 1.0f));
		Test.Assert(ParseColor("rgba(0, 0, 255, 0.5)").Value == Color(0.0f, 0.0f, 1.0f, 0.5f));
		Test.Assert(!ParseColor("rgb(255, x, 0)").HasValue);
		// hsl: hue in degrees, saturation and lightness as percentages; a space list with a slash
		// before the alpha too.
		Test.Assert(SameColor(ParseColor("hsl(120, 100%, 50%)"), 0.0f, 1.0f, 0.0f, 1.0f));
		Test.Assert(SameColor(ParseColor("hsla(0deg 100% 50% / 50%)"), 1.0f, 0.0f, 0.0f, 0.5f));
		Test.Assert(SameColor(ParseColor("hsl(240, 100%, 25%)"), 0.0f, 0.0f, 0.5f, 1.0f));
		Test.Assert(SameColor(ParseColor("hsl(0, 0%, 100%)"), 1.0f, 1.0f, 1.0f, 1.0f));
		Test.Assert(!ParseColor("hsl(120, 100%)").HasValue);
		// color-mix: half and half by default, or by the percentages given.
		Test.Assert(SameColor(ParseColor("color-mix(in srgb, red, blue)"), 0.5f, 0.0f, 0.5f, 1.0f));
		Test.Assert(SameColor(ParseColor("color-mix(in srgb, red 25%, blue)"), 0.25f, 0.0f, 0.75f, 1.0f));
		Test.Assert(!ParseColor("color-mix(in hsl, red, blue)").HasValue);
	}

	// === Lengths ===

	[Test]
	public static void LengthUnitsParseAndResolveAgainstTheirBases()
	{
		var ctx = LengthContext();
		ctx.RootFontSize = 10.0f;
		ctx.ElementFontSize = 20.0f;
		ctx.ViewportWidth = 800.0f;
		ctx.ViewportHeight = 600.0f;

		let rem = ParseLengthValue("1.5rem").Value;
		Test.Assert((rem.Unit == .Rem) && (rem.Value == 1.5f));
		Test.Assert(ResolveLengthValue(rem, ctx) == 15.0f);
		Test.Assert(ResolveLengthValue(ParseLengthValue("2em").Value, ctx) == 40.0f);
		Test.Assert(ResolveLengthValue(ParseLengthValue("50vw").Value, ctx) == 400.0f);
		Test.Assert(ResolveLength("80vh", ctx).Value == 480.0f);
		Test.Assert(ResolveLengthValue(ParseLengthValue("50%").Value, ctx, 300.0f) == 150.0f);
		let plain = ParseLengthValue("12").Value;
		Test.Assert((plain.Unit == .Px) && (plain.Value == 12.0f));
		let negative = ParseLengthValue("-3.25px").Value;
		Test.Assert((negative.Unit == .Px) && (negative.Value == -3.25f));
		Test.Assert(!ParseLengthValue("12pt").HasValue);
		Test.Assert(!ParseLengthValue("px").HasValue);
		// The plain number scanner ignores a trailing unit.
		Test.Assert(ParseLength("7.5px").Value == 7.5f);
		Test.Assert(!ParseLength("abc").HasValue);
		// Thicknesses in CSS's side order: top, right (and left), bottom.
		Test.Assert(ParseThickness("1 2 3").Value == Thickness(2.0f, 1.0f, 2.0f, 3.0f));
		Test.Assert(ParseThickness("4").Value == Thickness(4.0f));
		Test.Assert(!ParseThickness("1 2 3 4 5").HasValue);
		Test.Assert(ResolveThickness("1em 2rem", ctx).Value == Thickness(20.0f, 20.0f, 20.0f, 20.0f));
	}

	// === Style slots ===

	[Test]
	public static void StyleSlotSetsHoldABitPerSlotAcrossBothWords()
	{
		Test.Assert((int)StyleSlot.SlotCount == 65);
		Test.Assert(SlotBit(.SlotOpacity).Words[0] == 1);
		Test.Assert(SlotBit(.SlotWidth).Words[0] == (uint64)1 << 9);
		Test.Assert(SlotBit(.SlotFontStyle).Words[0] == (uint64)1 << 63);
		let wrap = SlotBit(.SlotOverflowWrap);
		Test.Assert((wrap.Words[0] == 0) && (wrap.Words[1] == 1));

		let set = SlotBit(.SlotWidth) | SlotBit(.SlotOverflowWrap);
		Test.Assert(set.Has(.SlotWidth) && set.Has(.SlotOverflowWrap) && !set.Has(.SlotHeight));
		Test.Assert((set & SlotBit(.SlotWidth)) == SlotBit(.SlotWidth));
		Test.Assert((~set).Has(.SlotHeight) && !(~set).Has(.SlotWidth) && !(~set).Has(.SlotOverflowWrap));
		Test.Assert(set.Any && !StyleSlotSet().Any);
		var grown = set;
		grown |= SlotBit(.SlotHeight);
		Test.Assert(grown.Has(.SlotHeight) && (grown != set));

		Test.Assert(StyleSlotProperty(.SlotOpacity) == "opacity");
		Test.Assert(StyleSlotProperty(.SlotWidth) == "width");
		Test.Assert(StyleSlotProperty(.SlotGridTemplateColumns) == "grid-template-columns");
		Test.Assert(StyleSlotProperty(.SlotDirection) == "direction");
		Test.Assert(StyleSlotProperty(.SlotOverflowWrap) == "overflow-wrap");
	}

	[Test]
	public static void ChangedLayoutSlotsNameExactlyTheFieldsThatDiffer()
	{
		let a = scope LayoutStyle();
		let b = scope LayoutStyle();
		Test.Assert(!ChangedLayoutSlots(a, b).Any);
		b.Width = LayoutLength.Px(120.0f);
		b.Columns.Add(GridTrack.Flex(1.0f));
		b.Margin.Left = 4.0f;
		b.RowGapPercent = 10.0f;
		b.DockSide = .Top;
		let expected = SlotBit(.SlotWidth) | SlotBit(.SlotGridTemplateColumns) | SlotBit(.SlotMarginLeft) | SlotBit(.SlotRowGap) |
			SlotBit(.SlotDock);
		Test.Assert(ChangedLayoutSlots(a, b) == expected);
		// A track list of the same length that differs in a track is a change too.
		a.Columns.Add(GridTrack.Fixed(10.0f));
		Test.Assert(ChangedLayoutSlots(a, b).Has(.SlotGridTemplateColumns));

		// Set copies deeply: the copy's tracks are its own.
		let copy = scope LayoutStyle();
		copy.Set(b);
		Test.Assert(!ChangedLayoutSlots(copy, b).Any);
		copy.Columns.Add(GridTrack.Fixed(5.0f));
		Test.Assert(b.Columns.Count == 1);
		Test.Assert(ChangedLayoutSlots(copy, b) == SlotBit(.SlotGridTemplateColumns));
	}

	// === Values by grammar ===

	[Test]
	public static void StyleValuesParseByTheirGrammar()
	{
		let v = scope StyleValue();
		Test.Assert(ParseStyleValue(.Number, "50%", v) && (v.Kind == .Number) && Near(v.Number, 0.5f));
		Test.Assert(ParseStyleValue(.Number, "0.25", v) && (v.Number == 0.25f));
		Test.Assert(!ParseStyleValue(.Number, "2px", v));
		Test.Assert(ParseStyleValue(.Size, "fit-content", v) && (v.Kind == .Keyword) && (v.Keyword == "fit-content"));
		Test.Assert(ParseStyleValue(.Size, "40%", v) && (v.Kind == .Length) && (v.Length == LengthValue(40.0f, .Percent)));
		Test.Assert(!ParseStyleValue(.Size, "wide", v));
		Test.Assert(ParseStyleValue(.Color, "#00ff00", v) && (v.Kind == .ColorValue) && (v.ColorValue == Color.Green));

		Test.Assert(ParseStyleValue(.Shadows, "inset 2px 3px 4px red", v) && (v.Kind == .Shadows));
		Test.Assert(v.Shadows.Count == 1);
		let shadow = v.Shadows[0];
		Test.Assert(shadow.Inset && (shadow.OffsetX == LengthValue(2.0f, .Px)) && (shadow.OffsetY == LengthValue(3.0f, .Px)));
		Test.Assert((shadow.Blur == LengthValue(4.0f, .Px)) && (shadow.Spread == LengthValue()) && (shadow.ShadowColor == Color.Red));
		Test.Assert(!ParseStyleValue(.Shadows, "2px", v)); // one offset is not a shadow

		Test.Assert(ParseStyleValue(.Transforms, "translate(10px, 50%) rotate(90deg)", v) && (v.Transforms.Count == 2));
		Test.Assert((v.Transforms[0].Kind == .Translate) && (v.Transforms[0].A == LengthValue(10.0f, .Px)) &&
			(v.Transforms[0].B == LengthValue(50.0f, .Percent)));
		Test.Assert((v.Transforms[1].Kind == .Rotate) && Near(v.Transforms[1].Angle, cPi / 2.0f));
		// Composed for a 200 by 100 box: the translation's percentage is of the height.
		let m = ComposeTransforms(v.Transforms, .(200.0f, 100.0f));
		Test.Assert(Near(m.Tx, 10.0f) && Near(m.Ty, 50.0f) && Near(m.A, 0.0f) && Near(m.B, 1.0f));
		Test.Assert(!ParseStyleValue(.Transforms, "wobble(1)", v));

		Test.Assert(ParseStyleValue(.Layers, "linear-gradient(to right, red, blue 80%), url('a.png')", v) && (v.Layers.Count == 2));
		let gradient = v.Layers[0];
		Test.Assert((gradient.Kind == .Gradient) && (gradient.Gradient.Kind == .Linear) && Near(gradient.Gradient.Angle, cPi / 2.0f));
		Test.Assert((gradient.Gradient.Stops.Count == 2) && (gradient.Gradient.Stops[0].Position < 0.0f) &&
			Near(gradient.Gradient.Stops[1].Position, 0.8f));
		Test.Assert((v.Layers[1].Kind == .Image) && (v.Layers[1].Image == "a.png"));
		let settled = scope List<GradientStopValue>();
		SettleStops(gradient.Gradient.Stops, settled);
		Test.Assert((settled[0].Position == 0.0f) && Near(settled[1].Position, 0.8f));

		Test.Assert(ParseStyleValue(.Origin, "right top", v) && (v.OriginX == LengthValue(100.0f, .Percent)) &&
			(v.OriginY == LengthValue(0.0f, .Percent)));
		Test.Assert(ParseStyleValue(.Filters, "blur(3px)", v) && (v.Filters.Count == 1) && (v.Filters[0].Amount == LengthValue(3.0f, .Px)));
		Test.Assert(!ParseStyleValue(.Filters, "brightness(2)", v));
	}

	[Test]
	public static void VariablesSubstituteNestedAndWithFallbacks()
	{
		delegate bool(StringView name, String outValue) lookup = scope (name, outValue) =>
		{
			if (name == "--a")
			{
				outValue.Append("10px");
				return true;
			}
			if (name == "--b")
			{
				outValue.Append("var(--a)");
				return true;
			}
			return false;
		};
		let text = scope String();
		Test.Assert(SubstituteVariables("calc(var(--a) + var(--missing, 4px))", lookup, text));
		Test.Assert(text == "calc(10px + 4px)");
		Test.Assert(SubstituteVariables("1px var(--b)", lookup, text));
		Test.Assert(text == "1px 10px");
		Test.Assert(!SubstituteVariables("var(--missing)", lookup, text));
	}

	// === Interpolation ===

	[Test]
	public static void InterpolationMixesWhatItCanAndSwitchesTheRestAtHalfway()
	{
		let a = scope StyleValue();
		let b = scope StyleValue();
		let mid = scope StyleValue();

		ParseStyleValue(.Number, "0", a);
		ParseStyleValue(.Number, "1", b);
		InterpolateStyleValue(a, b, 0.25f, mid);
		Test.Assert((mid.Kind == .Number) && (mid.Number == 0.25f));

		ParseStyleValue(.Color, "black", a);
		ParseStyleValue(.Color, "white", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert(mid.ColorValue == Color(0.5f, 0.5f, 0.5f, 1.0f));

		ParseStyleValue(.Length, "10px", a);
		ParseStyleValue(.Length, "20px", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert(mid.Length == LengthValue(15.0f, .Px));

		// Different units: discrete without a context, in pixels with one.
		ParseStyleValue(.Length, "1em", a);
		ParseStyleValue(.Length, "10px", b);
		InterpolateStyleValue(a, b, 0.4f, mid);
		Test.Assert(mid.Length == LengthValue(1.0f, .Em));
		var ctx = StyleInterpolationContext();
		ctx.Lengths.ElementFontSize = 20.0f;
		InterpolateStyleValue(a, b, 0.5f, mid, ctx);
		Test.Assert(mid.Length == LengthValue(15.0f, .Px));

		// Keywords switch at halfway.
		ParseStyleValue(.Keyword, "left", a);
		ParseStyleValue(.Keyword, "right", b);
		InterpolateStyleValue(a, b, 0.4f, mid);
		Test.Assert(mid.Keyword == "left");
		InterpolateStyleValue(a, b, 0.6f, mid);
		Test.Assert(mid.Keyword == "right");

		// none against a shadow: padded with a transparent one of the same colour.
		ParseStyleValue(.Shadows, "none", a);
		ParseStyleValue(.Shadows, "4px 8px black", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert(mid.Shadows.Count == 1);
		Test.Assert((mid.Shadows[0].OffsetX == LengthValue(2.0f, .Px)) && (mid.Shadows[0].OffsetY == LengthValue(4.0f, .Px)));
		Test.Assert(mid.Shadows[0].ShadowColor == Color(0.0f, 0.0f, 0.0f, 0.5f));

		// none against a rotation turns from 0.
		ParseStyleValue(.Transforms, "none", a);
		ParseStyleValue(.Transforms, "rotate(90deg)", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert((mid.Transforms.Count == 1) && (mid.Transforms[0].Kind == .Rotate) && Near(mid.Transforms[0].Angle, cPi / 4.0f));

		// Different functions go through their matrices.
		ParseStyleValue(.Transforms, "translateX(10px)", a);
		ParseStyleValue(.Transforms, "scale(3)", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert((mid.Transforms.Count == 1) && (mid.Transforms[0].Kind == .Matrix));
		let mm = mid.Transforms[0].M;
		Test.Assert(Near(mm[0], 2.0f) && Near(mm[3], 2.0f) && Near(mm[4], 5.0f) && Near(mm[5], 0.0f) && Near(mm[1], 0.0f));

		// Origins move in their percentages (a zero takes the other's unit).
		ParseStyleValue(.Origin, "left top", a);
		ParseStyleValue(.Origin, "right bottom", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert((mid.OriginX == LengthValue(50.0f, .Percent)) && (mid.OriginY == LengthValue(50.0f, .Percent)));

		// Gradients of one shape mix stop by stop.
		ParseStyleValue(.Layers, "linear-gradient(red, blue)", a);
		ParseStyleValue(.Layers, "linear-gradient(blue, red)", b);
		InterpolateStyleValue(a, b, 0.5f, mid);
		Test.Assert((mid.Layers.Count == 1) && (mid.Layers[0].Gradient.Stops.Count == 2));
		Test.Assert(mid.Layers[0].Gradient.Stops[0].StopColor == Color(0.5f, 0.0f, 0.5f, 1.0f));
		Test.Assert((mid.Layers[0].Gradient.Stops[0].Position == 0.0f) && (mid.Layers[0].Gradient.Stops[1].Position == 1.0f));

		// Different kinds switch.
		ParseStyleValue(.Number, "3", a);
		InterpolateStyleValue(a, b, 0.4f, mid);
		Test.Assert((mid.Kind == .Number) && (mid.Number == 3.0f));
	}

	// === Shorthands ===

	[Test]
	public static void TransitionAndAnimationExpandIntoTheirLonghands()
	{
		let list = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems(list); }
		Test.Assert(ExpandStyleShorthand("transition", "opacity 0.3s ease-in 100ms", list));
		Test.Assert(list.Count == 4);
		CheckLonghand(list, 0, "transition-property", "opacity");
		CheckLonghand(list, 1, "transition-duration", "0.3s");
		CheckLonghand(list, 2, "transition-timing-function", "cubic-bezier(0.42, 0, 1, 1)");
		CheckLonghand(list, 3, "transition-delay", "0.1s");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("transition", "opacity 1s, color 2s steps(3, jump-start)", list));
		CheckLonghand(list, 0, "transition-property", "opacity, color");
		CheckLonghand(list, 1, "transition-duration", "1s, 2s");
		CheckLonghand(list, 2, "transition-timing-function", "cubic-bezier(0.25, 0.1, 0.25, 1), steps(3, jump-start)");
		CheckLonghand(list, 3, "transition-delay", "0s, 0s");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("transition", "none", list));
		CheckLonghand(list, 0, "transition-property", "none");
		CheckLonghand(list, 1, "transition-duration", "0s");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("animation", "spin 2s linear infinite alternate", list));
		Test.Assert(list.Count == 8);
		CheckLonghand(list, 0, "animation-name", "spin");
		CheckLonghand(list, 1, "animation-duration", "2s");
		CheckLonghand(list, 2, "animation-timing-function", "linear");
		CheckLonghand(list, 3, "animation-delay", "0s");
		CheckLonghand(list, 4, "animation-iteration-count", "infinite");
		CheckLonghand(list, 5, "animation-direction", "alternate");
		CheckLonghand(list, 6, "animation-fill-mode", "none");
		CheckLonghand(list, 7, "animation-play-state", "running");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("animation", "pulse 0.5s 2.5 ease-out-bounce both paused", list));
		CheckLonghand(list, 0, "animation-name", "pulse");
		CheckLonghand(list, 2, "animation-timing-function", "ease-out-bounce");
		CheckLonghand(list, 4, "animation-iteration-count", "2.5");
		CheckLonghand(list, 6, "animation-fill-mode", "both");
		CheckLonghand(list, 7, "animation-play-state", "paused");
	}

	[Test]
	public static void TheLonghandsComposeBackIntoSpecs()
	{
		let transitions = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems(transitions); }
		ComposeTransitions("opacity, color", "1s", "", "", transitions);
		Test.Assert(transitions.Count == 2);
		Test.Assert((transitions[1].Property == "color") && (transitions[1].Duration == 1.0f) && (transitions[1].Delay == 0.0f));
		Test.Assert((transitions[1].Timing.Kind == .CubicBezier) && (transitions[1].Timing.X1 == 0.25f));

		let animations = scope List<AnimationSpec>();
		defer { ClearAndDeleteItems(animations); }
		ComposeAnimations("a, none, b", "1s, 2s", "linear", "", "infinite, 7, 3", "reverse", "forwards", "paused", animations);
		Test.Assert(animations.Count == 2);
		Test.Assert((animations[0].Name == "a") && (animations[0].Duration == 1.0f) && (animations[0].Iterations == -1.0f));
		Test.Assert((animations[1].Name == "b") && (animations[1].Duration == 1.0f) && (animations[1].Iterations == 3.0f));
		Test.Assert((animations[1].Direction == .Reverse) && (animations[1].Fill == .Forwards) && animations[1].Paused);
		Test.Assert(animations[1].Timing.Kind == .Linear);
	}

	[Test]
	public static void BoxShorthandsExpandInCssOrder()
	{
		let list = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems(list); }
		Test.Assert(ExpandStyleShorthand("margin", "1px 2px", list));
		Test.Assert(list.Count == 4);
		CheckLonghand(list, 0, "margin-top", "1px");
		CheckLonghand(list, 1, "margin-right", "2px");
		CheckLonghand(list, 2, "margin-bottom", "1px");
		CheckLonghand(list, 3, "margin-left", "2px");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("border", "2px solid red", list));
		Test.Assert(list.Count == 12);
		CheckLonghand(list, 0, "border-top-width", "2px");
		CheckLonghand(list, 1, "border-top-style", "solid");
		CheckLonghand(list, 2, "border-top-color", "red");
		CheckLonghand(list, 11, "border-left-color", "red");
		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("border-bottom", "dashed", list));
		Test.Assert(list.Count == 3);
		CheckLonghand(list, 0, "border-bottom-width", "3px");
		CheckLonghand(list, 2, "border-bottom-color", "#000000");
		Test.Assert(!ExpandStyleShorthand("border", "bogus", list));

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("border-radius", "4px 8px 12px", list));
		CheckLonghand(list, 0, "border-top-left-radius", "4px");
		CheckLonghand(list, 1, "border-top-right-radius", "8px");
		CheckLonghand(list, 2, "border-bottom-right-radius", "12px");
		CheckLonghand(list, 3, "border-bottom-left-radius", "8px");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("flex", "1", list));
		CheckLonghand(list, 0, "flex-grow", "1");
		CheckLonghand(list, 1, "flex-shrink", "1");
		CheckLonghand(list, 2, "flex-basis", "0px");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("background", "url(a.png), red", list));
		CheckLonghand(list, 0, "background-color", "red");
		CheckLonghand(list, 1, "background-image", "url(a.png)");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("padding-inline", "3px 5px", list));
		CheckLonghand(list, 0, "padding-inline-start", "3px");
		CheckLonghand(list, 1, "padding-inline-end", "5px");

		ClearAndDeleteItems(list);
		Test.Assert(ExpandStyleShorthand("opacity", " 0.5 ", list));
		Test.Assert(list.Count == 1);
		CheckLonghand(list, 0, "opacity", "0.5");
	}

	[Test]
	public static void ThePropertyTableNamesEachLonghandOnce()
	{
		Test.Assert(AllStyleProperties().Length == 113);
		let color = FindStyleProperty("color");
		Test.Assert((color != null) && (color.Grammar == .Color) && color.Inherited && (color.Initial === null));
		let opacity = FindStyleProperty("opacity");
		Test.Assert((opacity != null) && (opacity.Initial == "1") && !opacity.Inherited);
		Test.Assert(FindStyleProperty("margin") == null); // a shorthand, not a longhand
		Test.Assert(IsPaintOnlyStyleProperty("opacity") && !IsPaintOnlyStyleProperty("width"));
	}
}
