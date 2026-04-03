namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class DebugTests
{
	[Test]
	public static void ExportDOT_ValidSyntax()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("SceneColor", RGTextureDesc(.RGBA8Unorm));
		let depth = graph.CreateTransient("Depth", RGTextureDesc(.Depth32Float));

		graph.AddRenderPass("DepthPrepass", scope (builder) => {
			builder.SetDepthTarget(depth, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.ReadTexture(depth);
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		let dot = scope String();
		GraphDebug.ExportDOT(graph, dot);

		Test.Assert(dot.Contains("digraph"));
		Test.Assert(dot.Contains("DepthPrepass"));
		Test.Assert(dot.Contains("ForwardOpaque"));
		Test.Assert(dot.Contains("SceneColor"));
		Test.Assert(dot.Contains("}")); // Closing brace
	}

	[Test]
	public static void ExportSummary_IncludesCounts()
	{
		let graph = scope RenderGraph(null);
		graph.SetOutputSize(1920, 1080);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Pass1", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		graph.Compile();

		let summary = scope String();
		GraphDebug.ExportSummary(graph, summary);

		Test.Assert(summary.Contains("1920x1080"));
		Test.Assert(summary.Contains("Pass1"));
		Test.Assert(summary.Contains("Render"));
	}

	[Test]
	public static void DOT_ShowsCulledPasses()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		// This pass will be culled (no one reads its output)
		graph.AddRenderPass("Culled", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
		});

		graph.Compile();

		let dot = scope String();
		GraphDebug.ExportDOT(graph, dot);

		Test.Assert(dot.Contains("dashed")); // Culled passes shown with dashed style
	}
}
