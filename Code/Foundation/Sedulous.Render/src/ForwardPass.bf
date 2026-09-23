using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// The forward passes: it declares a view's opaque, blended and post tone mapping work into
/// the frame graph and, when the graph executes, resolves and emits that view's draws.
///
/// The pass body is a BUNDLE the graph replays. Resolving happens on one thread, since that
/// is where the uploads and allocations are; emitting touches nothing shared, so above a
/// threshold it fans out across the job system into a bundle per chunk.
class ForwardPass
{
	/// Above this many resolved draws the emission fans out; below it, one bundle on the
	/// calling thread. Recording in parallel only pays with many DISTINCT draws, and an
	/// instanced batch collapses to one resolved draw.
	private const int cParallelEmitThreshold = 256;

	private IDevice mDevice;
	private uint32 mFramesInFlight;
	/// The depth target is a graph transient.
	private TextureFormat mDepthFormat = .Depth32Float;

	/// Per frame: whether any temporal effect reads the velocity this frame.
	private bool mMotionNeeded = true;
	private float mShadowFarFade = 40.0f;
	/// The WIND sway's clock: this frame's seconds and last frame's.
	private float mTimeSeconds = 0.0f;
	private float mPrevTimeSeconds = 0.0f;

	/// Reused, and drained by each pass.
	private List<ResolvedDraw> mResolved = new .() ~ delete _;
	/// The per chunk bundles, kept in draw order.
	private List<IRenderBundle> mBundles = new .() ~ delete _;

	/// One command pool per frame slot AND chunk, for the parallel emit.
	private List<ICommandPool> mWorkerPools = new .() ~ delete _;
	private int32 mWorkerSlots = 0;

	public this(IDevice device, uint32 framesInFlight)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	public ~this()
	{
		ReleaseWorkerPools();
	}

	public TextureFormat DepthFormat => mDepthFormat;

	/// Whether any temporal effect consumes the motion vectors this frame. When it does not,
	/// the resolve skips the per instance previous world lookup and the velocity is nought.
	public void SetMotionNeeded(bool needed) => mMotionNeeded = needed;
	public void SetShadowFarFade(float value) => mShadowFarFade = value;

	/// The frame's clock, this frame's seconds and last frame's, which is the WIND sway's
	/// phase. Set once per frame.
	public void SetTime(float seconds, float prevSeconds)
	{
		mTimeSeconds = seconds;
		mPrevTimeSeconds = prevSeconds;
	}

	/// Once per frame, before composing: provisions and resets the per worker pools.
	///
	/// The reset happens ONCE per frame, not per view: a worker's bundle has to outlive the
	/// submission that executes it, so it cannot be freed between views.
	public void BeginFrame(uint32 frameIndex)
	{
		if (!HasGlobalJobSystem())
			return;
		if (!EnsureWorkerPools(GlobalJobs().SlotCount))
			return;

		let poolBase = (int)frameIndex * (int)mWorkerSlots;
		for (int s < (int)mWorkerSlots)
		{
			if (mWorkerPools[poolBase + s] != null)
				mWorkerPools[poolBase + s].Reset();
		}
	}

	/// Declares one view's OPAQUE pass: the shaded colour and the auxiliary targets, against
	/// the depth the prepass wrote.
	public void DeclarePass(RenderView view, RendererRegistry registry, RenderGraph graph,
		uint32 frameIndex, uint32 viewIndex, RGHandle color, RGHandle depth, bool clearColor,
		TextureFormat colorFormat, RGHandle normal, RGHandle velocity, RGHandle material,
		Float4x4 prevViewProj, Float2 jitter, Float2 prevJitter,
		ClusterBinding cluster = .(), ShadowBinding shadow = .(), IblBinding ibl = .(),
		LoadOp depthLoad = .Load, RGSubresourceRange colorSub = .(),
		RGHandle probeHandle = .Invalid, bool probeValid = false, uint32 probeBase = 0,
		uint32 probeCount = 0)
	{
		if ((view.Width == 0) || (view.Height == 0))
			return;

		let colorLoad = clearColor ? LoadOp.Clear : LoadOp.Load;
		let drawViewProj = view.Camera.ViewProjection;

		graph.AddRenderPass("forward", scope (builder) =>
			{
				// The sub range targets ONE LAYER when capturing into a cube face; empty is
				// the whole target.
				builder.SetColorTarget(0, color, colorLoad, .Store, view.Settings.Clear, colorSub);
				// The auxiliary targets, cleared per view: the view space normal, the motion
				// vector, and the roughness and metallic the reflections read.
				builder.SetColorTarget(1, normal, .Clear, .Store, .Black);
				builder.SetColorTarget(2, velocity, .Clear, .Store, .Black);
				builder.SetColorTarget(3, material, .Clear, .Store, .Black);
				// Loaded after the prepass, for the early rejection; a capture, having no
				// prepass, clears instead.
				builder.SetDepthTarget(depth, depthLoad, .Store);
				builder.SetViewport(view.ViewportX, view.ViewportY, view.ViewportWidth,
					view.ViewportHeight);

				if (cluster.Valid)
				{
					builder.ReadBuffer(cluster.OffsetsHandle);
					builder.ReadBuffer(cluster.IndicesHandle);
				}

				// The WHOLE cascade array, which orders every cascade pass ahead of this one
				// and barriers every layer readable. The shading binds the full array view, so
				// the descriptor spans every layer, and each must be readable when this pass's
				// bundle samples it, INCLUDING the layers belonging to other views.
				if (shadow.MapBound)
					builder.SampleDepth(shadow.Handle);
				// One atlas is shared by every view, so the whole texture is the dependency.
				if (shadow.AtlasValid)
					builder.SampleDepth(shadow.AtlasHandle);

				if (ibl.Valid)
				{
					builder.ReadTexture(ibl.PrefilterHandle);
					builder.ReadTexture(ibl.BrdfHandle);
					builder.ReadBuffer(ibl.ShHandle);
				}

				// The captured probe array, which orders the capture ahead of this pass and
				// barriers the WHOLE array readable, the uncaptured slices included.
				if (probeValid)
					builder.ReadTexture(probeHandle);

				builder.NeverCull();

				builder.SetBundleExecute(new (encoder, bundles) =>
					{
						ResolveAndEmit(view, registry, encoder, frameIndex, viewIndex, colorFormat,
							drawViewProj, prevViewProj, jitter, prevJitter, .Opaque, cluster,
							shadow, ibl, bundles, null, probeValid, probeBase, probeCount);
					});
			});
	}

	/// Declares one view's BLENDED pass: colour only, over the already lit image, depth tested
	/// against the opaque depth but never writing it, and drawn back to front.
	public void DeclareTransparent(RenderView view, RendererRegistry registry, RenderGraph graph,
		uint32 frameIndex, uint32 viewIndex, RGHandle color, RGHandle depth,
		TextureFormat colorFormat, Float4x4 drawViewProj, Float4x4 prevViewProj, Float2 jitter,
		Float2 prevJitter, ClusterBinding cluster = .(), ShadowBinding shadow = .(),
		IblBinding ibl = .(), uint32 probeBase = 0, uint32 probeCount = 0)
	{
		if ((view.Width == 0) || (view.Height == 0))
			return;

		graph.AddRenderPass("transparent", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store, view.Settings.Clear);
				builder.SetReadOnlyDepthTarget(depth);
				builder.SetViewport(view.ViewportX, view.ViewportY, view.ViewportWidth,
					view.ViewportHeight);

				if (cluster.Valid)
				{
					builder.ReadBuffer(cluster.OffsetsHandle);
					builder.ReadBuffer(cluster.IndicesHandle);
				}
				if (shadow.MapBound)
					builder.SampleDepth(shadow.Handle);
				if (shadow.AtlasValid)
					builder.SampleDepth(shadow.AtlasHandle);
				if (ibl.Valid)
				{
					builder.ReadTexture(ibl.PrefilterHandle);
					builder.ReadTexture(ibl.BrdfHandle);
					builder.ReadBuffer(ibl.ShHandle);
				}

				builder.NeverCull();

				builder.SetBundleExecute(new (encoder, bundles) =>
					{
						// The opaque depth is readable now, being a read only target, so its
						// view is resolved and handed to the renderers for a soft particle to
						// sample. Nothing changes in the graph: it is already in that state.
						let sceneDepth = graph.GetTextureView(depth);
						ResolveAndEmit(view, registry, encoder, frameIndex, viewIndex, colorFormat,
							drawViewProj, prevViewProj, jitter, prevJitter, .Blended, cluster,
							shadow, ibl, bundles, sceneDepth, true, probeBase, probeCount);
					});
			});
	}

	/// World space interface, drawn AFTER the tone map into the final image and depth tested
	/// against the opaque depth: a panel keeps its authored colours, exactly as the screen
	/// tier's do, yet is still occluded by the scene in front of it. Unlit by design.
	public void DeclarePostTonemapUI(RenderView view, RendererRegistry registry, RenderGraph graph,
		uint32 frameIndex, uint32 viewIndex, RGHandle color, RGHandle depth,
		TextureFormat colorFormat, Float4x4 drawViewProj, Float4x4 prevViewProj)
	{
		if ((view.Width == 0) || (view.Height == 0))
			return;

		var any = false;
		for (let item in view.DrawList)
		{
			if (CategoryRegistry.Instance.Affinity(item.Data.Category) == .PostTonemap)
			{
				any = true;
				break;
			}
		}
		if (!any)
			return;

		graph.AddRenderPass("worldui", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store, view.Settings.Clear);
				builder.SetReadOnlyDepthTarget(depth);
				builder.SetViewport(view.ViewportX, view.ViewportY, view.ViewportWidth,
					view.ViewportHeight);
				builder.NeverCull();

				builder.SetBundleExecute(new (encoder, bundles) =>
					{
						ResolveAndEmit(view, registry, encoder, frameIndex, viewIndex, colorFormat,
							drawViewProj, prevViewProj, .(0, 0), .(0, 0), .PostTonemap, .(), .(),
							.(), bundles, null, false, 0, 0);
					});
			});
	}

	/// Resolves this view's draws for one pass and emits them into bundles.
	private void ResolveAndEmit(RenderView view, RendererRegistry registry,
		ICommandEncoder encoder, uint32 frameIndex, uint32 viewIndex, TextureFormat colorFormat,
		Float4x4 drawViewProj, Float4x4 prevViewProj, Float2 jitter, Float2 prevJitter,
		PassAffinity passAffinity, ClusterBinding cluster, ShadowBinding shadow, IblBinding ibl,
		List<IRenderBundle> outBundles, ITextureView sceneDepthView, bool probesEnabled,
		uint32 probeBase, uint32 probeCount)
	{
		var context = RenderRecordContext();
		context.View = view;
		// The opaque pass draws jittered, for the temporal resolve; the blended one draws
		// unjittered, being composited after it.
		context.ViewProj = drawViewProj;
		context.PrevViewProj = prevViewProj;
		context.Jitter = jitter;
		context.PrevJitter = prevJitter;
		context.ViewMatrix = view.Camera.View;
		context.CameraPos = view.Camera.Position;
		context.Ambient = (view.Scene != null) ? view.Scene.Ambient : Float3(0.03f, 0.03f, 0.03f);

		if (view.Scene != null)
		{
			context.IblDiffuseIntensity = view.Scene.Sky.IblDiffuseIntensity;
			context.IblSpecularIntensity = view.Scene.Sky.IblSpecularIntensity;
			context.Lights = view.Scene.Lights;
		}

		context.Cascades = shadow.Cascades;
		context.CascadeLayerBase = shadow.LayerBase;
		context.LocalShadowEntryBase = shadow.LocalShadowEntryBase;
		context.Cluster = cluster;
		context.FrameIndex = frameIndex;
		context.ViewIndex = viewIndex;
		context.ColorFormat = colorFormat;
		context.DepthFormat = mDepthFormat;

		// ONLY the opaque pass renders into the multisampled target, so it and the renderers
		// it dispatches build multisampled pipelines and bundles. The blended pass and the
		// world interface run on the resolved image, so they stay single sampled.
		let passSamples = ((passAffinity == .Opaque) && (view.Settings.Post.MsaaSamples > 1))
			? view.Settings.Post.MsaaSamples
			: (uint8)1;
		context.SampleCount = passSamples;

		context.SceneDepthView = sceneDepthView;
		context.ProbesEnabled = probesEnabled;
		context.ProbeBase = probeBase;
		context.ProbeCount = probeCount;
		context.Ibl = ibl;
		context.NeedsMotion = view.Settings.Post.NeedsMotion;
		context.ShadowFarFade = mShadowFarFade;
		// The WIND clock is the view's SCENE clock, which is scaled and pausable; the frame's
		// own stands in only for a snapshot no scene stamped.
		context.TimeSeconds = mTimeSeconds;
		context.PrevTimeSeconds = mPrevTimeSeconds;
		if ((view.Scene != null) && view.Scene.HasTime)
		{
			context.TimeSeconds = view.Scene.TimeSeconds;
			context.PrevTimeSeconds = view.Scene.PrevTimeSeconds;
		}
		context.DebugSemantic = (view.Settings.Debug != null)
			? (uint8)view.Settings.Debug.Semantic
			: 0;

		// RESOLVE, on one thread. The list is category sorted, so this pass's items are
		// contiguous; within them, runs of the SAME RENDERER are handed to their owner. The
		// dispatch is per item rather than per category, so blended meshes and sprites
		// interleave by depth and each run still batches within one renderer.
		mResolved.Clear();
		let items = view.DrawList;
		var i = 0;
		while (i < items.Length)
		{
			if (CategoryRegistry.Instance.Affinity(items[i].Data.Category) != passAffinity)
			{
				i++;
				continue;
			}

			let rendererId = items[i].Data.RendererId;
			var j = i + 1;
			while ((j < items.Length)
				&& (CategoryRegistry.Instance.Affinity(items[j].Data.Category) == passAffinity)
				&& (items[j].Data.RendererId == rendererId))
				j++;

			let renderer = registry.ById(rendererId);
			if (renderer != null)
				renderer.Resolve(context, .(items.Ptr + i, j - i), mResolved);

			i = j;
		}

		// EMIT. The bundle records its own viewport up front, this view's sub rectangle rather
		// than the whole target, since a secondary buffer cannot inherit it.
		var desc = RenderBundleDesc();
		desc.ColorFormats[0] = colorFormat;
		if (passAffinity != .Opaque)
		{
			desc.ColorFormatCount = 1;
		}
		else
		{
			desc.ColorFormats[1] = RenderFormats.GNormal;
			desc.ColorFormats[2] = RenderFormats.GVelocity;
			desc.ColorFormats[3] = RenderFormats.GMaterial;
			desc.ColorFormatCount = 4;
		}
		desc.DepthStencilFormat = mDepthFormat;
		// A bundle's read only flags MUST match the pass that executes it, one backend
		// validating exactly that. Only the opaque pass writes depth; the others run over the
		// prepass depth read only. The engine's depth format carries no stencil, so the graph
		// never marks stencil read only and the bundle must not either.
		desc.DepthReadOnly = (passAffinity != .Opaque);
		desc.StencilReadOnly = false;
		desc.SampleCount = passSamples;
		desc.ViewportX = view.ViewportX;
		desc.ViewportY = view.ViewportY;
		desc.Width = view.ViewportWidth;
		desc.Height = view.ViewportHeight;
		desc.Label = "forward.bundle";

		mBundles.Clear();
		let total = mResolved.Count;
		if (HasGlobalJobSystem() && (total >= cParallelEmitThreshold))
		{
			EmitParallel(desc, frameIndex);
		}
		else
		{
			let bundleEncoder = encoder.CreateRenderBundleEncoder(desc);
			if (bundleEncoder != null)
			{
				for (let draw in mResolved)
					DrawEmitter.EmitDraw(bundleEncoder, draw);
				mBundles.Add(bundleEncoder.Finish());
			}
		}

		for (let bundle in mBundles)
		{
			if (bundle != null)
				outBundles.Add(bundle);
		}
	}

	/// Splits the resolved draws into contiguous chunks and records each into its own bundle on
	/// a worker, from that CHUNK's own pool: the pools are indexed by chunk rather than by
	/// worker, so no two threads ever touch one. The bundles stay in draw order.
	private void EmitParallel(RenderBundleDesc desc, uint32 frameIndex)
	{
		let jobs = GlobalJobs();
		let slots = jobs.SlotCount;
		if (!EnsureWorkerPools(slots) || (mWorkerSlots == 0))
			return;

		let total = (int32)mResolved.Count;
		let grain = (total + slots - 1) / slots;
		let chunks = (grain > 0) ? ((total + grain - 1) / grain) : 1;

		mBundles.Clear();
		for (int c < chunks)
			mBundles.Add(null);

		let poolBase = (int)frameIndex * (int)mWorkerSlots;

		jobs.ParallelFor(chunks, scope (c) =>
			{
				// One pool per chunk, so the recording never shares one.
				let pool = mWorkerPools[poolBase + (int)c];
				if (pool == null)
					return;

				// The bundle is minted straight from the pool, so the pool never holds an open
				// primary list and its per frame reset stays legal on every backend.
				let bundleEncoder = pool.CreateRenderBundleEncoder(desc);
				if (bundleEncoder == null)
					return;

				let first = c * grain;
				let last = Min((c + 1) * grain, total);
				for (int32 k = first; k < last; k++)
					DrawEmitter.EmitDraw(bundleEncoder, mResolved[k]);

				mBundles[c] = bundleEncoder.Finish();
			});
	}

	/// Provisions the pool grid, one per frame slot and worker. It only grows.
	private bool EnsureWorkerPools(int32 slotCount)
	{
		if (slotCount <= mWorkerSlots)
			return mWorkerSlots > 0;

		ReleaseWorkerPools();

		let count = (int)mFramesInFlight * (int)slotCount;
		for (int i < count)
		{
			if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			{
				ReleaseWorkerPools();
				return false;
			}
			mWorkerPools.Add(pool);
		}

		mWorkerSlots = slotCount;
		return true;
	}

	private void ReleaseWorkerPools()
	{
		for (var pool in ref mWorkerPools)
		{
			if (pool != null)
				mDevice.DestroyCommandPool(ref pool);
		}
		mWorkerPools.Clear();
		mWorkerSlots = 0;
	}
}
