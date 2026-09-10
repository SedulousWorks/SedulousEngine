using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// Style model v2 P2: the box model on every view. Draw and hit order by z index, absolutely
/// positioned children in any container, box shadow through the VG, opacity composing down the
/// tree, and the sheet filling the LayoutStyle fields the view did not declare inline.
class BoxModelTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A TestView that records the order it was drawn in, and paints an OPAQUE rect so the
	/// batch carries its composed opacity.
	private class RecordingView : TestView
	{
		public static List<RecordingView> DrawLog = new .() ~ delete _;
		public int32 Tag = 0;

		public this(float width, float height, int32 tag) : base(width, height)
		{
			Tag = tag;
		}

		public override void OnDraw(UIDrawContext ctx)
		{
			DrawLog.Add(this);
			ctx.VG.FillRect(.(0, 0, Width, Height), Color(1.0f, 0.0f, 0.0f, 1.0f));
		}
	}

	private static void EnsureGlobals()
	{
		StyleSheetLoader.InitializeGlobals();
		UITypeRegistry.Register("View", typeof(View));
		UITypeRegistry.Register("RootView", typeof(RootView));
		UITypeRegistry.Register("TestView", typeof(TestView));
		UITypeRegistry.Register("TestGroup", typeof(TestGroup));
		UITypeRegistry.Register("RecordingView", typeof(RecordingView));
	}

	/// OWNERSHIP of the sheet transfers.
	private static StyleSheet LoadSSS(StringView source)
	{
		EnsureGlobals();
		let loader = scope StyleSheetLoader();
		return loader.Load(source);
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	private static bool FindCommandWithMode(VGBatch batch, VGDrawMode mode, out VGCommand found)
	{
		for (let command in batch.Commands)
		{
			if ((command.DrawMode == mode) && (command.IndexCount > 0))
			{
				found = command;
				return true;
			}
		}
		found = .();
		return false;
	}

	// ---- z index ----------------------------------------------------------------------------

	/// z index orders the draw BACK to front, and a tie keeps child order, which is what makes
	/// the sort stable enough to reason about.
	[Test]
	public static void ZIndexOrdersTheDrawAndTiesKeepChildOrder()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let frame = new FrameLayout();
		let a = new RecordingView(50, 30, 1);
		let b = new RecordingView(50, 30, 2);
		let c = new RecordingView(50, 30, 3);
		var front = LayoutStyle();
		front.ZIndex = .(1, true);
		frame.AddView(a, front);
		frame.AddView(b); // z 0
		frame.AddView(c, front);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		Test.Assert(RecordingView.DrawLog.Count == 3);
		Test.Assert(RecordingView.DrawLog[0].Tag == 2, "z 0 draws first");
		Test.Assert(RecordingView.DrawLog[1].Tag == 1, "then the z 1 pair in child order");
		Test.Assert(RecordingView.DrawLog[2].Tag == 3);

		// With no z index at all the child order is untouched.
		a.SetLayout(.());
		c.SetLayout(.());
		UITest.LayoutPass(context, root);
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		Test.Assert(RecordingView.DrawLog.Count == 3);
		Test.Assert(RecordingView.DrawLog[0].Tag == 1);
		Test.Assert(RecordingView.DrawLog[2].Tag == 3);
	}

	/// And the hit test walks the SAME order in reverse, so what looks topmost is what answers
	/// the pointer even when it is the first child.
	[Test]
	public static void HitTestingWalksTheZOrderFrontToBack()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let frame = new FrameLayout();
		let below = new TestView(100, 100);
		let above = new TestView(100, 100);
		var front = LayoutStyle();
		front.ZIndex = .(5, true);
		frame.AddView(above, front); // the FIRST child, but drawn on top
		frame.AddView(below);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(frame.HitTest(.(10, 10)) == above);

		front.ZIndex = .(-5, true);
		above.SetLayout(front);
		Test.Assert(frame.HitTest(.(10, 10)) == below, "pushed behind");
	}

	// ---- Absolute positioning ---------------------------------------------------------------

	/// An absolute child inside a FLEX takes no flow space: the flow children pack as if it
	/// were not there, and the badge lands on its own insets.
	[Test]
	public static void AnAbsoluteChildInsideAFlexTakesNoFlowSpace()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let flex = new FlexLayout();
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		let badge = new TestView(20, 10);
		var absolute = LayoutStyle();
		absolute.Position = .(.Absolute, true);
		absolute.Left = .(10, true);
		absolute.Top = .(5, true);
		flex.AddView(a);
		flex.AddView(badge, absolute);
		flex.AddView(b);

		let host = new FrameLayout();
		host.AddView(flex);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 0));
		Test.Assert(Near(b.Bounds.X, 50), "packed as if the badge were absent");
		Test.Assert(Near(flex.MeasuredSize.X, 100));

		Test.Assert(Near(badge.Bounds.X, 10));
		Test.Assert(Near(badge.Bounds.Y, 5));
		Test.Assert(Near(badge.Bounds.Width, 20));
		Test.Assert(Near(badge.Bounds.Height, 10));

		Test.Assert(!View.IsInFlow(badge));
		Test.Assert(View.IsInFlow(a));
	}

	[Test]
	public static void FarInsetsAnchorTheFarEdgesAndBothInsetsPin()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let frame = new FrameLayout();
		var size = LayoutStyle();
		size.Width = .(SizeSpec.Fixed(Unit.Dp(200)), true);
		size.Height = .(SizeSpec.Fixed(Unit.Dp(100)), true);
		frame.SetLayout(size);
		frame.Padding = .(10, 10, 10, 10);

		let corner = new TestView(20, 10);
		var anchored = LayoutStyle();
		anchored.Position = .(.Absolute, true);
		anchored.Right = .(4, true);
		anchored.Bottom = .(6, true);
		frame.AddView(corner, anchored);

		let bar = new TestView(20, 10);
		var pinned = LayoutStyle();
		pinned.Position = .(.Absolute, true);
		pinned.Left = .(8, true);
		pinned.Right = .(12, true);
		pinned.Top = .(0, true);
		frame.AddView(bar, pinned);

		let host = new FrameLayout();
		host.AddView(frame);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		// The content box runs x 10 to 190 and y 10 to 90.
		Test.Assert(Near(corner.Bounds.X, 10 + 180 - 4 - 20));
		Test.Assert(Near(corner.Bounds.Y, 10 + 80 - 6 - 10));
		Test.Assert(Near(bar.Bounds.X, 10 + 8));
		Test.Assert(Near(bar.Bounds.Width, 180 - 8 - 12), "pinned between both insets");
		Test.Assert(Near(bar.Bounds.Y, 10));
	}

	[Test]
	public static void AnAbsoluteChildDoesNotGrowAWrappingContainer()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		let content = new TestView(50, 30);
		let floating = new TestView(300, 200);
		var absolute = LayoutStyle();
		absolute.Position = .(.Absolute, true);
		absolute.Left = .(5, true);
		absolute.Top = .(5, true);
		group.AddView(content);
		group.AddView(floating, absolute);

		let host = new FrameLayout();
		host.AddView(group);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(group.MeasuredSize.X, 50));
		Test.Assert(Near(group.MeasuredSize.Y, 30));
		Test.Assert(Near(floating.Bounds.X, 5));
		Test.Assert(Near(floating.Bounds.Width, 50 - 5), "loose within the content box");
	}

	// ---- Box shadow -------------------------------------------------------------------------

	/// The shadow is the child's border box grown by the SPREAD and moved by the offset, and it
	/// is drawn UNDER the child's own content.
	[Test]
	public static void ABoxShadowEmitsItsQuadsUnderTheChildWithTheRightBounds()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(
			LoadSSS("RecordingView { box-shadow: 4 6 8 2 #00000080; corner-radius: 3; }"));

		let frame = new FrameLayout();
		frame.Padding = .(20, 10, 0, 0);
		let child = new RecordingView(100, 50, 1);
		frame.AddView(child);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 20));
		Test.Assert(Near(child.Bounds.Y, 10));

		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		let batch = vg.GetBatch();
		Test.Assert(FindCommandWithMode(batch, .BoxShadow, let command));
		Test.Assert(command.IndexCount == 24, "four quadrant quads");

		var minX = float.MaxValue;
		var minY = float.MaxValue;
		var maxX = float.MinValue;
		var maxY = float.MinValue;
		var shadowVertices = 0;
		for (let vertex in batch.Vertices)
		{
			if ((vertex.Color.A <= 0.49f) || (vertex.Color.A >= 0.51f))
				continue;

			shadowVertices++;
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
			minY = Min(minY, vertex.Position.Y);
			maxY = Max(maxY, vertex.Position.Y);
			// The corner radius PLUS the spread, in sigma units.
			Test.Assert(Near(vertex.Coverage, (3.0f + 2.0f) / 4.0f));
		}
		Test.Assert(shadowVertices == 16);

		// The rect is x 20 + 4 - 2 = 22 by 104 wide, y 10 + 6 - 2 = 14 by 54 tall, and the
		// blur of eight reaches three sigma, so twelve, past each edge.
		Test.Assert(Near(minX, 22 - 12));
		Test.Assert(Near(maxX, 22 + 104 + 12));
		Test.Assert(Near(minY, 14 - 12));
		Test.Assert(Near(maxY, 14 + 54 + 12));

		// And it is the FIRST thing drawn, since it sits underneath the child.
		var shadowFirst = false;
		for (let command2 in batch.Commands)
		{
			if (command2.IndexCount == 0)
				continue;
			shadowFirst = command2.DrawMode == .BoxShadow;
			break;
		}
		Test.Assert(shadowFirst);
	}

	/// The shorthand takes its parts in any workable order: `inset` may lead or trail, the blur
	/// and spread are optional, and a missing colour falls back to the default shadow.
	[Test]
	public static void TheBoxShadowShorthandParsesItsForms()
	{
		let sheet = LoadSSS("""
			TestView { box-shadow: 1 2 #ff0000 inset; }
			.none { box-shadow: none; }
			.lead { box-shadow: inset 3 4 5; }
			""");
		defer sheet.ReleaseRef();

		Test.Assert(sheet.RuleCount == 3);

		let trailing = sheet.GetRule(0).GetValue(.BoxShadow).Value.AsShadow;
		Test.Assert(trailing != null);
		Test.Assert(Near(trailing.Value.OffsetX, 1));
		Test.Assert(Near(trailing.Value.OffsetY, 2));
		Test.Assert(Near(trailing.Value.Blur, 0), "no blur given");
		Test.Assert(trailing.Value.Inset);
		Test.Assert(Near(trailing.Value.Color.R, 1.0f));

		Test.Assert(sheet.GetRule(1).GetValue(.BoxShadow) == null, "`none` declares nothing");

		let leading = sheet.GetRule(2).GetValue(.BoxShadow).Value.AsShadow;
		Test.Assert(leading != null);
		Test.Assert(leading.Value.Inset, "the keyword may lead");
		Test.Assert(Near(leading.Value.Blur, 5));
		Test.Assert(Near(leading.Value.Color.A, 0.5f), "the default shadow colour");
	}

	// ---- Opacity ----------------------------------------------------------------------------

	/// Opacity COMPOSES: a half opaque child of a half opaque parent draws at a quarter, which
	/// is what makes fading a subtree one value rather than a walk.
	[Test]
	public static void OpacityComposesDownTheTree()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let outer = new FrameLayout();
		outer.Opacity = 0.5f;
		let inner = new RecordingView(50, 30, 1);
		inner.Opacity = 0.5f;
		outer.AddView(inner);
		root.AddView(outer);
		UITest.LayoutPass(context, root);

		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		let batch = vg.GetBatch();
		Test.Assert(batch.Vertices.Count >= 4);
		for (let vertex in batch.Vertices)
			Test.Assert(Near(vertex.Color.A, 0.25f));
	}

	// ---- The sheet filling LayoutStyle ------------------------------------------------------

	/// The cascade fills the fields the view did NOT declare inline, and an inline field wins
	/// even when its value equals the default: declared is not the same as default.
	[Test]
	public static void TheCascadeFillsUndeclaredLayoutFieldsAndInlineWins()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS("""
			.wide { width: 120; height: 40; margin: 4; }
			.fill { width: match; }
			.percent { width: 50%; }
			"""));

		let frame = new FrameLayout();
		let styled = new TestView(50, 30);
		styled.AddClass("wide");
		let inlineWins = new TestView(50, 30);
		inlineWins.AddClass("wide");
		var inlineWidth = LayoutStyle();
		inlineWidth.Width = .(SizeSpec.Fixed(Unit.Dp(60)), true); // the height stays the sheet's
		inlineWins.SetLayout(inlineWidth);
		let fill = new TestView(50, 30);
		fill.AddClass("fill");
		let half = new TestView(50, 30);
		half.AddClass("percent");

		frame.AddView(styled);
		frame.AddView(inlineWins);
		frame.AddView(fill);
		frame.AddView(half);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(styled.Bounds.Width, 120));
		Test.Assert(Near(styled.Bounds.Height, 40));
		Test.Assert(Near(styled.Bounds.X, 4), "the sheet's margin");
		Test.Assert(!styled.DeclaredLayout.Width.IsDeclared, "it came from the sheet");
		Test.Assert(styled.Layout.Width.Value.kind == .Fixed);

		Test.Assert(Near(inlineWins.Bounds.Width, 60));
		Test.Assert(Near(inlineWins.Bounds.Height, 40), "the sheet still fills the height");
		Test.Assert(inlineWins.DeclaredLayout.Width.IsDeclared);

		Test.Assert(fill.Layout.Width.Value.kind == .Match);
		Test.Assert(Near(fill.Bounds.Width, 400));
		Test.Assert(Near(half.Bounds.Width, 200));

		// An inline value EQUAL to the default still wins over the sheet.
		var wrap = LayoutStyle();
		wrap.Width = .(SizeSpec.Wrap(), true);
		fill.SetLayout(wrap);
		UITest.LayoutPass(context, root);
		Test.Assert(Near(fill.Bounds.Width, 50), "back to its own measurement");
	}

	[Test]
	public static void MinAndMaxClampFromInlineFieldsAndFromTheSheet()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS("""
			.narrow { max-width: 40; }
			.tall { min-height: 3em; font-size: 20; }
			"""));

		let frame = new FrameLayout();

		let clampedInline = new TestView(50, 30);
		var inlineLimits = LayoutStyle();
		inlineLimits.MinWidth = .(Unit.Dp(80), true);
		inlineLimits.MaxHeight = .(Unit.Dp(20), true);
		frame.AddView(clampedInline, inlineLimits);

		let narrow = new TestView(50, 30);
		narrow.AddClass("narrow");
		frame.AddView(narrow);

		let tall = new TestView(50, 30);
		tall.AddClass("tall");
		frame.AddView(tall);

		let fixedButClamped = new TestView(50, 30);
		var fixedLimits = LayoutStyle();
		fixedLimits.Width = .(SizeSpec.Fixed(Unit.Dp(100)), true);
		fixedLimits.MaxWidth = .(Unit.Percent(10), true); // of the four hundred wide frame
		frame.AddView(fixedButClamped, fixedLimits);

		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(clampedInline.Bounds.Width, 80), "a minimum grows it");
		Test.Assert(Near(clampedInline.Bounds.Height, 20), "a maximum shrinks it");
		Test.Assert(Near(narrow.Bounds.Width, 40), "from the sheet");
		Test.Assert(Near(tall.Bounds.Height, 60), "three em of a twenty unit font");
		Test.Assert(Near(fixedButClamped.Bounds.Width, 40), "a maximum beats a fixed size");
	}

	/// Position, z index, the insets, overflow, flex grow and align self all come from the
	/// sheet too, and REMOVING the class un-styles the field again on the next pass.
	[Test]
	public static void EveryLayoutFieldComesFromTheSheetAndUnstylesCleanly()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS("""
			.badge { position: absolute; right: 4; top: 2; z-index: 3; }
			.clip { overflow: hidden; }
			.grow { flex-grow: 1; align-self: end; }
			"""));

		let flex = new FlexLayout();
		var size = LayoutStyle();
		size.Width = .(SizeSpec.Fixed(Unit.Dp(300)), true);
		size.Height = .(SizeSpec.Fixed(Unit.Dp(100)), true);
		flex.SetLayout(size);

		let a = new TestView(50, 30);
		let badge = new TestView(20, 10);
		badge.AddClass("badge");
		let grow = new TestView(50, 30);
		grow.AddClass("grow");
		let clip = new TestView(50, 30);
		clip.AddClass("clip");
		flex.AddView(a);
		flex.AddView(badge);
		flex.AddView(grow);
		flex.AddView(clip);

		let host = new FrameLayout();
		host.AddView(flex);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		Test.Assert(badge.Layout.Position.Value == .Absolute);
		Test.Assert(badge.Layout.ZIndex.Value == 3);
		Test.Assert(Near(badge.Bounds.X, 300 - 4 - 20));
		Test.Assert(Near(badge.Bounds.Y, 2));

		Test.Assert(Near(grow.Layout.FlexGrow.Value, 1));
		Test.Assert(grow.Layout.AlignSelf != null);
		Test.Assert(grow.Layout.AlignSelf.Value == .End);
		Test.Assert(Near(grow.Bounds.Width, 300 - 50 - 50), "it absorbed the free space");
		Test.Assert(Near(grow.Bounds.Y, 100 - 30));

		Test.Assert(clip.EffectiveClipsContent);
		Test.Assert(!clip.ClipsContent, "the FIELD was never set, only the style");
		Test.Assert(!a.EffectiveClipsContent);

		// Nothing STICKS: removing the class puts the field back.
		clip.RemoveClass("clip");
		badge.RemoveClass("badge");
		UITest.LayoutPass(context, root);

		Test.Assert(!clip.EffectiveClipsContent);
		Test.Assert(badge.Layout.Position.Value == .Static);
		Test.Assert(View.IsInFlow(badge));
	}

	/// Declared distinguishes SET TO THE DEFAULT from unset, which is the whole reason the
	/// cascade can tell what to fill in.
	[Test]
	public static void DeclaredDistinguishesSetToDefaultFromUnset()
	{
		var unset = LayoutStyle();
		var declared = LayoutStyle();
		Test.Assert(unset == declared);

		declared.Width = .(SizeSpec.Wrap(), true); // the default VALUE, but declared
		Test.Assert(!(unset == declared));
		Test.Assert(declared.Width.IsDeclared);
		Test.Assert(declared.Width.Value == SizeSpec.Wrap());

		declared.Width.Clear(SizeSpec.Wrap());
		Test.Assert(unset == declared);
	}

	// ---- Length values through the plain accessor --------------------------------------------

	/// ResolveStyleFloat resolves a LENGTH, so a theme written in em reaches every control that
	/// reads a plain float without each one having to know.
	[Test]
	public static void ResolveStyleFloatResolvesALengthValue()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(
			LoadSSS("TestView { font-size: 20; corner-radius: 0.5em; spacing: calc(2em + 4); }"));

		let view = new TestView(50, 30);
		root.AddView(view);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(view.ResolveStyleFloat(.CornerRadius, -1.0f), 10));
		Test.Assert(Near(view.ResolveStyleFloat(.Spacing, -1.0f), 44));
		Test.Assert(Near(view.ResolveStyleFloat(.BorderWidth, -1.0f), -1), "unset stays unset");
	}
}
