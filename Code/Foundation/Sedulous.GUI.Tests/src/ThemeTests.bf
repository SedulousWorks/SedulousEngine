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

/// The theme's sheets: a widget part's (::part) rules resolved apart from the widget's own, a
/// sheet's colours, pictures and fonts reaching a label, every widget with text, and the faces
/// widgets draw for themselves; the default theme restyling the standard widgets, its tokens
/// following the user's scheme, and a skin's radius token rounding its control.
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

	[Test]
	public static void EveryWidgetWithTextTakesTheSheetsFont()
	{
		// A widget that keeps its text in parts (rows, a title, tab buttons) still takes font-family:
		// the sandbox's list showed empty rows when its ListBox did not.
		let fs = scope ThemeFontService();
		let mgr = scope StyleManager();
		WidgetFixtures.UseSheet(mgr, "listbox, menubar, tabview, window, messagebox, tooltip { font-family: Roboto; font-size: 15; }");
		mgr.FontService = fs;
		let list = new ListBox();
		defer list.ReleaseRef();
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		let tabs = new TabView();
		defer tabs.ReleaseRef();
		tabs.AddPage("One");
		let window = new Window();
		defer window.ReleaseRef();
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		let tip = new Tooltip();
		defer tip.ReleaseRef();
		UIWidget[6] widgets = .(list, bar, tabs, window, dialog, tip);
		for (let widget in widgets)
			mgr.ApplyTo(widget);
		Test.Assert(list.Font === fs.Font);
		Test.Assert(bar.Font === fs.Font);
		Test.Assert(tabs.Font === fs.Font);
		Test.Assert(tabs.Bar.GetTab(0).Font === fs.Font); // its tabs take it
		Test.Assert(window.Font === fs.Font);
		Test.Assert(dialog.Font === fs.Font);
		Test.Assert(tip.Font === fs.Font);
	}

	[Test]
	public static void AWidgetsOwnFaceGivesWayToASheetsMenusTheirBarTooltipsScrollbars()
	{
		// Their faces were drawings over the box, so a theme's colour (the light theme's) lay beneath
		// them unseen; each is now its own box, which a sheet's replaces.
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let menu = new Menu();
		defer menu.ReleaseRef();
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		let tooltip = new Tooltip();
		defer tooltip.ReleaseRef();
		let scrollbar = new ScrollBar();
		defer scrollbar.ReleaseRef();
		UIWidget[4] widgets = .(menu, bar, tooltip, scrollbar);
		for (let w in widgets)
		{
			root.AddChild(w);
			Test.Assert(w.BoxFills); // its own face, unstyled
		}
		let mgr = scope StyleManager();
		WidgetFixtures.UseSheet(mgr, "menu, menubar, tooltip, scrollbar { background-color: #ff0000; }");
		mgr.ApplyTree(root);
		for (let w in widgets)
		{
			Test.Assert(Near(w.Box.BackgroundColor.R, 1.0f), scope String(w.Tag));
			Test.Assert(Near(w.Box.BackgroundColor.G, 0.0f), scope String(w.Tag));
		}
	}

	[Test]
	public static void TheBuiltInDefaultThemeRestylesTheStandardWidgets()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		let textfield = new TextField();
		defer textfield.ReleaseRef();
		root.AddChild(button);
		root.AddChild(textfield);

		let mgr = scope StyleManager();
		WidgetFixtures.UseSheet(mgr, Theme.DefaultThemeCSS);
		mgr.ApplyTree(root);

		// The theme gives the button a background and padding, and the field padding.
		Test.Assert(button.Box.BackgroundColor.A > 0.0f);
		Test.Assert(Near(button.Padding.Left, 9.0f));
		Test.Assert(textfield.Box.BackgroundColor.A > 0.0f);
		Test.Assert(Near(textfield.Padding.Left, 6.0f));

		// Its tokens: the dark accent, then (the user's scheme light) the light one, from the same sheet.
		Test.Assert(NodeFixtures.Near(button.Box.BackgroundColor.R, 0x33 / 255.0f, 0.01f));
		var light = MediaContext();
		light.DarkScheme = false;
		mgr.MediaContext = light;
		mgr.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(button.Box.BackgroundColor.R, 0xcd / 255.0f, 0.01f));
	}

	[Test]
	public static void ASkinsRadiusTokenRoundsItsControlSoTheFocusRingFollowsTheArt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		let combo = new ComboBox();
		defer combo.ReleaseRef();
		root.AddChild(button);
		root.AddChild(field);
		root.AddChild(combo);
		let mgr = scope StyleManager();
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		mgr.UserAgentSheet = theme;
		mgr.ApplyTree(root);
		Test.Assert(button.Box.Radii.IsZero); // square by default
		Test.Assert(field.Box.Radii.IsZero);

		WidgetFixtures.UseSheet(mgr, ":root { --button-radius: 6px; --field-radius: 4px; }");
		mgr.ApplyTree(root);
		Test.Assert(Near(button.Box.Radii.TopLeft, 6.0f));
		Test.Assert(Near(field.Box.Radii.BottomRight, 4.0f));
		Test.Assert(Near(combo.Box.Radii.TopLeft, 4.0f)); // a combo box follows the fields
	}

	// The first widget in `node`'s subtree (`node` first) tagged `tag`, or null.
	private static UIWidget FindTagged(Node node, StringView tag)
	{
		if (let widget = node as UIWidget)
		{
			if (widget.Tag == tag)
				return widget;
		}
		for (int i = 0; i < node.ChildCount; ++i)
		{
			let found = FindTagged(node.GetChildAt(i), tag);
			if (found != null)
				return found;
		}
		return null;
	}

	[Test]
	public static void AListsRowsShowThePointerOverThemAComboBoxsPopupIsAListBox()
	{
		// The model first: the view unregisters from it when the tree lets the view go.
		StringView[2] rows = .("a", "b");
		let model = scope StringListModel(rows);
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let @box = new ListBox();
		@box.AddItem("one");
		@box.AddItem("two");
		let view = new ListView();
		view.Size = .(200.0f, 100.0f);
		view.RowHeight = 20.0f;
		root.AddChild(@box);
		root.AddChild(view);
		@box.ReleaseRef();
		view.ReleaseRef();
		view.Model = model;
		root.UpdateLayout();

		let mgr = scope StyleManager();
		WidgetFixtures.UseSheet(mgr, Theme.DefaultThemeCSS);
		mgr.ApplyTree(root);
		let item = FindTagged(@box, "listboxitem");
		Test.Assert(item != null);
		let row = FindTagged(view, "listviewrow");
		Test.Assert(row != null);
		Test.Assert(Near(item.Box.BackgroundColor.A, 0.0f));
		Test.Assert(Near(row.Box.BackgroundColor.A, 0.0f));

		item.Hovered = true;
		row.Hovered = true;
		mgr.ApplyTree(root);
		Test.Assert(item.Box.BackgroundColor.A > 0.0f);
		Test.Assert(row.Box.BackgroundColor.A > 0.0f);
		Test.Assert(item.TextColor.A > 0.0f); // still the label's text colour

		// A sheet retints the hover with one token.
		WidgetFixtures.UseSheet(mgr, ":root { --list-hover: #ff0000; }");
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		mgr.UserAgentSheet = theme;
		mgr.ApplyTree(root);
		Test.Assert(Near(item.Box.BackgroundColor.R, 1.0f));
	}
}
