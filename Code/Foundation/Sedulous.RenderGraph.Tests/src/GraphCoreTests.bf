namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class GraphCoreTests
{
	[Test]
	public static void CreateTransient_ReturnsValidHandle()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let handle = graph.CreateTransient("Test", RGTextureDesc(.RGBA8Unorm, .FullSize));

		Test.Assert(handle.IsValid);
		Test.Assert(graph.ResourceCount == 1);
	}

	[Test]
	public static void CreateMultipleResources_UniqueHandles()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let h1 = graph.CreateTransient("A", RGTextureDesc(.RGBA8Unorm));
		let h2 = graph.CreateTransient("B", RGTextureDesc(.Depth32Float));

		Test.Assert(h1 != h2);
		Test.Assert(graph.ResourceCount == 2);
	}

	[Test]
	public static void GetResource_ByName()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let h1 = graph.CreateTransient("SceneColor", RGTextureDesc(.RGBA8Unorm));
		let found = graph.GetResource("SceneColor");

		Test.Assert(found == h1);
		Test.Assert(!graph.GetResource("NonExistent").IsValid);
	}

	[Test]
	public static void AddPasses_CountCorrect()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("Pass1", scope (builder) => {
			builder.SetColorTarget(0, color, .Clear, .Store);
			builder.NeverCull();
		});

		graph.AddComputePass("Pass2", scope (builder) => {
			builder.HasSideEffects();
		});

		Test.Assert(graph.PassCount == 2);
	}

	[Test]
	public static void SetOutputSize_AffectsResolution()
	{
		let graph = scope RenderGraph(null);
		graph.SetOutputSize(1920, 1080);

		Test.Assert(graph.OutputWidth == 1920);
		Test.Assert(graph.OutputHeight == 1080);
	}

	[Test]
	public static void ImportTarget_WithFinalState()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let handle = graph.ImportTarget("Backbuffer", null, null, finalState: .Present);

		Test.Assert(handle.IsValid);
	}

	[Test]
	public static void Reset_KeepsPersistent()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.RegisterPersistent("Shadow", null, null);
		graph.CreateTransient("Temp", RGTextureDesc(.RGBA8Unorm));

		graph.Reset();

		// Persistent should survive
		Test.Assert(graph.GetResource("Shadow").IsValid);
		// Transient should be gone
		Test.Assert(!graph.GetResource("Temp").IsValid);
	}
}
