using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A font of 6px advance per byte, 12px line height (ascent 10, descent 2), no file and no shaper.
class SixFont : IFont
{
	public override void GetFamilyName(String outName) { outName.Append("six"); }
	public override Span<uint8> SourceData => default;
	public override FontMetrics Metrics => .(10.0f, -2.0f, 0.0f, 10.0f, 1.0f);
	public override float PixelHeight => 10.0f;

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var g = GlyphInfo();
		g.Codepoint = codepoint;
		g.AdvanceWidth = 6.0f;
		return g;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint) => 0.0f;
	public override bool HasGlyph(int32 codepoint) => true;
	public override float MeasureString(StringView text) => (float)text.Length * 6.0f;
	public override float MeasureString(StringView text, List<GlyphPosition> outPositions) => (float)text.Length * 6.0f;
}

/// A 600 by 400 view at the root's top-left, the graph's origin at its top-left at the zoom of 1: A
/// at (0, 0) and B at (300, 0) in view, C at (1200, 800) out of it. Its kinds of node: a Number
/// (Values; out "value": float), a Mix and a Tint (Maths; in "a" and "b": float, out "result"; in
/// "color": color, out "color"). The root goes with it.
class GraphViewBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public GraphView View = new .() ~ _.ReleaseRef();
	public GraphSet Graph = new .() ~ delete _;
	public BlobFormat Format = new .() ~ delete _;
	public MemoryClipboard Clipboard = new .() ~ delete _;
	public List<GraphChange> Changes = new .() ~ DeleteContainerAndItems!(_);
	public GraphId A = 0;
	public GraphId B = 0;
	public GraphId C = 0;

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		A = Graph.AddNode(MakeNode("A", .(0.0f, 0.0f), .. scope GraphNodeInfo()));
		B = Graph.AddNode(MakeNode("B", .(300.0f, 0.0f), .. scope GraphNodeInfo()));
		C = Graph.AddNode(MakeNode("C", .(1200.0f, 800.0f), .. scope GraphNodeInfo()));
		let number = scope GraphNodeInfo();
		number.Title.Set("Number");
		number.AddPin(scope GraphPinInfo("value", .Output, "float"));
		let mix = scope GraphNodeInfo();
		mix.Title.Set("Mix");
		mix.AddPin(scope GraphPinInfo("a", .Input, "float"));
		mix.AddPin(scope GraphPinInfo("b", .Input, "float"));
		mix.AddPin(scope GraphPinInfo("result", .Output, "float"));
		let tint = scope GraphNodeInfo();
		tint.Title.Set("Tint");
		tint.AddPin(scope GraphPinInfo("color", .Input, "color"));
		tint.AddPin(scope GraphPinInfo("color", .Output, "color"));
		Graph.AddNodeType(scope GraphNodeType("number", "Number", "Values"), number);
		Graph.AddNodeType(scope GraphNodeType("mix", "Mix", "Maths"), mix);
		Graph.AddNodeType(scope GraphNodeType("tint", "Tint", "Maths"), tint);
		Graph.TextFormat = Format;
		Graph.SetOnChange(new (change) =>
			{
				let copy = new GraphChange();
				copy.Set(change);
				Changes.Add(copy);
			});
		D.Clipboard = Clipboard;
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		View.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(600.0f);
				s.Height = LayoutLength.Px(400.0f);
			});
		Root.AddChild(View);
		View.Source = Graph;
		Root.UpdateLayout();
	}

	public ~this()
	{
		D.CloseAllPopups();
		D.Clipboard = null;
		View.Source = null;
	}

	/// A node of the kind "mix" (so it copies and pastes) titled `title` at `at`, into `node`.
	public static void MakeNode(StringView title, Float2 at, GraphNodeInfo node)
	{
		node.Type.Set("mix");
		node.Title.Set(title);
		node.Position = at;
		node.AddPin(scope GraphPinInfo("in", .Input));
		node.AddPin(scope GraphPinInfo("out", .Output));
	}

	public void RightClick(Float2 at)
	{
		D.InjectMouseMove(at);
		D.InjectMouseDown(at, .Right);
		D.InjectMouseUp(at, .Right);
	}

	public int NodeCount => Graph.State.Nodes.Count;
	public EventDispatcher D => Root.EventDispatcher;

	public Float2 Middle(GraphId node)
	{
		let r = View.NodeRect(node);
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	public Float2 Where(GraphId node) => Graph.GetNode(node).Position;

	public void Press(Float2 at, uint32 modifiers = 0)
	{
		D.InjectMouseMove(at, modifiers);
		D.InjectMouseDown(at, .Left, modifiers);
	}

	public void Drag(Float2 from, Float2 to, uint32 modifiers = 0)
	{
		Press(from, modifiers);
		D.InjectMouseMove(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f), modifiers);
		D.InjectMouseMove(to, modifiers);
		D.InjectMouseUp(to, .Left, modifiers);
	}

	public void Click(Float2 at, uint32 modifiers = 0)
	{
		Press(at, modifiers);
		D.InjectMouseUp(at, .Left, modifiers);
	}

	/// A later press is not the second of a double.
	public void Pause()
	{
		D.InjectMouseMove(.(790.0f, 590.0f));
		D.InjectMouseDown(.(790.0f, 590.0f), .Left);
		D.InjectMouseUp(.(790.0f, 590.0f), .Left);
	}

	public int Selected => View.SelectedNodes.Length;

	public GraphId PinOf(GraphId node, StringView name)
	{
		let @in = Graph.FindPin(node, name, .Input);
		return (@in != 0) ? @in : Graph.FindPin(node, name, .Output);
	}

	public Float2 PinAt(GraphId pin)
	{
		Float2 at;
		Test.Assert(View.PinPoint(pin, out at));
		return at;
	}

	public GraphPinRow Row(GraphId node, GraphId pin)
	{
		let widget = View.GetNodeWidget(node);
		if (widget == null)
			return null;
		for (int i = 0; i < widget.PinRowCount; ++i)
		{
			if (widget.PinRowAt(i).PinId == pin)
				return widget.PinRowAt(i);
		}
		return null;
	}

	public int LinkCount => Graph.State.Links.Count;

	public GraphId Add(StringView title, Float2 at)
	{
		let node = Graph.AddNode(MakeNode(title, at, .. scope GraphNodeInfo()));
		Root.UpdateLayout();
		return node;
	}

	public static bool Has(GraphPinRow row, StringView cls) => (row != null) && row.HasClass(cls);

	public static MenuItem Item(Sedulous.GUI.Menu menu, StringView text) => CurveBed.Item(menu, text);

	public static void Activate(Sedulous.GUI.Menu menu, StringView text)
	{
		let item = Item(menu, text);
		Test.Assert(item != null);
		item.HandleActivate();
	}

	/// Panned so the graph's (-100, -100) is at the view's top-left, not snapping, with a frame round A
	/// and B: from (-20, -40), 480 by 200. The changes so far forgotten.
	public GraphId Framed()
	{
		View.SnapToGrid = false;
		View.Pan = .(-100.0f, -100.0f);
		let frame = scope GraphFrameInfo();
		frame.Title.Set("Group");
		frame.Position = .(-20.0f, -40.0f);
		frame.Size = .(480.0f, 200.0f);
		let id = Graph.CreateFrame(frame);
		Root.UpdateLayout();
		ClearAndDeleteItems!(Changes);
		return id;
	}

	public GraphFrameInfo FrameOf(GraphId frame)
	{
		for (let at in Graph.State.Frames)
		{
			if (at.Id == frame)
				return at;
		}
		return null;
	}

	public static int ChildIndex(Node parent, Node child)
	{
		for (int i = 0; i < parent.ChildCount; ++i)
		{
			if (parent.GetChildAt(i) == child)
				return i;
		}
		return parent.ChildCount;
	}
}

/// The graph view: a source's nodes as widgets made while in view and reused as it moves (a node never
/// seen made once to learn its size); a click or a box selecting, Shift or Ctrl adding or taking away;
/// a drag moving the selected nodes as one gesture through the source, on the grid where it snaps,
/// Escape cancelling it; read only moving nothing; a double click the application's; the wheel
/// zooming about the pointer within limits and a middle drag panning; framing every node. Links:
/// dragged from a pin, the source asked of each pin; an input's link end rewired or let go; a node
/// link from just outside a node's edge; a click selecting a link; highlights. Menus and keys: the
/// picker of node kinds; Delete, Escape, Ctrl+C and Ctrl+V; a node's menu duplicating and beginning a
/// node link; a link's deleting. Frames: behind the nodes, moved by their title with what lies inside,
/// resized from their edges, renamed in place, made around the selection from the menu, deleted.
class GraphViewTests
{
	[Test]
	public static void NodesAreWidgetsMadeWhileInViewReusedAsItPansAndZoomedWithIt()
	{
		let bed = scope GraphViewBed();
		Test.Assert(bed.View.MadeNodeCount == 2);
		Test.Assert(bed.View.GetNodeWidget(bed.A) != null);
		Test.Assert(bed.View.GetNodeWidget(bed.B) != null);
		Test.Assert(bed.View.GetNodeWidget(bed.C) == null);
		Test.Assert(bed.View.GetNodeWidget(bed.A).TitleLabel.Text == "A");
		Test.Assert(bed.View.GetNodeWidget(bed.A).PinRowCount == 2);
		// C was made once to learn its size, then went back to the pool.
		Test.Assert(bed.View.PooledNodeCount == 1);
		CheckNear(bed.View.NodeSize(bed.C).X, bed.View.NodeSize(bed.A).X);
		CheckNear(bed.View.NodeSize(bed.C).Y, bed.View.NodeSize(bed.A).Y);

		// Panned to C: its widget is one reused, and A's and B's go back to the pool.
		bed.View.Pan = .(1100.0f, 700.0f);
		bed.Root.UpdateLayout();
		Test.Assert(bed.View.MadeNodeCount == 1);
		Test.Assert(bed.View.GetNodeWidget(bed.C) != null);
		Test.Assert(bed.View.GetNodeWidget(bed.C).TitleLabel.Text == "C");
		Test.Assert(bed.View.GetNodeWidget(bed.A) == null);
		Test.Assert(bed.View.MadeNodeCount + bed.View.PooledNodeCount == 3);
		let atC = bed.View.NodeRect(bed.C);
		CheckNear(atC.X, 100.0f);
		CheckNear(atC.Y, 100.0f);

		// Zoomed out, a widget is drawn at the zoom, its rect following.
		bed.View.Pan = .(0.0f, 0.0f);
		bed.View.SetZoom(0.5f);
		bed.Root.UpdateLayout();
		Test.Assert(bed.View.GetNodeWidget(bed.B) != null);
		CheckNear(bed.View.GetNodeWidget(bed.B).Scale.X, 0.5f);
		CheckNear(bed.View.NodeRect(bed.B).X, 150.0f);
		CheckNear(bed.View.NodeRect(bed.B).Width, bed.View.NodeSize(bed.B).X * 0.5f);
		// A pin is drawn on its node's edge: an input at the start, an output at the end.
		let node = bed.View.GetNodeWidget(bed.B);
		Float2 @in;
		Float2 @out;
		Test.Assert(node.PinPoint(node.PinRowAt(0).PinId, out @in));
		Test.Assert(node.PinPoint(node.PinRowAt(1).PinId, out @out));
		CheckNear(@in.X, 0.0f);
		CheckNear(@out.X, node.Size.X);
		Test.Assert(@in.Y > node.Header.Size.Y);
	}

	[Test]
	public static void RightToLeftTheCanvasStillRunsLeftToRightInputsOnANodesLeftAndOutputsOnItsRight()
	{
		let bed = scope GraphViewBed();
		bed.Root.SetLayoutDirection(.RightToLeft);
		bed.Root.UpdateLayout();
		Test.Assert(bed.View.IsRightToLeft);
		Test.Assert(bed.View.PlacesChildren); // its nodes at their canvas points, which right to left leaves
		let node = bed.View.GetNodeWidget(bed.A);
		let @in = node.PinRowAt(0);
		let @out = node.PinRowAt(1);
		Test.Assert(@in.PinDirection == .Input);
		Test.Assert(!@in.IsRightToLeft);
		// The input's row at the node's left, the output's at its right, their pins on those edges.
		let nodeAt = node.ScreenBounds;
		CheckNear(@in.ScreenBounds.X, nodeAt.X, 0.01);
		CheckNear(@out.ScreenBounds.Right, nodeAt.Right, 0.01);
		Float2 inAt;
		Float2 outAt;
		Test.Assert(node.PinPoint(@in.PinId, out inAt));
		Test.Assert(node.PinPoint(@out.PinId, out outAt));
		CheckNear(inAt.X, 0.0f);
		CheckNear(outAt.X, node.Size.X);
		// A's output to B's input is the short way across, not round the nodes.
		let aOut = bed.PinOf(bed.A, "out");
		let bIn = bed.PinOf(bed.B, "in");
		let shift = bed.View.ScreenBounds.X; // the root puts the view at its right
		Float2 Screen(Float2 at) => .(at.X + shift, at.Y);
		bed.Drag(Screen(bed.PinAt(aOut)), Screen(bed.PinAt(bIn)));
		Test.Assert(bed.LinkCount == 1);
		let points = scope List<Float2>();
		Test.Assert(bed.View.LinkPoints(bed.Graph.State.Links[0], points));
		let left = bed.View.NodeRect(bed.A).Right;
		let right = bed.View.NodeRect(bed.B).X;
		for (let p in points)
		{
			Test.Assert(p.X >= left - 0.5f);
			Test.Assert(p.X <= right + 0.5f);
		}
	}

	[Test]
	public static void AClickOrABoxSelectsShiftOrCtrlAddsOrTakesAway()
	{
		let bed = scope GraphViewBed();
		int told = 0;
		bed.View.SetOnSelectionChanged(new [&] () => { ++told; });
		bed.Click(bed.Middle(bed.A));
		Test.Assert(bed.Selected == 1);
		Test.Assert(bed.View.IsNodeSelected(bed.A));
		Test.Assert(bed.View.GetNodeWidget(bed.A).HasClass("selected"));
		Test.Assert(told == 1);
		bed.Pause();
		bed.Click(.(500.0f, 350.0f));
		Test.Assert(bed.Selected == 0); // a click on nothing selects nothing
		bed.Pause();
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		bed.Click(bed.Middle(bed.B), KeyModShift);
		Test.Assert(bed.Selected == 2);
		bed.Pause();
		bed.Click(bed.Middle(bed.A), KeyModShift);
		bed.Click(bed.Middle(bed.A), KeyModCtrl); // a second press soon after: still a toggle
		Test.Assert(bed.Selected == 2);
		bed.Pause();
		bed.Click(bed.Middle(bed.B), KeyModCtrl);
		Test.Assert(bed.Selected == 1);
		Test.Assert(bed.View.IsNodeSelected(bed.A));
		Test.Assert(!bed.View.GetNodeWidget(bed.B).HasClass("selected"));

		// A box from nothing over both; with Shift it adds to what is selected.
		bed.Pause();
		bed.Drag(.(590.0f, 390.0f), .(10.0f, 10.0f));
		Test.Assert(bed.Selected == 2);
		bed.Pause();
		bed.Click(bed.Middle(bed.B));
		Test.Assert(bed.Selected == 1);
		let atA = bed.View.NodeRect(bed.A);
		bed.Drag(.(atA.Right + 20.0f, 390.0f), .(atA.X + 10.0f, atA.Y + 10.0f), KeyModShift);
		Test.Assert(bed.Selected == 2);

		// A node the source takes away (an undo) leaves the selection.
		GraphId[1] gone = .(bed.A);
		Test.Assert(bed.Graph.DeleteNodes(gone));
		Test.Assert(bed.Selected == 1);
		Test.Assert(bed.View.IsNodeSelected(bed.B));
		bed.View.SetOnSelectionChanged(null);
	}

	[Test]
	public static void ADragMovesTheSelectedNodesAsOneGestureOnTheGridAndEscapeCancelsIt()
	{
		let bed = scope GraphViewBed();
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		bed.Click(bed.Middle(bed.B), KeyModShift);
		bed.Pause();
		// 37 by 21 on a grid of 16: the pressed node lands at (32, 16), the other keeps its place to it.
		let from = bed.Middle(bed.A);
		bed.Drag(from, .(from.X + 37.0f, from.Y + 21.0f));
		CheckNear(bed.Where(bed.A).X, 32.0f);
		CheckNear(bed.Where(bed.A).Y, 16.0f);
		CheckNear(bed.Where(bed.B).X, 332.0f);
		CheckNear(bed.Where(bed.B).Y, 16.0f);
		Test.Assert(bed.Changes.Count == 1); // one change for the whole drag
		Test.Assert(bed.Selected == 2);
		bed.Graph.Apply(bed.Changes[0], true);
		CheckNear(bed.Where(bed.A).X, 0.0f);

		// Not snapping, it moves as the pointer did (over the zoom).
		bed.Pause();
		bed.View.SnapToGrid = false;
		bed.View.SetZoom(0.5f);
		bed.Root.UpdateLayout();
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		let at = bed.Middle(bed.A);
		bed.Drag(at, .(at.X + 10.0f, at.Y + 5.0f));
		CheckNear(bed.Where(bed.A).X, 20.0f);
		CheckNear(bed.Where(bed.A).Y, 10.0f);
		CheckNear(bed.Where(bed.B).X, 300.0f); // not selected
		Test.Assert(bed.Changes.Count == 2);

		// Escape mid-drag puts it back, and nothing is told.
		bed.Pause();
		let again = bed.Middle(bed.A);
		bed.Press(again);
		bed.D.InjectMouseMove(.(again.X + 40.0f, again.Y + 40.0f));
		CheckNear(bed.Where(bed.A).X, 100.0f);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		CheckNear(bed.Where(bed.A).X, 20.0f);
		bed.D.InjectMouseUp(.(again.X + 40.0f, again.Y + 40.0f), .Left);
		CheckNear(bed.Where(bed.A).X, 20.0f);
		Test.Assert(bed.Changes.Count == 2);

		// Read only, a drag selects and moves nothing.
		bed.Pause();
		bed.View.IsReadOnly = true;
		let still = bed.Middle(bed.A);
		bed.Drag(still, .(still.X + 50.0f, still.Y));
		CheckNear(bed.Where(bed.A).X, 20.0f);
		Test.Assert(bed.Changes.Count == 2);
		Test.Assert(bed.View.IsNodeSelected(bed.A));
	}

	[Test]
	public static void TheWheelZoomsAboutThePointerWithinItsLimitsAMiddleDragPans()
	{
		let bed = scope GraphViewBed();
		let at = Float2(250.0f, 150.0f);
		let under = bed.View.ViewToGraph(at);
		bed.D.InjectMouseMove(at);
		bed.D.InjectMouseWheel(at, .(0.0f, 1.0f));
		CheckNear(bed.View.Zoom, 1.15f);
		CheckNear(bed.View.ViewToGraph(at).X, under.X);
		CheckNear(bed.View.ViewToGraph(at).Y, under.Y);
		for (int32 i = 0; i < 20; ++i)
			bed.D.InjectMouseWheel(at, .(0.0f, 1.0f));
		CheckNear(bed.View.Zoom, bed.View.ZoomMax);
		for (int32 i = 0; i < 40; ++i)
			bed.D.InjectMouseWheel(at, .(0.0f, -1.0f));
		CheckNear(bed.View.Zoom, bed.View.ZoomMin);

		bed.View.SetZoom(0.5f);
		let pan = bed.View.Pan;
		bed.D.InjectMouseDown(at, .Middle);
		bed.D.InjectMouseMove(.(at.X + 50.0f, at.Y + 30.0f));
		bed.D.InjectMouseUp(.(at.X + 50.0f, at.Y + 30.0f), .Middle);
		CheckNear(bed.View.Pan.X, pan.X - 100.0f);
		CheckNear(bed.View.Pan.Y, pan.Y - 60.0f);
		Test.Assert(bed.Changes.IsEmpty);
	}

	[Test]
	public static void ADoubleClickOnANodeIsTheApplicationsFramingFitsTheNodesInView()
	{
		let bed = scope GraphViewBed();
		GraphId opened = 0;
		bed.View.SetOnNodeDoubleClick(new [&] (node) => { opened = node; });
		bed.Click(bed.Middle(bed.B));
		bed.Click(bed.Middle(bed.B));
		Test.Assert(opened == bed.B);
		Test.Assert(bed.Changes.IsEmpty);
		bed.View.SetOnNodeDoubleClick(null);

		bed.View.FrameAll();
		bed.Root.UpdateLayout();
		let @box = bed.View.ContentBounds;
		GraphId[3] all = .(bed.A, bed.B, bed.C);
		for (let node in all)
			Test.Assert(@box.Contains(bed.View.NodeRect(node)));
		Test.Assert(bed.View.MadeNodeCount == 3);

		// Asked before it has a size, it frames them once it is laid out.
		let later = new GraphView();
		defer later.ReleaseRef();
		later.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Height = LayoutLength.Px(200.0f);
			});
		later.Source = bed.Graph;
		later.FrameAll();
		bed.Root.AddChild(later);
		bed.Root.UpdateLayout();
		let small = later.ContentBounds;
		Test.Assert(small.Width > 0.0f);
		for (let node in all)
			Test.Assert(small.Contains(later.NodeRect(node)));
		// It goes on fitting them as its nodes change size, until the canvas is moved.
		Test.Assert(later.IsFitting);
		later.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(420.0f); });
		bed.Root.UpdateLayout();
		for (let node in all)
			Test.Assert(later.ContentBounds.Contains(later.NodeRect(node)));
		later.Pan = later.Pan;
		Test.Assert(!later.IsFitting);
		later.Source = null;

		// The selection alone, at no more than the zoom of 1.
		GraphId[1] c = .(bed.C);
		bed.View.SetSelectedNodes(c);
		bed.View.FrameSelection();
		CheckNear(bed.View.Zoom, 1.0f);
		Test.Assert(@box.Contains(bed.View.NodeRect(bed.C)));
		Test.Assert(!@box.Intersects(bed.View.NodeRect(bed.A)));
	}

	[Test]
	public static void ADragFromAnOutputToAnInputThatFitsLinksThemThePinsLitAndDimmedAsTheSourceAnswers()
	{
		let bed = scope GraphViewBed();
		let aIn = bed.PinOf(bed.A, "in");
		let aOut = bed.PinOf(bed.A, "out");
		let bIn = bed.PinOf(bed.B, "in");
		let bOut = bed.PinOf(bed.B, "out");
		let from = bed.PinAt(aOut);
		bed.Press(from);
		bed.D.InjectMouseMove(.(from.X + 40.0f, from.Y + 150.0f));
		Test.Assert(bed.View.IsLinking);
		Test.Assert(GraphViewBed.Has(bed.Row(bed.B, bIn), "fits"));
		Test.Assert(GraphViewBed.Has(bed.Row(bed.A, aIn), "refused")); // a node does not feed itself
		Test.Assert(GraphViewBed.Has(bed.Row(bed.B, bOut), "refused")); // an output to an output
		bed.D.InjectMouseMove(bed.PinAt(bIn));
		Test.Assert(GraphViewBed.Has(bed.Row(bed.B, bIn), "target"));
		Test.Assert(bed.View.LinkCheck.Allowed);
		bed.D.InjectMouseUp(bed.PinAt(bIn), .Left);
		Test.Assert(!bed.View.IsLinking);
		Test.Assert(bed.LinkCount == 1);
		Test.Assert(bed.Graph.State.Links[0].FromPin == aOut);
		Test.Assert(bed.Graph.State.Links[0].ToPin == bIn);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Linked");
		Test.Assert(!GraphViewBed.Has(bed.Row(bed.B, bIn), "target"));
		Test.Assert(!GraphViewBed.Has(bed.Row(bed.A, aIn), "refused"));

		// Onto a pin it may not reach: refused, and why; nothing made.
		bed.Pause();
		bed.Press(bed.PinAt(aOut));
		bed.D.InjectMouseMove(.(from.X + 40.0f, from.Y + 150.0f));
		bed.D.InjectMouseMove(bed.PinAt(aIn));
		Test.Assert(!bed.View.LinkCheck.Allowed);
		Test.Assert(bed.View.LinkCheck.Reason == "A node does not feed itself");
		bed.D.InjectMouseUp(bed.PinAt(aIn), .Left);
		Test.Assert(bed.LinkCount == 1);

		// Another output onto B's input: the link it would replace is known, and goes when it is made.
		bed.Pause();
		let d = bed.Add("D", .(0.0f, 200.0f));
		let dOut = bed.PinOf(d, "out");
		bed.Press(bed.PinAt(dOut));
		bed.D.InjectMouseMove(.(400.0f, 300.0f));
		bed.D.InjectMouseMove(bed.PinAt(bIn));
		Test.Assert(bed.View.LinkCheck.Replaces.Count == 1);
		Test.Assert(bed.View.LinkCheck.Replaces[0] == bed.Graph.State.Links[0].Id);
		bed.D.InjectMouseUp(bed.PinAt(bIn), .Left);
		Test.Assert(bed.LinkCount == 1);
		Test.Assert(bed.Graph.State.Links[0].FromPin == dOut);

		// Dropped on nothing, a new link is not made; Escape mid-drag ends it too.
		bed.Pause();
		bed.Drag(bed.PinAt(bOut), .(560.0f, 380.0f));
		Test.Assert(bed.LinkCount == 1);
		bed.Press(bed.PinAt(aOut));
		bed.D.InjectMouseMove(bed.PinAt(bIn));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!bed.View.IsLinking);
		bed.D.InjectMouseUp(bed.PinAt(bIn), .Left);
		Test.Assert(bed.LinkCount == 1);
		Test.Assert(bed.Changes.Count == 2);
	}

	[Test]
	public static void AnInputsLinkEndIsDraggedOffToRewireItOrLetItGoFromAnInputWithNoneALinkBeginsBackwards()
	{
		let bed = scope GraphViewBed();
		let aOut = bed.PinOf(bed.A, "out");
		let bIn = bed.PinOf(bed.B, "in");
		var made = GraphLinkInfo();
		made.FromNode = bed.A;
		made.FromPin = aOut;
		made.ToNode = bed.B;
		made.ToPin = bIn;
		let link = bed.Graph.AddLink(made);
		let d = bed.Add("D", .(300.0f, 200.0f));
		let dIn = bed.PinOf(d, "in");

		bed.Drag(bed.PinAt(bIn), bed.PinAt(dIn));
		Test.Assert(bed.LinkCount == 1);
		Test.Assert(bed.Graph.State.Links[0].Id == link); // the same link, its end moved
		Test.Assert(bed.Graph.State.Links[0].ToNode == d);
		Test.Assert(bed.Graph.State.Links[0].ToPin == dIn);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Relinked");

		// Off and back where it came from: nothing changes.
		bed.Pause();
		bed.Press(bed.PinAt(dIn));
		bed.D.InjectMouseMove(.(560.0f, 380.0f));
		bed.D.InjectMouseMove(bed.PinAt(dIn));
		Test.Assert(bed.View.LinkCheck.Allowed);
		bed.D.InjectMouseUp(bed.PinAt(dIn), .Left);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Graph.State.Links[0].ToPin == dIn);

		// Dropped on nothing, it goes.
		bed.Pause();
		bed.Drag(bed.PinAt(dIn), .(560.0f, 380.0f));
		Test.Assert(bed.LinkCount == 0);
		Test.Assert(bed.Changes.Count == 2);
		Test.Assert(bed.Changes[1].Words == "Unlinked");

		// From the input, now with none, to an output: a link from that output.
		bed.Pause();
		bed.Drag(bed.PinAt(dIn), bed.PinAt(aOut));
		Test.Assert(bed.LinkCount == 1);
		Test.Assert(bed.Graph.State.Links[0].FromPin == aOut);
		Test.Assert(bed.Graph.State.Links[0].ToPin == dIn);

		// Read only, a drag from a pin makes nothing.
		bed.Pause();
		bed.View.IsReadOnly = true;
		bed.Drag(bed.PinAt(bed.PinOf(bed.B, "out")), bed.PinAt(dIn));
		Test.Assert(bed.LinkCount == 1);
	}

	[Test]
	public static void AClickSelectsALinkShiftOrCtrlAddingOrTakingItAwayTheApplicationHighlightsNodesAndLinks()
	{
		let bed = scope GraphViewBed();
		let aOut = bed.PinOf(bed.A, "out");
		let bIn = bed.PinOf(bed.B, "in");
		var made = GraphLinkInfo();
		made.FromNode = bed.A;
		made.FromPin = aOut;
		made.ToNode = bed.B;
		made.ToPin = bIn;
		let link = bed.Graph.AddLink(made);
		let points = scope List<Float2>();
		Test.Assert(bed.View.LinkPoints(made, points));
		Test.Assert(points.Count > 2); // a curve
		let from = bed.PinAt(aOut);
		let to = bed.PinAt(bIn);
		let middle = Float2((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f); // the curve's middle
		Test.Assert(bed.View.HitLink(middle) == link);
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		bed.Click(middle);
		Test.Assert(bed.View.SelectedLinks.Length == 1);
		Test.Assert(bed.View.IsLinkSelected(link));
		Test.Assert(bed.Selected == 0); // a click on a link alone selects it alone
		bed.Pause();
		bed.Click(middle, KeyModCtrl);
		Test.Assert(bed.View.SelectedLinks.IsEmpty);
		bed.Pause();
		bed.Click(middle);
		bed.Pause();
		bed.Click(.(500.0f, 350.0f));
		Test.Assert(bed.View.SelectedLinks.IsEmpty);
		Test.Assert(bed.Changes.IsEmpty);

		// An undo taking the link away takes it from the selection.
		bed.Pause();
		bed.Click(middle);
		GraphId[1] gone = .(link);
		Test.Assert(bed.Graph.Disconnect(gone));
		Test.Assert(bed.View.SelectedLinks.IsEmpty);

		GraphId[1] a = .(bed.A);
		bed.View.SetHighlightedNodes(a);
		bed.Root.UpdateLayout();
		Test.Assert(bed.View.GetNodeWidget(bed.A).HasClass("highlighted"));
		Test.Assert(!bed.View.GetNodeWidget(bed.B).HasClass("highlighted"));
		bed.View.SetHighlightedLinks(gone);
		Test.Assert(bed.View.IsLinkHighlighted(link));
	}

	[Test]
	public static void NodeLinksFromJustOutsideANodesEdgeWhereTheSourceTakesThemTheTwoWaysApartToItselfAfterLeavingIt()
	{
		let bed = scope GraphViewBed();
		let atA = bed.View.NodeRect(bed.A);
		let atB = bed.View.NodeRect(bed.B);
		let edgeA = Float2(atA.Right + 3.0f, atA.Y + 4.0f);
		let edgeB = Float2(atB.X - 3.0f, atB.Y + 4.0f);
		// A graph of pins: the edge begins nothing.
		bed.Drag(edgeA, bed.Middle(bed.B));
		Test.Assert(bed.LinkCount == 0);

		bed.Graph.NodeLinks = true;
		bed.Pause();
		bed.Drag(edgeA, bed.Middle(bed.B));
		Test.Assert(bed.LinkCount == 1);
		let there = bed.Graph.State.Links[0];
		Test.Assert(there.Kind == .Nodes);
		Test.Assert(there.FromNode == bed.A);
		Test.Assert(there.ToNode == bed.B);
		bed.Pause();
		bed.Drag(edgeB, bed.Middle(bed.A));
		Test.Assert(bed.LinkCount == 2);
		let back = bed.Graph.State.Links[1];
		Test.Assert(back.FromNode == bed.B);
		// The two ways drawn apart, each with its own line to click.
		let one = scope List<Float2>();
		let other = scope List<Float2>();
		Test.Assert(bed.View.LinkPoints(there, one));
		Test.Assert(bed.View.LinkPoints(back, other));
		let m1 = Float2((one[0].X + one.Back.X) * 0.5f, (one[0].Y + one.Back.Y) * 0.5f);
		let m2 = Float2((other[0].X + other.Back.X) * 0.5f, (other[0].Y + other.Back.Y) * 0.5f);
		Test.Assert(Math.Abs(m1.Y - m2.Y) >= 2.0f * GraphView.cParallelGap - 0.01f);
		Test.Assert(bed.View.HitLink(m1) == there.Id);
		Test.Assert(bed.View.HitLink(m2) == back.Id);

		// Straight back onto its own node: nothing; out and back: a link to itself.
		bed.Pause();
		bed.Drag(edgeA, bed.Middle(bed.A));
		Test.Assert(bed.LinkCount == 2);
		bed.Pause();
		bed.Press(edgeA);
		bed.D.InjectMouseMove(.(560.0f, 380.0f));
		bed.D.InjectMouseMove(bed.Middle(bed.A));
		bed.D.InjectMouseUp(bed.Middle(bed.A), .Left);
		Test.Assert(bed.LinkCount == 3);
		Test.Assert(bed.Graph.State.Links[2].FromNode == bed.A);
		Test.Assert(bed.Graph.State.Links[2].ToNode == bed.A);
		Test.Assert(bed.View.LinkPoints(bed.Graph.State.Links[2], one));
		Test.Assert(one.Count > 2); // a loop
	}

	[Test]
	public static void NodeLinksTheSameWayEachLieFurtherApartThanTheOneBefore()
	{
		let bed = scope GraphViewBed();
		bed.Graph.NodeLinks = true;
		var link = GraphLinkInfo();
		link.Kind = .Nodes;
		link.FromNode = bed.A;
		link.ToNode = bed.B;
		let first = bed.Graph.AddLink(link);
		let second = bed.Graph.AddLink(link);
		let third = bed.Graph.AddLink(link);
		let points = scope List<Float2>();
		Float2 Middle(GraphId id)
		{
			for (let at in bed.Graph.State.Links)
			{
				if (at.Id == id)
				{
					Test.Assert(bed.View.LinkPoints(at, points));
					return .((points[0].X + points.Back.X) * 0.5f, (points[0].Y + points.Back.Y) * 0.5f);
				}
			}
			Test.Assert(false);
			return .Zero;
		}
		let m0 = Middle(first);
		// Across the line: the first lies on it (no reverse), the next 3 gaps off it, the one after 5.
		var along = Float2(points.Back.X - points[0].X, points.Back.Y - points[0].Y);
		let length = Math.Sqrt(along.X * along.X + along.Y * along.Y);
		along = .(along.X / length, along.Y / length);
		float Across(Float2 m) => Math.Abs((m.X - m0.X) * -along.Y + (m.Y - m0.Y) * along.X);
		CheckNear(Across(Middle(second)), 3.0f * GraphView.cParallelGap);
		CheckNear(Across(Middle(third)), 5.0f * GraphView.cParallelGap);
	}

	[Test]
	public static void TheMenuOverNothingAddsANodeThroughThePickerByCategoryWithASearch()
	{
		let bed = scope GraphViewBed();
		let at = Float2(450.0f, 300.0f);
		bed.RightClick(at);
		let menu = bed.View.Menu;
		Test.Assert(menu != null);
		Test.Assert(GraphViewBed.Item(menu, "Paste") != null);
		Test.Assert(!GraphViewBed.Item(menu, "Paste").Enabled); // nothing on the clipboard
		Test.Assert(GraphViewBed.Item(menu, "Frame all") != null);
		GraphViewBed.Activate(menu, "Add node\u{2026}");
		Test.Assert(bed.View.IsNodePickerOpen);
		let picker = bed.View.NodePicker;
		Test.Assert(picker.ShownCount == 3); // Values: Number; Maths: Mix, Tint
		Test.Assert(picker.ShownAt(0).Name == "Number");
		Test.Assert(picker.ShownAt(1).Name == "Mix");
		picker.SetQuery("MI");
		Test.Assert(picker.ShownCount == 1);
		Test.Assert(picker.ShownAt(0).Name == "Mix");
		Test.Assert(picker.ChooseCurrent());
		Test.Assert(!bed.View.IsNodePickerOpen);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Added Mix");
		Test.Assert(bed.Selected == 1);
		let made = bed.Graph.GetNode(bed.View.SelectedNodes[0]);
		Test.Assert(made != null);
		CheckNear(made.Position.X, 448.0f); // where the menu was, on the grid
		CheckNear(made.Position.Y, 304.0f);

		// By the keys: Down to the second kind, Enter.
		Test.Assert(bed.View.OpenNodePicker(.(100.0f, 300.0f)));
		bed.D.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(picker.Current == 1);
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!bed.View.IsNodePickerOpen);
		Test.Assert(bed.Changes.Count == 2);
		Test.Assert(bed.Changes[1].Words == "Added Mix");
	}

	[Test]
	public static void ALinkDroppedOnNothingOpensThePickerOfTheKindsItReachesTheNodeChosenComesLinkedOneChange()
	{
		let bed = scope GraphViewBed();
		let aOut = bed.PinOf(bed.A, "out");
		bed.Drag(bed.PinAt(aOut), .(450.0f, 300.0f));
		Test.Assert(bed.View.IsNodePickerOpen);
		let picker = bed.View.NodePicker;
		Test.Assert(picker.ShownCount == 2); // those with an input: Mix and Tint
		Test.Assert(picker.ShownAt(0).Name == "Mix");
		Test.Assert(picker.ShownAt(1).Name == "Tint");
		Test.Assert(picker.Choose(0));
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Added Mix");
		Test.Assert(bed.LinkCount == 1);
		let link = bed.Graph.State.Links[0];
		Test.Assert(link.FromPin == aOut);
		Test.Assert(link.ToNode == bed.View.SelectedNodes[0]);
		Test.Assert(link.ToPin == bed.Graph.FindPin(link.ToNode, "a", .Input));
	}

	[Test]
	public static void DeleteEscapeCtrlCAndCtrlVAsThePropertyGridsDuplicateFromANodesMenu()
	{
		let bed = scope GraphViewBed();
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		bed.Click(bed.Middle(bed.B), KeyModShift);
		bed.D.InjectKeyDown((uint32)KeyCode.C, KeyModCtrl);
		Test.Assert(bed.Clipboard.HasText);
		bed.D.InjectMouseMove(.(450.0f, 300.0f));
		bed.D.InjectKeyDown((uint32)KeyCode.V, KeyModCtrl);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Pasted");
		Test.Assert(bed.NodeCount == 5);
		Test.Assert(bed.Selected == 2); // the copies
		Test.Assert(!bed.View.IsNodeSelected(bed.A));
		let first = bed.Graph.GetNode(bed.View.SelectedNodes[0]);
		Test.Assert(first != null);
		CheckNear(first.Position.Y, 300.0f); // their top-left at the pointer

		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.NodeCount == 3);
		Test.Assert(bed.Changes.Count == 2);
		Test.Assert(bed.Changes[1].Words == "Deleted");
		Test.Assert(bed.Selected == 0);

		bed.Pause();
		bed.Click(bed.Middle(bed.A));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(bed.Selected == 0);

		// A selected link goes with Delete.
		var made = GraphLinkInfo();
		made.FromNode = bed.A;
		made.FromPin = bed.PinOf(bed.A, "out");
		made.ToNode = bed.B;
		made.ToPin = bed.PinOf(bed.B, "in");
		bed.Graph.AddLink(made);
		let from = bed.PinAt(made.FromPin);
		let to = bed.PinAt(made.ToPin);
		bed.Pause();
		bed.Click(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f));
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.LinkCount == 0);
		Test.Assert(bed.Changes.Back.Words == "Unlinked");

		// Duplicate beside it, from its menu (the clipboard kept).
		bed.Clipboard.SetText("kept");
		bed.RightClick(bed.Middle(bed.A));
		Test.Assert(bed.View.Menu != null);
		GraphViewBed.Activate(bed.View.Menu, "Duplicate");
		Test.Assert(bed.NodeCount == 4);
		Test.Assert(bed.Selected == 1);
		let copy = bed.Graph.GetNode(bed.View.SelectedNodes[0]);
		Test.Assert(copy != null);
		Test.Assert(copy.Title == "A");
		CheckNear(copy.Position.X, 32.0f);
		CheckNear(copy.Position.Y, 32.0f);
		Test.Assert(bed.Clipboard.Text == "kept");

		// Read only: no Duplicate or Delete, and Delete deletes nothing.
		bed.View.IsReadOnly = true;
		bed.Pause();
		bed.RightClick(bed.Middle(bed.A));
		Test.Assert(bed.View.Menu != null);
		Test.Assert(GraphViewBed.Item(bed.View.Menu, "Copy") != null);
		Test.Assert(GraphViewBed.Item(bed.View.Menu, "Duplicate") == null);
		Test.Assert(GraphViewBed.Item(bed.View.Menu, "Delete") == null);
		bed.D.CloseAllPopups();
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.NodeCount == 4);
	}

	[Test]
	public static void ANodesMenuBeginsANodeLinkThatFollowsThePointerUntilAClickALinksMenuDeletesIt()
	{
		let bed = scope GraphViewBed();
		bed.RightClick(bed.Middle(bed.A));
		Test.Assert(bed.View.Menu != null);
		Test.Assert(GraphViewBed.Item(bed.View.Menu, "Add transition") == null); // a graph of pins
		bed.D.CloseAllPopups();

		bed.Graph.NodeLinks = true;
		bed.Pause();
		bed.RightClick(bed.Middle(bed.A));
		Test.Assert(bed.View.Menu != null);
		GraphViewBed.Activate(bed.View.Menu, "Add transition");
		Test.Assert(bed.View.IsLinking);
		bed.D.InjectMouseMove(bed.Middle(bed.B));
		Test.Assert(bed.View.LinkCheck.Allowed);
		bed.Click(bed.Middle(bed.B));
		Test.Assert(!bed.View.IsLinking);
		Test.Assert(bed.LinkCount == 1);
		let link = bed.Graph.State.Links[0];
		Test.Assert(link.Kind == .Nodes);
		Test.Assert(link.FromNode == bed.A);
		Test.Assert(link.ToNode == bed.B);

		// Escape ends one unmade.
		bed.Pause();
		bed.RightClick(bed.Middle(bed.B));
		GraphViewBed.Activate(bed.View.Menu, "Add transition");
		Test.Assert(bed.View.IsLinking);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!bed.View.IsLinking);
		Test.Assert(bed.LinkCount == 1);

		// The link's menu deletes it.
		let points = scope List<Float2>();
		Test.Assert(bed.View.LinkPoints(link, points));
		bed.Pause();
		bed.RightClick(.((points[0].X + points.Back.X) * 0.5f, (points[0].Y + points.Back.Y) * 0.5f));
		Test.Assert(bed.View.Menu != null);
		GraphViewBed.Activate(bed.View.Menu, "Delete");
		Test.Assert(bed.LinkCount == 0);
	}

	[Test]
	public static void AFrameStandsBehindTheNodesDraggedByItsTitleItMovesWithWhatLiesInsideOneChange()
	{
		let bed = scope GraphViewBed();
		let frame = bed.Framed();
		Test.Assert(bed.View.GetFrameWidget(frame) != null);
		Test.Assert(bed.View.GetFrameWidget(frame).TitleLabel.Text == "Group");
		Test.Assert(GraphViewBed.ChildIndex(bed.View, bed.View.GetFrameWidget(frame)) < GraphViewBed.ChildIndex(bed.View, bed.View.GetNodeWidget(bed.A)));
		let r = bed.View.FrameRect(frame);
		CheckNear(r.X, 80.0f);
		CheckNear(r.Y, 60.0f);
		let title = Float2(r.X + 30.0f, r.Y + 10.0f);

		bed.Click(title);
		Test.Assert(bed.View.IsFrameSelected(frame));
		Test.Assert(bed.View.GetFrameWidget(frame).HasClass("selected"));
		Test.Assert(bed.Selected == 0);
		bed.Pause();
		bed.Drag(title, .(title.X + 37.0f, title.Y + 21.0f));
		CheckNear(bed.FrameOf(frame).Position.X, 17.0f);
		CheckNear(bed.FrameOf(frame).Position.Y, -19.0f);
		CheckNear(bed.Where(bed.A).X, 37.0f); // inside it
		CheckNear(bed.Where(bed.B).X, 337.0f);
		CheckNear(bed.Where(bed.C).X, 1200.0f); // outside
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Moved");

		// Escape mid-drag puts it all back.
		bed.Pause();
		let again = Float2(bed.View.FrameRect(frame).X + 30.0f, bed.View.FrameRect(frame).Y + 10.0f);
		bed.Press(again);
		bed.D.InjectMouseMove(.(again.X + 50.0f, again.Y));
		CheckNear(bed.Where(bed.A).X, 87.0f);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		bed.D.InjectMouseUp(.(again.X + 50.0f, again.Y), .Left);
		CheckNear(bed.Where(bed.A).X, 37.0f);
		CheckNear(bed.FrameOf(frame).Position.X, 17.0f);
		Test.Assert(bed.Changes.Count == 1);

		// A box over the whole of it selects it, and the nodes it touches.
		bed.Pause();
		bed.Drag(.(599.0f, 395.0f), .(60.0f, 50.0f)); // it reaches 597 now
		Test.Assert(bed.View.IsFrameSelected(frame));
		Test.Assert(bed.Selected == 2);
	}

	[Test]
	public static void AFramesEdgesResizeItPreviewedAndOneChangeOnReleaseEscapeCancels()
	{
		let bed = scope GraphViewBed();
		let frame = bed.Framed();
		var r = bed.View.FrameRect(frame);
		let right = Float2(r.Right - 2.0f, r.Y + r.Height * 0.5f);
		bed.Press(right);
		bed.D.InjectMouseMove(.(right.X + 30.0f, right.Y));
		CheckNear(bed.View.FrameRect(frame).Width, 510.0f); // previewed
		Test.Assert(bed.Changes.IsEmpty);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		bed.D.InjectMouseUp(.(right.X + 30.0f, right.Y), .Left);
		CheckNear(bed.View.FrameRect(frame).Width, 480.0f);
		Test.Assert(bed.Changes.IsEmpty);

		bed.Pause();
		bed.Drag(right, .(right.X + 60.0f, right.Y));
		CheckNear(bed.FrameOf(frame).Size.X, 540.0f);
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Edited a frame");

		// From its bottom start corner: wider to the start, taller.
		bed.Pause();
		r = bed.View.FrameRect(frame);
		let corner = Float2(r.X + 2.0f, r.Bottom - 2.0f);
		bed.Drag(corner, .(corner.X - 30.0f, corner.Y + 40.0f));
		CheckNear(bed.FrameOf(frame).Position.X, -50.0f);
		CheckNear(bed.FrameOf(frame).Position.Y, -40.0f);
		CheckNear(bed.FrameOf(frame).Size.X, 570.0f);
		CheckNear(bed.FrameOf(frame).Size.Y, 240.0f);

		// No smaller than its least.
		bed.Pause();
		r = bed.View.FrameRect(frame);
		let left = Float2(r.X + 2.0f, r.Y + r.Height * 0.5f);
		bed.Drag(left, .(left.X + 1000.0f, left.Y));
		CheckNear(bed.FrameOf(frame).Size.X, GraphView.cFrameMinWidth);
	}

	[Test]
	public static void AFramesTitleAndBodyEditInPlaceTheMenuAddsAFrameRoundTheSelectionAndACommentDeleteDeletesThem()
	{
		let bed = scope GraphViewBed();
		let frame = bed.Framed();
		let widget = bed.View.GetFrameWidget(frame);
		widget.TitleLabel.BeginEdit();
		Test.Assert(widget.TitleLabel.Editor != null);
		widget.TitleLabel.Editor.Text = "Renamed";
		Test.Assert(widget.TitleLabel.EndEdit(true));
		Test.Assert(bed.FrameOf(frame).Title == "Renamed");
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Edited a frame");

		// While its body is edited, the keys are the field's: Delete deletes no node.
		bed.Click(bed.Middle(bed.A));
		widget.EditBody();
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.NodeCount == 3);
		widget.BodyLabel.Editor.Text = "A note";
		Test.Assert(widget.BodyLabel.EndEdit(true));
		Test.Assert(bed.FrameOf(frame).Body == "A note");
		bed.Root.UpdateLayout();
		Test.Assert(widget.BodyLabel.Displayed);

		// Its title's menu renames it.
		bed.Pause();
		bed.RightClick(.(bed.View.FrameRect(frame).X + 30.0f, bed.View.FrameRect(frame).Y + 10.0f));
		Test.Assert(bed.View.Menu != null);
		GraphViewBed.Activate(bed.View.Menu, "Rename");
		Test.Assert(widget.TitleLabel.IsEditing);
		Test.Assert(widget.TitleLabel.EndEdit(false));

		// Round the selected nodes, from the menu over nothing.
		bed.Pause();
		bed.Click(bed.Middle(bed.A));
		bed.Pause();
		bed.Click(bed.Middle(bed.B), KeyModShift);
		bed.RightClick(.(300.0f, 380.0f));
		Test.Assert(bed.View.Menu != null);
		GraphViewBed.Activate(bed.View.Menu, "Add frame");
		Test.Assert(bed.Graph.State.Frames.Count == 2);
		let round = bed.Graph.State.Frames[1];
		Test.Assert(bed.Changes.Back.Words == "Framed");
		let inside = Rect(round.Position.X, round.Position.Y, round.Size.X, round.Size.Y);
		Test.Assert(inside.Contains(Rect(0.0f, 0.0f, bed.View.NodeSize(bed.A).X, bed.View.NodeSize(bed.A).Y)));
		Test.Assert(inside.Contains(Rect(300.0f, 0.0f, bed.View.NodeSize(bed.B).X, bed.View.NodeSize(bed.B).Y)));
		Test.Assert(bed.View.IsFrameSelected(round.Id));

		// A comment where the menu was, nothing selected: a frame with a body.
		bed.Pause();
		bed.Click(.(300.0f, 380.0f));
		bed.RightClick(.(300.0f, 380.0f));
		GraphViewBed.Activate(bed.View.Menu, "Add comment");
		Test.Assert(bed.Graph.State.Frames.Count == 3);
		let comment = bed.Graph.State.Frames[2];
		Test.Assert(!comment.Body.IsEmpty);
		bed.Root.UpdateLayout();
		Test.Assert(bed.View.GetFrameWidget(comment.Id) != null);
		Test.Assert(bed.View.GetFrameWidget(comment.Id).BodyLabel.Displayed);

		// Delete deletes the selected frame, and nothing else.
		let commentId = comment.Id;
		Test.Assert(bed.View.IsFrameSelected(commentId));
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.Graph.State.Frames.Count == 2);
		Test.Assert(bed.Changes.Back.Words == "Deleted a frame");
		Test.Assert(bed.NodeCount == 3);
		Test.Assert(bed.View.SelectedFrames.IsEmpty);
	}

	[Test]
	public static void ACommentLongerThanItsFrameScrollsInItsBoxToTheCaretWhileTypedInAndUnderTheWheel()
	{
		let bed = scope GraphViewBed();
		let frame = bed.Framed();
		let widget = bed.View.GetFrameWidget(frame);
		let font = scope CachedFont(new SixFont(), null);
		widget.BodyLabel.Font = font;
		widget.EditBody();
		let area = widget.BodyLabel.Editor as TextArea;
		Test.Assert(area != null);
		Test.Assert(area.IsFocused);
		// Thirty lines of 12 in a frame 200 tall.
		for (int32 i = 0; i < 30; ++i)
		{
			bed.D.InjectText("line");
			bed.D.InjectKeyDown((uint32)KeyCode.Return);
		}
		bed.Root.UpdateLayout();
		let @box = widget.BodyBox;
		let label = widget.BodyLabel;
		let frameAt = widget.ScreenBounds;
		Test.Assert(@box.ScreenBounds.Bottom <= frameAt.Bottom - 7.5f); // the frame's padding below it
		// As tall as its text, the box scrolled to its end, where the caret is.
		CheckNear(label.Size.Y, 31.0f * 12.0f);
		Test.Assert(@box.IsScrollContainer);
		CheckNear(@box.ScrollOffset.Y, label.Size.Y - @box.ContentBounds.Height);
		CheckNear(area.ScrollY, 0.0f);
		Test.Assert(widget.ClipsChildren);
		// Back to the top (Ctrl+Home), the box follows the caret there.
		bed.D.InjectKeyDown((uint32)KeyCode.Home, KeyModCtrl);
		CheckNear(@box.ScrollOffset.Y, 0.0f);

		// Committed, it is as tall as its text, the box scrolling it; it reads from its top.
		Test.Assert(label.EndEdit(true));
		bed.Root.UpdateLayout();
		CheckNear(label.Size.Y, 31.0f * 12.0f);
		CheckNear(label.BaselineAt(label.Size), label.Chrome.Top + 10.0f);
		CheckNear(@box.ScrollOffset.Y, 0.0f);
		let zoom = bed.View.Zoom;
		let boxAt = @box.ScreenBounds;
		let over = Float2(boxAt.X + 200.0f, boxAt.Y + 40.0f); // between A and B
		bed.D.InjectMouseMove(over);
		bed.D.InjectMouseWheel(over, .(0.0f, -1.0f));
		Test.Assert(@box.ScrollTarget.Y > 0.0f);
		CheckNear(bed.View.Zoom, zoom); // the box took it
		// At its top, the wheel up is the view's zoom again.
		@box.ScrollOffset = .(0.0f, 0.0f);
		bed.D.InjectMouseWheel(over, .(0.0f, 1.0f));
		Test.Assert(bed.View.Zoom > zoom);
		label.Font = null;
		bed.Root.UpdateLayout();
	}

	// Further cases: the zoom's limits set from code, and a pin's widget told its state
	// only while a link is dragged.
	[Test]
	public static void TheZoomLimitsHoldTheZoomAndAPinsStateEndsWithTheDrag()
	{
		let bed = scope GraphViewBed();
		bed.View.SetZoomLimits(0.5f, 0.8f);
		CheckNear(bed.View.Zoom, 0.8f);
		bed.View.SetZoom(0.1f);
		CheckNear(bed.View.Zoom, 0.5f);
		bed.View.SetZoomLimits(0.0f, 4.0f);
		CheckNear(bed.View.ZoomMin, 0.01f);
		bed.View.SetZoom(1.0f);
		bed.Root.UpdateLayout();
		let bIn = bed.PinOf(bed.B, "in");
		Test.Assert(bed.Row(bed.B, bIn).LinkState == .None);
		bed.Press(bed.PinAt(bed.PinOf(bed.A, "out")));
		bed.D.InjectMouseMove(.(100.0f, 300.0f));
		Test.Assert(bed.Row(bed.B, bIn).LinkState == .Fits);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(bed.Row(bed.B, bIn).LinkState == .None);
		bed.D.InjectMouseUp(.(100.0f, 300.0f), .Left);
	}
}
