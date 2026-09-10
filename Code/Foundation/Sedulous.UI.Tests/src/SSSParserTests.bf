using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The SSS parser end to end: colours and colour functions, the palette, every drawable
/// factory, the property value kinds, and the @import, @icon and @image directives.
class SSSParserTests
{
	private static bool Near(float a, float b, float epsilon = 0.005f) => Abs(a - b) <= epsilon;

	private static Color Rgb(float r, float g, float b, float a = 255.0f) =>
		.(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);

	private static void EnsureGlobals()
	{
		StyleSheetLoader.InitializeGlobals();
		UITypeRegistry.Register("View", typeof(View));
		UITypeRegistry.Register("TestView", typeof(TestView));
		UITypeRegistry.Register("TestGroup", typeof(TestGroup));
	}

	/// OWNERSHIP of the sheet transfers.
	private static StyleSheet LoadSSS(StringView source)
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	/// A context and root with a sheet installed, and a builder for views under the root.
	private class Fixture
	{
		public UIContext Context = new .() ~ delete _;
		public RootView Root = new .() ~ _.ReleaseRef();

		/// CONSUMES the sheet's reference.
		public this(StyleSheet sheet)
		{
			EnsureGlobals();
			UITest.Init(Context, Root);
			Context.SetStyleSheet(sheet);
		}

		public TestView AddView()
		{
			let view = new TestView(50.0f, 30.0f);
			Root.AddView(view);
			return view;
		}
	}

	/// An in memory resource provider for @import, @icon and @image.
	private class MockResourceProvider : IResourceProvider
	{
		private Dictionary<String, String> mTexts = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
		private Dictionary<String, ImageData> mImages = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public void AddText(StringView path, StringView content)
		{
			mTexts[new String(path)] = new String(content);
		}

		/// A two by two white image, which is enough for a factory to build a drawable around.
		public void AddImage(StringView path)
		{
			uint8[16] pixels = .(255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255);
			mImages[new String(path)] = new OwnedImageData(2, 2, .RGBA8, .(&pixels[0], 16),
				.Linear);
		}

		public bool LoadText(StringView path, String outText)
		{
			if (mTexts.TryGetValueAlt(path, let text))
			{
				outText.Append(text);
				return true;
			}
			return false;
		}

		public ImageData LoadImage(StringView path)
		{
			if (mImages.TryGetValueAlt(path, let image))
				return image;
			return null;
		}
	}

	// ---- Colours ----------------------------------------------------------------------------

	[Test]
	public static void AHexColourParsesAtSixOrEightDigits()
	{
		let six = StyleValueParser.ParseHexColor("#4a8eff");
		Test.Assert(six != null);
		Test.Assert(Near(six.Value.R, 0x4a / 255.0f));
		Test.Assert(Near(six.Value.G, 0x8e / 255.0f));
		Test.Assert(six.Value.B == 1.0f);
		Test.Assert(six.Value.A == 1.0f, "no alpha digits means opaque");

		let eight = StyleValueParser.ParseHexColor("#4a8effcc");
		Test.Assert(eight != null);
		Test.Assert(Near(eight.Value.R, 0x4a / 255.0f));
		Test.Assert(Near(eight.Value.A, 0xcc / 255.0f));
	}

	[Test]
	public static void ThePaletteDerivationsMoveTheRightWay()
	{
		Test.Assert(Near(Palette.Darken(Rgb(200, 200, 200), 0.5f).R, 100 / 255.0f));
		Test.Assert(Palette.Lighten(Color(0, 0, 0, 1), 0.5f).R > 100 / 255.0f);
	}

	[Test]
	public static void TheColourFunctionsResolveToColours()
	{
		let lightened = scope Fixture(LoadSSS("View { text-color: lighten(#000000, 50%); }"));
		Test.Assert(lightened.AddView().ResolveStyleColor(.TextColor).R > 100 / 255.0f);

		let darkened = scope Fixture(LoadSSS("View { text-color: darken(#ffffff, 50%); }"));
		let darkR = darkened.AddView().ResolveStyleColor(.TextColor).R;
		Test.Assert((darkR < 200 / 255.0f) && (darkR > 100 / 255.0f));

		let faded = scope Fixture(LoadSSS("View { text-color: alpha(#ff0000, 0.5); }"));
		let fadedColour = faded.AddView().ResolveStyleColor(.TextColor);
		Test.Assert(fadedColour.R == 1.0f);
		Test.Assert(Near(fadedColour.A, 0.5f));

		let mixed = scope Fixture(LoadSSS("View { text-color: mix(#000000, #ffffff, 0.5); }"));
		let mixedR = mixed.AddView().ResolveStyleColor(.TextColor).R;
		Test.Assert((mixedR > 100 / 255.0f) && (mixedR < 160 / 255.0f));
	}

	[Test]
	public static void ANamedColourAndTheRgbFunctionsParse()
	{
		let named = scope Fixture(LoadSSS("View { text-color: white; }"));
		let white = named.AddView().ResolveStyleColor(.TextColor);
		Test.Assert((white.R == 1.0f) && (white.G == 1.0f) && (white.B == 1.0f));

		let rgb = scope Fixture(LoadSSS("View { text-color: rgb(100, 150, 200); }"));
		let opaque = rgb.AddView().ResolveStyleColor(.TextColor);
		Test.Assert(Near(opaque.R, 100 / 255.0f));
		Test.Assert(Near(opaque.G, 150 / 255.0f));
		Test.Assert(Near(opaque.B, 200 / 255.0f));

		let rgba = scope Fixture(LoadSSS("View { text-color: rgba(100, 150, 200, 0.5); }"));
		let translucent = rgba.AddView().ResolveStyleColor(.TextColor);
		Test.Assert(Near(translucent.R, 100 / 255.0f));
		Test.Assert(Near(translucent.A, 0.5f));
	}

	/// The STATE colour functions must agree exactly with the palette's own maths, since a
	/// sheet and a code built theme have to produce the same colour for the same input.
	///
	/// disabled() is the one that matters: its luminance desaturation is the part lighten and
	/// darken cannot express, so an approximation would drift.
	[Test]
	public static void TheStateColourFunctionsMatchThePaletteExactly()
	{
		let disabled = scope Fixture(LoadSSS("View { text-color: disabled(#6496c8); }"));
		let expected = Palette.ComputeDisabled(Rgb(0x64, 0x96, 0xc8));
		let got = disabled.AddView().ResolveStyleColor(.TextColor, Color.White);
		Test.Assert(Near(got.R, expected.R));
		Test.Assert(Near(got.G, expected.G));
		Test.Assert(Near(got.B, expected.B));

		let hovered = scope Fixture(LoadSSS("View { text-color: hover(#404040); }"));
		let expectedHover = Palette.ComputeHover(Rgb(0x40, 0x40, 0x40));
		Test.Assert(Near(hovered.AddView().ResolveStyleColor(.TextColor, Color.White).R,
			expectedHover.R));
	}

	// ---- Rules and selectors ----------------------------------------------------------------

	[Test]
	public static void ACompoundStateRuleCarriesEveryFlag()
	{
		let sheet = LoadSSS("""
			View { text-color: #ffffff; }
			View:checked:hover { text-color: #ff0000; }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 2);
		let compound = sheet.GetRule(1);
		Test.Assert(compound.Selector.State != null);
		Test.Assert(compound.Selector.State.Value.HasFlag(.Checked));
		Test.Assert(compound.Selector.State.Value.HasFlag(.Hover));
	}

	/// Every property in each family parses, which is what catches a name dropped from the
	/// parser's table rather than from the enum.
	[Test]
	public static void EveryPropertyFamilyParses()
	{
		let drawables = LoadSSS(
			"View { background: color(#111); checked-background: color(#222); menu-item-hover-drawable: color(#333); }");
		defer drawables.ReleaseRef();
		Test.Assert(drawables.RuleCount == 1);
		Test.Assert(drawables.GetRule(0).PropertyCount == 3);

		let colours = LoadSSS("""
			View { text-color: #111; text-dim-color: #222; placeholder-color: #333; border-color: #444;
			       cursor-color: #555; selection-color: #666; accent-color: #777; }
			""");
		defer colours.ReleaseRef();
		Test.Assert(colours.GetRule(0).PropertyCount == 7);

		let floats = LoadSSS(
			"View { font-size: 16; corner-radius: 4; border-width: 1; spacing: 8; opacity: 0.5; width: 100; height: 50; }");
		defer floats.ReleaseRef();
		Test.Assert(floats.GetRule(0).PropertyCount == 7);
	}

	[Test]
	public static void CommentsAreIgnoredWhereverTheySit()
	{
		let sheet = LoadSSS("""
			/* comment */
			View { font-size: 14; /* inline */ }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 1);
	}

	[Test]
	public static void TypeClassAndStateRulesResolveThroughTheTree()
	{
		let byType = scope Fixture(LoadSSS("View { text-color: #ff0000; font-size: 16; }"));
		let typed = byType.AddView();
		let colour = typed.ResolveStyleColor(.TextColor);
		Test.Assert((colour.R == 1.0f) && (colour.G == 0) && (colour.B == 0));
		Test.Assert(Near(typed.ResolveStyleFloat(.FontSize), 16));

		let byClass = scope Fixture(LoadSSS(".primary { font-size: 24; }"));
		let classed = byClass.AddView();
		classed.AddClass("primary");
		Test.Assert(classed.ResolveStyleFloat(.FontSize) == 24.0f);

		let byState = scope Fixture(
			LoadSSS("View { font-size: 12; } View:disabled { font-size: 10; }"));
		let stated = byState.AddView();
		stated.IsEnabled = false;
		Test.Assert(Near(stated.ResolveStyleFloat(.FontSize), 10));
	}

	[Test]
	public static void TheCascadeAndInheritanceHoldForParsedSheets()
	{
		let byClass = scope Fixture(LoadSSS("View { font-size: 12; } .big { font-size: 24; }"));
		let classed = byClass.AddView();
		classed.AddClass("big");
		Test.Assert(classed.ResolveStyleFloat(.FontSize) == 24.0f);

		let byState = scope Fixture(
			LoadSSS("View { text-color: #cccccc; } View:disabled { text-color: #333333; }"));
		let disabled = byState.AddView();
		disabled.IsEnabled = false;
		Test.Assert(Near(disabled.ResolveStyleColor(.TextColor).R, 0x33 / 255.0f));

		let inherited = scope Fixture(LoadSSS("View { text-color: #aabbcc; }"));
		let group = new TestGroup();
		inherited.Root.AddView(group);
		let child = new TestView(50, 30);
		group.AddView(child);
		Test.Assert(Near(child.ResolveStyleColor(.TextColor).R, 0xaa / 255.0f));
	}

	/// Two rules for the same type COMBINE rather than the later one replacing the earlier.
	[Test]
	public static void TwoRulesForOneTypeCombine()
	{
		let fixture = scope Fixture(
			LoadSSS("View { font-size: 12; } View { text-color: #ff0000; }"));
		let view = fixture.AddView();

		Test.Assert(view.ResolveStyleFloat(.FontSize) == 12.0f);
		Test.Assert(view.ResolveStyleColor(.TextColor).R == 1.0f);
	}

	// ---- The palette ------------------------------------------------------------------------

	[Test]
	public static void APaletteBlockDeclaresVariablesForTheSheet()
	{
		let fixture = scope Fixture(LoadSSS("""
			@palette dark { text: #e0e0ee; }
			View { text-color: $text; }
			"""));

		Test.Assert(Near(fixture.AddView().ResolveStyleColor(.TextColor).R, 0xe0 / 255.0f));
	}

	[Test]
	public static void ThemePaletteDarkFeedsTheLoader()
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		loader.SetPalette(ThemePalette.Dark());

		let fixture = scope Fixture(loader.Load("View { text-color: $text; }"));

		Test.Assert(Near(fixture.AddView().ResolveStyleColor(.TextColor).R, 220 / 255.0f));
	}

	/// `extends base` INHERITS the loader's pre set variables, so a theme can add to what the
	/// host already established rather than restating it.
	[Test]
	public static void APaletteExtendingBaseInheritsTheLoadersValues()
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		loader.SetPaletteVariable("base-bg", Rgb(40, 40, 50));
		loader.SetPaletteVariable("base-text", Rgb(220, 220, 230));

		let fixture = scope Fixture(loader.Load("""
			@palette custom extends base { accent: #ff8800; }
			View { text-color: $base-text; accent-color: $accent; background: color($base-bg); }
			"""));
		let view = fixture.AddView();

		Test.Assert(Near(view.ResolveStyleColor(.TextColor).R, 220 / 255.0f), "from the loader");

		let accent = view.ResolveStyleColor(.AccentColor);
		Test.Assert(accent.R == 1.0f, "from the @palette block");
		Test.Assert(Near(accent.G, 0x88 / 255.0f));

		let background = view.ResolveStyleDrawable(.Background) as ColorDrawable;
		Test.Assert(background != null);
		Test.Assert(Near(background.Color.R, 40 / 255.0f), "the loader's value inside a drawable");
	}

	// ---- Drawable factories -----------------------------------------------------------------

	[Test]
	public static void TheBasicDrawableFactoriesBuildTheirTypes()
	{
		let colour = scope Fixture(LoadSSS("View { background: color(#336699); }"));
		Test.Assert(colour.AddView().ResolveStyleDrawable(.Background) is ColorDrawable);

		let stateList = scope Fixture(LoadSSS(
			"View { background: state-list(normal=color(#111111), hover=color(#222222), pressed=color(#333333)); }"));
		Test.Assert(stateList.AddView().ResolveStyleDrawable(.Background) is StateListDrawable);

		let layered = scope Fixture(
			LoadSSS("View { background: layer(color(#111111), color(#222222)); }"));
		Test.Assert(layered.AddView().ResolveStyleDrawable(.Background) is LayerDrawable);

		let stateColours = scope Fixture(
			LoadSSS("View { background: state-colors(#334455); }"));
		Test.Assert(stateColours.AddView().ResolveStyleDrawable(.Background) is StateListDrawable);

		let stateRounded = scope Fixture(
			LoadSSS("View { background: state-rounded(#334455, radius=4); }"));
		Test.Assert(stateRounded.AddView().ResolveStyleDrawable(.Background) is StateListDrawable);
	}

	[Test]
	public static void RoundedRectCarriesItsFillBorderAndRadius()
	{
		let fixture = scope Fixture(LoadSSS(
			"View { background: rounded-rect(#336699, radius=6, border=#555555, border-width=1); }"));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as RoundedRectDrawable;
		Test.Assert(drawable != null);
		Test.Assert(Near(drawable.FillColor.R, 0x33 / 255.0f));
		Test.Assert(drawable.BorderWidth == 1.0f);
	}

	/// A per corner radius: four values in the order CSS uses.
	[Test]
	public static void RoundedRectAcceptsAPerCornerRadius()
	{
		let fixture = scope Fixture(
			LoadSSS("View { background: rounded-rect(#336699, radius=1 2 3 4); }"));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as RoundedRectDrawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Radii.TopLeft == 1.0f);
		Test.Assert(drawable.Radii.TopRight == 2.0f);
		Test.Assert(drawable.Radii.BottomRight == 3.0f);
		Test.Assert(drawable.Radii.BottomLeft == 4.0f);
	}

	[Test]
	public static void AGradientKeepsItsDirection()
	{
		let fixture = scope Fixture(
			LoadSSS("View { background: gradient(left-to-right, #000000, #ffffff); }"));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as GradientDrawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Direction == .LeftToRight);
	}

	[Test]
	public static void AnInsetDrawableKeepsItsInset()
	{
		let fixture = scope Fixture(
			LoadSSS("View { background: inset(color(#336699), 4, 4, 4, 4); }"));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as InsetDrawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Inset.Top == 4);
	}

	/// A bare colour literal in a drawable slot becomes a ColorDrawable, so `background: #333`
	/// works without spelling out `color(...)`.
	[Test]
	public static void ABareColourLiteralBecomesAColourDrawable()
	{
		let fixture = scope Fixture(LoadSSS("View { background: #336699; }"));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as ColorDrawable;
		Test.Assert(drawable != null);
		Test.Assert(Near(drawable.Color.R, 0x33 / 255.0f));
	}

	/// `background-color` stores a raw COLOR rather than a drawable, which a control resolving
	/// through ResolveStyleColor needs: plain `background:` always builds a drawable, and that
	/// path would simply not see it.
	[Test]
	public static void BackgroundColourStoresAColourNotADrawable()
	{
		let fixture = scope Fixture(LoadSSS("View { background-color: #6496c8; }"));
		let view = fixture.AddView();

		Test.Assert(view.ResolveStyleDrawable(.Background) == null);

		let colour = view.ResolveStyleColor(.Background, Color.White);
		Test.Assert(Near(colour.R, 0x64 / 255.0f));
		Test.Assert(Near(colour.G, 0x96 / 255.0f));
		Test.Assert(Near(colour.B, 0xc8 / 255.0f));
	}

	[Test]
	public static void APaletteVariableReachesInsideADrawableFactory()
	{
		let fixture = scope Fixture(LoadSSS("""
			@palette dark { surface: #24242c; border: #3a3a45; }
			View { background: rounded-rect($surface, radius=6, border=$border, border-width=1); }
			"""));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as RoundedRectDrawable;
		Test.Assert(drawable != null);
		Test.Assert(Near(drawable.FillColor.R, 0x24 / 255.0f));
		Test.Assert(Near(drawable.BorderColor.R, 0x3a / 255.0f));
	}

	// ---- Property value kinds ---------------------------------------------------------------

	/// A thickness takes one, two or four values, in the CSS order.
	[Test]
	public static void AThicknessTakesOneTwoOrFourValues()
	{
		let single = scope Fixture(LoadSSS("View { padding: 8; }"));
		let uniform = single.AddView().ResolveStyleThickness(.Padding);
		Test.Assert((uniform.Left == 8) && (uniform.Top == 8)
			&& (uniform.Right == 8) && (uniform.Bottom == 8));

		let pair = scope Fixture(LoadSSS("View { padding: 8 12; }"));
		let pairs = pair.AddView().ResolveStyleThickness(.Padding);
		Test.Assert(pairs.Top == 8, "vertical first");
		Test.Assert(pairs.Left == 12, "then horizontal");

		let all = scope Fixture(LoadSSS("View { padding: 1 2 3 4; }"));
		let sides = all.AddView().ResolveStyleThickness(.Padding);
		Test.Assert((sides.Top == 1) && (sides.Right == 2)
			&& (sides.Bottom == 3) && (sides.Left == 4));
	}

	[Test]
	public static void BoolAndFloatPropertiesParse()
	{
		let flag = scope Fixture(LoadSSS("View { word-wrap: true; }"));
		let wrap = flag.AddView().ResolveStyle(.WordWrap).AsBool;
		Test.Assert(wrap != null);
		Test.Assert(wrap.Value == true);

		let number = scope Fixture(LoadSSS("View { corner-radius: 6; }"));
		Test.Assert(number.AddView().ResolveStyleFloat(.CornerRadius) == 6.0f);
	}

	/// A font family takes a QUOTED string, so it can contain spaces, or a bare identifier when
	/// it does not need to.
	[Test]
	public static void AFontFamilyTakesAQuotedStringOrABareIdentifier()
	{
		let quoted = scope Fixture(LoadSSS("View { font-family: \"Attack Of Monster\"; }"));
		// Held in a NAMED local: AsString borrows into the value.
		let quotedValue = quoted.AddView().ResolveStyle(.FontFamily);
		Test.Assert(quotedValue.AsString != null);
		Test.Assert(quotedValue.AsString.Value == "Attack Of Monster");

		let bare = scope Fixture(LoadSSS("View { font-family: JungleAdventurer; }"));
		let bareValue = bare.AddView().ResolveStyle(.FontFamily);
		Test.Assert(bareValue.AsString != null);
		Test.Assert(bareValue.AsString.Value == "JungleAdventurer");
	}

	// ---- Inline styles through the parser ---------------------------------------------------

	/// A regression: ApplyInlineStyle has to register the drawable factories ITSELF. Without
	/// them the value is not recognised and falls back to a plain white colour, which looks
	/// like a theme bug rather than a parse failure.
	[Test]
	public static void AnInlineStyleBuildsADrawableRatherThanFallingBack()
	{
		EnsureGlobals();
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		SSSParser.ApplyInlineStyle(view,
			"background: rounded-rect(rgb(35, 38, 48), radius=12, border-width=2, border=rgb(80, 90, 110));");

		let drawable = view.ResolveStyleDrawable(.Background) as RoundedRectDrawable;
		Test.Assert(drawable != null, "not a fallback colour drawable");
		Test.Assert(Near(drawable.FillColor.R, 35 / 255.0f));
		Test.Assert(Near(drawable.FillColor.G, 38 / 255.0f));
		Test.Assert(Near(drawable.FillColor.B, 48 / 255.0f));
		Test.Assert(drawable.Radii.TopLeft == 12.0f);
		Test.Assert(drawable.BorderWidth == 2.0f);
		Test.Assert(Near(drawable.BorderColor.R, 80 / 255.0f));
	}

	// ---- SVG --------------------------------------------------------------------------------

	private const String cCheckmarkSvg = """
		<svg viewBox="0 0 16 16">
		  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
		</svg>
		""";

	[Test]
	public static void AnSvgFactoryResolvesAPreRegisteredGlyphWithAnOptionalTint()
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		loader.RegisterSvg("checkmark", cCheckmarkSvg);

		let fixture = scope Fixture(loader.Load("""
			TestView::checkmark { background: svg(checkmark); }
			TestView::tinted { background: svg(checkmark, tint=#ff0000); }
			"""));
		let view = fixture.AddView();

		Test.Assert(view.ResolvePartDrawable("checkmark", .Background, .Normal) is SVGDrawable);

		let tinted = view.ResolvePartDrawable("tinted", .Background, .Normal) as SVGDrawable;
		Test.Assert(tinted != null);
		Test.Assert(tinted.TintColor != null);
		Test.Assert(tinted.TintColor.Value.R == 1.0f);
	}

	/// An unknown glyph with no provider fails GRACEFULLY: the sheet still parses and the rest
	/// of it still works.
	[Test]
	public static void AnUnknownSvgGlyphDoesNotFault()
	{
		let fixture = scope Fixture(
			LoadSSS("TestView::checkmark { background: svg(missing); font-size: 11; }"));
		let view = fixture.AddView();

		view.ResolvePartDrawable("checkmark", .Background, .Normal);
		Test.Assert(view.ResolvePartFloat("checkmark", .FontSize, .Normal) == 11.0f,
			"the rest of the rule survived");
	}

	/// A BUILT IN glyph name resolves with no registration at all, so a cooked theme does not
	/// silently get nothing where a host that pre-registered names would get an icon.
	[Test]
	public static void ABuiltInGlyphResolvesWithoutRegistration()
	{
		let fixture = scope Fixture(LoadSSS("View { background: svg(close); }"));

		Test.Assert(fixture.AddView().ResolveStyleDrawable(.Background) is SVGDrawable);
	}

	/// With the icon set live, the same name resolves to the SHARED baked instance rather than
	/// a fresh parse. Identity is what proves it took the crisp path.
	[Test]
	public static void ABuiltInGlyphSharesTheBakedInstance()
	{
		ThemeIconSet.Get().Initialize();
		defer ThemeIconSet.Get().Shutdown();

		let fixture = scope Fixture(LoadSSS("View { background: svg(close); }"));
		let background = fixture.AddView().ResolveStyleDrawable(.Background);

		let shared = ThemeIconSet.Acquire(.Close);
		defer shared.ReleaseRef();
		Test.Assert(background == shared);
	}

	// ---- Resource directives ----------------------------------------------------------------

	[Test]
	public static void ImportPullsRulesFromTheProvider()
	{
		EnsureGlobals();
		let provider = scope MockResourceProvider();
		provider.AddText("extra.sss", "TestView { padding: 6 12; }");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;
		let sheet = loader.Load("""
			View { font-size: 14; }
			@import "extra.sss";
			""");

		Test.Assert(sheet.RuleCount == 2, "one from the main sheet, one from the import");

		let fixture = scope Fixture(sheet);
		let padding = fixture.AddView().ResolveStyleThickness(.Padding);
		Test.Assert(padding.Top == 6);
		Test.Assert(padding.Left == 12);
	}

	/// WITHOUT a provider, @import is skipped silently rather than failing the parse: a sheet
	/// that mentions a file is still useful for everything else it declares.
	[Test]
	public static void ImportWithoutAProviderIsSkippedNotFatal()
	{
		let sheet = LoadSSS("""
			@import "nonexistent.sss";
			View { font-size: 14; }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 1);
	}

	[Test]
	public static void IconLoadsItsSvgThroughTheProvider()
	{
		EnsureGlobals();
		let provider = scope MockResourceProvider();
		provider.AddText("icons/check.svg", cCheckmarkSvg);

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;
		let fixture = scope Fixture(loader.Load("""
			@icon checkmark "icons/check.svg";
			TestView::checkmark { background: svg(checkmark); }
			"""));

		Test.Assert(fixture.AddView().ResolvePartDrawable("checkmark", .Background, .Normal)
			is SVGDrawable);
	}

	[Test]
	public static void ImageAndNineSliceLoadThroughTheProvider()
	{
		EnsureGlobals();
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/bg.png");
		provider.AddImage("textures/panel.png");
		provider.AddImage("textures/btn.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;
		let fixture = scope Fixture(loader.Load("""
			@image bg "textures/bg.png";
			@image panel "textures/panel.png";
			@image btn "textures/btn.png";
			View { background: image(bg); }
			TestView::sliced { background: nine-slice(panel, 4 4 4 4); }
			TestView::uniform { background: nine-slice(btn, 8); }
			"""));
		let view = fixture.AddView();

		Test.Assert(view.ResolveStyleDrawable(.Background) is ImageDrawable);
		Test.Assert(view.ResolvePartDrawable("sliced", .Background, .Normal) is NineSliceDrawable);
		Test.Assert(view.ResolvePartDrawable("uniform", .Background, .Normal)
			is NineSliceDrawable, "a single slice value applies to every edge");
	}

	[Test]
	public static void AnImageCanBeTinted()
	{
		EnsureGlobals();
		let provider = scope MockResourceProvider();
		provider.AddImage("textures/icon.png");

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;
		let fixture = scope Fixture(loader.Load("""
			@image icon "textures/icon.png";
			View { background: image(icon, tint=#ff0000); }
			"""));

		let drawable = fixture.AddView().ResolveStyleDrawable(.Background) as ImageDrawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Tint.R == 1.0f);
		Test.Assert(drawable.Tint.G == 0);
	}

	[Test]
	public static void APreRegisteredImageNeedsNoProvider()
	{
		EnsureGlobals();
		uint8[16] pixels = .(255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 0, 255);
		let imageData = scope OwnedImageData(2, 2, .RGBA8, .(&pixels[0], 16), .Linear);

		let loader = scope StyleSheetLoader();
		loader.RegisterImage("test-img", imageData);

		let fixture = scope Fixture(loader.Load("View { background: image(test-img); }"));

		Test.Assert(fixture.AddView().ResolveStyleDrawable(.Background) is ImageDrawable);
	}
}
