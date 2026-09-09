using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Reflection probes: local, parallax corrected, cluster assigned cubemap reflections.
///
/// Three resources. The captured array holds each probe's raw six face render of the scene.
/// The prefiltered array holds its convolved specular, one level per roughness, which is what
/// the forward samples. The metadata buffer carries each probe's centre, box, blend and slice,
/// which is what the clustering assigns by.
///
/// A probe keeps its slice from frame to frame, keyed on a stable per entity tag, so only a
/// probe that is new or has moved captures again. That static caching is the whole point: a
/// six face render per probe per frame would cost more than the reflections are worth.
class ReflectionProbeSystem
{
	/// ONE resolution for every slice: an array cannot vary its size per slice.
	public const uint32 cCaptureResolution = 128;
	public const uint32 cPrefilterResolution = 128;
	/// The roughness of a level is its index over the last.
	public const uint32 cPrefilterMips = 5;
	public const uint32 cMaxProbes = RenderLimits.MaxReflectionProbes;
	public const TextureFormat cCubeFormat = .RGBA16Float;

	/// The face cameras' planes, which have to cover the box's inside out to distant geometry
	/// and the sky.
	public const float cCaptureNear = 0.1f;
	public const float cCaptureFar = 1000.0f;

	private const uint32 cInvalidSlot = 0xFFFFFFFF;

	private struct SlotState
	{
		public uint64 ProbeKey;
		public uint64 Signature;
		/// A full cube has been captured and prefiltered at least once.
		public bool Captured;
		/// It needs capturing again this frame.
		public bool Dirty;
	}

	/// One scene's run of records, appended in the order the scenes are assigned.
	private struct SceneRange
	{
		public ExtractedScene Scene;
		public uint32 Base;
		public uint32 Count;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;

	// The captured into prefiltered blit, which corrects the horizontal mirror the face
	// cameras leave. Per face two dimensional views, so the filtering stays within a face and
	// a smooth gradient like the sky shows no seam across one.
	private IBindGroupLayout mBlitLayout = null;
	private IPipelineLayout mBlitPipelineLayout = null;
	private IRenderPipeline mBlitPipeline = null;
	private ITextureView[cMaxProbes * 6] mCapturedFaceViews;
	private IBindGroup[cMaxProbes * 6] mBlitFaceBindGroups;

	// The roughness convolution, from the corrected first level into the rest.
	private IBindGroupLayout mPrefilterLayout = null;
	private IPipelineLayout mPrefilterPipelineLayout = null;
	private IRenderPipeline mPrefilterPipeline = null;
	private uint64 mPipelineShaderVersion = 0;
	private ITextureView[cMaxProbes] mPrefilterSourceViews;
	private IBindGroup[cMaxProbes] mPrefilterSourceBindGroups;

	private ITexture mCapturedCube = null;
	private ITextureView mCapturedArrayView = null;
	/// Persists ACROSS frames, since the resource is imported rather than transient.
	private ResourceState mCapturedState = .Undefined;
	private bool mLayoutsInitialised = false;

	private ITexture mPrefilterCube = null;
	private ITextureView mPrefilterArrayView = null;
	private ResourceState mPrefilterState = .Undefined;

	private IBuffer mProbeBuffer = null;
	private ISampler mSampler = null;

	private List<ProbeCaptureTask> mCaptures = new .() ~ delete _;
	private List<SceneRange> mSceneRanges = new .() ~ delete _;

	private Dictionary<uint64, uint32> mSlots = new .() ~ delete _;
	private uint32 mNextSlot = 0;
	private SlotState[cMaxProbes] mSlotStates = .();
	private GpuProbe[cMaxProbes] mCpuProbes = .();
	private uint32 mActive = 0;

	/// The startup recapture window, for the same reason the environment bake has one: a
	/// dropped submission during startup would otherwise lose a one shot capture silently.
	private uint32 mCaptureWarmup = 20;

	public this(IDevice device, ShaderSystem shaders)
	{
		mDevice = device;
		mShaders = shaders;
	}

	public ~this()
	{
		DestroyResources();
	}

	public Result<void> Initialize()
	{
		if (!CreateResources())
			return .Err;
		if (!CreateBlitPipeline() || !CreatePrefilterPipeline())
			return .Err;
		mPipelineShaderVersion = ShaderVersion();
		return .Ok;
	}

	/// Opens the frame, clearing the record accumulation. The slots and what has been captured
	/// persist; only this frame's ranges and capture list are per frame.
	public void BeginFrame()
	{
		let shaderVersion = ShaderVersion();
		if (shaderVersion != mPipelineShaderVersion)
		{
			// The layouts and the cached groups survive a reload; only the pipelines rebuild.
			if (mBlitPipeline != null)
				mDevice.DestroyRenderPipeline(ref mBlitPipeline);
			if (mPrefilterPipeline != null)
				mDevice.DestroyRenderPipeline(ref mPrefilterPipeline);

			CreateBlitPipeline();
			CreatePrefilterPipeline();
			mPipelineShaderVersion = shaderVersion;
		}

		mActive = 0;
		mCaptures.Clear();
		mSceneRanges.Clear();

		if (mCaptureWarmup > 0)
			mCaptureWarmup--;
	}

	/// Maps ONE SCENE's probes onto their persistent slots and appends their records to this
	/// frame's buffer. Called once per extracted scene per frame; a scene assigned twice, which
	/// is what several views of one scene amount to, is a no op the second time.
	///
	/// A probe is marked for capture when it takes a new slot or its transform has changed.
	/// Probes beyond the limit are dropped.
	public uint32 Assign(ExtractedScene scene, Span<ReflectionProbe> probes)
	{
		for (let existing in mSceneRanges)
		{
			// This frame's records for a scene are the same whichever view asks.
			if (existing.Scene == scene)
				return mActive;
		}

		var range = SceneRange();
		range.Scene = scene;
		range.Base = mActive;

		for (let probe in probes)
		{
			if (mActive >= cMaxProbes)
				break;

			let slot = SlotFor(probe.Key);
			if (slot == cInvalidSlot)
				continue;

			let boxMin = probe.Center - probe.HalfExtents;
			let boxMax = probe.Center + probe.HalfExtents;

			var record = GpuProbe();
			record.Center = .(probe.Center.X, probe.Center.Y, probe.Center.Z, probe.Intensity);
			record.BoxMin = .(boxMin.X, boxMin.Y, boxMin.Z, probe.BlendDistance);
			record.BoxMax = .(boxMax.X, boxMax.Y, boxMax.Z, (float)slot);
			record.Params = .((float)cPrefilterMips, (float)probe.Priority,
				probe.Parallax ? 1.0f : 0.0f, 0.0f);
			mCpuProbes[mActive] = record;

			let signature = TransformSignature(probe);
			if (!mSlotStates[slot].Captured || (mSlotStates[slot].Signature != signature)
				|| (probe.Update == .Realtime) || (mCaptureWarmup > 0))
				mSlotStates[slot].Dirty = true;

			mSlotStates[slot].Signature = signature;
			mSlotStates[slot].ProbeKey = probe.Key;

			if (mSlotStates[slot].Dirty)
			{
				// Deduplicated BY SLOT: a scene assigned twice, or a reused key, must not
				// queue the same capture again.
				var queued = false;
				for (let task in mCaptures)
				{
					if (task.Slot == slot)
					{
						queued = true;
						break;
					}
				}

				// The capture renders THIS probe's own scene, never another's geometry.
				if (!queued)
					mCaptures.Add(.(slot, probe.Center, scene));
			}

			mActive++;
		}

		range.Count = mActive - range.Base;
		mSceneRanges.Add(range);
		return mActive;
	}

	/// This frame's record range for a scene.
	public ProbeRange RangeFor(ExtractedScene scene)
	{
		for (let range in mSceneRanges)
		{
			if (range.Scene == scene)
				return .(range.Base, range.Count);
		}
		return .();
	}

	public uint32 ActiveCount => mActive;
	public Span<GpuProbe> CpuProbes => .(&mCpuProbes[0], mActive);

	/// Copies this frame's records into the metadata buffer. Once per frame, after assigning.
	public void Upload()
	{
		if ((mProbeBuffer == null) || (mActive == 0))
			return;

		let mapped = mProbeBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &mCpuProbes[0], (int)mActive * sizeof(GpuProbe));
			mProbeBuffer.Unmap();
		}
	}

	public Span<ProbeCaptureTask> Captures => mCaptures;
	public static uint32 LayerBase(uint32 slot) => slot * 6;

	public void MarkCaptured(uint32 slot)
	{
		if (slot < cMaxProbes)
		{
			mSlotStates[slot].Captured = true;
			mSlotStates[slot].Dirty = false;
		}
	}

	/// Puts the WHOLE captured array into a readable state once, outside the graph, so the
	/// slices no probe has claimed are not left undefined when the forward binds the array. It
	/// only does anything the first time.
	public void InitLayouts(ICommandEncoder encoder)
	{
		if (mLayoutsInitialised)
			return;

		encoder.TransitionTexture(mCapturedCube, .Undefined, .ShaderRead);
		encoder.TransitionTexture(mPrefilterCube, .Undefined, .ShaderRead);
		mCapturedState = .ShaderRead;
		mPrefilterState = .ShaderRead;
		mLayoutsInitialised = true;
	}

	/// Imports the captured array whole; the capture passes target individual layers through
	/// their own subresource ranges. Its state persists across frames, as the shadow atlas's
	/// does.
	public RGHandle ImportCaptured(RenderGraph graph)
	{
		let handle = graph.ImportTarget("probes.captured", mCapturedCube, mCapturedArrayView,
			ResourceState.ShaderRead, mCapturedState);
		mCapturedState = .ShaderRead;
		return handle;
	}

	/// Imports the prefiltered array, which is a SEPARATE texture from the captured one and
	/// never a capture target, so there is no read against write between the two.
	public RGHandle ImportPrefiltered(RenderGraph graph)
	{
		let handle = graph.ImportTarget("probes.prefilter", mPrefilterCube, mPrefilterArrayView,
			ResourceState.ShaderRead, mPrefilterState);
		mPrefilterState = .ShaderRead;
		return handle;
	}

	/// Bridges the captured faces into the prefiltered array's first level, correcting the
	/// horizontal mirror the face cameras leave. That level stays sharp, being roughness
	/// nought; the convolution below fills the rougher ones.
	public void DeclareBlit(RenderGraph graph, RGHandle captured, RGHandle prefiltered,
		uint32 slot)
	{
		// A shader broken mid reload: skip until it compiles again.
		if (mBlitPipeline == null)
			return;

		for (uint32 face = 0; face < 6; face++)
		{
			let faceBindGroup = EnsureFaceBlit(slot, face);
			if (faceBindGroup == null)
				continue;

			graph.AddRenderPass("probes.blit", scope [&] (builder) =>
				{
					builder.SetColorTarget(0, prefiltered, .Clear, .Store, .Black,
						.(0, 0, slot * 6 + face, 1));
					builder.ReadTexture(captured);
					builder.SetViewport(0, 0, cPrefilterResolution, cPrefilterResolution);
					builder.NeverCull();

					builder.SetExecute(new [=] (encoder) =>
						{
							encoder.SetPipeline(mBlitPipeline);
							encoder.SetBindGroup(0, faceBindGroup);
							encoder.Draw(3, 1, 0, 0);
						});
				});
		}
	}

	/// Convolves the prefiltered first level into the rougher ones. The graph orders it after
	/// the blit, which wrote that level, through the handle they share.
	public void DeclarePrefilter(RenderGraph graph, RGHandle prefiltered, uint32 slot)
	{
		if (mPrefilterPipeline == null)
			return;

		let sourceBindGroup = EnsurePrefilterSource(slot);
		if (sourceBindGroup == null)
			return;

		for (uint32 mip = 1; mip < cPrefilterMips; mip++)
		{
			let roughness = (float)mip / (float)(cPrefilterMips - 1);
			let resolution = cPrefilterResolution >> mip;

			for (uint32 face = 0; face < 6; face++)
			{
				graph.AddRenderPass("probes.prefilter", scope [&] (builder) =>
					{
						builder.ReadTexture(prefiltered, .(0, 1, slot * 6, 6));
						builder.SetColorTarget(0, prefiltered, .Clear, .Store, .Black,
							.(mip, 1, slot * 6 + face, 1));
						builder.SetViewport(0, 0, resolution, resolution);
						builder.NeverCull();

						builder.SetExecute(new [=] (encoder) =>
							{
								var push = ProbePrefilterPush();
								push.FaceIndex = (int32)face;
								push.Roughness = roughness;

								encoder.SetPipeline(mPrefilterPipeline);
								encoder.SetBindGroup(0, sourceBindGroup);
								encoder.SetPushConstants(.Fragment, 0, sizeof(ProbePrefilterPush),
									&push);
								encoder.Draw(3, 1, 0, 0);
							});
					});
			}
		}
	}

	/// The captured array as a sample view, which the forward binds directly for its sharp
	/// first level. The same view the import uses, so there is one allocation of it.
	public ITextureView CapturedSampleView => mCapturedArrayView;
	public ITextureView PrefilterArrayView => mPrefilterArrayView;
	public IBuffer ProbeBuffer => mProbeBuffer;
	public ISampler Sampler => mSampler;

	private uint64 ShaderVersion()
	{
		return mShaders.Version("probe_blit_vs") + mShaders.Version("probe_blit_ps")
			+ mShaders.Version("probe_prefilter_ps");
	}

	/// The stable slot for a key: the one it already has, or the next free one.
	private uint32 SlotFor(uint64 key)
	{
		if (mSlots.TryGetValue(key, let existing))
			return existing;

		if (mNextSlot >= cMaxProbes)
			return cInvalidSlot;

		let slot = mNextSlot++;
		mSlots[key] = slot;
		return slot;
	}

	/// A cheap signature over what a capture depends on. Exact equality is all that is wanted
	/// here: the question is only whether it changed since last frame.
	private static uint64 TransformSignature(ReflectionProbe probe)
	{
		var hash = FnvOffsetBasis;

		mixin Mix(float value)
		{
			var v = value;
			hash ^= (uint64)*(uint32*)&v;
			hash = hash &* FnvPrime;
		}

		Mix!(probe.Center.X);
		Mix!(probe.Center.Y);
		Mix!(probe.Center.Z);
		Mix!(probe.HalfExtents.X);
		Mix!(probe.HalfExtents.Y);
		Mix!(probe.HalfExtents.Z);
		hash ^= (uint64)probe.Resolution;
		return hash;
	}

	private bool CreateResources()
	{
		let layers = cMaxProbes * 6;

		// The captured array: the raw six face render per probe, which the blit samples.
		var capturedDesc = TextureDesc();
		capturedDesc.Format = cCubeFormat;
		capturedDesc.Width = cCaptureResolution;
		capturedDesc.Height = cCaptureResolution;
		capturedDesc.ArrayLayerCount = layers;
		capturedDesc.MipLevelCount = 1;
		capturedDesc.Usage = .RenderTarget | .Sampled | .CopySrc;
		capturedDesc.Label = "probes.captured";
		if (!(mDevice.CreateTexture(capturedDesc) case .Ok(let capturedCube)))
			return false;
		mCapturedCube = capturedCube;

		var capturedViewDesc = TextureViewDesc();
		capturedViewDesc.Format = cCubeFormat;
		capturedViewDesc.Dimension = .TextureCubeArray;
		capturedViewDesc.ArrayLayerCount = layers;
		capturedViewDesc.MipLevelCount = 1;
		if (!(mDevice.CreateTextureView(capturedCube, capturedViewDesc) case .Ok(let capturedView)))
			return false;
		mCapturedArrayView = capturedView;

		// The prefiltered array, one level per roughness, which the forward samples.
		var prefilterDesc = TextureDesc();
		prefilterDesc.Format = cCubeFormat;
		prefilterDesc.Width = cPrefilterResolution;
		prefilterDesc.Height = cPrefilterResolution;
		prefilterDesc.ArrayLayerCount = layers;
		prefilterDesc.MipLevelCount = cPrefilterMips;
		prefilterDesc.Usage = .RenderTarget | .Sampled | .CopyDst;
		prefilterDesc.Label = "probes.prefilter";
		if (!(mDevice.CreateTexture(prefilterDesc) case .Ok(let prefilterCube)))
			return false;
		mPrefilterCube = prefilterCube;

		var prefilterViewDesc = TextureViewDesc();
		prefilterViewDesc.Format = cCubeFormat;
		prefilterViewDesc.Dimension = .TextureCubeArray;
		prefilterViewDesc.ArrayLayerCount = layers;
		prefilterViewDesc.MipLevelCount = cPrefilterMips;
		if (!(mDevice.CreateTextureView(prefilterCube, prefilterViewDesc) case .Ok(let preView)))
			return false;
		mPrefilterArrayView = preView;

		// The metadata, host visible so the forward reads this frame's records directly. It is
		// small enough that streaming it through a staging buffer would cost more than it saves.
		var bufferDesc = BufferDesc();
		bufferDesc.Size = sizeof(GpuProbe) * cMaxProbes;
		bufferDesc.Usage = .StorageRead;
		bufferDesc.Memory = .CpuToGpu;
		bufferDesc.Label = "probes.meta";
		if (!(mDevice.CreateBuffer(bufferDesc) case .Ok(let probeBuffer)))
			return false;
		mProbeBuffer = probeBuffer;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "probes.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return false;
		mSampler = sampler;

		return true;
	}

	private bool CreateBlitPipeline()
	{
		let vertex = mShaders.GetVariant("probe_blit_vs", .Vertex, .None);
		let fragment = mShaders.GetVariant("probe_blit_ps", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		// The layouts survive a shader reload.
		if (mBlitLayout == null)
		{
			// An ARRAY view, not a plain two dimensional one: the source is ONE LAYER of the
			// captured array, and a plain two dimensional view cannot address a layer other
			// than the first on every backend. The per face view carries the slice, and the
			// shader samples the first of it.
			var entries = BindGroupLayoutEntry[2](
				BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture2DArray),
				BindGroupLayoutEntry.Sampler(0, .Fragment));

			var layoutDesc = BindGroupLayoutDesc();
			layoutDesc.Entries = .(&entries[0], 2);
			if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
				return false;
			mBlitLayout = layout;

			var layouts = IBindGroupLayout[1](mBlitLayout);
			var pipelineLayoutDesc = PipelineLayoutDesc();
			pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
			if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
				return false;
			mBlitPipelineLayout = pipelineLayout;
		}

		mBlitPipeline = MakeFullscreenPipeline(vertex, fragment, mBlitPipelineLayout,
			"probes.blit");
		return mBlitPipeline != null;
	}

	/// The single face view and its group, built the first time a slot's face is blitted.
	/// Sampling the one layer keeps the filtering inside the face, so there are no seams.
	private IBindGroup EnsureFaceBlit(uint32 slot, uint32 face)
	{
		let index = (int)(slot * 6 + face);
		if (mBlitFaceBindGroups[index] != null)
			return mBlitFaceBindGroups[index];

		var viewDesc = TextureViewDesc();
		viewDesc.Format = cCubeFormat;
		viewDesc.Dimension = .Texture2DArray;
		viewDesc.BaseArrayLayer = (uint32)index;
		viewDesc.ArrayLayerCount = 1;
		viewDesc.MipLevelCount = 1;
		if (!(mDevice.CreateTextureView(mCapturedCube, viewDesc) case .Ok(let view)))
			return null;
		mCapturedFaceViews[index] = view;

		mBlitFaceBindGroups[index] = MakeSourceBindGroup(mBlitLayout, view);
		return mBlitFaceBindGroups[index];
	}

	private bool CreatePrefilterPipeline()
	{
		let vertex = mShaders.GetVariant("probe_blit_vs", .Vertex, .None);
		let fragment = mShaders.GetVariant("probe_prefilter_ps", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return false;

		if (mPrefilterLayout == null)
		{
			// An ARRAY view for the same reason as the blit's: the source is ONE CUBE of the
			// array, and a plain cube view cannot address a first face other than nought.
			var entries = BindGroupLayoutEntry[2](
				BindGroupLayoutEntry.SampledTexture(0, .Fragment, .TextureCubeArray),
				BindGroupLayoutEntry.Sampler(0, .Fragment));

			var layoutDesc = BindGroupLayoutDesc();
			layoutDesc.Entries = .(&entries[0], 2);
			if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
				return false;
			mPrefilterLayout = layout;

			var layouts = IBindGroupLayout[1](mPrefilterLayout);
			var pushRange = PushConstantRange();
			pushRange.Stages = .Fragment;
			pushRange.Offset = 0;
			pushRange.Size = sizeof(ProbePrefilterPush);

			var pipelineLayoutDesc = PipelineLayoutDesc();
			pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
			pipelineLayoutDesc.PushConstantRanges = .(&pushRange, 1);
			if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
				return false;
			mPrefilterPipelineLayout = pipelineLayout;
		}

		mPrefilterPipeline = MakeFullscreenPipeline(vertex, fragment, mPrefilterPipelineLayout,
			"probes.prefilter");
		return mPrefilterPipeline != null;
	}

	/// The slot's own cube view of the first level, which is the convolution's source.
	private IBindGroup EnsurePrefilterSource(uint32 slot)
	{
		if (mPrefilterSourceBindGroups[slot] != null)
			return mPrefilterSourceBindGroups[slot];

		var viewDesc = TextureViewDesc();
		viewDesc.Format = cCubeFormat;
		viewDesc.Dimension = .TextureCubeArray;
		viewDesc.BaseMipLevel = 0;
		viewDesc.MipLevelCount = 1;
		viewDesc.BaseArrayLayer = slot * 6;
		viewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(mPrefilterCube, viewDesc) case .Ok(let view)))
			return null;
		mPrefilterSourceViews[slot] = view;

		mPrefilterSourceBindGroups[slot] = MakeSourceBindGroup(mPrefilterLayout, view);
		return mPrefilterSourceBindGroups[slot];
	}

	private IBindGroup MakeSourceBindGroup(IBindGroupLayout layout, ITextureView view)
	{
		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(view),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = layout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;
		return bindGroup;
	}

	private IRenderPipeline MakeFullscreenPipeline(IShaderModule vertex, IShaderModule fragment,
		IPipelineLayout layout, StringView label)
	{
		var color = ColorTargetState();
		color.Format = cCubeFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = label;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;
		return pipeline;
	}

	private void DestroyResources()
	{
		if (mDevice == null)
			return;

		for (int i < cMaxProbes * 6)
		{
			if (mBlitFaceBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mBlitFaceBindGroups[i]);
			if (mCapturedFaceViews[i] != null)
				mDevice.DestroyTextureView(ref mCapturedFaceViews[i]);
		}

		for (int i < cMaxProbes)
		{
			if (mPrefilterSourceBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mPrefilterSourceBindGroups[i]);
			if (mPrefilterSourceViews[i] != null)
				mDevice.DestroyTextureView(ref mPrefilterSourceViews[i]);
		}

		if (mPrefilterPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPrefilterPipeline);
		if (mPrefilterPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPrefilterPipelineLayout);
		if (mPrefilterLayout != null)
			mDevice.DestroyBindGroupLayout(ref mPrefilterLayout);

		if (mBlitPipeline != null)
			mDevice.DestroyRenderPipeline(ref mBlitPipeline);
		if (mBlitPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mBlitPipelineLayout);
		if (mBlitLayout != null)
			mDevice.DestroyBindGroupLayout(ref mBlitLayout);

		if (mPrefilterArrayView != null)
			mDevice.DestroyTextureView(ref mPrefilterArrayView);
		if (mPrefilterCube != null)
			mDevice.DestroyTexture(ref mPrefilterCube);
		if (mCapturedArrayView != null)
			mDevice.DestroyTextureView(ref mCapturedArrayView);
		if (mCapturedCube != null)
			mDevice.DestroyTexture(ref mCapturedCube);
		if (mProbeBuffer != null)
			mDevice.DestroyBuffer(ref mProbeBuffer);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
	}
}
