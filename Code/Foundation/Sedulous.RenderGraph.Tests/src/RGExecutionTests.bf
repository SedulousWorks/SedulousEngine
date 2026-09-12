using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// Executing a graph against a device: allocation, pooling, the transient identities, and the
/// bundle path.
class RGExecutionTests
{
	/// A null device, a command pool, an encoder, and an imported back buffer to draw into.
	private class Harness
	{
		public IBackend Backend ~ delete _;
		public IDevice Device;
		public ICommandPool Pool;
		public ICommandEncoder Encoder;
		public ITexture Backbuffer;
		public ITextureView BackbufferView;

		public this()
		{
			Backend = NullRhi.CreateBackend();
			Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
			Pool = Device.CreateCommandPool(.Graphics).Value;
			Encoder = Pool.CreateEncoder().Value;

			Backbuffer = Device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64)).Value;
			BackbufferView = Device.CreateTextureView(Backbuffer, .()).Value;
		}

		public ~this()
		{
			Device.DestroyTextureView(ref BackbufferView);
			Device.DestroyTexture(ref Backbuffer);
			Pool.DestroyEncoder(ref Encoder);
			Device.DestroyCommandPool(ref Pool);
		}
	}

	/// One frame: a transient written and then read into the back buffer, answering the
	/// transient's identity and view.
	private static void RunFrame(RenderGraph graph, Harness harness, int32 frameIndex,
		out uint64 outGeneration, out ITextureView outView)
	{
		var generation = (uint64)0;
		ITextureView view = null;

		graph.SetOutputSize(64, 64);
		graph.BeginFrame(frameIndex);

		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);
		let scene = graph.CreateTransient("Scene", .(TextureFormat.RGBA16Float, 64, 64));

		graph.AddRenderPass("Scene", scope [&generation, &graph, &scene, &view] (builder) =>
			{
				builder.SetColorTarget(0, scene, .Clear, .Store);
				builder.SetExecute(new [&generation, &graph, &scene, &view] (encoder) =>
					{
						generation = graph.GetTextureGeneration(scene);
						view = graph.GetTextureView(scene);
					});
			});
		graph.AddRenderPass("Present", scope (builder) =>
			{
				builder.ReadTexture(scene);
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		graph.EndFrame();

		outGeneration = generation;
		outView = view;
	}

	/// A pooled texture keeps its identity, which is what lets a bind group cache over the
	/// view stay valid rather than being rebuilt every frame.
	[Test]
	public static void APooledTransientKeepsItsIdentity()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		RunFrame(graph, harness, 0, let firstGeneration, let firstView);
		RunFrame(graph, harness, 1, let secondGeneration, let secondView);

		Test.Assert(firstGeneration != 0, "a fresh allocation gets a real identity");
		Test.Assert(firstView != null);
		Test.Assert(secondGeneration == firstGeneration, "the same description came out of the pool");
		Test.Assert(secondView == firstView);
	}

	/// Two DIFFERENT transients are two different physical textures, so their identities
	/// differ: a cache keyed on one must not serve the other.
	[Test]
	public static void DistinctTransientsGetDistinctIdentities()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		var firstGeneration = (uint64)0;
		var secondGeneration = (uint64)0;

		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);

		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);
		let first = graph.CreateTransient("A", .(TextureFormat.RGBA16Float, 64, 64));
		let second = graph.CreateTransient("B", .(TextureFormat.RGBA8Unorm, 32, 32));

		graph.AddRenderPass("PassA", scope [&first, &firstGeneration, &graph] (builder) =>
			{
				builder.SetColorTarget(0, first, .Clear, .Store);
				builder.SetExecute(new [&first, &firstGeneration, &graph] (encoder) =>
					{
						firstGeneration = graph.GetTextureGeneration(first);
					});
			});
		graph.AddRenderPass("PassB", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, second, .Clear, .Store);
				builder.SetExecute(new [&graph, &second, &secondGeneration] (encoder) =>
					{
						secondGeneration = graph.GetTextureGeneration(second);
					});
			});
		graph.AddRenderPass("Sink", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.ReadTexture(first);
				builder.ReadTexture(second);
				builder.NeverCull();
				builder.SetExecute(new (encoder) => {});
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);

		Test.Assert(firstGeneration != 0);
		Test.Assert(secondGeneration != 0);
		Test.Assert(firstGeneration != secondGeneration);
	}

	/// A CULLED pass's body never runs, which is the whole point of culling.
	[Test]
	public static void ACulledPassDoesNotRun()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		var orphanRan = false;
		var keptRan = false;

		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);
		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);
		let orphaned = graph.CreateTransient("Orphaned", .(TextureFormat.RGBA8Unorm, 64, 64));

		graph.AddRenderPass("Orphan", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, orphaned, .Clear, .Store);
				builder.SetExecute(new [&orphanRan] (encoder) => { orphanRan = true; });
			});
		graph.AddRenderPass("Kept", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.NeverCull();
				builder.SetExecute(new [&keptRan] (encoder) => { keptRan = true; });
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		Test.Assert(!orphanRan);
		Test.Assert(keptRan);
	}

	/// A condition that says no skips the pass for THIS FRAME without rebuilding the graph.
	[Test]
	public static void AFalseConditionSkipsThePass()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		var ran = false;
		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);
		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);

		graph.AddRenderPass("Conditional", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.NeverCull();
				builder.EnableIf(new () => false);
				builder.SetExecute(new [&ran] (encoder) => { ran = true; });
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		Test.Assert(!ran);
		Test.Assert(!graph.Passes[0].IsCulled, "skipped rather than culled");
	}

	/// A bundle pass records its bundles BEFORE the pass begins, which is the only time a
	/// bundle can be made, and the graph then replays them inside it.
	[Test]
	public static void ABundlePassRecordsBeforeThePassBegins()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		var recorded = false;
		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);
		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);

		graph.AddRenderPass("Bundled", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.NeverCull();
				builder.SetBundleExecute(new [&recorded] (encoder, bundles) => { recorded = true; });
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		Test.Assert(recorded);
	}

	/// A bundle pass that produces NO bundles still runs, so its attachments are still
	/// cleared: a frame where the workers had nothing to draw is not a frame with no pass.
	[Test]
	public static void ABundlePassWithNoBundlesStillRuns()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);
		let backbuffer = graph.ImportTarget("Backbuffer", harness.Backbuffer,
			harness.BackbufferView, ResourceState.Present);

		graph.AddRenderPass("Empty", scope (builder) =>
			{
				builder.SetColorTarget(0, backbuffer, .Clear, .Store);
				builder.NeverCull();
				builder.SetBundleExecute(new (encoder, bundles) => {});
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		Test.Assert(graph.ExecutionOrder.Length == 1);
	}

	/// A compute pass and a copy pass record through their own callbacks.
	[Test]
	public static void ComputeAndCopyPassesRun()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		var computeRan = false;
		var copyRan = false;

		graph.BeginFrame(0);
		graph.AddComputePass("Compute", scope [&] (builder) =>
			{
				builder.HasSideEffects();
				builder.SetComputeExecute(new [&computeRan] (encoder) => { computeRan = true; });
			});
		graph.AddCopyPass("Copy", scope [&] (builder) =>
			{
				builder.HasSideEffects();
				builder.SetCopyExecute(new [&copyRan] (encoder) => { copyRan = true; });
			});

		Test.Assert(graph.Execute(harness.Encoder) case .Ok);
		Test.Assert(computeRan && copyRan);
	}

	/// A transient nothing references is NEVER ALLOCATED, which is the other half of culling.
	[Test]
	public static void AnUnreferencedTransientIsNotAllocated()
	{
		let harness = scope Harness();
		let graph = scope RenderGraph(harness.Device);

		graph.SetOutputSize(64, 64);
		graph.BeginFrame(0);
		let unused = graph.CreateTransient("Unused", .(TextureFormat.RGBA8Unorm, 64, 64));

		Test.Assert(graph.Compile() case .Ok);
		Test.Assert(graph.GetTexture(unused) == null);
	}

	/// The pool ages out what nothing has asked for, so a target that stops being used does
	/// not sit on GPU memory forever.
	[Test]
	public static void ThePoolAgesOutWhatIsUnwanted()
	{
		let harness = scope Harness();
		let pool = scope TransientTexturePool(harness.Device);
		pool.MaxUnusedFrames = 2;

		let desc = TextureDesc.RenderTarget(.RGBA8Unorm, 16, 16);
		let texture = harness.Device.CreateTexture(desc).Value;
		let view = harness.Device.CreateTextureView(texture, .()).Value;
		pool.ReturnToPool(desc, texture, view, 1);
		Test.Assert(pool.Count == 1);

		pool.EndFrame();
		pool.EndFrame();
		Test.Assert(pool.Count == 1, "still within its grace");

		pool.EndFrame();
		Test.Assert(pool.Count == 0);
	}

	/// Matching is EXACT: a target that differs in any of its description is a different
	/// target, and handing back a near miss gives a pass the wrong shape.
	[Test]
	public static void ThePoolMatchesExactly()
	{
		let harness = scope Harness();
		let pool = scope TransientTexturePool(harness.Device);

		let desc = TextureDesc.RenderTarget(.RGBA8Unorm, 16, 16);
		let texture = harness.Device.CreateTexture(desc).Value;
		let view = harness.Device.CreateTextureView(texture, .()).Value;
		pool.ReturnToPool(desc, texture, view, 7);

		var different = desc;
		different.Width = 32;
		Test.Assert(!pool.TryAcquire(different, let missTexture, let missView, let missGeneration));
		Test.Assert(missTexture == null);
		Test.Assert(missGeneration == 0);

		Test.Assert(pool.TryAcquire(desc, var hitTexture, var hitView, let hitGeneration));
		Test.Assert(hitTexture == texture);
		Test.Assert(hitGeneration == 7, "the identity came back with it");
		Test.Assert(pool.Count == 0, "and it left the pool");

		// Acquiring took it out of the pool, so the pool will not free it.
		harness.Device.DestroyTextureView(ref hitView);
		harness.Device.DestroyTexture(ref hitTexture);
	}
}
