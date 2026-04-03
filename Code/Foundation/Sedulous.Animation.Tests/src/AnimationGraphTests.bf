namespace Sedulous.Animation.Tests;

using System;

class AnimationGraphTests
{
	[Test]
	public static void AddParameter_ReturnsSequentialIndices()
	{
		let graph = scope AnimationGraph();
		let idx0 = graph.AddParameter("Speed", .Float);
		let idx1 = graph.AddParameter("Grounded", .Bool);
		let idx2 = graph.AddParameter("Attack", .Trigger);

		Test.Assert(idx0 == 0);
		Test.Assert(idx1 == 1);
		Test.Assert(idx2 == 2);
		Test.Assert(graph.Parameters.Count == 3);
	}

	[Test]
	public static void FindParameter_ExistingName_ReturnsIndex()
	{
		let graph = scope AnimationGraph();
		graph.AddParameter("Speed", .Float);
		graph.AddParameter("Grounded", .Bool);

		Test.Assert(graph.FindParameter("Speed") == 0);
		Test.Assert(graph.FindParameter("Grounded") == 1);
	}

	[Test]
	public static void FindParameter_NonExistent_ReturnsNegative()
	{
		let graph = scope AnimationGraph();
		graph.AddParameter("Speed", .Float);

		Test.Assert(graph.FindParameter("Missing") == -1);
	}

	[Test]
	public static void GetParameter_ValidIndex_ReturnsParameter()
	{
		let graph = scope AnimationGraph();
		graph.AddParameter("Speed", .Float);

		let param = graph.GetParameter(0);
		Test.Assert(param != null);
		Test.Assert(param.Type == .Float);
	}

	[Test]
	public static void GetParameter_InvalidIndex_ReturnsNull()
	{
		let graph = scope AnimationGraph();
		Test.Assert(graph.GetParameter(0) == null);
		Test.Assert(graph.GetParameter(-1) == null);
	}

	[Test]
	public static void AddLayer_ReturnsSequentialIndices()
	{
		let graph = scope AnimationGraph();
		let layer0 = new AnimationLayer("Base");
		let layer1 = new AnimationLayer("Upper");

		let idx0 = graph.AddLayer(layer0);
		let idx1 = graph.AddLayer(layer1);

		Test.Assert(idx0 == 0);
		Test.Assert(idx1 == 1);
		Test.Assert(graph.Layers.Count == 2);
	}

	[Test]
	public static void EmptyGraph_HasNoParametersOrLayers()
	{
		let graph = scope AnimationGraph();
		Test.Assert(graph.Parameters.Count == 0);
		Test.Assert(graph.Layers.Count == 0);
	}

	[Test]
	public static void FindParameter_CaseSensitive()
	{
		let graph = scope AnimationGraph();
		graph.AddParameter("Speed", .Float);

		// FindParameter uses case-insensitive comparison (StringView.Compare with ignoreCase=false)
		Test.Assert(graph.FindParameter("speed") == -1);
		Test.Assert(graph.FindParameter("SPEED") == -1);
		Test.Assert(graph.FindParameter("Speed") == 0);
	}
}
