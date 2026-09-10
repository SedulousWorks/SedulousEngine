using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// The theme data types: the palettes, the icon set, the atlas that packs a themed image set,
/// and the font family resolution that runs through the font service.
class ThemeAndFontTests
{
	private static bool Near(float a, float b, float epsilon = 0.005f) => Abs(a - b) <= epsilon;

	private static ImageData MakeTestImage(uint32 width, uint32 height,
		uint8 r, uint8 g, uint8 b)
	{
		let pixels = new uint8[width * height * 4];
		defer delete pixels;
		for (uint32 i < width * height)
		{
			pixels[i * 4] = r;
			pixels[i * 4 + 1] = g;
			pixels[i * 4 + 2] = b;
			pixels[i * 4 + 3] = 255;
		}
		return new OwnedImageData(width, height, .RGBA8, .(&pixels[0], pixels.Count), .Linear);
	}

	// ---- ThemePalette -----------------------------------------------------------------------

	/// The two base palettes are recognisably dark and light, and their text CONTRASTS with
	/// their background, which is the one property a palette cannot get wrong.
	[Test]
	public static void TheDarkAndLightPalettesContrastTheirOwnText()
	{
		let dark = ThemePalette.Dark();
		Test.Assert(dark.Background.R < 50 / 255.0f);
		Test.Assert(dark.Background.G < 50 / 255.0f);
		Test.Assert(dark.Background.B < 50 / 255.0f);
		Test.Assert(dark.Text.R > 200 / 255.0f, "light text on a dark ground");

		let light = ThemePalette.Light();
		Test.Assert(light.Background.R > 200 / 255.0f);
		Test.Assert(light.Background.G > 200 / 255.0f);
		Test.Assert(light.Background.B > 200 / 255.0f);
		Test.Assert(light.Text.R < 100 / 255.0f, "dark text on a light ground");
	}

	/// The graphite palette is a WARM dark: red at least green at least blue through the
	/// neutrals, with an orange accent. That ordering is what separates warm from cool, and it
	/// is the whole identity of the palette.
	[Test]
	public static void TheGraphitePaletteIsAWarmDarkWithAnOrangeAccent()
	{
		let palette = ThemePalette.GraphiteOrange();

		Test.Assert(palette.Background.R < 50 / 255.0f);
		Test.Assert(palette.Background.R >= palette.Background.G);
		Test.Assert(palette.Background.G >= palette.Background.B);

		Test.Assert(palette.PrimaryAccent.R > 200 / 255.0f);
		Test.Assert(palette.PrimaryAccent.B < palette.PrimaryAccent.G);
		Test.Assert(palette.PrimaryAccent.G < palette.PrimaryAccent.R);

		Test.Assert(palette.Text.R > 200 / 255.0f);
	}

	// ---- ThemeIconSet -----------------------------------------------------------------------

	/// An INITIALISED set shares one baked instance per glyph, and dedupes per tint. The host
	/// bakes once and every theme gets the same crisp drawable.
	[Test]
	public static void AnInitialisedIconSetSharesOneInstancePerGlyph()
	{
		let set = ThemeIconSet.Get();
		set.Initialize();
		defer set.Shutdown(); // hygiene: later tests must see the uninitialised behaviour

		let first = ThemeIconSet.Acquire(.Close);
		defer first.ReleaseRef();
		let second = ThemeIconSet.Acquire(.Close);
		defer second.ReleaseRef();
		Test.Assert(first == second, "shared, not re-parsed");

		let tint = Color(0.2f, 0.3f, 0.4f, 1.0f);
		let tinted = ThemeIconSet.Acquire(.Close, tint);
		defer tinted.ReleaseRef();
		let tintedAgain = ThemeIconSet.Acquire(.Close, tint);
		defer tintedAgain.ReleaseRef();

		Test.Assert(tinted == tintedAgain, "the same glyph and tint dedupe");
		Test.Assert(tinted != first, "but a tinted variant is its own instance");

		let bakeable = scope List<BakedSVGDrawable>();
		set.CollectBakeable(bakeable);
		Test.Assert(bakeable.Count == ThemeIconSet.cGlyphCount + 1, "ten base plus one tinted");
	}

	/// An UNINITIALISED set still hands out something, a fresh unbaked fallback each time, so a
	/// headless run or a test gets a drawable rather than a null.
	[Test]
	public static void AnUninitialisedIconSetHandsOutFreshFallbacks()
	{
		let set = ThemeIconSet.Get();
		set.Shutdown(); // whatever the test order was

		let first = ThemeIconSet.Acquire(.Close);
		defer first.ReleaseRef();
		let second = ThemeIconSet.Acquire(.Close);
		defer second.ReleaseRef();

		Test.Assert(first != null);
		Test.Assert(first != second, "distinct instances, not shared");
	}

	// ---- ThemeAtlas -------------------------------------------------------------------------

	/// Packing happens at BUILD: a drawable asked for before that has no atlas region to point
	/// at, so it is null rather than a drawable pointing nowhere.
	[Test]
	public static void AnAtlasHandsOutNothingBeforeItIsBuilt()
	{
		let atlas = new ThemeAtlas();
		defer atlas.ReleaseRef();

		Test.Assert(atlas.CreateImageDrawable("missing") == null);
	}

	[Test]
	public static void ABuiltAtlasCreatesImageAndNineSliceDrawables()
	{
		let atlas = new ThemeAtlas();
		defer atlas.ReleaseRef();
		let image = MakeTestImage(32, 32, 255, 0, 0);
		defer delete image;

		atlas.AddImage("button", image);
		atlas.AddImage("panel", image);
		Test.Assert(atlas.Build());

		let plain = atlas.CreateImageDrawable("button");
		defer plain.ReleaseRef();
		Test.Assert(plain != null);
		Test.Assert(plain.AtlasImage != null);

		let sliced = atlas.CreateNineSliceDrawable("panel", NineSlice(4, 4, 4, 4));
		defer sliced.ReleaseRef();
		Test.Assert(sliced != null);
		Test.Assert(sliced.Slices.Left == 4);
	}

	[Test]
	public static void AnAtlasBuildsAStateDrawableFromItsPackedImages()
	{
		let atlas = new ThemeAtlas();
		defer atlas.ReleaseRef();
		let normal = MakeTestImage(16, 16, 200, 200, 200);
		defer delete normal;
		let hover = MakeTestImage(16, 16, 220, 220, 220);
		defer delete hover;

		atlas.AddImage("btn_normal", normal);
		atlas.AddImage("btn_hover", hover);
		Test.Assert(atlas.Build());

		let states = scope StateImageEntry[](
			StateImageEntry(.Normal, "btn_normal"),
			StateImageEntry(.Hover, "btn_hover"));
		let drawable = atlas.CreateStateDrawable(states);
		defer drawable.ReleaseRef();

		Test.Assert(drawable != null);
	}

	/// Several images of different sizes all pack, which is what an atlas is for: one texture
	/// and one bind for a whole theme's chrome.
	[Test]
	public static void SeveralImagesOfDifferentSizesAllPack()
	{
		let atlas = new ThemeAtlas();
		defer atlas.ReleaseRef();
		let big = MakeTestImage(64, 64, 255, 0, 0);
		defer delete big;
		let small = MakeTestImage(32, 32, 0, 255, 0);
		defer delete small;
		let middling = MakeTestImage(48, 48, 0, 0, 255);
		defer delete middling;

		atlas.AddImage("red", big);
		atlas.AddImage("green", small);
		atlas.AddImage("blue", middling);
		Test.Assert(atlas.Build());

		let first = atlas.CreateImageDrawable("red");
		defer first.ReleaseRef();
		let second = atlas.CreateImageDrawable("green");
		defer second.ReleaseRef();
		let third = atlas.CreateImageDrawable("blue");
		defer third.ReleaseRef();

		Test.Assert(first != null);
		Test.Assert(second != null);
		Test.Assert(third != null);
	}

	// ---- ThemeImageSet ----------------------------------------------------------------------

	[Test]
	public static void AnImageSetRemembersWhetherAnEntryIsNineSliced()
	{
		let set = scope ThemeImageSet();
		let plain = MakeTestImage(16, 16, 255, 0, 0);
		defer delete plain;
		let sliced = MakeTestImage(32, 32, 255, 0, 0);
		defer delete sliced;

		set.AddImage("button:Background", plain);
		let plainEntry = set.GetEntry("button:Background");
		Test.Assert(plainEntry != null);
		Test.Assert(!plainEntry.Value.IsNineSlice);

		set.AddImage("panel:Background", sliced, NineSlice(4, 4, 4, 4));
		let slicedEntry = set.GetEntry("panel:Background");
		Test.Assert(slicedEntry != null);
		Test.Assert(slicedEntry.Value.IsNineSlice);
		Test.Assert(slicedEntry.Value.Slices.Left == 4);
	}

	/// State images are stored under DERIVED keys, one per state, so the atlas packs each and
	/// the state list is assembled from them afterwards.
	[Test]
	public static void StateImagesAreStoredUnderPerStateKeys()
	{
		let set = scope ThemeImageSet();
		let normal = MakeTestImage(16, 16, 200, 200, 200);
		defer delete normal;
		let hover = MakeTestImage(16, 16, 220, 220, 220);
		defer delete hover;

		set.AddStateImages("button:Background", normal, hover);

		Test.Assert(set.GetEntry("button:Background_Normal") != null);
		Test.Assert(set.GetEntry("button:Background_Hover") != null);
	}

	/// A null image is IGNORED rather than stored, so a theme that fails to load one asset does
	/// not leave an entry pointing at nothing.
	[Test]
	public static void ANullImageIsIgnored()
	{
		let set = scope ThemeImageSet();

		set.AddImage("key", null);

		Test.Assert(set.GetEntry("key") == null);
	}

	// ---- Font family resolution ---------------------------------------------------------------

	/// A stub service with a known default family. No unit test uses a real font: glyph
	/// rendering is a sample's concern, and the resolution order is what matters here.
	private class StubFontService : IFontService
	{
		public override CachedFont GetFont(float pixelHeight) => null;
		public override CachedFont GetFont(StringView familyName, float pixelHeight) => null;
		public override ImageData GetAtlasTexture(CachedFont font) => null;
		public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight) => null;
		public override void ReleaseFont(CachedFont font) {}
		public override void GetDefaultFontFamily(String outFamily) => outFamily.Append("StubDefault");
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static StyleSheet SetupSheet(UIContext context)
	{
		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		return sheet;
	}

	/// The resolution order, floor upward: the font service's default, then the cascade, then a
	/// per instance override, with an EMPTY override deferring rather than blanking.
	[Test]
	public static void TheFontFamilyResolvesInOrder()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let fontService = scope StubFontService();
		context.SetFontService(fontService);
		let sheet = SetupSheet(context);

		let unstyled = new TestView(50, 30);
		root.AddView(unstyled);
		let family = scope String();
		unstyled.ResolveStyleFontFamily(family);
		Test.Assert(family == "StubDefault", "the floor");

		sheet.ForType(typeof(TestView)).Set(.FontFamily, "Roboto");
		let styled = new TestView(50, 30);
		root.AddView(styled);
		let cascaded = scope String();
		styled.ResolveStyleFontFamily(cascaded);
		Test.Assert(cascaded == "Roboto", "the cascade beats the floor");

		let overridden = scope String();
		styled.ResolveStyleFontFamily(overridden, "CustomFamily");
		Test.Assert(overridden == "CustomFamily", "an instance override beats the cascade");

		let deferred = scope String();
		styled.ResolveStyleFontFamily(deferred, "");
		Test.Assert(deferred == "Roboto", "an EMPTY override defers rather than blanking");
	}

	[Test]
	public static void AnInlineFontFamilyBeatsTheContextSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		SetupSheet(context).ForType(typeof(TestView)).Set(.FontFamily, "Roboto");

		let view = new TestView(50, 30);
		root.AddView(view);
		view.SetStyle(.FontFamily, "JungleAdventurer");

		let resolved = view.ResolveStyle(.FontFamily);
		Test.Assert(resolved.AsString != null);
		Test.Assert(resolved.AsString.Value == "JungleAdventurer");
	}

	/// The draw path re-asserts the context's CURRENT font service into the VG every frame.
	///
	/// The VG resolves atlases through its OWN service pointer, set when it was built. A game
	/// that swaps the context's service afterwards, binding a cooked font once the project
	/// loads, would leave the VG asking the stale service for atlases of fonts it never
	/// created: null, silently skipped, invisible text in the built game and nothing wrong in
	/// the source tree where the stale service happens to be the working one.
	[Test]
	public static void DrawingReAssertsTheContextsFontService()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let atConstruction = scope StubFontService();
		let swappedIn = scope StubFontService();
		let vg = scope VGContext(atConstruction);
		context.SetFontService(swappedIn); // the swap happens after the VG was built

		context.DrawRootView(root, vg);

		Test.Assert(vg.FontService == swappedIn, "the draw re-asserted the truth");
	}
}
