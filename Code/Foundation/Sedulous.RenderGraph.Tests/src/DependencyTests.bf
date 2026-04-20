namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class DependencyTests
{
	[Test]
	public static void ReaderDependsOnWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Writer", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddRenderPass("Reader", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		graph.Compile();

		let order = graph.ExecutionOrder;
		Test.Assert(order.Count == 2);

		// Writer should come before Reader
		let writerOrder = graph.Passes[order[0]].Name;
		Test.Assert(writerOrder.Equals("Writer"));
	}

	[Test]
	public static void MultipleReaders_FanOut()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Writer", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddRenderPass("ReaderA", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		graph.AddRenderPass("ReaderB", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		graph.Compile();

		// All 3 passes should execute, Writer first
		Test.Assert(graph.ExecutionOrder.Count == 3);
		let firstName = graph.Passes[graph.ExecutionOrder[0]].Name;
		Test.Assert(firstName.Equals("Writer"));
	}

	[Test]
	public static void SubresourceWrites_Independent()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let atlas = graph.CreateTransient("ShadowAtlas", RGTextureDesc(.Depth32Float) { ArrayLayerCount = 4 });

		// Two passes writing to different layers - should be independent
		graph.AddRenderPass("Cascade0", scope (builder) => {
			builder.SetDepthTarget(atlas, .Clear, .Store, 1.0f, .(0, 1, 0, 1));
			builder.NeverCull();
		});

		graph.AddRenderPass("Cascade1", scope (builder) => {
			builder.SetDepthTarget(atlas, .Clear, .Store, 1.0f, .(0, 1, 1, 1));
			builder.NeverCull();
		});

		// Reader of all layers - depends on both
		graph.AddRenderPass("Forward", scope (builder) => {
			builder.ReadTexture(atlas);
			builder.NeverCull();
		});

		graph.Compile();

		// All 3 should execute, Forward last
		Test.Assert(graph.ExecutionOrder.Count == 3);
		let lastIdx = graph.ExecutionOrder[2];
		let lastName = graph.Passes[lastIdx].Name;
		Test.Assert(lastName.Equals("Forward"));
	}

	/// When a pass uses SetColorTarget with LoadOp.Load, it reads existing content.
	/// It must depend on whoever wrote the resource (e.g., ForwardOpaque before Terrain).
	[Test]
	public static void LoadOp_CreatesDependencyOnWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("SceneColor", RGTextureDesc(.RGBA16Float));

		// ForwardOpaque clears and writes
		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		// Terrain loads (reads existing) and writes on top
		graph.AddRenderPass("Terrain", scope (builder) => {
			builder.SetColorTarget(0, color, .Load, .Store);
			builder.NeverCull();
		});

		graph.Compile();

		Test.Assert(graph.ExecutionOrder.Count == 2);
		// ForwardOpaque must run before Terrain
		Test.Assert(graph.Passes[graph.ExecutionOrder[0]].Name.Equals("ForwardOpaque"));
		Test.Assert(graph.Passes[graph.ExecutionOrder[1]].Name.Equals("Terrain"));
	}

	/// Same for depth: LoadOp.Load on depth target creates dependency on prior depth writer.
	[Test]
	public static void DepthLoadOp_CreatesDependencyOnWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let depth = graph.CreateTransient("Depth", RGTextureDesc(.Depth32Float));

		// DepthPrepass clears and writes depth
		graph.AddRenderPass("DepthPrepass", scope (builder) => {
			builder.SetDepthTarget(depth, .Clear, .Store);
			builder.NeverCull();
		});

		// ForwardOpaque loads depth (reads existing, no write)
		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.SetDepthTarget(depth, .Load, .Store);
			builder.NeverCull();
		});

		graph.Compile();

		Test.Assert(graph.ExecutionOrder.Count == 2);
		Test.Assert(graph.Passes[graph.ExecutionOrder[0]].Name.Equals("DepthPrepass"));
		Test.Assert(graph.Passes[graph.ExecutionOrder[1]].Name.Equals("ForwardOpaque"));
	}

	[Test]
	public static void WriterChain_CorrectOrdering()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let tex = graph.CreateTransient("Tex", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Write1", scope (builder) => {
			builder.SetColorTarget(0, tex, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddComputePass("Process", scope (builder) => {
			builder.ReadTexture(tex);
			builder.WriteStorage(tex);
			builder.NeverCull();
		});

		graph.AddRenderPass("FinalRead", scope (builder) => {
			builder.ReadTexture(tex);
			builder.NeverCull();
		});

		graph.Compile();

		// Order: Write1 -> Process -> FinalRead
		Test.Assert(graph.ExecutionOrder.Count == 3);
		Test.Assert(graph.Passes[graph.ExecutionOrder[0]].Name.Equals("Write1"));
		Test.Assert(graph.Passes[graph.ExecutionOrder[1]].Name.Equals("Process"));
		Test.Assert(graph.Passes[graph.ExecutionOrder[2]].Name.Equals("FinalRead"));
	}
}
