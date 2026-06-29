namespace Sedulous.RenderGraph.Tests;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class BundlePassTests
{
	[Test]
	public static void SetBundleExecute_StoresCallback()
	{
		let pass = scope RenderGraphPass("Bundle", .Render);
		var builder = PassBuilder(pass);

		builder.SetBundleExecute(new (encoder, outBundles) => {
			// Would record bundles here
		});

		Test.Assert(pass.BundleCallback != null);
		Test.Assert(pass.ExecuteCallback == null);
	}

	[Test]
	public static void BundlePass_WithColorTarget()
	{
		let pass = scope RenderGraphPass("Bundle", .Render);
		var builder = PassBuilder(pass);
		let color = RGHandle(0, 1);

		builder
			.SetColorTarget(0, color, .Clear, .Store)
			.SetBundleExecute(new (encoder, outBundles) => { });

		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.BundleCallback != null);
	}

	[Test]
	public static void BundlePass_WithDepthTarget()
	{
		let pass = scope RenderGraphPass("Bundle", .Render);
		var builder = PassBuilder(pass);
		let color = RGHandle(0, 1);
		let depth = RGHandle(1, 1);

		builder
			.SetColorTarget(0, color, .Clear, .Store)
			.SetDepthTarget(depth, .Clear, .Store)
			.SetBundleExecute(new (encoder, outBundles) => { });

		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.DepthTarget.HasValue);
		Test.Assert(pass.BundleCallback != null);
	}

	[Test]
	public static void BundlePass_NeverCull()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		graph.AddRenderPass("BundlePass", scope (builder) => {
			builder
				.SetColorTarget(0, color, .Clear, .Store)
				.SetBundleExecute(new (encoder, outBundles) => { })
				.NeverCull();
		});

		graph.Compile();

		Test.Assert(graph.CulledPassCount == 0);
	}

	[Test]
	public static void BundlePass_CulledWhenUnused()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));

		// Bundle pass writes color but nobody reads it
		graph.AddRenderPass("BundlePass", scope (builder) => {
			builder
				.SetColorTarget(0, color, .Clear, .Store)
				.SetBundleExecute(new (encoder, outBundles) => { });
		});

		graph.Compile();

		Test.Assert(graph.CulledPassCount == 1);
	}

	[Test]
	public static void BundlePass_KeptWhenConsumed()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("Color", RGTextureDesc(.RGBA8Unorm));
		let final = graph.CreateTransient("Final", RGTextureDesc(.RGBA8Unorm));

		// Bundle pass writes color
		graph.AddRenderPass("BundlePass", scope (builder) => {
			builder
				.SetColorTarget(0, color, .Clear, .Store)
				.SetBundleExecute(new (encoder, outBundles) => { });
		});

		// Post pass reads color, writes final, never cull
		graph.AddRenderPass("PostProcess", scope (builder) => {
			builder
				.ReadTexture(color)
				.SetColorTarget(0, final, .Clear, .Store)
				.NeverCull();
		});

		graph.Compile();

		// Both passes should survive
		Test.Assert(graph.CulledPassCount == 0);
	}

	[Test]
	public static void BundlePass_ReadTexture()
	{
		let pass = scope RenderGraphPass("Bundle", .Render);
		var builder = PassBuilder(pass);
		let shadow = RGHandle(0, 1);
		let color = RGHandle(1, 1);

		builder
			.ReadTexture(shadow)
			.SetColorTarget(0, color, .Clear, .Store)
			.SetBundleExecute(new (encoder, outBundles) => { });

		// Should have ReadTexture + WriteColorTarget accesses
		Test.Assert(pass.Accesses.Count == 2);

		bool hasRead = false;
		for (let access in pass.Accesses)
		{
			if (access.Handle == shadow && access.Type == .ReadTexture)
				hasRead = true;
		}
		Test.Assert(hasRead);
	}

	[Test]
	public static void BundleAndExecute_AreMutuallyExclusive()
	{
		// Setting both is structurally allowed (no runtime assertion),
		// but ExecuteRenderPass picks the bundle path when BundleCallback != null.
		let pass = scope RenderGraphPass("Bundle", .Render);
		var builder = PassBuilder(pass);

		builder
			.SetBundleExecute(new (encoder, outBundles) => { })
			.SetExecute(new (rp) => { });

		// Both are set - the graph uses BundleCallback when present
		Test.Assert(pass.BundleCallback != null);
		Test.Assert(pass.ExecuteCallback != null);
	}
}
