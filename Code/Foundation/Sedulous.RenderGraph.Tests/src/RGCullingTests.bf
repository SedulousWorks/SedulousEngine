using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// Culling, dependency building and ordering: the whole of compile, with no device.
class RGCullingTests
{
	private static int32 OrderOf(RenderGraph graph, StringView name)
	{
		for (int i < graph.Passes.Length)
		{
			if (graph.Passes[i].Name == name)
				return graph.Passes[i].ExecutionOrder;
		}
		return -1;
	}

	private static bool IsCulled(RenderGraph graph, StringView name)
	{
		for (let pass in graph.Passes)
		{
			if (pass.Name == name)
				return pass.IsCulled;
		}
		return true;
	}

	/// A pass nothing consumes is CULLED: the work would go into a texture that is thrown
	/// away.
	[Test]
	public static void APassNothingConsumesIsCulled()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let unused = graph.CreateTransient("Unused", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Orphan", scope (builder) =>
			{
				builder.SetColorTarget(0, unused, .Clear, .Store);
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(IsCulled(graph, "Orphan"));
		Test.Assert(graph.CulledPassCount == 1);
	}

	[Test]
	public static void NeverCullKeepsAPass()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let unused = graph.CreateTransient("Unused", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Kept", scope (builder) =>
			{
				builder.SetColorTarget(0, unused, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(!IsCulled(graph, "Kept"));
		Test.Assert(graph.CulledPassCount == 0);
	}

	/// A pass that does something the graph CANNOT SEE says so, and is kept for the same
	/// reason.
	[Test]
	public static void SideEffectsKeepAPass()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.AddComputePass("Readback", scope (builder) => { builder.HasSideEffects(); });

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(!IsCulled(graph, "Readback"));
	}

	/// A live pass keeps ALIVE whatever produced what it reads, and that propagates back up
	/// the chain until it settles.
	[Test]
	public static void CullingPropagatesBackwardThroughTheChain()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let first = graph.CreateTransient("First", .(TextureFormat.RGBA8Unorm));
		let second = graph.CreateTransient("Second", .(TextureFormat.RGBA8Unorm));
		let final = graph.CreateTransient("Final", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("A", scope (builder) =>
			{
				builder.SetColorTarget(0, first, .Clear, .Store);
			});
		graph.AddRenderPass("B", scope (builder) =>
			{
				builder.ReadTexture(first);
				builder.SetColorTarget(0, second, .Clear, .Store);
			});
		graph.AddRenderPass("C", scope (builder) =>
			{
				builder.ReadTexture(second);
				builder.SetColorTarget(0, final, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(!IsCulled(graph, "A"), "kept because B needs it");
		Test.Assert(!IsCulled(graph, "B"));
		Test.Assert(!IsCulled(graph, "C"));
	}

	/// A pass writing an IMPORTED resource that was promised a final state stays: the promise
	/// is to whoever owns that resource rather than to the graph.
	[Test]
	public static void APromisedFinalStateKeepsItsWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let backbuffer = graph.ImportTarget("Backbuffer", null, null, ResourceState.Present);

		graph.AddRenderPass("Present", scope (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(!IsCulled(graph, "Present"));
	}

	// ---- dependencies ----

	/// A read depends on the pass that WROTE what it reads, which is what turns declarations
	/// into an order.
	[Test]
	public static void AReaderIsOrderedAfterItsWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));
		let output = graph.CreateTransient("Output", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Writer", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
			});
		graph.AddRenderPass("Reader", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.SetColorTarget(0, output, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(graph.ExecutionOrder.Length == 2);
		Test.Assert(OrderOf(graph, "Writer") < OrderOf(graph, "Reader"));
	}

	/// Several readers of one resource all follow the writer, and none of them depends on
	/// each other.
	[Test]
	public static void SeveralReadersAllFollowTheWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let shared = graph.CreateTransient("Shared", .(TextureFormat.RGBA8Unorm));
		let firstOut = graph.CreateTransient("FirstOut", .(TextureFormat.RGBA8Unorm));
		let secondOut = graph.CreateTransient("SecondOut", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Writer", scope (builder) =>
			{
				builder.SetColorTarget(0, shared, .Clear, .Store);
			});
		graph.AddRenderPass("ReaderA", scope (builder) =>
			{
				builder.ReadTexture(shared);
				builder.SetColorTarget(0, firstOut, .Clear, .Store);
				builder.NeverCull();
			});
		graph.AddRenderPass("ReaderB", scope (builder) =>
			{
				builder.ReadTexture(shared);
				builder.SetColorTarget(0, secondOut, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "Writer") < OrderOf(graph, "ReaderA"));
		Test.Assert(OrderOf(graph, "Writer") < OrderOf(graph, "ReaderB"));
	}

	/// Writes to DIFFERENT subresources are independent, and a reader of the whole resource
	/// still comes after both.
	[Test]
	public static void SubresourceWritesAreIndependentAndTheReaderComesLast()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		var desc = RGTextureDesc(TextureFormat.Depth32Float, 1024, 1024);
		desc.ArrayLayerCount = 4;
		let cascades = graph.CreateTransient("Cascades", desc);
		let output = graph.CreateTransient("Output", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Cascade0", scope (builder) =>
			{
				builder.SetDepthTarget(cascades, .Clear, .Store, 1.0f, .(0, 1, 0, 1));
			});
		graph.AddRenderPass("Cascade1", scope (builder) =>
			{
				builder.SetDepthTarget(cascades, .Clear, .Store, 1.0f, .(0, 1, 1, 1));
			});
		graph.AddRenderPass("Shade", scope (builder) =>
			{
				builder.SampleDepth(cascades);
				builder.SetColorTarget(0, output, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "Shade") > OrderOf(graph, "Cascade0"));
		Test.Assert(OrderOf(graph, "Shade") > OrderOf(graph, "Cascade1"));

		// Neither cascade waits on the other: they touch different layers.
		for (let pass in graph.Passes)
		{
			if (pass.Name == "Cascade1")
				Test.Assert(pass.Dependencies.IsEmpty);
		}
	}

	/// LOADING an attachment is a read, so it orders after whoever wrote it even though the
	/// pass declared no read at all.
	[Test]
	public static void LoadingAnAttachmentOrdersAfterItsWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Clear", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
			});
		graph.AddRenderPass("Overlay", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "Clear") < OrderOf(graph, "Overlay"));
	}

	/// The same for depth.
	[Test]
	public static void LoadingADepthAttachmentOrdersAfterItsWriter()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let depth = graph.CreateTransient("Depth", .(TextureFormat.Depth32Float));

		graph.AddRenderPass("Prepass", scope (builder) =>
			{
				builder.SetDepthTarget(depth, .Clear, .Store);
			});
		graph.AddRenderPass("Forward", scope (builder) =>
			{
				builder.SetDepthTarget(depth, .Load, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "Prepass") < OrderOf(graph, "Forward"));
	}

	/// A chain of writers and readers comes out in one order.
	[Test]
	public static void AChainOrdersEndToEnd()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let a = graph.CreateTransient("A", .(TextureFormat.RGBA8Unorm));
		let b = graph.CreateTransient("B", .(TextureFormat.RGBA8Unorm));
		let c = graph.CreateTransient("C", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("First", scope (builder) =>
			{
				builder.SetColorTarget(0, a, .Clear, .Store);
			});
		graph.AddRenderPass("Second", scope (builder) =>
			{
				builder.ReadTexture(a);
				builder.SetColorTarget(0, b, .Clear, .Store);
			});
		graph.AddRenderPass("Third", scope (builder) =>
			{
				builder.ReadTexture(b);
				builder.SetColorTarget(0, c, .Clear, .Store);
				builder.NeverCull();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "First") < OrderOf(graph, "Second"));
		Test.Assert(OrderOf(graph, "Second") < OrderOf(graph, "Third"));
	}

	/// An EXPLICIT dependency orders two passes that share no resource at all.
	[Test]
	public static void AnExplicitDependencyOrdersUnrelatedPasses()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let first = graph.AddComputePass("First", scope (builder) => { builder.HasSideEffects(); });
		graph.AddComputePass("Second", scope (builder) =>
			{
				builder.DependsOn(first);
				builder.HasSideEffects();
			});

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(OrderOf(graph, "First") < OrderOf(graph, "Second"));
	}

	/// A CYCLE is a declaration error, and compiling says so rather than running some of it.
	[Test]
	public static void ACycleFailsToCompile()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let first = graph.AddComputePass("First", scope (builder) => { builder.HasSideEffects(); });
		let second = graph.AddComputePass("Second", scope (builder) =>
			{
				builder.DependsOn(first);
				builder.HasSideEffects();
			});

		// Close the loop by hand: no builder can express this, which is the point.
		graph.Passes[0].Dependencies.Add(second);

		Test.Assert(graph.Compile() case .Err);
	}
}
