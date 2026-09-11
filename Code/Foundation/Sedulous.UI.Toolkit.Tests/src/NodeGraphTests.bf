using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The node graph: its model, what it will and will not connect, and the two edge styles that
/// make it serve both a dataflow graph and a state machine.
class NodeGraphTests
{
	/// OWNERSHIP transfers to AddNode.
	private static NodeGraphNode MakeNode(StringView title = default)
	{
		let node = new NodeGraphNode();
		if (!title.IsEmpty)
			node.Title.Set(title);

		return node;
	}

	/// OWNERSHIP transfers to the node's port list.
	private static NodeGraphPort MakePort(PortDirection direction) => new NodeGraphPort(direction, "");

	private static NodeGraphConnection Connection(int32 sourceNode, int32 sourcePort,
		int32 destNode, int32 destPort) => .(sourceNode, sourcePort, destNode, destPort);

	/// One node with one output, another with one input: the smallest connectable pair.
	private static void AddConnectablePair(NodeGraphCanvas canvas, NodeGraphPortType sourceType,
		NodeGraphPortType destType)
	{
		let source = MakeNode();
		let outPort = MakePort(.Output);
		outPort.PortType = sourceType;
		source.OutputPorts.Add(outPort);
		canvas.AddNode(source);

		let dest = MakeNode();
		let inPort = MakePort(.Input);
		inPort.PortType = destType;
		dest.InputPorts.Add(inPort);
		canvas.AddNode(dest);
	}

	// ---- The model ------------------------------------------------------------------------------

	[Test]
	public static void ANodesDefaultsAreWorkable()
	{
		let node = scope NodeGraphNode();

		Test.Assert(node.UserHandle == 0);
		Test.Assert(node.IsMovable);
		Test.Assert(node.IsDeletable);
		Test.Assert(!node.IsSelected);
		Test.Assert(!node.IsHighlighted);
		Test.Assert(node.InputPorts.IsEmpty);
		Test.Assert(node.OutputPorts.IsEmpty);
	}

	[Test]
	public static void AnUntypedPortConnectsToAnything()
	{
		let untyped = NodeGraphPortType.Untyped();
		Test.Assert(untyped.TypeId == 0);
	}

	[Test]
	public static void NodesAreAddedAndCounted()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		Test.Assert(canvas.AddNode(MakeNode("A")) == 0);
		Test.Assert(canvas.AddNode(MakeNode("B")) == 1);
		Test.Assert(canvas.AddNode(MakeNode("C")) == 2);
		Test.Assert(canvas.NodeCount == 3);
		Test.Assert(canvas.GetNode(1).Title == "B");
		Test.Assert(canvas.GetNode(9) == null);
	}

	[Test]
	public static void RemovingANodeTakesItsConnectionsWithIt()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		AddConnectablePair(canvas, NodeGraphPortType.Untyped(), NodeGraphPortType.Untyped());
		Test.Assert(canvas.AddConnection(Connection(0, 0, 1, 0)) == 0);
		Test.Assert(canvas.ConnectionCount == 1);

		canvas.RemoveNode(0);
		Test.Assert(canvas.NodeCount == 1);
		Test.Assert(canvas.ConnectionCount == 0, "an edge cannot outlive either end");
	}

	/// A REGRESSION GATE on the renumbering. Connections address nodes by INDEX, so removing one
	/// has to shift every edge that pointed past it, or the graph silently re-wires itself.
	[Test]
	public static void RemovingANodeRenumbersTheEdgesAboveIt()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		// Three nodes, each with a port either way, and an edge from the second to the third.
		for (int32 i = 0; i < 3; i++)
		{
			let node = MakeNode();
			node.OutputPorts.Add(MakePort(.Output));
			node.InputPorts.Add(MakePort(.Input));
			canvas.AddNode(node);
		}

		Test.Assert(canvas.AddConnection(Connection(1, 0, 2, 0)) == 0);

		// Removing the FIRST node shifts the other two down by one.
		canvas.RemoveNode(0);
		Test.Assert(canvas.NodeCount == 2);
		Test.Assert(canvas.ConnectionCount == 1);

		let connection = canvas.GetConnection(0);
		Test.Assert(connection.SourceNodeIndex == 0);
		Test.Assert(connection.DestNodeIndex == 1);
	}

	// ---- Connecting -----------------------------------------------------------------------------

	[Test]
	public static void AValidConnectionIsAccepted()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		AddConnectablePair(canvas, NodeGraphPortType.Untyped(), NodeGraphPortType.Untyped());
		Test.Assert(canvas.AddConnection(Connection(0, 0, 1, 0)) == 0);
		Test.Assert(canvas.ConnectionCount == 1);
	}

	[Test]
	public static void ANodeCannotConnectToItself()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		let node = MakeNode();
		node.OutputPorts.Add(MakePort(.Output));
		node.InputPorts.Add(MakePort(.Input));
		canvas.AddNode(node);

		Test.Assert(canvas.AddConnection(Connection(0, 0, 0, 0)) == -1);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	[Test]
	public static void TheSameEdgeCannotBeAddedTwice()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		AddConnectablePair(canvas, NodeGraphPortType.Untyped(), NodeGraphPortType.Untyped());
		Test.Assert(canvas.AddConnection(Connection(0, 0, 1, 0)) == 0);
		Test.Assert(canvas.AddConnection(Connection(0, 0, 1, 0)) == -1);
		Test.Assert(canvas.ConnectionCount == 1);
	}

	[Test]
	public static void AnEdgeToANodeThatIsNotThereIsRefused()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		let node = MakeNode();
		node.OutputPorts.Add(MakePort(.Output));
		canvas.AddNode(node);

		Test.Assert(canvas.AddConnection(Connection(0, 0, 5, 0)) == -1);
		Test.Assert(canvas.AddConnection(Connection(0, 9, 0, 0)) == -1, "nor to a port");
	}

	/// The default rule: the same type, or either of them untyped.
	[Test]
	public static void TypesMustMatchUnlessOneIsUntyped()
	{
		let typeA = NodeGraphPortType(1, Color.Rgb(255, 0, 0));
		let typeB = NodeGraphPortType(2, Color.Rgb(0, 255, 0));

		let same = new NodeGraphCanvas();
		defer same.ReleaseRef();
		AddConnectablePair(same, typeA, typeA);
		Test.Assert(same.AddConnection(Connection(0, 0, 1, 0)) >= 0);

		let different = new NodeGraphCanvas();
		defer different.ReleaseRef();
		AddConnectablePair(different, typeA, typeB);
		Test.Assert(different.AddConnection(Connection(0, 0, 1, 0)) == -1);

		let untyped = new NodeGraphCanvas();
		defer untyped.ReleaseRef();
		AddConnectablePair(untyped, typeA, NodeGraphPortType.Untyped());
		Test.Assert(untyped.AddConnection(Connection(0, 0, 1, 0)) >= 0);
	}

	/// The caller's validator REPLACES the default rule, which is what lets a domain define its
	/// own compatibility without the canvas knowing anything about it.
	[Test]
	public static void ACustomValidatorOverridesTheDefaultRule()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		canvas.ConnectionValidator = new (source, dest) => true;
		AddConnectablePair(canvas, NodeGraphPortType(1, Color.Rgb(255, 0, 0)),
			NodeGraphPortType(2, Color.Rgb(0, 255, 0)));

		Test.Assert(canvas.AddConnection(Connection(0, 0, 1, 0)) >= 0);
	}

	/// Removing an edge reports its INDEX first and its endpoints second, because two parallel
	/// edges share endpoints and a caller keeping its own list cannot tell them apart otherwise.
	[Test]
	public static void RemovingAConnectionReportsItsIndexBeforeItsEndpoints()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		AddConnectablePair(canvas, NodeGraphPortType.Untyped(), NodeGraphPortType.Untyped());
		canvas.AddConnection(Connection(0, 0, 1, 0));

		var deletingIndex = -1;
		var removedSource = -1;
		var removedDest = -1;
		var order = scope String();

		canvas.OnConnectionDeleting.Add(new [&deletingIndex, &order](index) =>
			{
				deletingIndex = index;
				order.Append("D");
			});
		canvas.OnConnectionRemoved.Add(new [&order, &removedDest, &removedSource](sourceNode, sourcePort, destNode, destPort) =>
			{
				removedSource = sourceNode;
				removedDest = destNode;
				order.Append("R");
			});

		canvas.RemoveConnection(0);
		Test.Assert(canvas.ConnectionCount == 0);
		Test.Assert(deletingIndex == 0);
		Test.Assert(removedSource == 0);
		Test.Assert(removedDest == 1);
		Test.Assert(order == "DR", "the index goes out while it still means something");
	}

	// ---- Selection ------------------------------------------------------------------------------

	[Test]
	public static void SelectingANodeReplacesOrExtendsTheSelection()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		canvas.AddNode(MakeNode("A"));
		canvas.AddNode(MakeNode("B"));
		canvas.AddNode(MakeNode("C"));

		var changes = 0;
		canvas.OnSelectionChanged.Add(new [&changes]() => { changes++; });

		canvas.SelectNode(0);
		Test.Assert(canvas.GetNode(0).IsSelected);
		Test.Assert(!canvas.GetNode(1).IsSelected);

		canvas.SelectNode(1);
		Test.Assert(!canvas.GetNode(0).IsSelected, "a plain select replaces");
		Test.Assert(canvas.GetNode(1).IsSelected);

		canvas.SelectNode(2, true);
		Test.Assert(canvas.GetNode(1).IsSelected, "and an additive one extends");
		Test.Assert(canvas.GetNode(2).IsSelected);
		Test.Assert(changes == 3);
	}

	[Test]
	public static void TheSelectionIsReadBackAndCleared()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		canvas.AddNode(MakeNode("A"));
		canvas.AddNode(MakeNode("B"));
		canvas.AddNode(MakeNode("C"));

		canvas.SelectNode(0);
		canvas.SelectNode(2, true);

		let selected = scope List<int32>();
		canvas.GetSelectedNodes(selected);
		Test.Assert(selected.Count == 2);
		Test.Assert(selected[0] == 0);
		Test.Assert(selected[1] == 2);

		canvas.ClearSelection();
		selected.Clear();
		canvas.GetSelectedNodes(selected);
		Test.Assert(selected.IsEmpty);
	}

	[Test]
	public static void ClearRemovesEverything()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		AddConnectablePair(canvas, NodeGraphPortType.Untyped(), NodeGraphPortType.Untyped());
		canvas.AddConnection(Connection(0, 0, 1, 0));

		canvas.Clear();
		Test.Assert(canvas.NodeCount == 0);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	// ---- The view -------------------------------------------------------------------------------

	[Test]
	public static void TheCoordinateTransformsInvertEachOther()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		// At rest the two spaces coincide.
		Test.Assert(canvas.ScreenToCanvas(.(100, 50)) == Float2(100, 50));
		Test.Assert(canvas.CanvasToScreen(.(100, 50)) == Float2(100, 50));

		Float2[3] points = .(.(0, 0), .(123.5f, -47.25f), .(-900, 640));
		for (let point in points)
		{
			let back = canvas.ScreenToCanvas(canvas.CanvasToScreen(point));
			Test.Assert(Abs(back.X - point.X) < 0.001f);
			Test.Assert(Abs(back.Y - point.Y) < 0.001f);
		}
	}

	/// A node GROWS to fit its ports but is never shrunk below what the caller asked for.
	[Test]
	public static void ANodeAutoSizesForItsPorts()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		let node = MakeNode("Multi-port");
		node.Size = .(160, 40);
		for (int32 i = 0; i < 5; i++)
			node.InputPorts.Add(MakePort(.Input));

		canvas.AddNode(node);
		Test.Assert(node.Size.Y > 40, "five ports do not fit in forty pixels");
		Test.Assert(node.Size.X == 160, "the width the caller chose is kept");
	}

	// ---- The two edge styles --------------------------------------------------------------------

	[Test]
	public static void TheDefaultEdgeStyleIsTheDataflowOne()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		Test.Assert(canvas.EdgeStyle == .BezierPorts);
	}

	/// State machine nodes have NO PORTS, so the straight style validates on node bounds alone,
	/// and parallel edges are legal because two transitions between the same pair of states are
	/// two different transitions.
	[Test]
	public static void StraightModeConnectsPortlessNodesAndAllowsParallels()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();
		canvas.EdgeStyle = .StraightNodeToNode;

		let idle = canvas.AddNode(MakeNode("Idle"));
		let run = canvas.AddNode(MakeNode("Run"));

		Test.Assert(canvas.AddConnection(Connection(idle, 0, run, 0)) >= 0);
		Test.Assert(canvas.AddConnection(Connection(idle, 0, run, 0)) >= 0, "a second is legal");
		Test.Assert(canvas.AddConnection(Connection(run, 0, idle, 0)) >= 0, "and so is the reverse");
		Test.Assert(canvas.ConnectionCount == 3);

		Test.Assert(canvas.AddConnection(Connection(idle, 0, idle, 0)) == -1, "but not to itself");
		Test.Assert(canvas.AddConnection(Connection(idle, 0, 99, 0)) == -1, "nor out of bounds");
	}

	/// A REGRESSION GATE on the other side of that: the dataflow style still requires real
	/// ports, so relaxing the straight one did not relax both.
	[Test]
	public static void BezierModeStillRefusesPortlessNodes()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();

		let a = canvas.AddNode(MakeNode("A"));
		let b = canvas.AddNode(MakeNode("B"));
		Test.Assert(canvas.AddConnection(Connection(a, 0, b, 0)) == -1);
	}

	[Test]
	public static void StartLinkFromIgnoresBadIndicesAndReadOnlyCanvases()
	{
		let canvas = new NodeGraphCanvas();
		defer canvas.ReleaseRef();
		canvas.EdgeStyle = .StraightNodeToNode;

		let idle = canvas.AddNode(MakeNode("Idle"));

		var fired = false;
		canvas.OnNodeLinkRequested.Add(new [&fired](source, target) => { fired = true; });

		canvas.StartLinkFrom(-1);
		canvas.StartLinkFrom(5);
		canvas.ReadOnly = true;
		canvas.StartLinkFrom(idle);

		Test.Assert(!fired, "no gesture ever started, so nothing can complete");
	}
}
