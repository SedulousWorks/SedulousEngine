using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// A small state machine on the node canvas: four states, three transitions, and one typed
/// input port.
///
/// Any State is deliberately NOT deletable, which is the case a graph editor has to get right:
/// some nodes are structural and the delete key must refuse them rather than leave the graph
/// dangling.
static class NodeGraphTab
{
	public static void Build(TabView tabView)
	{
		let graph = new NodeGraphCanvas();
		graph.ShowGrid = true;

		AddState(graph, "Idle", "", .(50, 50), Color.Rgb(70, 130, 80), true, false);
		AddState(graph, "Walk", "", .(300, 50), Color.Rgb(70, 100, 180), true, false);
		let run = AddState(graph, "Run", "BlendTree1D", .(300, 200), Color.Rgb(180, 100, 70),
			true, false);
		// Typed, so the canvas can refuse a connection from an untyped output.
		run.InputPorts.Add(new NodeGraphPort(.Input, "Speed",
			NodeGraphPortType(1, Color.Rgb(100, 200, 100))));

		let anyState = AddState(graph, "Any State", "", .(50, 200), Color.Rgb(100, 100, 110),
			false, true);
		anyState.IsDeletable = false;

		// Idle to Walk, Idle to Run, and Any State into Walk.
		graph.AddConnection(NodeGraphConnection(0, 0, 1, 0));
		graph.AddConnection(NodeGraphConnection(0, 0, 2, 0));
		graph.AddConnection(NodeGraphConnection(3, 0, 1, 0));

		LogInteractions(graph);
		tabView.AddTab("Node Graph", graph);
	}

	/// Returns the node BORROWED: the canvas owns it from here.
	private static NodeGraphNode AddState(NodeGraphCanvas graph, StringView title,
		StringView subtitle, Float2 position, Color header, bool hasInput, bool outputOnly)
	{
		let node = new NodeGraphNode();
		node.Title.Set(title);
		node.Subtitle.Set(subtitle);
		node.Position = position;
		node.HeaderColor = header;

		node.OutputPorts.Add(new NodeGraphPort(.Output, outputOnly ? "" : "Out"));
		if (hasInput)
			node.InputPorts.Add(new NodeGraphPort(.Input, "In"));

		graph.AddNode(node);
		return node;
	}

	/// The interaction events, written to the console. What they are FOR is a host that keeps
	/// its own model in step with the canvas, so seeing them fire is the point.
	private static void LogInteractions(NodeGraphCanvas graph)
	{
		graph.OnNodeMoved.Add(new (index) => Console.WriteLine(scope $"Node moved: {index}"));
		graph.OnConnectionCreated.Add(new (index) =>
			Console.WriteLine(scope $"Connection created: {index}"));
		graph.OnNodeDeleted.Add(new (index) => Console.WriteLine(scope $"Node deleted: {index}"));
		graph.OnSelectionChanged.Add(new () => Console.WriteLine("Selection changed"));
		graph.OnCanvasContextMenu.Add(new (x, y) =>
			Console.WriteLine(scope $"Canvas context menu at ({x:0.0}, {y:0.0})"));
		graph.OnNodeContextMenu.Add(new (index) =>
			Console.WriteLine(scope $"Node context menu: {index}"));
		graph.OnNodeDoubleClicked.Add(new (index) =>
			Console.WriteLine(scope $"Node double-clicked: {index}"));
	}
}
