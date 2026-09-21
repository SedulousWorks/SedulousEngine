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
		Test.Assert(list.Specs[0].Easing == .EaseIn);
		Test.Assert(list.Specs[1].Property == .Opacity);
		Test.Assert(Near(list.Specs[1].Duration, 1.0f));
		Test.Assert(list.Specs[1].Easing == .Ease, "the default easing");
		Test.Assert(list.Specs[2].Property == .COUNT, "`all`");
		Test.Assert(Near(list.Specs[2].Duration, 0.12f), "a bare number is milliseconds");
		Test.Assert(list.Specs[2].Easing == .EaseOut);

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
		Test.Assert(Near(Red(view), 0.25f), "halfway through, ease-in gives a quarter");
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
		Test.Assert(all.Value.Easing == .EaseOut);

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
}
