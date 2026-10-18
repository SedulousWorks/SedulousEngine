using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// Style model v2 P3: `transition` parsing, the per view transitions that overlay ResolveStyle,
/// the state cross fade through Drawable.Draw, layout against visual damage, and the sheet swap
/// and detach edges.
class TransitionTests
{
	private static bool Near(float a, float b, float epsilon = 0.005f) => Abs(a - b) <= epsilon;

	/// A TestView whose control state the TEST sets, drawing its styled background.
	private class StatefulView : TestView
	{
		public ControlState State = .Normal;

		public this(float width, float height) : base(width, height) {}

		public override ControlState GetControlState() => State;

		public override void OnDraw(UIDrawContext ctx)
		{
			if (let background = ResolveStyleDrawable(.Background))
				background.Draw(ctx, .(0, 0, Width, Height), GetControlState());
		}
	}

	/// Paints a rect whose COLOUR says which state it was drawn with, so a cross fade is
	/// visible in the batch rather than having to be inferred.
	private class StateColorDrawable : Drawable
	{
		public override void Draw(UIDrawContext ctx, Rectangle bounds)
		{
			ctx.VG.FillRect(bounds, Color(1, 0, 0, 1));
		}

		protected override void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
		{
			let hovered = (state & .Hover) == .Hover;
			ctx.VG.FillRect(bounds, hovered ? Color(0, 1, 0, 1) : Color(1, 0, 0, 1));
		}
	}

	private static void EnsureGlobals()
	{
		StyleSheetLoader.InitializeGlobals();
		UITypeRegistry.Register("View", typeof(View));
		UITypeRegistry.Register("RootView", typeof(RootView));
		UITypeRegistry.Register("TestView", typeof(TestView));
		UITypeRegistry.Register("TestGroup", typeof(TestGroup));
		UITypeRegistry.Register("StatefulView", typeof(StatefulView));
	}

	/// OWNERSHIP of the sheet transfers.
	private static StyleSheet LoadSSS(StringView source)
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	private class Fixture
	{
		public UIContext Context = new .() ~ delete _;
		public RootView Root = new .() ~ _.ReleaseRef();

		public this(StyleSheet sheet)
		{
			EnsureGlobals();
			UITest.Init(Context, Root);
			Context.SetStyleSheet(sheet);
		}

		public StatefulView Stateful()
		{
			let view = new StatefulView(50.0f, 30.0f);
			Root.AddView(view);
			return view;
		}

		public TestView Leaf()
		{
			let view = new TestView(50.0f, 30.0f);
			Root.AddView(view);
			return view;
		}
	}

	private static float Red(View view) =>
		view.ResolveStyleColor(.TextColor, Color(-1, -1, -1, -1)).R;

	// ---- Parsing ----------------------------------------------------------------------------

	/// The shorthand takes a property, a duration in ms or s, an easing and a delay, in that
	/// order, and `all` covers everything. A LATER entry governs, so `all` written last wins
	/// over the named entries before it.
	[Test]
	public static void TheTransitionListParsesEveryForm()
	{
		let sheet = LoadSSS("""
			TestView { transition: text-color 200ms ease-in 50ms, opacity 1s, all 120 ease-out; }
			.none { transition: none; }
			.unknown { transition: not-a-property 100ms, font-size 0.5s; }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 3);

		let list = sheet.GetRule(0).GetValue(.Transition).Value.AsTransitions;
		Test.Assert(list != null);
		Test.Assert(list.Specs.Count == 3);
		Test.Assert(list.Specs[0].Property == .TextColor);
		Test.Assert(Near(list.Specs[0].Duration, 0.2f));
		Test.Assert(Near(list.Specs[0].Delay, 0.05f));
		Test.Assert(list.Specs[0].Easing == TimingFunction.EaseIn);
		Test.Assert(list.Specs[1].Property == .Opacity);
		Test.Assert(Near(list.Specs[1].Duration, 1.0f));
		Test.Assert(list.Specs[1].Easing == TimingFunction.Ease, "the default easing");
		Test.Assert(list.Specs[2].Property == .COUNT, "`all`");
		Test.Assert(Near(list.Specs[2].Duration, 0.12f), "a bare number is milliseconds");
		Test.Assert(list.Specs[2].Easing == TimingFunction.EaseOut);

		// `all` came last, so it governs text-color too.
		Test.Assert(list.Find(.TextColor).Value == list.Specs[2]);
		Test.Assert(list.Find(.BorderColor).Value == list.Specs[2]);

		let none = sheet.GetRule(1).GetValue(.Transition).Value.AsTransitions;
		Test.Assert(none != null);
		Test.Assert(none.Specs.IsEmpty);
		Test.Assert(none.Find(.TextColor) == null);

		// An unknown property drops out and the REST of the list survives, so one typo does
		// not silently disable a theme's whole motion.
		let partial = sheet.GetRule(2).GetValue(.Transition).Value.AsTransitions;
		Test.Assert(partial != null);
		Test.Assert(partial.Specs.Count == 1);
		Test.Assert(partial.Specs[0].Property == .FontSize);
		Test.Assert(Near(partial.Specs[0].Duration, 0.5f));
	}

	/// Interpolation is per KIND: colours and numbers blend, a thickness blends per side, a
	/// shadow blends its lengths but flips its inset at the midpoint, and a string is discrete.
	[Test]
	public static void LerpInterpolatesEachValueKindAppropriately()
	{
		let colour = StyleValueOps.Lerp(.Color(Color(0, 0, 0, 1)), .Color(Color(1, 0.5f, 0, 0)),
			0.5f);
		Test.Assert(Near(colour.AsColor.Value.R, 0.5f));
		Test.Assert(Near(colour.AsColor.Value.G, 0.25f));
		Test.Assert(Near(colour.AsColor.Value.A, 0.5f));

		Test.Assert(Near(StyleValueOps.Lerp(.Float(10), .Float(20), 0.25f).AsFloat.Value, 12.5f));

		// A float against a length mixes AS a length, the float counting as dp.
		let mixed = StyleValueOps.Lerp(.Float(10), .Length(Unit.Em(2)), 0.5f);
		Test.Assert(mixed.AsLength != null);
		Test.Assert(Near(mixed.AsLength.Value.dp, 5));
		Test.Assert(Near(mixed.AsLength.Value.em, 1));

		let thickness = StyleValueOps.Lerp(.Thickness(Thickness(0, 0, 0, 0)),
			.Thickness(Thickness(4, 8, 12, 16)), 0.5f);
		Test.Assert(Near(thickness.AsThickness.Value.Right, 6));

		var from = BoxShadow();
		from.Blur = 0;
		var to = BoxShadow();
		to.Blur = 8;
		to.OffsetY = 4;
		to.Inset = true;
		let shadow = StyleValueOps.Lerp(.Shadow(from), .Shadow(to), 0.25f);
		Test.Assert(Near(shadow.AsShadow.Value.Blur, 2));
		Test.Assert(Near(shadow.AsShadow.Value.OffsetY, 1));
		Test.Assert(!shadow.AsShadow.Value.Inset, "discrete: it flips at the midpoint");

		Test.Assert(StyleValueOps.Lerp(.Float(1), .Float(2), 0.0f).AsFloat.Value == 1);
		Test.Assert(StyleValueOps.Lerp(.Float(1), .Float(2), 1.0f).AsFloat.Value == 2);
		Test.Assert(StyleValueOps.Lerp(.String("a"), .String("b"), 0.4f).AsString.Value == "a");
		Test.Assert(StyleValueOps.Lerp(.String("a"), .String("b"), 0.6f).AsString.Value == "b");
	}

	// ---- Class toggles ----------------------------------------------------------------------

	/// A class toggle animates only the LISTED properties; everything else changes at once.
	/// Shadow lists go shadow by shadow, the shorter padded with a clear shadow of the other's
	/// colour, so a shadow added fades in. The in-between list is the caller's; without one, a
	/// pair of lists switches at the midpoint.
	[Test]
	public static void ShadowListsInterpolateShadowByShadowPaddedWithClearOnes()
	{
		var one = BoxShadow();
		one.Blur = 4.0f;
		one.Color = Color(0, 0, 0, 1);
		var added = one;
		added.OffsetY = 10.0f;
		added.Color = Color(1, 0, 0, 1);
		let two = new BoxShadowList();
		defer two.ReleaseRef();
		two.Add(one);
		two.Add(added);

		let scratch = new BoxShadowList();
		defer scratch.ReleaseRef();
		let mid = StyleValueOps.Lerp(.Shadow(one), .Shadows(two), 0.5f, scratch);
		Test.Assert(mid.ShadowCount == 2);
		Test.Assert(Near(mid.ShadowAt(0).Blur, 4.0f));
		Test.Assert(Near(mid.ShadowAt(1).OffsetY, 5.0f));
		Test.Assert(Near(mid.ShadowAt(1).Color.R, 1.0f), "its own colour");
		Test.Assert(Near(mid.ShadowAt(1).Color.A, 0.5f), "fading in");
		Test.Assert((mid case .Shadows(let list)) && (list == scratch));

		Test.Assert(StyleValueOps.Lerp(.Shadow(one), .Shadows(two), 0.4f).ShadowCount == 1, "no list to write: it switches");
		Test.Assert(!StyleValueOps.Equivalent(.Shadow(one), .Shadows(two)));
		Test.Assert(StyleValueOps.Equivalent(.Shadows(two), .Shadows(two)));
	}

	/// A hover that adds a shadow fades it in, and leaving halfway runs back from the
	/// in-between list rather than snapping, the view holding it until the transition ends.
	[Test]
	public static void AHoverThatAddsAShadowFadesItInAndLeavingHalfwayRunsBack()
	{
		let fixture = scope Fixture(LoadSSS("""
			StatefulView { transition: box-shadow 100ms linear; box-shadow: 0 2 4 #000000; }
			StatefulView:hover { box-shadow: 0 2 4 #000000, 0 10 4 #FF0000; }
			"""));
		let view = fixture.Stateful();
		Test.Assert(view.ResolveStyle(.BoxShadow).ShadowCount == 1);

		view.State = .Hover;
		view.ResolveStyle(.BoxShadow);
		fixture.Context.BeginFrame(0.05f);
		let mid = view.ResolveStyle(.BoxShadow);
		Test.Assert(mid.ShadowCount == 2);
		Test.Assert(Near(mid.ShadowAt(1).Color.A, 0.5f));
		Test.Assert(Near(mid.ShadowAt(1).OffsetY, 5.0f), "from a clear shadow at rest");

		view.State = .Normal;
		let back = view.ResolveStyle(.BoxShadow);
		Test.Assert((back.ShadowCount == 2) && Near(back.ShadowAt(1).Color.A, 0.5f), "no snap");
		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(view.ResolveStyle(.BoxShadow).ShadowAt(1).Color.A, 0.25f));
		fixture.Context.BeginFrame(0.06f);
		Test.Assert(view.ActiveTransitionCount == 0);
		Test.Assert(view.ResolveStyle(.BoxShadow).ShadowCount == 1);
	}

	[Test]
	public static void AClassToggleAnimatesOnlyTheListedProperties()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { transition: text-color 100ms linear; text-color: #000000; font-size: 10; }
			.big { text-color: #ffffff; font-size: 20; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(Red(view), 0.0f), "this read builds the cache");

		view.AddClass("big");

		// The first read after the change starts the transition FROM the old value.
		Test.Assert(Near(Red(view), 0.0f));
		Test.Assert(Near(view.ResolveStyleFloat(.FontSize), 20), "unlisted, so instant");
		Test.Assert(view.ActiveTransitionCount == 1);
		Test.Assert(fixture.Context.TransitioningViewCount == 1);

		// And the frame clock moves it.
		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(Red(view), 0.5f));
		fixture.Context.BeginFrame(0.03f);
		Test.Assert(Near(Red(view), 0.8f));

		fixture.Context.BeginFrame(0.05f); // past the end
		Test.Assert(Near(Red(view), 1.0f));
		Test.Assert(view.ActiveTransitionCount == 0, "the entry left");
		Test.Assert(!view.IsTransitioning);
		Test.Assert(fixture.Context.TransitioningViewCount == 0);
	}

	/// A zero duration is instant, and a style generation bump with no VALUE change starts
	/// nothing: a theme wide rule must not animate on every unrelated tree edit.
	[Test]
	public static void ZeroDurationIsInstantAndAnUnchangedValueStartsNothing()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { transition: text-color 0ms; text-color: #000000; }
			.big { text-color: #ffffff; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(Red(view), 0.0f));

		view.AddClass("big");
		Test.Assert(Near(Red(view), 1.0f), "instant");
		Test.Assert(view.ActiveTransitionCount == 0);

		// An unrelated tree mutation bumps the generation; the values are the same.
		fixture.Leaf();
		Test.Assert(Near(Red(view), 1.0f));
		Test.Assert(view.ActiveTransitionCount == 0);
	}

	// ---- State changes ----------------------------------------------------------------------

	/// Reversing mid flight RETARGETS from the current value rather than snapping back to the
	/// start, which is what makes a fast hover in and out look continuous.
	[Test]
	public static void ReversingMidFlightRetargetsFromTheCurrentValue()
	{
		let fixture = scope Fixture(LoadSSS("""
			StatefulView { transition: text-color 100ms linear; text-color: #000000; }
			StatefulView:hover { text-color: #ffffff; }
			"""));
		let view = fixture.Stateful();
		Test.Assert(Near(Red(view), 0.0f));

		view.State = .Hover;
		Test.Assert(Near(Red(view), 0.0f), "starts");
		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(Red(view), 0.5f));

		// Hover out halfway: the new transition runs from 0.5 back to 0 over a FULL hundred ms.
		view.State = .Normal;
		Test.Assert(Near(Red(view), 0.5f), "no snap");
		Test.Assert(view.ActiveTransitionCount == 1, "retargeted, not stacked");

		fixture.Context.BeginFrame(0.025f);
		Test.Assert(Near(Red(view), 0.375f));
		fixture.Context.BeginFrame(0.075f);
		Test.Assert(Near(Red(view), 0.0f));
		Test.Assert(view.ActiveTransitionCount == 0);
	}

	[Test]
	public static void EasingAndDelayShapeTheCurve()
	{
		let fixture = scope Fixture(LoadSSS("""
			StatefulView { transition: text-color 100ms ease-in 50ms; text-color: #000000; }
			StatefulView:hover { text-color: #ffffff; }
			"""));
		let view = fixture.Stateful();
		Test.Assert(Near(Red(view), 0.0f));

		view.State = .Hover;
		Test.Assert(Near(Red(view), 0.0f));

		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(Red(view), 0.0f), "still inside the delay");

		fixture.Context.BeginFrame(0.05f);
		// Halfway through, CSS's ease-in, cubic-bezier(0.42, 0, 1, 1), is 0.3154.
		Test.Assert(Near(Red(view), 0.3154f, 0.002f), scope $"{Red(view)}");
	}

	/// A transform interpolates its move, turn and scale, and a transition on it only redraws.
	[Test]
	public static void ATransformInterpolatesItsMoveTurnAndScale()
	{
		StyleTransform from = .();
		StyleTransform to = .();
		to.Translate = .(0.0f, -8.0f);
		to.RotateDegrees = 90.0f;
		to.Scale = .(1.5f, 1.5f);
		let mid = StyleValueOps.Lerp(.Transform(from), .Transform(to), 0.5f).AsTransform.Value;
		Test.Assert(Near(mid.Translate.Y, -4.0f));
		Test.Assert(Near(mid.RotateDegrees, 45.0f));
		Test.Assert(Near(mid.Scale.X, 1.25f));
		Test.Assert(StylePropertyKinds.IsAnimatable(.Transform));
		Test.Assert(StylePropertyKinds.IsVisualOnly(.Transform), "a lift never relays the page out");
	}

	/// The named easings are CSS's curves, as a browser computes them at their midpoints; a
	/// curve may overshoot, steps hold each level, and sheets write cubic-bezier(), steps(),
	/// step-start and step-end, a curve's x kept within 0 to 1.
	[Test]
	public static void TimingFunctionsAreCssCurvesCubicBezierAndSteps()
	{
		Test.Assert(Near(TimingFunction.Linear.Evaluate(0.5f), 0.5f));
		Test.Assert(Near(TimingFunction.Ease.Evaluate(0.5f), 0.8024f, 0.002f));
		Test.Assert(Near(TimingFunction.EaseIn.Evaluate(0.5f), 0.3154f, 0.002f));
		Test.Assert(Near(TimingFunction.EaseOut.Evaluate(0.5f), 1.0f - 0.3154f, 0.002f));
		Test.Assert(Near(TimingFunction.EaseInOut.Evaluate(0.5f), 0.5f));
		Test.Assert(Near(TimingFunction.Ease.Evaluate(0.0f), 0.0f));
		Test.Assert(Near(TimingFunction.Ease.Evaluate(1.0f), 1.0f));
		// A back-out bounce: y past 1 between the ends.
		let back = TimingFunction.CubicBezier(0.34f, 1.56f, 0.64f, 1.0f);
		Test.Assert(back.Evaluate(0.6f) > 1.0f);
		// Steps jump at a step's end, or its start.
		Test.Assert(Near(TimingFunction.StepsOf(4).Evaluate(0.3f), 0.25f));
		Test.Assert(Near(TimingFunction.StepsOf(4, true).Evaluate(0.3f), 0.5f));
		Test.Assert(Near(TimingFunction.StepsOf(4).Evaluate(1.0f), 1.0f));


		let sheet = LoadSSS("TestView { transition: opacity 200ms cubic-bezier(0.34, 1.56, 0.64, 1), text-color 1s steps(5, start), background 1s step-end, border-color 1s cubic-bezier(1.5, 0, -1, 1); }");
		defer sheet.ReleaseRef();
		let list = sheet.GetRule(0).GetValue(.Transition).Value.AsTransitions;
		Test.Assert((list != null) && (list.Specs.Count == 4));
		Test.Assert(list.Specs[0].Easing == back);
		Test.Assert(Near(list.Specs[0].Duration, 0.2f));
		Test.Assert(list.Specs[1].Easing == TimingFunction.StepsOf(5, true));
		Test.Assert(list.Specs[2].Easing == TimingFunction.StepsOf(1, false));
		Test.Assert(Near(list.Specs[3].Easing.X1, 1.0f) && Near(list.Specs[3].Easing.X2, 0.0f), "x kept within 0 to 1");
	}

	/// A state change CROSS FADES a state aware background: the old state draws under the new
	/// one at rising opacity, which is why the batch briefly carries both.
	[Test]
	public static void AStateChangeCrossFadesAStateAwareBackground()
	{
		let fixture = scope Fixture(LoadSSS("StatefulView { transition: all 100ms linear; }"));
		let view = fixture.Stateful();
		view.SetStyle(.Background, new StateColorDrawable());
		UITest.LayoutPass(fixture.Context, fixture.Root);

		let plain = scope VGContext();
		fixture.Context.DrawRootView(fixture.Root, plain);
		Test.Assert(plain.GetBatch().Vertices.Count == 4, "one red quad");
		Test.Assert(Near(plain.GetBatch().Vertices[0].Color.R, 1.0f));

		view.State = .Hover;
		let starting = scope VGContext();
		fixture.Context.DrawRootView(fixture.Root, starting);
		Test.Assert(starting.GetBatch().Vertices.Count == 8, "the blend starts here");
		Test.Assert(view.IsTransitioning);

		fixture.Context.BeginFrame(0.05f);
		let midway = scope VGContext();
		fixture.Context.DrawRootView(fixture.Root, midway);
		let batch = midway.GetBatch();
		Test.Assert(batch.Vertices.Count == 8);
		Test.Assert(Near(batch.Vertices[0].Color.R, 1.0f), "the old state at full strength");
		Test.Assert(Near(batch.Vertices[0].Color.A, 1.0f));
		Test.Assert(Near(batch.Vertices[4].Color.G, 1.0f), "the new state over it");
		Test.Assert(Near(batch.Vertices[4].Color.A, 0.5f));

		fixture.Context.BeginFrame(0.06f);
		Test.Assert(!view.IsTransitioning);
		let settled = scope VGContext();
		fixture.Context.DrawRootView(fixture.Root, settled);
		Test.Assert(settled.GetBatch().Vertices.Count == 4, "one green quad");
		Test.Assert(Near(settled.GetBatch().Vertices[0].Color.G, 1.0f));
	}

	// ---- Damage -----------------------------------------------------------------------------

	/// A property DECLARES its own damage kind, so animating a colour costs a redraw and
	/// animating a font size costs a relayout. Getting this wrong makes every hover relayout
	/// the tree.
	[Test]
	public static void DamageFollowsThePropertysKind()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { transition: font-size 100ms, text-color 100ms; font-size: 10; text-color: #000; }
			.big { font-size: 20; }
			.light { text-color: #fff; }
			"""));
		let view = fixture.Leaf();
		UITest.LayoutPass(fixture.Context, fixture.Root);

		view.AddClass("light");
		Red(view); // starts the VISUAL transition
		UITest.LayoutPass(fixture.Context, fixture.Root);
		fixture.Context.ClearLayoutDamage();
		Test.Assert(!fixture.Context.NeedsLayout);

		fixture.Context.BeginFrame(0.01f);
		Test.Assert(!fixture.Context.NeedsLayout, "a colour does not relayout");
		Test.Assert(fixture.Context.NeedsRedraw);

		view.AddClass("big");
		view.ResolveStyleFloat(.FontSize); // starts the LAYOUT kind one
		UITest.LayoutPass(fixture.Context, fixture.Root);
		fixture.Context.ClearLayoutDamage();

		fixture.Context.BeginFrame(0.01f);
		Test.Assert(fixture.Context.NeedsLayout, "a font size does");
	}

	// ---- Motion is theme data ---------------------------------------------------------------

	/// The ENGINE adds no motion of its own. A sheet with no transition rule animates nothing,
	/// and a theme declares it on View so everything inherits it; a later type rule opts that
	/// type out.
	[Test]
	public static void MotionComesFromTheThemeAndTheEngineAddsNoDefaults()
	{
		let fixture = scope Fixture(LoadSSS("TestView { text-color: #000; }"));
		let leaf = fixture.Leaf();
		let group = new TestGroup();
		fixture.Root.AddView(group);

		Test.Assert(leaf.ResolveStyle(.Transition).AsTransitions == null);
		Test.Assert(group.ResolveStyle(.Transition).AsTransitions == null);

		// A group is opted out here, the point being that a later type rule overrides the View
		// wide one.
		fixture.Context.SetStyleSheet(LoadSSS("""
			View { transition: all 120ms ease-out; }
			TestGroup { transition: none; }
			"""));

		let onLeaf = leaf.ResolveStyle(.Transition);
		Test.Assert(onLeaf.AsTransitions != null);
		let all = onLeaf.AsTransitions.Find(.TextColor);
		Test.Assert(all != null);
		Test.Assert(Near(all.Value.Duration, 0.12f));
		Test.Assert(all.Value.Easing == TimingFunction.EaseOut);

		let onGroup = group.ResolveStyle(.Transition);
		Test.Assert(onGroup.AsTransitions != null);
		Test.Assert(onGroup.AsTransitions.Find(.TextColor) == null, "opted out");
	}

	/// A child with NO rule of its own inherits the parent's mid flight value through the
	/// overlay, without starting an entry of its own.
	[Test]
	public static void AChildInheritsTheParentsMidFlightValue()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestGroup { transition: text-color 100ms linear; text-color: #000000; }
			TestGroup.light { text-color: #ffffff; }
			"""));
		let group = new TestGroup();
		fixture.Root.AddView(group);
		let child = new TestView(50.0f, 30.0f);
		group.AddView(child);
		Test.Assert(Near(Red(child), 0.0f));

		group.AddClass("light");
		Test.Assert(Near(Red(group), 0.0f), "it starts on the parent");

		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(Red(group), 0.5f));
		Test.Assert(Near(Red(child), 0.5f), "inherited through the overlay");
		Test.Assert(child.ActiveTransitionCount == 0, "with no entry of its own");
	}

	/// Only a CHANGED winner starts an entry, which is what keeps a theme wide `all` rule cheap:
	/// gaining a property that had no old value, or losing one entirely, animates nothing.
	[Test]
	public static void OnlyAChangedWinnerStartsAnEntry()
	{
		let fixture = scope Fixture(LoadSSS("""
			View { transition: all 100ms linear; }
			TestView { text-color: #000000; font-size: 10; }
			.tag { border-color: #ff0000; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(Red(view), 0.0f));

		view.AddClass("tag"); // border-color gains a winner; the others keep theirs
		Red(view);
		Test.Assert(view.ActiveTransitionCount == 0, "no old value to start from");

		view.RemoveClass("tag");
		Red(view);
		Test.Assert(view.ActiveTransitionCount == 0, "and losing it goes to None");
	}

	// ---- Edges ------------------------------------------------------------------------------

	/// A sheet SWAP ends the running transitions without animating to the new values: the old
	/// rule objects are gone, so there is nothing coherent to animate from.
	[Test]
	public static void ASheetSwapEndsRunningTransitionsWithoutAnimating()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { transition: text-color 100ms linear; text-color: #000000; }
			.big { text-color: #ffffff; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(Red(view), 0.0f));
		view.AddClass("big");
		Red(view);
		fixture.Context.BeginFrame(0.05f);
		Test.Assert(Near(Red(view), 0.5f));

		fixture.Context.SetStyleSheet(
			LoadSSS("TestView { transition: text-color 100ms linear; text-color: #0000ff; }"));

		Test.Assert(Near(Red(view), 0.0f), "the new sheet's value, at once");
		Test.Assert(view.ActiveTransitionCount == 0);
		fixture.Context.BeginFrame(0.01f);
		Test.Assert(fixture.Context.TransitioningViewCount == 0);
	}

	/// Detaching mid flight DE LISTS the view, so the frame tick never reaches a view that has
	/// left the tree.
	[Test]
	public static void DetachingMidFlightDeListsTheView()
	{
		let fixture = scope Fixture(LoadSSS("""
			TestView { transition: text-color 100ms linear; text-color: #000000; }
			.big { text-color: #ffffff; }
			"""));
		let view = fixture.Leaf();
		view.AddRef(); // held past the removal
		Test.Assert(Near(Red(view), 0.0f));
		view.AddClass("big");
		Red(view);
		Test.Assert(fixture.Context.TransitioningViewCount == 1);

		fixture.Root.RemoveView(view);

		Test.Assert(fixture.Context.TransitioningViewCount == 0);
		Test.Assert(!view.IsTransitioning);

		view.ReleaseRef(); // gone for good
		fixture.Context.BeginFrame(0.05f); // nothing dangling to tick
		Test.Assert(fixture.Context.TransitioningViewCount == 0);
	}

	/// The shipped themes declare their own MOTION, and declare it narrowly.
	///
	/// There is no user-agent sheet and no hard-coded list of which controls animate: a theme
	/// says what transitions, so a theme that wants none simply says nothing. What it must not
	/// say is geometry - animating a font size relayouts the tree every frame of the
	/// transition, so the rule covers colour and nothing else.
	[Test]
	public static void TheShippedThemesCarryAMotionRuleThatExcludesGeometry()
	{
		StyleSheetLoader.InitializeGlobals();

		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root);
		defer { root.ReleaseRef(); delete context; }

		context.SetStyleSheet(DarkTheme.Create());

		let button = new Button("Go");
		root.AddView(button);

		let transitions = button.ResolveStyle(.Transition).AsTransitions;
		Test.Assert(transitions != null, "the theme declares motion");
		Test.Assert(transitions.Find(.Background) != null);
		Test.Assert(transitions.Find(.TextColor) != null);
		Test.Assert(transitions.Find(.FontSize) == null, "geometry never animates");
	}

	// ---- Animations (@keyframes) --------------------------------------------------------------

	private static float OpacityOf(View view) => view.ResolveStyleFloat(.Opacity, -1.0f);

	/// @keyframes keep their frames by offset, a shared block under each of its selectors, and
	/// the animation list reads its parts in any order.
	[Test]
	public static void KeyframesAndTheAnimationListParse()
	{
		let sheet = LoadSSS("""
			@keyframes pulse { to { opacity: 1; } from { opacity: 0; } 25%, 75% { opacity: 0.8; } }
			TestView { animation: pulse 2s cubic-bezier(0.2, 0, 0, 1) 500ms infinite alternate both, spin 300ms 3 reverse forwards; }
			.none { animation: none; }
			""");
		defer sheet.ReleaseRef();
		let pulse = sheet.FindKeyframes("pulse");
		Test.Assert(pulse != null);
		Test.Assert(pulse.Frames.Count == 4);
		Test.Assert(Near(pulse.Frames[0].Offset, 0.0f) && Near(pulse.Frames[1].Offset, 0.25f));
		Test.Assert(Near(pulse.Frames[2].Offset, 0.75f) && Near(pulse.Frames[3].Offset, 1.0f));
		Test.Assert(pulse.Animates(.Opacity));
		Test.Assert(!pulse.Animates(.TextColor));
		Test.Assert(sheet.FindKeyframes("spin") == null);

		let list = sheet.GetRule(0).GetValue(.Animation).Value.AsAnimations;
		Test.Assert((list != null) && (list.Specs.Count == 2));
		let a = list.Specs[0];
		Test.Assert(a.Name == "pulse");
		Test.Assert(Near(a.Duration, 2.0f) && Near(a.Delay, 0.5f));
		Test.Assert(a.Iterations < 0.0f);
		Test.Assert((a.Direction == .Alternate) && (a.Fill == .Both));
		Test.Assert(a.Easing == TimingFunction.CubicBezier(0.2f, 0.0f, 0.0f, 1.0f));
		let b = list.Specs[1];
		Test.Assert(Near(b.Duration, 0.3f) && Near(b.Iterations, 3.0f));
		Test.Assert((b.Direction == .Reverse) && (b.Fill == .Forwards));
		let none = sheet.GetRule(1).GetValue(.Animation).Value.AsAnimations;
		Test.Assert((none != null) && none.Specs.IsEmpty);
	}

	/// Keyframes play over the cascade, a missing frame being the cascade's value, and a
	/// forwards fill holds the end without starting again.
	[Test]
	public static void KeyframesPlayOverTheCascadeAndAFillHoldsTheEnd()
	{
		let fixture = scope Fixture(LoadSSS("""
			@keyframes fade { to { opacity: 1; } }
			TestView { opacity: 0.2; animation: fade 1s linear forwards; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(OpacityOf(view), 0.2f), "no from frame: the cascade's value");
		fixture.Context.BeginFrame(0.5f);
		Test.Assert(Near(OpacityOf(view), 0.6f));
		fixture.Context.BeginFrame(0.75f);
		Test.Assert(Near(OpacityOf(view), 1.0f), "forwards holds the last frame");
		Test.Assert(view.RunningAnimationCount == 0);
		fixture.Context.BeginFrame(1.0f);
		Test.Assert(Near(OpacityOf(view), 1.0f), "and it does not start again");
	}

	/// Without a fill an animation gives the cascade back; a delay waits on the cascade, and a
	/// backwards fill shows the first frame during it.
	[Test]
	public static void WithoutAFillTheCascadeComesBackAndBackwardsShowsTheFirstFrame()
	{
		let fixture = scope Fixture(LoadSSS("""
			@keyframes dim { from { opacity: 0.5; } to { opacity: 0; } }
			TestView { opacity: 1; animation: dim 1s linear 1s; }
			.early { animation: dim 1s linear 1s backwards; }
			"""));
		let view = fixture.Leaf();
		Test.Assert(Near(OpacityOf(view), 1.0f), "inside the delay: the cascade");
		fixture.Context.BeginFrame(1.5f);
		Test.Assert(Near(OpacityOf(view), 0.25f));
		fixture.Context.BeginFrame(1.0f);
		Test.Assert(Near(OpacityOf(view), 1.0f), "ended, no fill: the cascade again");

		let early = fixture.Leaf();
		early.AddClass("early");
		Test.Assert(Near(OpacityOf(early), 0.5f), "its delay shows the first frame");
	}

	/// Alternate runs every other iteration backwards, each segment between frames eased.
	[Test]
	public static void AlternateRunsEveryOtherIterationBackwards()
	{
		let fixture = scope Fixture(LoadSSS("""
			@keyframes swing { from { opacity: 0; } 50% { opacity: 1; } to { opacity: 0.5; } }
			TestView { animation: swing 1s linear infinite alternate; }
			"""));
		let view = fixture.Leaf();
		OpacityOf(view);
		fixture.Context.BeginFrame(0.25f);
		Test.Assert(Near(OpacityOf(view), 0.5f), "half way to the 50% frame");
		fixture.Context.BeginFrame(0.5f);
		Test.Assert(Near(OpacityOf(view), 0.75f), "75%: half way from 1 to 0.5");
		fixture.Context.BeginFrame(0.5f);
		Test.Assert(Near(OpacityOf(view), 0.75f), "the second iteration backwards, at 75% again");
		Test.Assert(view.RunningAnimationCount == 1);
	}

	/// A transform keyframe animates the drawn transform and only redraws.
	[Test]
	public static void ATransformKeyframeAnimatesTheDrawnTransformAndOnlyRedraws()
	{
		let fixture = scope Fixture(LoadSSS("""
			@keyframes bob { from { transform: translateY(0); } to { transform: translateY(-10); } }
			TestView { animation: bob 1s linear; }
			"""));
		let view = fixture.Leaf();
		UITest.LayoutPass(fixture.Context, fixture.Root);
		fixture.Context.ClearLayoutDamage();
		fixture.Context.BeginFrame(0.5f);
		Test.Assert(!fixture.Context.NeedsLayout, "a transform never moves the layout");
		let canvas = scope VGContext();
		fixture.Context.DrawRootView(fixture.Root, canvas);
		Test.Assert(Near(view.EffectiveTransform.Translation.Y, -5.0f));
	}
}
