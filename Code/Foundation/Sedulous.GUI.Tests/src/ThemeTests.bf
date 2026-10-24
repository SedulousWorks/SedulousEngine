using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A resource provider that hands out one image, recording the requested path.
class ThemeResources : IResourceProvider
{
	public OwnedImageData Img ~ delete _;
	public String LastPath = new .() ~ delete _;

	public this()
	{
		uint8[16] pixels = .(255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255);
		Img = new OwnedImageData(2, 2, .RGBA8, Span<uint8>(&pixels[0], 16));
	}

	public override ImageData LoadImage(StringView path)
	{
		LastPath.Set(path);
		return Img;
	}

	public override bool LoadText(StringView path, String outText) => false;

	public override SVGDocument LoadSvg(StringView path) => null;
}

/// A font service that hands out one font (the mock's), recording the requested family and size.
class ThemeFontService : IFontService
{
	public CachedFont Font = new .(new MockFont(), null) ~ delete _;
	public String LastFamily = new .() ~ delete _;
	public float LastSize = 0.0f;

	public override CachedFont GetFont(float pixelHeight) => Font;

	public override CachedFont GetFont(StringView familyName, float pixelHeight)
	{
		LastFamily.Set(familyName);
		LastSize = pixelHeight;
		return Font;
	}

	public override ImageData GetAtlasTexture(CachedFont font) => null;
	public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight) => null;
	public override void ReleaseFont(CachedFont font) { }
	public override void GetDefaultFontFamily(String outFamily) { outFamily.Append("mock"); }
	public override bool HasFamily(StringView familyName) => false;
}

/// The theme's sheets: a widget part's (::part) rules resolved apart from the widget's own, and a
/// sheet's colours, pictures and fonts reaching a label.
class ThemeTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new label styled by `css` (with `resources` when given), held by the caller.
	private static Label ApplyCSS(StringView css, IResourceProvider resources = null)
	{
		let label = new Label();
		let manager = scope StyleManager();
		WidgetFixtures.UseSheet(manager, css);
		if (resources != null)
			manager.ResourceProvider = resources;
		manager.ApplyTo(label);
		return label;
	}
	[Test]
	public static void PseudoElementPartRulesResolveSeparatelyFromTheElementStyle()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.Tag = "slider";
		let sheet = scope StyleSheet();
		CSSParser.Parse("slider { background-color: #00ff00; } " +
			"slider::fill { background-color: #ff0000; } " +
			"slider::thumb { background-color: #0000ff; }", sheet);

		// The element's own style has only the non-pseudo declaration.
		let main = scope ResolvedStyle();
		sheet.Resolve(w, main);
		Test.Assert(main.Get("background-color") == "#00ff00");

		// Each part resolves its own cascade.
		let fill = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "fill", null, fill);
		Test.Assert(fill.Get("background-color") == "#ff0000");
		let thumb = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "thumb", null, thumb);
		Test.Assert(thumb.Get("background-color") == "#0000ff");

		// A part with no rule resolves to nothing.
		let none = scope ResolvedStyle();
		sheet.Resolve(w, MediaContext(), true, "track", null, none);
		Test.Assert(!none.Has("background-color"));
	}

	[Test]
	public static void TheDefaultThemeCarriesPseudoElementPartRules()
	{
		// Sanity: the built-in themes actually contain ::part rules a Slider/Window can pick up.
		// A part inherits its widget's style (its tokens, from :root).
		let dark = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, dark);
		let slider = new UIWidget();
		defer slider.ReleaseRef();
		slider.Tag = "slider";
		let sliderStyle = scope ResolvedStyle();
		dark.Resolve(slider, MediaContext(), sliderStyle);
		let fill = scope ResolvedStyle();
		dark.Resolve(slider, MediaContext(), true, "fill", sliderStyle, fill);
		Test.Assert(fill.Has("background-color"));

		let window = new UIWidget();
		defer window.ReleaseRef();
		window.Tag = "window";
		let windowStyle = scope ResolvedStyle();
		dark.Resolve(window, MediaContext(), windowStyle);
		let title = scope ResolvedStyle();
		dark.Resolve(window, MediaContext(), true, "title", windowStyle, title);
		Test.Assert(title.Has("background-color"));
	}

	[Test]
	public static void ParseUrlStripsTheUrlWrapperAndQuotes()
	{
		Test.Assert(ParseUrl("url(panel)") == "panel");
		Test.Assert(ParseUrl("url('a/b.png')") == "a/b.png");
		Test.Assert(ParseUrl("plain") == "plain");
	}

	[Test]
	public static void ColorStylesALabelsTextColor()
	{
		let label = ApplyCSS("label { color: #ff8800; }");
		defer label.ReleaseRef();
		Test.Assert(Near(label.TextColor.R, 1.0f));
		Test.Assert(Near(label.TextColor.G, 0x88 / 255.0f));
		Test.Assert(Near(label.TextColor.B, 0.0f));
	}

	[Test]
	public static void BackgroundImageLoadsViaTheProviderIntoABoxLayer()
	{
		let res = scope ThemeResources();
		let label = ApplyCSS("label { background-image: url(panel); }", res);
		defer label.ReleaseRef();
		Test.Assert(res.LastPath == "panel");
		// The provider's raw image becomes a layer of the label's box.
		Test.Assert(label.Box.Layers.Count == 1);
		Test.Assert(label.Box.Layers[0].IsImage);
		Test.Assert(label.Box.Layers[0].Image === res.Img);
	}

	[Test]
	public static void FontFamilyAndFontSizeResolveAFontViaTheFontService()
	{
		let fs = scope ThemeFontService();
		let label = new Label();
		defer label.ReleaseRef();
		let manager = scope StyleManager();
		WidgetFixtures.UseSheet(manager, "label { font-family: Roboto; font-size: 18; }");
		manager.FontService = fs;
		manager.ApplyTo(label);

		Test.Assert(fs.LastFamily == "Roboto");
		Test.Assert(Near(fs.LastSize, 18.0f));
		Test.Assert(label.Font === fs.Font);
	}

	[Test]
	public static void WithoutProvidersResourcePropertiesAreSkippedNoCrash()
	{
		let label = ApplyCSS("label { background-image: url(panel); font-family: Roboto; color: #ffffff; }");
		defer label.ReleaseRef();
		Test.Assert(label.Box.Layers.IsEmpty); // no provider -> background-image ignored
		Test.Assert(Near(label.TextColor.R, 1.0f)); // color still applied
	}

	[Test]
	public static void APartTakesAColourForAPartThatIsTextACodeEditorsKeyword()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		root.AddChild(slider);
		let manager = scope StyleManager();
		WidgetFixtures.UseSheet(manager, "slider::thumb { color: #ff8000; }");
		manager.ApplyTree(root);
		let thumb = slider.GetPartStyle("thumb");
		Test.Assert(thumb.HasColor);
		Test.Assert(Near(thumb.TextColor.R, 1.0f));
		Test.Assert(NodeFixtures.Near(thumb.TextColor.G, 0x80 / 255.0f, 0.01f));
		Test.Assert(!slider.GetPartStyle("fill").HasColor);
	}

	[Test]
	public static void TokensRetintEverythingASubtreeOverridesThemAndAWidgetTokenChangesOneControl()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let page = new Panel();
		defer page.ReleaseRef();
		let inside = new Button();
		defer inside.ReleaseRef();
		let outside = new Button();
		defer outside.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		root.AddChild(page);
		root.AddChild(outside);
		root.AddChild(slider);
		page.AddChild(inside);
		page.AddClass("special");
		let mgr = scope StyleManager();
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		mgr.UserAgentSheet = theme;
		// A game's sheet: the base accent retinted, a subtree's own accent, and one widget token.
		WidgetFixtures.UseSheet(mgr, ":root { --accent: #ff0000; --slider-fill: #00ff00; } .special { --accent: #0000ff; }");
		mgr.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(outside.Box.BackgroundColor.R, 1.0f));
		Test.Assert(NodeFixtures.Near(inside.Box.BackgroundColor.B, 1.0f)); // the subtree's
		Test.Assert(NodeFixtures.Near(slider.GetPartStyle("fill").Box.BackgroundColor.G, 1.0f)); // one control's token
		// A part with no override reads its widget token through to the base one.
		Test.Assert(slider.GetPartStyle("track").HasBackground);
	}
}
