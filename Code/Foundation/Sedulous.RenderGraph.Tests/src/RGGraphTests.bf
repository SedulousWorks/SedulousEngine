using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// Declaring resources and passes, and what the graph then knows about them.
///
/// No device: everything here is about the declarations, which is exactly what compiling
/// without an encoder is for.
class RGGraphTests
{
	[Test]
	public static void ATransientGetsAValidHandle()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let handle = graph.CreateTransient("Test", .(TextureFormat.RGBA8Unorm, SizeMode.FullSize));
		Test.Assert(handle.IsValid);
		Test.Assert(graph.ResourceCount == 1);
	}

	[Test]
	public static void EachResourceGetsItsOwnHandle()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("A", .(TextureFormat.RGBA8Unorm));
		let depth = graph.CreateTransient("B", .(TextureFormat.Depth32Float));

		Test.Assert(color != depth);
		Test.Assert(graph.ResourceCount == 2);
	}

	[Test]
	public static void ResourcesAreFoundByName()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let color = graph.CreateTransient("SceneColor", .(TextureFormat.RGBA8Unorm));
		Test.Assert(graph.GetResource("SceneColor") == color);
		Test.Assert(!graph.GetResource("NoSuchThing").IsValid);
	}

	[Test]
	public static void PassesAreCounted()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Pass1", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.NeverCull();
			});
		graph.AddRenderPass("Pass2", scope (builder) =>
			{
				builder.ReadTexture(color);
				builder.NeverCull();
			});

		Test.Assert(graph.PassCount == 2);
	}

	/// The output size is what a relative transient resolves against, so changing it changes
	/// what gets allocated.
	[Test]
	public static void TheOutputSizeDrivesResolution()
	{
		let graph = scope RenderGraph(null);
		graph.SetOutputSize(800, 600);
		graph.BeginFrame(0);

		Test.Assert(graph.OutputWidth == 800);
		Test.Assert(graph.OutputHeight == 600);

		let handle = graph.CreateTransient("Half", .(TextureFormat.RGBA8Unorm, SizeMode.HalfSize));
		let resource = graph.Resources[handle.Index];
		Test.Assert((resource.TextureDesc.Width == 400) && (resource.TextureDesc.Height == 300));
	}

	[Test]
	public static void AnImportedTargetKeepsItsFinalState()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let handle = graph.ImportTarget("Backbuffer", null, null, ResourceState.Present);
		Test.Assert(handle.IsValid);

		let resource = graph.Resources[handle.Index];
		Test.Assert(resource.Lifetime == .Imported);
		Test.Assert(resource.FinalState.Value == .Present);
	}

	/// An import that does not say what state it is in assumes UNDEFINED for a null texture,
	/// which is the honest answer rather than a guess.
	[Test]
	public static void AnImportWithoutACurrentStateStartsUndefined()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		let handle = graph.ImportTarget("Imported", null, null);
		Test.Assert(graph.Resources[handle.Index].LastKnownState == .Undefined);

		let stated = graph.ImportTarget("Stated", null, null, null, ResourceState.ShaderRead);
		Test.Assert(graph.Resources[stated.Index].LastKnownState == .ShaderRead);
	}

	/// A reset keeps the PERSISTENT resources and drops everything else, which is what a
	/// second view rendered in the same frame needs.
	[Test]
	public static void ResetKeepsThePersistentResources()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		graph.CreateTransient("Transient", .(TextureFormat.RGBA8Unorm));
		graph.RegisterPersistent("History", null, null);
		Test.Assert(graph.ResourceCount == 2);

		graph.Reset();
		Test.Assert(graph.ResourceCount == 1, "only the persistent one survived");
		Test.Assert(graph.GetResource("History").IsValid);
		Test.Assert(!graph.GetResource("Transient").IsValid);
	}

	/// A recycled slot bumps nothing, so a handle from the last frame must NOT resolve to
	/// whatever took its place.
	[Test]
	public static void AStaleHandleDoesNotResolve()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let stale = graph.CreateTransient("First", .(TextureFormat.RGBA8Unorm));

		graph.BeginFrame(1);
		graph.CreateTransient("Second", .(TextureFormat.RGBA8Unorm));

		// The slot was reused, and the graph answers about the resource that is there now.
		Test.Assert(graph.GetResource("First") == RGHandle.Invalid);
		Test.Assert(graph.GetTexture(stale) == null);
	}

	[Test]
	public static void APassCanOverrideItsViewport()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Split", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.SetViewport(10, 20, 300, 400);
				builder.NeverCull();
			});

		let pass = graph.Passes[0];
		Test.Assert(pass.HasViewport);
		Test.Assert((pass.ViewportX == 10) && (pass.ViewportY == 20));
		Test.Assert((pass.ViewportWidth == 300) && (pass.ViewportHeight == 400));
	}

	/// Without one, a pass covers the WHOLE attachment, which is what the graph works out at
	/// execution time rather than something the pass records.
	[Test]
	public static void APassWithoutAViewportOverrideHasNone()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);
		let color = graph.CreateTransient("Color", .(TextureFormat.RGBA8Unorm));

		graph.AddRenderPass("Full", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Clear, .Store);
				builder.NeverCull();
			});

		let pass = graph.Passes[0];
		Test.Assert(!pass.HasViewport);
		Test.Assert((pass.ViewportWidth == 0) && (pass.ViewportHeight == 0));
	}

	/// A graph with no passes compiles to nothing rather than failing.
	[Test]
	public static void AnEmptyGraphCompiles()
	{
		let graph = scope RenderGraph(null);
		graph.BeginFrame(0);

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(graph.ExecutionOrder.IsEmpty);
		Test.Assert(graph.Execute(null) case .Ok, "and executing with no encoder is a compile");
	}

	/// A ping pong resource hands back this frame's slot and last frame's, and the swap moves
	/// them along.
	[Test]
	public static void PingPongSwapsItsSlots()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc.Label = "RGGraphTests.PingPongSwapsItsSlots";
		let first = device.CreateTexture(textureDesc).Value;
		var textureDesc2 = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc2.Label = "RGGraphTests.PingPongSwapsItsSlots";
		let second = device.CreateTexture(textureDesc2).Value;
		let firstView = device.CreateTextureView(first, .() { Label = "RGGraphTests.PingPongSwapsItsSlots" }).Value;
		let secondView = device.CreateTextureView(second, .() { Label = "RGGraphTests.PingPongSwapsItsSlots" }).Value;
		defer
		{
			var a = first; var b = second; var av = firstView; var bv = secondView;
			device.DestroyTextureView(ref av);
			device.DestroyTextureView(ref bv);
			device.DestroyTexture(ref a);
			device.DestroyTexture(ref b);
		}

		let graph = scope RenderGraph(device);
		graph.BeginFrame(0);
		let handle = graph.RegisterPersistentPingPong("History", first, second, firstView, secondView);

		Test.Assert(graph.GetTexture(handle) == first);
		graph.SwapPingPong(handle);
		Test.Assert(graph.GetTexture(handle) == second);
		graph.SwapPingPong(handle);
		Test.Assert(graph.GetTexture(handle) == first, "two slots, so it comes back around");
	}
}
