using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// The editor's debug view: ANY named graph texture, shown in the viewport.
///
/// A fullscreen pass declared after the compose chain and before the overlays, so it
/// overwrites the view's sub rectangle with the chosen resource run through a channel select,
/// a range remap and, for a depth source, a linearisation. The gizmos and overlays still draw
/// over the top.
///
/// Reading the source is a REAL graph edge, so the transient aliasing keeps that resource
/// alive as far as this pass with nothing special asked of it. The source binds as
/// unfilterable and the shader reads it by load rather than by sampling, so every format
/// works; a depth resource binds through its depth only view.
class DebugBlitPass
{
	private const int cMaxViews = 8;
	private const int cMaxFramesInFlight = 8;
	private const int cMaxSlots = cMaxViews * cMaxFramesInFlight;
	private const int cMaxPipelineFormats = 4;

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private PipelineEntry[cMaxPipelineFormats] mPipelines = .();
	private IBindGroup[cMaxSlots] mBindGroups = .();
	private ITextureView[cMaxSlots] mBindGroupViews = .();
	private uint64[cMaxSlots] mBindGroupGenerations = .();

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		// Read by load, with no sampler: unfilterable accepts every colour format, and a
		// depth source binds through its depth only view.
		var textureEntry = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		textureEntry.TextureSampleType = .UnfilterableFloat;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&textureEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(DebugBlitPush);

		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		pipelineLayoutDesc.PushConstantRanges = .(&pushRange, 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		return .Ok;
	}

	/// Reads any single sampled graph texture and overwrites the view's sub rectangle of the
	/// final image with its visualisation. A depth source selects the depth only view and the
	/// linearisation the configuration asks for.
	public void DeclareDebugBlit(RenderGraph graph, RGHandle source, RGHandle ldr,
		TextureFormat ldrFormat, int32 viewportX, int32 viewportY, uint32 viewportWidth,
		uint32 viewportHeight, uint32 frameIndex, uint32 viewIndex, float sourceWidth,
		float sourceHeight, bool sourceIsDepth, ViewDebugView config)
	{
		let pipeline = EnsurePipeline(ldrFormat);
		if (pipeline == null)
			return;

		let slot = (int)(viewIndex % cMaxViews) * mFramesInFlight + (frameIndex % mFramesInFlight);

		var push = DebugBlitPush();
		push.UvScaleX = 1.0f;
		push.UvScaleY = 1.0f;
		push.UvOffsetX = 0.0f;
		push.UvOffsetY = 0.0f;
		push.SourceWidth = sourceWidth;
		push.SourceHeight = sourceHeight;
		push.RangeMin = config.RangeMin;
		push.RangeMax = config.RangeMax;
		push.NearZ = config.NearZ;
		push.FarZ = config.FarZ;
		push.Mode = (uint32)(config.Channel & 7);
		if (sourceIsDepth && config.LinearizeDepth)
			push.Mode |= 16;

		graph.AddRenderPass("debug.blit", scope (builder) =>
			{
				builder.SetColorTarget(0, ldr, .Load, .Store);
				builder.ReadTexture(source);
				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						var view = sourceIsDepth
							? graph.GetDepthOnlyTextureView(source)
							: graph.GetTextureView(source);
						if (view == null)
							view = graph.GetTextureView(source);

						let bindGroup = EnsureBindGroup(slot, view,
							graph.GetTextureGeneration(source));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(DebugBlitPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	private IRenderPipeline EnsurePipeline(TextureFormat format)
	{
		let shaderVersion = mShaders.Version("debug_blit");

		var index = -1;
		for (int i < cMaxPipelineFormats)
		{
			if ((mPipelines[i].Pipeline != null) && (mPipelines[i].Format == format))
			{
				index = i;
				break;
			}
		}

		if ((index >= 0) && (mPipelines[index].ShaderVersion == shaderVersion))
			return mPipelines[index].Pipeline;

		let vertex = mShaders.GetVariant("debug_blit", .Vertex, .None);
		let fragment = mShaders.GetVariant("debug_blit", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		if (index < 0)
		{
			for (int i < cMaxPipelineFormats)
			{
				if (mPipelines[i].Pipeline == null)
				{
					index = i;
					break;
				}
			}
		}

		// More formats than the cache holds: the first is the one to evict.
		if (index < 0)
			index = 0;

		if (mPipelines[index].Pipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipelines[index].Pipeline);

		var color = ColorTargetState();
		color.Format = format;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "debug.blit";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipelines[index].Pipeline = pipeline;
		mPipelines[index].Format = format;
		mPipelines[index].ShaderVersion = shaderVersion;
		return pipeline;
	}

	private IBindGroup EnsureBindGroup(int slot, ITextureView source, uint64 generation)
	{
		if ((slot < 0) || (slot >= cMaxSlots) || (source == null))
			return null;

		if ((mBindGroups[slot] != null) && (mBindGroupViews[slot] == source)
			&& (mBindGroupGenerations[slot] == generation))
			return mBindGroups[slot];

		if (mBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[slot]);

		var entries = BindGroupEntry[1](BindGroupEntry.TextureEntry(source));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 1);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[slot] = bindGroup;
		mBindGroupViews[slot] = source;
		mBindGroupGenerations[slot] = generation;
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int i < cMaxSlots)
		{
			if (mBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[i]);
		}

		for (int i < cMaxPipelineFormats)
		{
			if (mPipelines[i].Pipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipelines[i].Pipeline);
		}

		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
