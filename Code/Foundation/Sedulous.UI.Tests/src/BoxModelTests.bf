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

	/// The shadow's corners for `sheetText` over a 100 by 50 view, in sigma units, as every
	/// shadow vertex's coverage carries them; -1 when nothing drew a shadow.
	private static float ShadowCoverage(StringView sheetText)
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS(sheetText));
		let child = new RecordingView(100, 50, 1);
		root.AddView(child);
		UITest.LayoutPass(context, root);
		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);
		for (let vertex in vg.GetBatch().Vertices)
		{
			if ((vertex.Color.A > 0.49f) && (vertex.Color.A < 0.51f))
				return vertex.Coverage;
		}
		return -1.0f;
	}

	/// A card that rounds its background (rounded-rect(..., radius=24), as Sky Hopper's cloud
	/// and HUD cards do) and sets no corner-radius casts a shadow with those corners, grown by
	/// its spread; a corner-radius the view sets still decides. Blur 8 is sigma 4.
	[Test]
	public static void ABoxShadowFollowsTheCornersItsBackgroundRounds()
	{
		Test.Assert(Near(ShadowCoverage("RecordingView { background: rounded-rect(#FFFFFF, radius=12); box-shadow: 0 0 8 #00000080; }"), 12.0f / 4.0f));
		Test.Assert(Near(ShadowCoverage("RecordingView { background: rounded-rect(#FFFFFF, radius=12); box-shadow: 0 0 8 2 #00000080; }"), 14.0f / 4.0f));
		Test.Assert(Near(ShadowCoverage("RecordingView { background: rounded-rect(#FFFFFF, radius=12); corner-radius: 3; box-shadow: 0 0 8 #00000080; }"), 3.0f / 4.0f));
		// A background that rounds nothing leaves the shadow square.
		Test.Assert(Near(ShadowCoverage("RecordingView { background: #FFFFFF; box-shadow: 0 0 8 #00000080; }"), 0.0f));
	}

	/// Draws that a stencil clip holds, under a clipping card styled by `sheetText` that holds
	/// one view.
	private static int StencilClippedDraws(StringView sheetText)
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS(sheetText));
		let card = new FrameLayout();
		card.AddClass("card");
		card.ClipsContent = true;
		card.AddView(new RecordingView(100, 50, 1));
		root.AddView(card);
		UITest.LayoutPass(context, root);
		let vg = scope VGContext();
		vg.SetStencilFills(true);
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);
		var clipped = 0;
		for (let command in vg.GetBatch().Commands)
		{
			if ((command.IndexCount > 0) && (command.ClipMode == .Stencil) && (command.FillPhase == .Direct))
				clipped++;
		}
		return clipped;
	}

	/// What a clipping card holds draws inside its corners: through a stencil clip of its
	/// rounded box, over the rectangle clip every clipping view keeps. The corners a background
	/// rounds clip as they shape the shadow; a square card stays a scissor.
	[Test]
	public static void AClippingViewWithRoundedCornersClipsItsChildrenToThem()
	{
		Test.Assert(StencilClippedDraws(".card { corner-radius: 8; }") > 0);
		Test.Assert(StencilClippedDraws(".card { background: rounded-rect(#FFFFFF, radius=12); }") > 0);
		Test.Assert(StencilClippedDraws(".card { background: #FFFFFF; }") == 0);
	}

	/// A list, each shadow drawn, the first on top: the outer ones under the content (the last
	/// first), the inset ones over it. An rgba()'s commas are its own.
	[Test]
	public static void ABoxShadowTakesAListEachDrawnTheFirstOnTop()
	{
		let sheet = LoadSSS("RecordingView { box-shadow: 0 2 4 rgba(255, 0, 0, 0.5), inset 1 1 2 #0000FF80, 0 8 16 #00FF0080; }");
		let value = sheet.GetRule(0).GetValue(.BoxShadow).Value;
		Test.Assert(value.ShadowCount == 3);
		Test.Assert(Near(value.ShadowAt(0).Color.R, 1.0f));
		Test.Assert(value.ShadowAt(1).Inset);
		Test.Assert(Near(value.ShadowAt(2).Blur, 16.0f));

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(sheet);
		root.AddView(new RecordingView(100, 50, 1));
		UITest.LayoutPass(context, root);
		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		let order = scope String();
		var contentSeen = false;
		let vertices = vg.GetBatch().Vertices;
		for (int i = 0; (i + 3) < vertices.Count; i += 4)
		{
			let c = vertices[i].Color;
			let shadow = (c.A > 0.49f) && (c.A < 0.51f);
			let tag = !shadow ? 'c' : (c.R > 0.99f) ? 'r' : (c.G > 0.99f) ? 'g' : 'b';
			if ((tag == 'c') && contentSeen)
				continue;
			contentSeen = contentSeen || (tag == 'c');
			if (order.IsEmpty || (order[order.Length - 1] != tag))
				order.Append(tag);
		}
		Test.Assert(order == "grcb", order);
	}

	/// A box under a scaled view rounds to the device pixels it is drawn on: at a scale of 0.5,
	/// a box at 3 layout units would sit at 1.5 device pixels, so it rounds to 4 (2 device
	/// pixels) and the top at 5 (2.5) to 6, its far edges too. Unscaled, the DPI's grid alone.
	[Test]
	public static void ABoxUnderAScaledViewRoundsToTheDevicePixelsItIsDrawnOn()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let canvas = new FrameLayout();
		canvas.Transform.Scale = .(0.5f, 0.5f);
		canvas.Transform.Origin = .(0.0f, 0.0f);
		let child = new TestView(21, 11);
		var placed = LayoutStyle();
		placed.Margin = .(Thickness(3, 5, 0, 0), true);
		child.SetLayout(placed);
		canvas.AddView(child);
		root.AddView(canvas);
		UITest.LayoutPass(context, root);
		Test.Assert(Near(child.Bounds.X, 4.0f) && Near(child.Bounds.Y, 6.0f));
		// 5 + 11 = 16 is 8 device pixels and 3 + 21 = 24 is 12, so the box keeps its far edges.
		Test.Assert(Near(child.Bounds.X + child.Bounds.Width, 24.0f));
		Test.Assert(Near(child.Bounds.Y + child.Bounds.Height, 16.0f));
		Test.Assert(Near(child.DeviceUnitScale(), 0.5f));

		canvas.Transform.Scale = .(1.0f, 1.0f);
		child.Invalidate();
		UITest.LayoutPass(context, root);
		Test.Assert(Near(child.Bounds.X, 3.0f));
	}

	/// A sheet's transform moves, scales and turns a view as it is drawn and hit tested, over
	/// the view's own Transform field, and layout keeps its box; an unknown function leaves the
	/// property unset.
	[Test]
	public static void ASheetsTransformMovesScalesAndTurnsAViewAsDrawnAndHitTested()
	{
		let sheet = LoadSSS(".lift { transform: translate(10, 0) scale(2); } .turn { transform: rotate(0.25turn); } .bad { transform: skew(10deg); }");
		let lift = sheet.GetRule(0).GetValue(.Transform).Value.AsTransform;
		Test.Assert(lift.HasValue);
		Test.Assert(Near(lift.Value.Translate.X, 10.0f) && Near(lift.Value.Scale.Y, 2.0f));
		Test.Assert(Near(sheet.GetRule(1).GetValue(.Transform).Value.AsTransform.Value.RotateDegrees, 90.0f));
		let bad = sheet.GetRule(2).GetValue(.Transform);
		Test.Assert((bad == null) || bad.Value.IsNone, "an unknown function: unset");

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(sheet);
		let child = new RecordingView(100, 50, 1);
		child.AddClass("lift");
		child.Transform.Translation = .(0.0f, 4.0f); // the code's own transform stays under it
		let frame = new FrameLayout();
		frame.Padding = .(150, 100, 0, 0);
		frame.AddView(child);
		root.AddView(frame);
		UITest.LayoutPass(context, root);
		let layoutBox = child.Bounds;
		Test.Assert(Near(layoutBox.Width, 100.0f), "layout keeps its box");
		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		// About the centre: (0, 0) is (-50, -25) from it, doubled to (-100, -50), back by
		// (50, 25), then moved by (10, 0) and the field's (0, 4).
		let corner = child.LocalToParent(.(0.0f, 0.0f));
		Test.Assert(Near(corner.X, layoutBox.X - 40.0f) && Near(corner.Y, layoutBox.Y - 21.0f));
		let back = child.ParentToLocal(corner);
		Test.Assert(Near(back.X, 0.0f) && Near(back.Y, 0.0f));
		// The drawn quad spans the scaled box.
		var minX = float.MaxValue;
		var maxX = float.MinValue;
		for (let vertex in vg.GetBatch().Vertices)
		{
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
		}
		Test.Assert(Near(maxX - minX, 200.0f));
		// Hit testing follows it: a point the scaled view covers outside its layout box.
		Test.Assert(root.HitTest(.(layoutBox.X - 30.0f, layoutBox.Y + 10.0f)) == child);
	}

	/// The indices of the backdrop composite under a `.glass` view styled by `sheetText`: its
	/// shape, a rounded outline where the background rounds, four corners where nothing does.
	private static int BackdropIndices(StringView sheetText)
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS(sheetText));
		let glass = new RecordingView(80, 60, 2);
		glass.AddClass("glass");
		let frame = new FrameLayout();
		frame.AddView(new RecordingView(200, 200, 1));
		frame.AddView(glass);
		root.AddView(frame);
		UITest.LayoutPass(context, root);
		let vg = scope VGContext();
		vg.SetLayers(true);
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);
		for (let command in vg.GetBatch().Commands)
		{
			if ((command.DrawMode == .Layer) && command.Backdrop)
				return command.IndexCount;
		}
		return 0;
	}

	/// A frosted card rounded by its background blurs a rounded shape behind it, as its shadow
	/// and its clip follow those corners.
	[Test]
	public static void ABackdropBlurKeepsToTheCornersTheBackgroundRounds()
	{
		let square = BackdropIndices(".glass { backdrop-filter: blur(6); background: #FFFFFF40; }");
		let rounded = BackdropIndices(".glass { backdrop-filter: blur(6); background: rounded-rect(#FFFFFF40, radius=10); }");
		Test.Assert(square > 0);
		Test.Assert(rounded > square, scope $"{rounded} vs {square}");
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

	/// With layers, a faded view with children fades as one group, like CSS opacity: the frame's
	/// opacity applies once, at its layer's composite, and the leaf inside fades its own fill.
	[Test]
	public static void WithLayersAFadedGroupFadesAsOneAndAFadedLeafAlone()
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
		vg.SetLayers(true);
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);

		let batch = vg.GetBatch();
		Test.Assert(batch.Layers.Count == 1, "the frame's; the leaf fades its own fill");
		Test.Assert(Near(batch.Layers[0].Opacity, 0.5f));
		var sawFill = false;
		var sawComposite = false;
		for (let command in batch.Commands)
		{
			let alpha = batch.Vertices[(int)batch.Indices[command.StartIndex]].Color.A;
			if (command.DrawMode == .Layer)
			{
				sawComposite = true;
				Test.Assert(command.Layer == -1);
				Test.Assert(Near(alpha, 0.5f), "the group's opacity, once");
			}
			else
			{
				sawFill = true;
				Test.Assert(command.Layer == 0);
				Test.Assert(Near(alpha, 0.5f), "the leaf's own, inside the layer");
			}
		}
		Test.Assert(sawFill && sawComposite);
	}

	/// The sheet's opacity fades a view, times its own field: it used to be parsed and never
	/// applied.
	[Test]
	public static void TheSheetsOpacityFadesAViewTimesItsOwn()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS("RecordingView { opacity: 0.5; }"));

		let view = new RecordingView(50, 30, 1);
		view.Opacity = 0.5f;
		root.AddView(view);
		UITest.LayoutPass(context, root);

		let vg = scope VGContext();
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);
		let batch = vg.GetBatch();
		Test.Assert(batch.Vertices.Count >= 4);
		Test.Assert(Near(batch.Vertices[0].Color.A, 0.25f));
	}

	/// `filter: blur()` blurs a view through a layer, a leaf too since the filter needs the
	/// layer; `backdrop-filter: blur()` blurs what is behind it; `filter: none` makes none.
	[Test]
	public static void FilterBlursAViewThroughALayerAndBackdropFilterWhatIsBehindIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		context.SetStyleSheet(LoadSSS(
			".soft { filter: blur(4px); } .glass { backdrop-filter: blur(6); corner-radius: 8; } .plain { filter: none; }"));

		let frame = new FrameLayout();
		frame.AddView(new RecordingView(200, 200, 1)); // something to be behind the glass
		let soft = new RecordingView(50, 30, 2);
		soft.AddClass("soft");
		frame.AddView(soft);
		let glass = new RecordingView(80, 60, 3);
		glass.AddClass("glass");
		frame.AddView(glass);
		let plain = new RecordingView(20, 20, 4);
		plain.AddClass("plain");
		frame.AddView(plain);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		let vg = scope VGContext();
		vg.SetLayers(true);
		RecordingView.DrawLog.Clear();
		context.DrawRootView(root, vg);
		let batch = vg.GetBatch();
		var blurred = 0;
		var backdrops = 0;
		for (let layer in batch.Layers)
		{
			if (layer.Blur > 0.0f)
			{
				Test.Assert(Near(layer.Blur, 4.0f));
				blurred++;
			}
			if (layer.BackdropBlur > 0.0f)
			{
				Test.Assert(Near(layer.BackdropBlur, 6.0f));
				backdrops++;
			}
		}
		Test.Assert(blurred == 1);
		Test.Assert(backdrops == 1);
		Test.Assert(batch.Layers.Count == 2, "`filter: none` makes none");
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
