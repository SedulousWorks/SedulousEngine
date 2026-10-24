using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @media conditions evaluated against a MediaContext: one feature, a conjunction, height, the
/// empty query, orientation, `not`, comma lists and media types; and @media blocks parsed and
/// gating resolution.
class MediaQueryTests
{
	private static bool Matches(StringView query, MediaContext context)
	{
		let q = scope MediaQuery(query);
		return q.Evaluate(context);
	}

	[Test]
	public static void SingleFeature()
	{
		let mq = scope MediaQuery("(min-width: 600px)");
		Test.Assert(mq.FeatureCount == 1);
		Test.Assert(mq.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(400.0f, 0.0f, 96.0f)));
		Test.Assert(mq.Evaluate(.(600.0f, 0.0f, 96.0f))); // inclusive
	}

	[Test]
	public static void ConjunctionAnd()
	{
		let mq = scope MediaQuery("(min-width: 600px) and (max-width: 900px)");
		Test.Assert(mq.FeatureCount == 2);
		Test.Assert(mq.Evaluate(.(800.0f, 0.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(1000.0f, 0.0f, 96.0f))); // over max
		Test.Assert(!mq.Evaluate(.(500.0f, 0.0f, 96.0f))); // under min
	}

	[Test]
	public static void HeightFeatures()
	{
		let mq = scope MediaQuery("(max-height: 480px)");
		Test.Assert(mq.Evaluate(.(0.0f, 400.0f, 96.0f)));
		Test.Assert(!mq.Evaluate(.(0.0f, 600.0f, 96.0f)));
	}

	[Test]
	public static void EmptyAlwaysMatches()
	{
		let empty = scope MediaQuery();
		Test.Assert(empty.IsEmpty);
		Test.Assert(empty.Evaluate(.(0.0f, 0.0f, 0.0f)));
	}

	[Test]
	public static void OrientationNotCommaListsAndMediaTypes()
	{
		let wide = MediaContext(800.0f, 600.0f, 96.0f);
		let tall = MediaContext(600.0f, 800.0f, 96.0f);
		Test.Assert(Matches("(orientation: landscape)", wide));
		Test.Assert(!Matches("(orientation: landscape)", tall));
		Test.Assert(Matches("(orientation: portrait)", tall));
		Test.Assert(Matches("not (orientation: portrait)", wide));
		Test.Assert(!Matches("not all and (min-width: 700px)", wide));
		Test.Assert(Matches("screen and (max-width: 500px), (orientation: portrait)", tall)); // the second
		Test.Assert(!Matches("screen and (max-width: 500px), (orientation: portrait)", wide));
		Test.Assert(!Matches("print", wide));
		Test.Assert(!Matches("not (hover: hover)", wide)); // a feature it cannot test: not either
		Test.Assert(Matches("(hover: hover), (min-width: 1px)", wide)); // another in the list still can
	}

	/// The `color` `sheet` resolves to on a button under `context`; empty when it sets none.
	private static void ButtonColor(StyleSheet sheet, MediaContext context, String outText)
	{
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, context, rs);
		outText.Append(rs.Get("color"));
	}

	[Test]
	public static void AtMediaBlockParsesAndGatesResolution()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { color: black; } @media (min-width: 600px) { button { color: red; } }", sheet);
		Test.Assert(sheet.RuleCount == 2);

		// Wide viewport: the @media rule is active and (later source) wins.
		Test.Assert(ButtonColor(sheet, .(800.0f, 600.0f, 96.0f), .. scope String()) == "red");
		// Narrow viewport: the @media rule is inactive; the base rule stands.
		Test.Assert(ButtonColor(sheet, .(400.0f, 600.0f, 96.0f), .. scope String()) == "black");
	}

	[Test]
	public static void MultipleRulesInsideOneAtMediaBlock()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@media (min-width: 600px) { button { color: red; } .box { padding: 8; } }", sheet);
		Test.Assert(sheet.RuleCount == 2);

		let btn = StyleFixtures.Widget("button");
		defer btn.ReleaseRef();
		let wide = scope ResolvedStyle();
		sheet.Resolve(btn, .(800.0f, 0.0f, 96.0f), wide);
		Test.Assert(wide.Get("color") == "red");
		let narrow = scope ResolvedStyle();
		sheet.Resolve(btn, .(400.0f, 0.0f, 96.0f), narrow);
		Test.Assert(!narrow.Has("color"));
	}

	[Test]
	public static void AFeatureItDoesNotKnowMatchesNothingRatherThanEverything()
	{
		let wide = MediaContext(800.0f, 600.0f, 96.0f);
		Test.Assert(!Matches("(aspect-ratio: 16/9)", wide));
		Test.Assert(!Matches("(prefers-reduced-motion)", wide)); // known now: the context does not ask for it
		Test.Assert(!Matches("(min-width: 600px) and (hover: hover)", wide));
		Test.Assert(Matches("(min-width: 600px)", wide));
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { color: black; } @media (pointer: coarse) { button { color: red; } }", sheet);
		Test.Assert(ButtonColor(sheet, wide, .. scope String()) == "black");
	}

	[Test]
	public static void TheHostsPreferencesColourSchemeContrastReducedMotion()
	{
		var context = MediaContext(800.0f, 600.0f, 96.0f);
		Test.Assert(Matches("(prefers-color-scheme: dark)", context)); // dark by default
		context.DarkScheme = false;
		Test.Assert(Matches("(prefers-color-scheme: light)", context));
		Test.Assert(Matches("(prefers-contrast: no-preference)", context));
		Test.Assert(!Matches("(prefers-contrast)", context));
		context.Contrast = .More;
		Test.Assert(Matches("(prefers-contrast: more)", context));
		Test.Assert(Matches("(prefers-contrast)", context));
		Test.Assert(!Matches("(prefers-reduced-motion: reduce)", context));
		context.ReducedMotion = true;
		Test.Assert(Matches("(prefers-reduced-motion)", context));

		// From the GUI to a sheet: a root's media context carries the host's flags.
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let gui = root.Context;
		let w = StyleFixtures.Widget("button");
		defer w.ReleaseRef();
		root.AddChild(w);
		let sheet = scope StyleSheet();
		CSSParser.Parse("button { opacity: 1; } @media (prefers-color-scheme: light) and (prefers-contrast: more) { button { opacity: 0.5; } }", sheet);
		let styles = scope StyleManager(sheet);
		styles.MediaContext = root.MediaContext;
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(w.Alpha, 1.0f));
		gui.DarkScheme = false;
		gui.ContrastPreference = .More;
		styles.MediaContext = root.MediaContext; // the host passes it each frame: a change restyles
		styles.ApplyTree(root);
		Test.Assert(NodeFixtures.Near(w.Alpha, 0.5f));
	}

	/// How many widgets of four buttons a frame of a window's resize restyles under `css`, one
	/// of them with an inline `width: 10vw` when `inlineVw`.
	private static uint32 RestyledByResize(StringView css, bool inlineVw)
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		for (int i = 0; i < 4; i++)
		{
			let w = StyleFixtures.Widget("button");
			root.AddChild(w);
			if (inlineVw && (i == 2))
				w.SetInlineStyle("width", "10vw");
			w.ReleaseRef(); // the tree's reference keeps it
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		let styles = scope StyleManager(sheet);
		styles.MediaContext = root.MediaContext;
		styles.ApplyTree(root);
		root.Size = .(820.0f, 610.0f); // a frame of a window's resize
		styles.MediaContext = root.MediaContext;
		styles.ApplyTree(root);
		return styles.LastRestyleCount;
	}

	[Test]
	public static void AResizeRestylesOnlyWhatReadsTheViewport()
	{
		Test.Assert(RestyledByResize("button { opacity: 0.5; }", false) == 0); // nothing reads the size
		Test.Assert(RestyledByResize("button { opacity: 0.5; } @media (min-width: 1000px) { button { opacity: 1; } }", false) == 0); // no flip
		Test.Assert(RestyledByResize("button { opacity: 0.5; } @media (min-width: 810px) { button { opacity: 1; } }", false) >= 4); // flips
		Test.Assert(RestyledByResize("button { width: 50vw; }", false) >= 4);
		Test.Assert(RestyledByResize(":root { --side: calc(100vh - 20px); } button { opacity: 0.5; }", false) >= 4);
		Test.Assert(RestyledByResize("button { opacity: 0.5; }", true) == 1); // its own inline vw
	}
}
