namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class CullingTests
{
	[Test]
	public static void UnusedPass_IsCulled()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		// This pass writes to Color but nothing reads it, so it should be culled
		graph.AddRenderPass("Unused", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
		});

		graph.Compile();

		Test.Assert(graph.CulledPassCount == 1);
	}

	[Test]
	public static void NeverCull_PreventsCulling()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Important", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		graph.Compile();

		Test.Assert(graph.CulledPassCount == 0);
	}

	[Test]
	public static void HasSideEffects_PreventsCulling()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.AddComputePass("SideEffect", scope (builder) => {
			builder.HasSideEffects();
		});

		graph.Compile();

		Test.Assert(graph.CulledPassCount == 0);
	}

	[Test]
	public static void BackwardPropagation_KeepsDependencies()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let depth = graph.CreateTransient("Depth", RGTextureDesc(.Depth32Float));
		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		// Pass 1: writes depth
		graph.AddRenderPass("DepthPrepass", scope (builder) => {
			builder.SetDepthTarget(depth, .Clear, .Store);
		});

		// Pass 2: reads depth, writes color — NeverCull
		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.ReadTexture(depth);
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		graph.Compile();

		// DepthPrepass should NOT be culled (ForwardOpaque needs it)
		Test.Assert(graph.CulledPassCount == 0);
	}

	[Test]
	public static void ImportedWithFinalState_PreventsCulling()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let backbuffer = graph.ImportTarget("BB", null, null, finalState: .Present);
		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		// Pass 1: writes Color
		graph.AddRenderPass("Render", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
		});

		// Pass 2: reads Color, writes backbuffer (has finalState)
		graph.AddRenderPass("Blit", scope (builder) => {
			builder.ReadTexture(color);
			builder.SetColorTarget(0, backbuffer, .Clear, .Store);
		});

		graph.Compile();

		// Both passes should survive (Blit writes to imported with finalState, Render feeds it)
		Test.Assert(graph.CulledPassCount == 0);
	}
}
