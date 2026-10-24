using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A library's widget with a property of its own, styled by the name it declares.
[GuiReflect]
class StyleCoreGauge : UIWidget
{
	private Color mNeedle = .();
	private float mNeedleWidth = 1.0f;

	[GuiProperty("needle-color")]
	public Color NeedleColor
	{
		get => mNeedle;
		set => mNeedle = value;
	}

	[GuiProperty("needle-width")]
	public float NeedleWidth
	{
		get => mNeedleWidth;
		set => mNeedleWidth = value;
	}
}

/// The cascade's core: var() anywhere in a value, custom properties inherited, shorthands
/// cascading as their longhands, and a declaration parsed once.
class StyleCoreTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void VarResolvesAnywhereInAValueNestedAndWithFallbacks()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"box { --x: 3px; --shade: rgba(0, 0, 0, 0.5); --outer: var(--x); " +
			"box-shadow: var(--outer) 4px 6px var(--shade), inset 0 0 2px var(--missing, red); " +
			"border: var(--w, 2px) solid var(--c, blue); }", sheet);
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);

		let shadows = rs.Value("box-shadow");
		Test.Assert(shadows != null);
		Test.Assert(shadows.Shadows.Count == 2);
		Test.Assert(Near(shadows.Shadows[0].OffsetX.Value, 3.0f)); // var() -> var() -> 3px
		Test.Assert(Near(shadows.Shadows[0].ShadowColor.A, 0.5f)); // a var() inside rgba's place
		Test.Assert(shadows.Shadows[1].Inset);
		Test.Assert(Near(shadows.Shadows[1].ShadowColor.R, 1.0f)); // the fallback
		// A shorthand built of var()s expands after they resolve.
		Test.Assert(rs.Get("border-left-width") == "2px");
		Test.Assert(Near(rs.Value("border-top-color").ColorValue.B, 1.0f));

		// A reference with no value and no fallback leaves its declaration out.
		let broken = scope StyleSheet();
		CSSParser.Parse("box { opacity: var(--nothing); }", broken);
		let none = scope ResolvedStyle();
		broken.Resolve(w, none);
		Test.Assert(!none.Has("opacity"));
	}

	[Test]
	public static void CustomPropertiesInheritFromTheParentsStyle()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("panel { --accent: #00ff00; } button { color: var(--accent); }", sheet);
		let panel = StyleFixtures.Widget("panel");
		defer panel.ReleaseRef();
		let button = StyleFixtures.Widget("button");
		defer button.ReleaseRef();
		let parent = scope ResolvedStyle();
		sheet.Resolve(panel, parent);
		let alone = scope ResolvedStyle();
		sheet.Resolve(button, alone);
		Test.Assert(!alone.Has("color")); // alone, --accent is unset
		let child = scope ResolvedStyle();
		sheet.Resolve(button, MediaContext(), true, default, parent, child);
		Test.Assert(child.Value("color") != null);
		Test.Assert(Near(child.Value("color").ColorValue.G, 1.0f));
	}

	[Test]
	public static void AShorthandCascadesAsItsLonghands()
	{
		// A later, more specific longhand overrides one side of an earlier shorthand; the others stay.
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { border: 1px solid red; padding: 2 4; } .warn { border-left-color: yellow; padding-top: 9; }", sheet);
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		w.AddClass("warn");
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		Test.Assert(Near(rs.Value("border-left-color").ColorValue.G, 1.0f)); // yellow
		Test.Assert(Near(rs.Value("border-right-color").ColorValue.G, 0.0f)); // still red
		Test.Assert(rs.Get("padding-top") == "9");
		Test.Assert(rs.Get("padding-right") == "4");
		Test.Assert(rs.Get("padding-bottom") == "2");
		Test.Assert(!rs.Has("border")); // only longhands are resolved
	}

	[Test]
	public static void ADeclarationWithoutVarIsParsedOnceAndOnceMoreAfterItChanges()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { transform: rotate(90deg) scale(2); }", sheet);
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		let first = scope ResolvedStyle();
		sheet.Resolve(w, first);
		let declared = sheet.Rules[0].Properties[0];
		Test.Assert(declared.Cached);
		Test.Assert(declared.CacheValid);
		Test.Assert(declared.Longhands.Count == 1);
		Test.Assert(declared.Longhands[0].Value.Kind == .Transforms);
		Test.Assert(declared.Longhands[0].Value.Transforms.Count == 2);
		// A second cascade reads the cached value (the same parse, the same result).
		let second = scope ResolvedStyle();
		sheet.Resolve(w, second);
		let again = second.Value("transform");
		Test.Assert(again != null);
		Test.Assert(Near(again.Transforms[0].Angle, 1.5707963f));

		// A declaration with a var() is substituted on every cascade instead.
		let withVar = scope StyleSheet();
		CSSParser.Parse("box { --a: 0.25; opacity: var(--a); }", withVar);
		let third = scope ResolvedStyle();
		withVar.Resolve(w, third);
		Test.Assert(!withVar.Rules[0].Properties[1].CacheValid);
	}

	[Test]
	public static void AWidgetsReflectedPropertyTakesTheCssNameItDeclares()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("gauge { needle-color: #ff8000; needle-width: 0.5rem; }", sheet);
		let gauge = new StyleCoreGauge();
		defer gauge.ReleaseRef();
		gauge.Tag = "gauge";
		var lengths = LengthContext();
		lengths.RootFontSize = 16.0f;
		let rs = scope ResolvedStyle();
		sheet.Resolve(gauge, rs);
		ApplyStyle(gauge, rs, null, null, lengths);
		Test.Assert(Near(gauge.NeedleColor.R, 1.0f));
		Test.Assert(Near(gauge.NeedleColor.G, 128.0f / 255.0f));
		Test.Assert(Near(gauge.NeedleWidth, 8.0f)); // a length, resolved
	}

	[Test]
	public static void TheBoxBelongsToTheSheetARestyleWithoutBoxPropertiesClearsIt()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(".card { background-color: red; box-shadow: 0 2px 4px black; }", sheet);
		let w = StyleFixtures.Widget("box");
		defer w.ReleaseRef();
		w.AddClass("card");
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		ApplyStyle(w, rs);
		Test.Assert(Near(w.Box.BackgroundColor.R, 1.0f));
		Test.Assert(w.Box.Shadows.Count == 1);
		w.RemoveClass("card");
		sheet.Resolve(w, rs);
		ApplyStyle(w, rs);
		Test.Assert(w.Box.IsEmpty);

		// A box set natively is the node's own: a sheet with no box properties leaves it.
		let native = StyleFixtures.Widget("box");
		defer native.ReleaseRef();
		let nativeBox = scope NodeBox();
		nativeBox.BackgroundColor = Color(0.0f, 0.0f, 1.0f, 1.0f);
		native.SetBox(nativeBox);
		sheet.Resolve(native, rs);
		ApplyStyle(native, rs);
		Test.Assert(Near(native.Box.BackgroundColor.B, 1.0f));
	}

	[Test]
	public static void TheStyleManagerGivesEachWidgetItsAncestorsCustomProperties()
	{
		// A var() set on a row reaches its children through ApplyTree (it was dropped when the
		// manager resolved each widget alone).
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let row = StyleFixtures.Widget("row");
		defer row.ReleaseRef();
		let card = StyleFixtures.Widget("card");
		defer card.ReleaseRef();
		root.AddChild(row);
		row.AddChild(card);
		let sheet = scope StyleSheet();
		CSSParser.Parse("row { --glow: #00ff00; } card { box-shadow: 0 0 4px var(--glow); }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		Test.Assert(card.Box.Shadows.Count == 1);
		Test.Assert(Near(card.Box.Shadows[0].ShadowColor.G, 1.0f));
	}
}
