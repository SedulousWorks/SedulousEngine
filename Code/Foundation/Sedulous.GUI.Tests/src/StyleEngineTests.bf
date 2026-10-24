using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget with a property a sheet sets by its CSS name (`gauge-level`), its own value 5.
[GuiReflect]
class EngineGauge : UIWidget
{
	private float mLevel = 5.0f;

	[GuiProperty("gauge-level")]
	public float Level
	{
		get => mLevel;
		set => mLevel = value;
	}

	public this()
	{
		Tag = "gauge";
	}
}

/// The style engine end to end: the applier's reflected properties and code's pins, the restore of
/// a node's own value, transitions and keyframes on a GUI's clock, tweens, springs, data tweens,
/// and a style pass that restyles only what changed.
class StyleEngineTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// `css` resolved for `widget` and applied to it.
	private static void Apply(StringView css, UIWidget widget)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(widget, MediaContext(), false, default, null, rs);
		ApplyStyle(widget, rs);
	}

	[Test]
	public static void ASheetsDeclarationReachesAReflectedPropertyAndCodePinsItOverTheSheet()
	{
		let g = new EngineGauge();
		defer g.ReleaseRef();
		StringView css = "gauge { gauge-level: 12; } gauge.low { gauge-level: 3; }";
		Apply(css, g);
		Test.Assert(Near(g.Level, 12.0f));
		g.AddClass("low");
		Apply(css, g);
		Test.Assert(Near(g.Level, 3.0f)); // the sheet's, while the sheet sets it
		g.Level = 7.0f; // code takes it
		Apply(css, g);
		Test.Assert(Near(g.Level, 7.0f));
		g.RemoveClass("low");
		Apply(css, g);
		Test.Assert(Near(g.Level, 7.0f)); // code's from now on
	}

	[Test]
	public static void TheOwnValueReturnsWhenTheRuleStopsMatching()
	{
		let g = new EngineGauge();
		defer g.ReleaseRef();
		StringView css = "gauge.set { gauge-level: 12; opacity: 0.5; }";
		g.AddClass("set");
		Apply(css, g);
		Test.Assert(Near(g.Level, 12.0f));
		Test.Assert(Near(g.Alpha, 0.5f));
		g.RemoveClass("set");
		Apply(css, g);
		Test.Assert(Near(g.Level, 5.0f)); // its own value back
		Test.Assert(Near(g.Alpha, 1.0f));

		// A setter's property pinned by code stays code's until unpinned.
		g.AddClass("set");
		g.Alpha = 0.8f;
		Apply(css, g);
		Test.Assert(Near(g.Alpha, 0.8f));
		g.UnpinStyle(SlotBit(.SlotOpacity));
		Apply(css, g);
		Test.Assert(Near(g.Alpha, 0.5f));
	}

	/// A scene holding one `box` widget, styled by `css`.
	private class EngineBed
	{
		public SceneRoot Root = SceneFixtures.NewScene(200.0f, 100.0f) ~ _.ReleaseRef();
		public UIWidget Box = StyleFixtures.Widget("box") ~ _.ReleaseRef();
		public StyleManager Styles = new .() ~ delete _;

		public this(StringView css)
		{
			Root.AddChild(Box);
			let sheet = scope StyleSheet();
			CSSParser.Parse(css, sheet);
			Styles.StyleSheet = sheet;
			Styles.ApplyTree(Root);
		}

		public void Frame(double seconds)
		{
			Root.Context.Update(SceneFixtures.Seconds(seconds));
			Styles.ApplyTree(Root);
		}
	}

	[Test]
	public static void ATransitionStartsOnAChangeWithItsDurationAndEasing()
	{
		let bed = scope EngineBed("box { opacity: 1; transition: opacity 1s linear; } box.dim { opacity: 0; }");
		int ends = 0;
		bed.Box.AddEventListener(.TransitionEnd, new [&] (e) => { ends++; });
		Test.Assert(Near(bed.Box.Alpha, 1.0f));
		bed.Box.AddClass("dim");
		bed.Styles.ApplyTree(bed.Root);
		Test.Assert(Near(bed.Box.Alpha, 1.0f)); // it starts where it showed
		bed.Frame(0.25);
		Test.Assert(Near(bed.Box.Alpha, 0.75f));
		bed.Frame(0.25);
		Test.Assert(Near(bed.Box.Alpha, 0.5f));
		bed.Frame(0.5);
		Test.Assert(Near(bed.Box.Alpha, 0.0f));
		Test.Assert(ends == 1);
	}

	[Test]
	public static void ATransitionsDelayHoldsTheOldValueAndItsEasingShapesTheMove()
	{
		let bed = scope EngineBed("box { opacity: 1; transition: opacity 1s ease-in-quad 0.5s; } box.dim { opacity: 0; }");
		bed.Box.AddClass("dim");
		bed.Styles.ApplyTree(bed.Root);
		bed.Frame(0.25);
		Test.Assert(Near(bed.Box.Alpha, 1.0f)); // waiting
		bed.Frame(0.75); // half way through the move: eased in, a quarter of it
		Test.Assert(Near(bed.Box.Alpha, 0.75f));
	}

	[Test]
	public static void KeyframesRunTheirIterationsInTheirDirection()
	{
		let bed = scope EngineBed("@keyframes fade { from { opacity: 1; } to { opacity: 0; } } box { animation: fade 1s linear 2 alternate; }");
		int ends = 0;
		bed.Box.AddEventListener(.AnimationEnd, new [&] (e) => { ends++; });
		Test.Assert(Near(bed.Box.Alpha, 1.0f));
		bed.Frame(0.25);
		Test.Assert(Near(bed.Box.Alpha, 0.75f)); // the first run, forwards
		bed.Frame(1.0);
		Test.Assert(Near(bed.Box.Alpha, 0.25f)); // the second, back: a quarter of the way from the end
		bed.Frame(1.0);
		Test.Assert(Near(bed.Box.Alpha, 1.0f)); // ended, no fill: the node's own
		Test.Assert(ends == 1);
	}

	[Test]
	public static void ATweenEasesAndTheNextOnTheSamePropertyReplacesIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = SceneFixtures.NewNode(0.0f, 0.0f, 10.0f, 10.0f, root);
		defer node.ReleaseRef();
		let first = node.Animate("x", "100", 1.0f, "ease-in-quad");
		defer first.ReleaseRef();
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(node.X, 25.0f)); // eased in: a quarter at half time
		let second = node.Animate("x", "0", 1.0f, "linear");
		defer second.ReleaseRef();
		Test.Assert(first.IsDone); // replaced
		root.Context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(node.X, 12.5f)); // from where the first left it
		Test.Assert(node.StopAnimation("x"));
		Test.Assert(second.IsDone);
	}

	[Test]
	public static void ASpringSettlesAtItsEndAndALooseOneOvershootsFirst()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let node = SceneFixtures.NewNode(0.0f, 0.0f, 10.0f, 10.0f, root);
		defer node.ReleaseRef();
		let spring = node.SpringTo("x", "100");
		defer spring.ReleaseRef();
		let loose = node.SpringTo("y", "100", 300.0f, 5.0f, 1.0f);
		defer loose.ReleaseRef();
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert((node.X > 0.0f) && (node.X < 100.0f));
		float highest = 0.0f;
		for (int i = 0; i < 625; i++) // ten seconds of frames
		{
			root.Context.Update(SceneFixtures.Frame);
			highest = Math.Max(highest, node.Y);
		}
		Test.Assert(spring.IsDone);
		Test.Assert(node.X == 100.0f); // settled exactly at its end
		Test.Assert(highest > 100.0f); // little damping rings past it
		Test.Assert(loose.IsDone);
		Test.Assert(node.Y == 100.0f);
		// A spring already moving a property turns toward the new end rather than starting again.
		let again = node.SpringTo("x", "0");
		defer again.ReleaseRef();
		let turned = node.SpringTo("x", "50");
		defer turned.ReleaseRef();
		Test.Assert(turned == again);
	}

	[Test]
	public static void ADataTweenClaimsItsNameAndKeepsTheValuesType()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let context = root.Context;
		let first = context.AnimateData("score", 100.0, 1.0f, "linear");
		defer first.ReleaseRef();
		context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(NumberOf(context.Data.Get("score"), let half) && Near((float)half, 50.0f));
		let second = context.AnimateData("score", 0.0, 1.0f, "linear");
		defer second.ReleaseRef();
		context.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(first.IsDone); // the second took the name
		Test.Assert(NumberOf(context.Data.Get("score"), let quarter) && Near((float)quarter, 25.0f));

		// A whole number counts in whole numbers.
		context.Data.Set("coins", System.Variant.Create((int32)3));
		let coins = context.AnimateData("coins", 10.0, 1.0f, "linear");
		defer coins.ReleaseRef();
		context.Update(SceneFixtures.Seconds(0.5));
		let value = context.Data.Get("coins");
		Test.Assert(value.VariantType == typeof(int32));
		Test.Assert(value.Get<int32>() == 7); // 6.5, to the nearest
	}

	[Test]
	public static void TheStylePassRestylesOnlyWhatAChangeTouched()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let a = StyleFixtures.Widget("box");
		defer a.ReleaseRef();
		let a1 = StyleFixtures.Widget("box");
		defer a1.ReleaseRef();
		let b = StyleFixtures.Widget("box");
		defer b.ReleaseRef();
		root.AddChild(a);
		a.AddChild(a1);
		root.AddChild(b);
		let styles = scope StyleManager();
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { opacity: 1; } box.x { opacity: 0.5; }", sheet);
		styles.StyleSheet = sheet;
		styles.ApplyTree(root);
		Test.Assert(styles.LastRestyleCount == 3);
		Test.Assert(styles.CachedWidgetCount == 3);
		styles.ApplyTree(root);
		Test.Assert(styles.LastRestyleCount == 0); // nothing changed
		b.AddClass("x");
		styles.ApplyTree(root);
		Test.Assert(styles.LastRestyleCount == 1);
		Test.Assert(Near(b.Alpha, 0.5f));
		a.AddClass("x");
		styles.ApplyTree(root);
		Test.Assert(styles.LastRestyleCount == 2); // its subtree with it
		Test.Assert(Near(a.Alpha, 0.5f));
		Test.Assert(Near(a1.Alpha, 1.0f));
	}
}
