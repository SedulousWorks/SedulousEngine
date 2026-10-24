using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A small dataflow graph: a Number (out "value": float, many), a Colour (out "rgb": color), and a
/// Mix (in "a": float, in "b": float, out "result": float); each change kept.
class GraphBed
{
	public GraphSet Graph = new .() ~ delete _;
	public List<GraphChange> Changes = new .() ~ DeleteContainerAndItems!(_);
	public GraphId Number = 0;
	public GraphId Colour = 0;
	public GraphId Mix = 0;

	public this()
	{
		let numberNode = scope GraphNodeInfo();
		numberNode.Title.Set("Number");
		numberNode.AddPin(scope GraphPinInfo("value", .Output, "float", true));
		let colourNode = scope GraphNodeInfo();
		colourNode.Title.Set("Colour");
		colourNode.AddPin(scope GraphPinInfo("rgb", .Output, "color", true));
		let mixNode = scope GraphNodeInfo();
		mixNode.Title.Set("Mix");
		mixNode.AddPin(scope GraphPinInfo("a", .Input, "float"));
		mixNode.AddPin(scope GraphPinInfo("b", .Input, "float"));
		mixNode.AddPin(scope GraphPinInfo("result", .Output, "float", true));
		Graph.AddNodeType(scope GraphNodeType("number", "Number", "Values"), numberNode);
		Graph.AddNodeType(scope GraphNodeType("colour", "Colour", "Values"), colourNode);
		Graph.AddNodeType(scope GraphNodeType("mix", "Mix", "Maths"), mixNode);
		numberNode.Type.Set("number");
		colourNode.Type.Set("colour");
		mixNode.Type.Set("mix");
		Number = Graph.AddNode(numberNode);
		Colour = Graph.AddNode(colourNode);
		mixNode.Position = .(200.0f, 0.0f);
		Mix = Graph.AddNode(mixNode);
		Graph.SetOnChange(new (change) =>
			{
				let copy = new GraphChange();
				copy.Set(change);
				Changes.Add(copy);
			});
	}

	public GraphLinkInfo Link(GraphId fromNode, StringView @out, GraphId toNode, StringView @in)
	{
		var link = GraphLinkInfo();
		link.Kind = .Pins;
		link.FromNode = fromNode;
		link.FromPin = Graph.FindPin(fromNode, @out, .Output);
		link.ToNode = toNode;
		link.ToPin = Graph.FindPin(toNode, @in, .Input);
		return link;
	}

	public int LinkCount => Graph.State.Links.Count;

	/// What the graph says of `link`, into a check the caller passes.
	public GraphLinkCheck Check(GraphLinkInfo link, GraphLinkCheck check)
	{
		Graph.CheckLink(link, check);
		return check;
	}
}

/// The graph source: nodes, pins, links and frames by stable ids; a link asked for first (allowed or
/// why not, what it replaces); a move a gesture; each other edit one change, told before and after,
/// undone by putting the graph back; node types for a menu, filtered to a pin that fits, a node made
/// linked to it; copies through the application's serializer.
class GraphSourceTests
{
	[Test]
	public static void NodesPinsAndLinksByIdsThatStayWhenAnotherGoes()
	{
		let bed = scope GraphBed();
		let nodes = scope List<GraphId>();
		bed.Graph.GetNodes(nodes);
		Test.Assert(nodes.Count == 3);
		let mix = bed.Graph.GetNode(bed.Mix);
		Test.Assert(mix != null);
		Test.Assert(mix.Title == "Mix");
		Test.Assert(mix.Pins.Count == 3);
		Test.Assert(mix.Pins[0].Id != 0);
		Test.Assert(mix.Pins[0].Id != mix.Pins[1].Id);

		let link = bed.Graph.Connect(bed.Link(bed.Number, "value", bed.Mix, "a"));
		Test.Assert(link != 0);
		GraphId[1] gone = .(bed.Colour);
		Test.Assert(bed.Graph.DeleteNodes(gone));
		Test.Assert(bed.Graph.GetNode(bed.Mix) != null); // the others keep their ids
		let links = scope List<GraphLinkInfo>();
		bed.Graph.GetLinks(links);
		Test.Assert(links.Count == 1);
		Test.Assert(links[0].Id == link);
	}

	[Test]
	public static void ALinkIsAskedForFirstAllowedRefusedWithWhyOrWhatItWouldReplace()
	{
		let bed = scope GraphBed();
		let check = scope GraphLinkCheck();
		bed.Check(bed.Link(bed.Number, "value", bed.Mix, "a"), check);
		Test.Assert(check.Allowed);
		Test.Assert(check.Replaces.IsEmpty);

		bed.Check(bed.Link(bed.Colour, "rgb", bed.Mix, "a"), check);
		Test.Assert(!check.Allowed);
		Test.Assert(check.Reason == "A color does not go into a float");

		var backwards = bed.Link(bed.Number, "value", bed.Mix, "a");
		backwards.ToPin = bed.Graph.FindPin(bed.Mix, "result", .Output);
		Test.Assert(!bed.Check(backwards, check).Allowed);

		let first = bed.Graph.Connect(bed.Link(bed.Number, "value", bed.Mix, "a"));
		Test.Assert(!bed.Check(bed.Link(bed.Number, "value", bed.Mix, "a"), check).Allowed); // linked already
		// An input takes one: a second into it replaces the first.
		let other = bed.Graph.AddNode(bed.Graph.GetNode(bed.Number));
		bed.Check(bed.Link(other, "value", bed.Mix, "a"), check);
		Test.Assert(check.Allowed);
		Test.Assert(check.Replaces.Count == 1);
		Test.Assert(check.Replaces[0] == first);
		Test.Assert(bed.Graph.Connect(bed.Link(other, "value", bed.Mix, "a")) != 0);
		Test.Assert(bed.LinkCount == 1);
		// An output takes many.
		Test.Assert(bed.Check(bed.Link(bed.Number, "value", bed.Mix, "b"), check).Replaces.IsEmpty);

		// Where a link may begin: any pin, either way.
		var begin = GraphLinkInfo();
		begin.FromNode = bed.Mix;
		begin.FromPin = bed.Graph.FindPin(bed.Mix, "a", .Input);
		Test.Assert(bed.Check(begin, check).Allowed);

		// Node links (a state machine's) only where the graph takes them; then any two, a node to
		// itself, several.
		var transition = GraphLinkInfo();
		transition.Kind = .Nodes;
		transition.FromNode = bed.Number;
		transition.ToNode = bed.Number;
		Test.Assert(!bed.Check(transition, check).Allowed);
		transition.ToNode = 0;
		Test.Assert(!bed.Check(transition, check).Allowed);
		bed.Graph.NodeLinks = true;
		Test.Assert(bed.Check(transition, check).Allowed);
		transition.ToNode = bed.Number;
		Test.Assert(bed.Check(transition, check).Allowed);
	}

	[Test]
	public static void EachChangeToldBeforeAndAfterOneEachAMoveAGestureAnUndoPutsTheGraphBack()
	{
		let bed = scope GraphBed();
		let link = bed.Graph.Connect(bed.Link(bed.Number, "value", bed.Mix, "a"));
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Before.Links.IsEmpty);
		Test.Assert(bed.Changes[0].After.Links.Count == 1);

		GraphId[2] moved = .(bed.Number, bed.Mix);
		bed.Graph.BeginMove();
		bed.Graph.PreviewMove(moved, default, .(10.0f, 5.0f));
		bed.Graph.PreviewMove(moved, default, .(30.0f, 15.0f));
		CheckNear(bed.Graph.GetNode(bed.Mix).Position.X, 230.0f);
		Test.Assert(bed.Changes.Count == 1); // previews are no change
		bed.Graph.CommitMove();
		Test.Assert(bed.Changes.Count == 2);
		bed.Graph.BeginMove();
		bed.Graph.PreviewMove(moved, default, .(100.0f, 0.0f));
		bed.Graph.CancelMove();
		CheckNear(bed.Graph.GetNode(bed.Mix).Position.X, 230.0f);
		Test.Assert(bed.Changes.Count == 2);

		// Relinked: the same link, its end moved.
		let to = bed.Link(bed.Number, "value", bed.Mix, "b");
		Test.Assert(bed.Graph.Relink(link, to));
		let links = scope List<GraphLinkInfo>();
		bed.Graph.GetLinks(links);
		Test.Assert(links.Count == 1);
		Test.Assert(links[0].Id == link);
		Test.Assert(links[0].ToPin == to.ToPin);
		Test.Assert(!bed.Graph.Relink(link, bed.Link(bed.Colour, "rgb", bed.Mix, "b"))); // refused: as it was
		bed.Graph.GetLinks(links);
		Test.Assert(links[0].ToPin == to.ToPin);

		GraphId[1] going = .(link);
		Test.Assert(bed.Graph.Disconnect(going));
		Test.Assert(bed.LinkCount == 0);
		bed.Graph.Apply(bed.Changes.Back, true);
		Test.Assert(bed.LinkCount == 1);
		bed.Graph.Apply(bed.Changes[1], true); // back before the move
		CheckNear(bed.Graph.GetNode(bed.Mix).Position.X, 200.0f);
	}

	[Test]
	public static void NodeTypesForAMenuFilteredToAPinThatFitsANodeMadeLinkedToItInOneChange()
	{
		let bed = scope GraphBed();
		let types = scope List<GraphNodeType>();
		defer { ClearAndDeleteItems!(types); }
		bed.Graph.GetNodeTypes(0, types);
		Test.Assert(types.Count == 3);
		// From a colour's output: only what takes a colour or anything (none takes a colour here).
		bed.Graph.GetNodeTypes(bed.Graph.FindPin(bed.Colour, "rgb", .Output), types);
		Test.Assert(types.IsEmpty);
		// From a number's output: the Mix takes it.
		let value = bed.Graph.FindPin(bed.Number, "value", .Output);
		bed.Graph.GetNodeTypes(value, types);
		Test.Assert(types.Count == 1);
		Test.Assert(types[0].Type == "mix");

		let made = bed.Graph.CreateNode("mix", .(50.0f, 80.0f), value);
		Test.Assert(made != 0);
		CheckNear(bed.Graph.GetNode(made).Position.Y, 80.0f);
		let links = scope List<GraphLinkInfo>();
		bed.Graph.GetLinks(links);
		Test.Assert(links.Count == 1);
		Test.Assert(links[0].FromPin == value);
		Test.Assert(links[0].ToPin == bed.Graph.FindPin(made, "a", .Input));
		Test.Assert(bed.Changes.Count == 1);
		Test.Assert(bed.Changes[0].Words == "Added Mix");
	}

	[Test]
	public static void FramesMadeEditedAndDeletedEachOneChangeMovedWithNodesInOneGesture()
	{
		let bed = scope GraphBed();
		let frame = scope GraphFrameInfo();
		frame.Title.Set("Inputs");
		let id = bed.Graph.CreateFrame(frame);
		Test.Assert(id != 0);
		let frames = scope List<GraphFrameInfo>();
		defer { ClearAndDeleteItems!(frames); }
		bed.Graph.GetFrames(frames);
		Test.Assert(frames.Count == 1);
		frame.Set(frames[0]);
		frame.Body.Set("What feeds the mix");
		Test.Assert(bed.Graph.EditFrame(frame));
		Test.Assert(!bed.Graph.EditFrame(frame)); // nothing changed

		GraphId[1] node = .(bed.Number);
		GraphId[1] framed = .(id);
		bed.Graph.BeginMove();
		bed.Graph.PreviewMove(node, framed, .(40.0f, 0.0f));
		bed.Graph.CommitMove();
		bed.Graph.GetFrames(frames);
		CheckNear(frames[0].Position.X, 40.0f);
		CheckNear(bed.Graph.GetNode(bed.Number).Position.X, 40.0f);
		Test.Assert(bed.Graph.DeleteFrames(framed));
		Test.Assert(bed.Changes.Count == 4);
	}

	[Test]
	public static void NodesCopiedWithTheLinksAmongThemPastedAsNewNodesAtAPlaceOneChange()
	{
		let bed = scope GraphBed();
		let format = scope BlobFormat();
		bed.Graph.TextFormat = format;
		Test.Assert(bed.Graph.Connect(bed.Link(bed.Number, "value", bed.Mix, "a")) != 0);
		Test.Assert(bed.Graph.Connect(bed.Link(bed.Colour, "rgb", bed.Number, "value")) == 0); // refused, not in the copy
		GraphId[2] chosen = .(bed.Number, bed.Mix);
		let text = scope String();
		bed.Graph.CopyNodes(chosen, text);
		Test.Assert(text.Length != 0);

		let made = scope List<GraphId>();
		Test.Assert(bed.Graph.PasteNodes(text, .(0.0f, 300.0f), made));
		Test.Assert(made.Count == 2);
		Test.Assert(bed.Graph.GetNode(made[0]).Title == "Number");
		CheckNear(bed.Graph.GetNode(made[1]).Position.X, 200.0f); // its place from the copy's top-left
		CheckNear(bed.Graph.GetNode(made[1]).Position.Y, 300.0f);
		Test.Assert(bed.LinkCount == 2); // the copy's own link, between the copies
		Test.Assert(bed.Changes.Back.Words == "Pasted");
		Test.Assert(!bed.Graph.PasteNodes("not ours", .(0.0f, 0.0f), made));

		// Nodes of no kind it makes: nothing pasted, and no change told.
		let told = bed.Changes.Count;
		let stray = scope GraphNodeInfo();
		stray.Title.Set("Stray");
		stray.Type.Set("unknown");
		let strayId = bed.Graph.AddNode(stray);
		let strays = scope String();
		GraphId[1] strayIds = .(strayId);
		bed.Graph.CopyNodes(strayIds, strays);
		Test.Assert(!strays.IsEmpty);
		Test.Assert(!bed.Graph.PasteNodes(strays, .(0.0f, 0.0f), made));
		Test.Assert(made.IsEmpty);
		Test.Assert(bed.Changes.Count == told);
	}

	// What no Raptor test covers: a link from an output to its own node refused, and a node that may
	// not be deleted staying while its neighbours go.
	[Test]
	public static void ANodeDoesNotFeedItselfAndAnUndeletableNodeStays()
	{
		let bed = scope GraphBed();
		let check = scope GraphLinkCheck();
		bed.Check(bed.Link(bed.Mix, "result", bed.Mix, "a"), check);
		Test.Assert(!check.Allowed);
		Test.Assert(check.Reason == "A node does not feed itself");

		bed.Graph.GetNode(bed.Colour).Deletable = false;
		GraphId[2] both = .(bed.Colour, bed.Number);
		Test.Assert(bed.Graph.DeleteNodes(both));
		Test.Assert(bed.Graph.GetNode(bed.Colour) != null);
		Test.Assert(bed.Graph.GetNode(bed.Number) == null);
	}
}
