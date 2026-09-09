using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// Turning a graph into something a person can read.
class RGDebugTests
{
	/// A small graph: one pass writing, one reading, one that nothing consumes.
	private static void BuildGraph(RenderGraph graph)
	{
		graph.BeginFrame(0);
		let color = graph.CreateTransient("SceneColor", .(TextureFormat.RGBA8Unorm));
		let output = graph.ImportTarget("Backbuffer", null, null, ResourceState.Present);
		let orphaned = graph.CreateTransient("Orphaned", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Scene", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
			});
		graph.AddRenderPass("Present", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.SetColorTarget(0, output, .Clear, .Store);
			});
		graph.AddComputePass("Wasted", scope (builder) =>
			{
				builder.WriteStorage(orphaned);
			});

		graph.Compile().IgnoreError();
	}

	[Test]
	public static void TheDotOutputIsWellFormed()
	{
		let graph = scope RenderGraph(null);
		BuildGraph(graph);

		let dot = scope String();
		GraphDebug.ExportDOT(graph, dot);

		Test.Assert(dot.StartsWith("digraph RenderGraph {"));
		Test.Assert(dot.EndsWith("}\n"));
		Test.Assert(dot.Contains("rankdir=LR;"));
		Test.Assert(dot.Contains("Scene"));
		Test.Assert(dot.Contains("SceneColor"));
		Test.Assert(dot.Contains("(imported)"), "a resource says what it is");
		Test.Assert(dot.Contains("->"), "and the accesses are edges");
	}

	/// A CULLED pass is drawn dashed and grey, so a pass that vanished and the reason are
	/// both on the page.
	[Test]
	public static void CulledPassesAreDrawnDashed()
	{
		let graph = scope RenderGraph(null);
		BuildGraph(graph);

		let dot = scope String();
		GraphDebug.ExportDOT(graph, dot);

		Test.Assert(dot.Contains("style=dashed"));
		Test.Assert(dot.Contains("fontcolor=\"gray\""));
	}

	[Test]
	public static void TheSummaryCountsEverything()
	{
		let graph = scope RenderGraph(null);
		graph.SetOutputSize(1280, 720);
		BuildGraph(graph);

		let summary = scope String();
		GraphDebug.ExportSummary(graph, summary);

		Test.Assert(summary.Contains("=== Render Graph Summary ==="));
		Test.Assert(summary.Contains("Passes:"));
		Test.Assert(summary.Contains("culled"));
		Test.Assert(summary.Contains("transient"));
		Test.Assert(summary.Contains("imported"));
		Test.Assert(summary.Contains("1280x720"));
		Test.Assert(summary.Contains("Execution order:"));
		Test.Assert(summary.Contains("[Render] Scene"));
	}

	/// A graph that has not been compiled has no order to print, and says the rest anyway.
	[Test]
	public static void AnUncompiledGraphStillSummarises()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		let summary = scope String();
		GraphDebug.ExportSummary(graph, summary);

		Test.Assert(summary.Contains("Passes: 0 active"));
		Test.Assert(!summary.Contains("Execution order:"));
	}
}
