namespace Sedulous.UI.Tests;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

class NodeGraphTests
{
	// === Data Model ===

	[Test]
	public static void NodeGraphNode_Defaults()
	{
		let node = scope NodeGraphNode();
		Test.Assert(node.UserHandle == 0);
		Test.Assert(node.IsMovable == true);
		Test.Assert(node.IsDeletable == true);
		Test.Assert(node.IsSelected == false);
		Test.Assert(node.InputPorts.Count == 0);
		Test.Assert(node.OutputPorts.Count == 0);
		Test.Assert(node.Size.X >= 120); // NodeMinWidth
	}

	[Test]
	public static void NodeGraphPortType_Untyped()
	{
		let untyped = NodeGraphPortType.Untyped;
		Test.Assert(untyped.TypeId == 0);
	}

	// === Add / Remove Nodes ===

	[Test]
	public static void AddNode_ReturnsIndex()
	{
		let canvas = scope NodeGraphCanvas();
		let node = new NodeGraphNode();
		node.Title.Set("Test");
		let idx = canvas.AddNode(node);
		Test.Assert(idx == 0);
		Test.Assert(canvas.NodeCount == 1);
	}

	[Test]
	public static void AddMultipleNodes()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		let n2 = new NodeGraphNode();
		n2.Title.Set("C");

		Test.Assert(canvas.AddNode(n0) == 0);
		Test.Assert(canvas.AddNode(n1) == 1);
		Test.Assert(canvas.AddNode(n2) == 2);
		Test.Assert(canvas.NodeCount == 3);
	}

	[Test]
	public static void RemoveNode_DecreasesCount()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		canvas.AddNode(n0);
		canvas.AddNode(n1);

		canvas.RemoveNode(0);
		Test.Assert(canvas.NodeCount == 1);
		Test.Assert(canvas.GetNode(0).Title == "B");
	}

	[Test]
	public static void RemoveNode_RemovesConnections()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(canvas.ConnectionCount == 1);

		canvas.RemoveNode(0);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	[Test]
	public static void RemoveNode_RemapsConnectionIndices()
	{
		let canvas = scope NodeGraphCanvas();

		// Node 0
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		// Node 1
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		let out1 = new NodeGraphPort();
		out1.Direction = .Output;
		n1.OutputPorts.Add(out1);
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		// Node 2
		let n2 = new NodeGraphNode();
		n2.Title.Set("C");
		let in2 = new NodeGraphPort();
		in2.Direction = .Input;
		n2.InputPorts.Add(in2);
		canvas.AddNode(n2);

		// Connection: B(1) -> C(2)
		canvas.AddConnection(.() { SourceNodeIndex = 1, SourcePortIndex = 0, DestNodeIndex = 2, DestPortIndex = 0 });

		// Remove A(0) - B becomes 0, C becomes 1
		canvas.RemoveNode(0);
		Test.Assert(canvas.ConnectionCount == 1);
		let conn = canvas.GetConnection(0);
		Test.Assert(conn.SourceNodeIndex == 0); // was 1, now 0
		Test.Assert(conn.DestNodeIndex == 1);   // was 2, now 1
	}

	// === Connections ===

	[Test]
	public static void AddConnection_Valid()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(idx == 0);
		Test.Assert(canvas.ConnectionCount == 1);
	}

	[Test]
	public static void AddConnection_RejectsSelfConnection()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		let in0 = new NodeGraphPort();
		in0.Direction = .Input;
		n0.InputPorts.Add(in0);
		canvas.AddNode(n0);

		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 0, DestPortIndex = 0 });
		Test.Assert(idx == -1);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	[Test]
	public static void AddConnection_RejectsDuplicate()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		let dup = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(dup == -1);
		Test.Assert(canvas.ConnectionCount == 1);
	}

	[Test]
	public static void AddConnection_RejectsInvalidIndices()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		// Dest node doesn't exist
		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 5, DestPortIndex = 0 });
		Test.Assert(idx == -1);
	}

	[Test]
	public static void AddConnection_TypeValidation_SameType()
	{
		let canvas = scope NodeGraphCanvas();

		let audioType = NodeGraphPortType(1, .(100, 200, 255, 255));
		let floatType = NodeGraphPortType(2, .(100, 255, 100, 255));

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		out0.PortType = audioType;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		in1.PortType = floatType; // Different type
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		// Mismatched types should be rejected
		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(idx == -1);
	}

	[Test]
	public static void AddConnection_TypeValidation_UntypedConnectsToAnything()
	{
		let canvas = scope NodeGraphCanvas();

		let audioType = NodeGraphPortType(1, .(100, 200, 255, 255));

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		out0.PortType = .Untyped;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		in1.PortType = audioType;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(idx >= 0);
	}

	[Test]
	public static void RemoveConnection()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		canvas.RemoveConnection(0);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	// === Selection ===

	[Test]
	public static void SelectNode()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		canvas.AddNode(n0);
		canvas.AddNode(n1);

		canvas.SelectNode(0);
		Test.Assert(n0.IsSelected);
		Test.Assert(!n1.IsSelected);

		// Selecting another clears previous
		canvas.SelectNode(1);
		Test.Assert(!n0.IsSelected);
		Test.Assert(n1.IsSelected);
	}

	[Test]
	public static void SelectNode_AddToSelection()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		canvas.AddNode(n0);
		canvas.AddNode(n1);

		canvas.SelectNode(0);
		canvas.SelectNode(1, addToSelection: true);
		Test.Assert(n0.IsSelected);
		Test.Assert(n1.IsSelected);
	}

	[Test]
	public static void ClearSelection()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		canvas.AddNode(n0);

		canvas.SelectNode(0);
		Test.Assert(n0.IsSelected);

		canvas.ClearSelection();
		Test.Assert(!n0.IsSelected);
	}

	[Test]
	public static void GetSelectedNodes()
	{
		let canvas = scope NodeGraphCanvas();
		let n0 = new NodeGraphNode();
		n0.Title.Set("A");
		let n1 = new NodeGraphNode();
		n1.Title.Set("B");
		let n2 = new NodeGraphNode();
		n2.Title.Set("C");
		canvas.AddNode(n0);
		canvas.AddNode(n1);
		canvas.AddNode(n2);

		canvas.SelectNode(0);
		canvas.SelectNode(2, addToSelection: true);

		let selected = scope List<int32>();
		canvas.GetSelectedNodes(selected);
		Test.Assert(selected.Count == 2);
		Test.Assert(selected.Contains(0));
		Test.Assert(selected.Contains(2));
	}

	// === Clear ===

	[Test]
	public static void Clear_RemovesEverything()
	{
		let canvas = scope NodeGraphCanvas();

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });

		canvas.Clear();
		Test.Assert(canvas.NodeCount == 0);
		Test.Assert(canvas.ConnectionCount == 0);
	}

	// === Coordinate Transforms ===

	[Test]
	public static void ScreenToCanvas_Identity()
	{
		let canvas = scope NodeGraphCanvas();
		// Default: zoom=1, pan=(0,0)
		let result = canvas.ScreenToCanvas(.(100, 200));
		Test.Assert(Math.Abs(result.X - 100) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 200) < 0.01f);
	}

	[Test]
	public static void CanvasToScreen_Identity()
	{
		let canvas = scope NodeGraphCanvas();
		let result = canvas.CanvasToScreen(.(100, 200));
		Test.Assert(Math.Abs(result.X - 100) < 0.01f);
		Test.Assert(Math.Abs(result.Y - 200) < 0.01f);
	}

	[Test]
	public static void ScreenToCanvas_Roundtrip()
	{
		let canvas = scope NodeGraphCanvas();
		// Simulate some pan/zoom by going through the public API
		let original = Vector2(150, 250);
		let screen = canvas.CanvasToScreen(original);
		let back = canvas.ScreenToCanvas(screen);
		Test.Assert(Math.Abs(back.X - original.X) < 0.01f);
		Test.Assert(Math.Abs(back.Y - original.Y) < 0.01f);
	}

	// === Auto-sizing ===

	[Test]
	public static void AutoSize_ExpandsForPorts()
	{
		let canvas = scope NodeGraphCanvas();
		let node = new NodeGraphNode();
		node.Title.Set("Multi-port");
		node.Size = .(160, 40); // Intentionally small

		for (int i = 0; i < 5; i++)
		{
			let port = new NodeGraphPort();
			port.Direction = .Input;
			port.Label.Set("In");
			node.InputPorts.Add(port);
		}

		canvas.AddNode(node); // AddNode calls AutoSizeNode
		Test.Assert(node.Size.Y > 40); // Should have expanded for 5 ports
	}

	// === Custom Connection Validator ===

	[Test]
	public static void CustomValidator_AllowsAll()
	{
		let canvas = scope NodeGraphCanvas();
		canvas.ConnectionValidator = new (src, dst) => true; // Allow everything

		let typeA = NodeGraphPortType(1, .(255, 0, 0, 255));
		let typeB = NodeGraphPortType(2, .(0, 255, 0, 255));

		let n0 = new NodeGraphNode();
		let out0 = new NodeGraphPort();
		out0.Direction = .Output;
		out0.PortType = typeA;
		n0.OutputPorts.Add(out0);
		canvas.AddNode(n0);

		let n1 = new NodeGraphNode();
		let in1 = new NodeGraphPort();
		in1.Direction = .Input;
		in1.PortType = typeB;
		n1.InputPorts.Add(in1);
		canvas.AddNode(n1);

		// Different types but custom validator allows it
		let idx = canvas.AddConnection(.() { SourceNodeIndex = 0, SourcePortIndex = 0, DestNodeIndex = 1, DestPortIndex = 0 });
		Test.Assert(idx >= 0);
	}
}
