using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Fast approximate antialiasing: one pass over the tone mapped image that finds the edges by
/// their luminance and blends along them.
///
/// The cheap alternative to the temporal resolve, and the one a view falls back to when it
/// cannot keep a history: no reprojection, no ghosting, and no accumulated detail either.
class FxaaPass
{
	private const int cMaxViews = 8;
	private const int cMaxFramesInFlight = 8;
	private const int cMaxSlots = cMaxViews * cMaxFramesInFlight;
	/// One frame can hold views with different target formats, so the pipelines are cached
	/// per format rather than destroyed on a mismatch.
	private const int cMaxPipelineFormats = 4;
	/// The texel size, the coordinate transform, the quality and the two thresholds.
	private const int cPushFloats = 10;

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight = 2;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private PipelineEntry[cMaxPipelineFormats] mPipelines = .();
	private ISampler mSampler = null;

	private IBindGroup[cMaxSlots] mBindGroups = .();
	private ITextureView[cMaxSlots] mBindGroupViews = .();
	private uint64[cMaxSlots] mBindGroupGeneration = .();

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = Max(framesInFlight, (uint32)1);
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		var entries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(float) * cPushFloats;

		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		pipelineLayoutDesc.PushConstantRanges = .(&pushRange, 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "fxaa.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		return .Ok;
	}

	/// Declares the pass: read the tone mapped image and write the final one, into this
	/// view's sub rectangle.
	public void DeclareFxaa(RenderGraph graph, RGHandle source, RGHandle ldr, bool clearColor,
		ClearColor clear, TextureFormat ldrFormat, int32 viewportX, int32 viewportY,
		uint32 viewportWidth, uint32 viewportHeight, uint32 frameIndex, uint32 viewIndex,
		Float2 texelSize, Float2 uvScale, Float2 uvOffset, float subpixelQuality = 0.75f)
	{
		let pipeline = EnsurePipeline(ldrFormat);
		if (pipeline == null)
			return;

		let slot = (int)(viewIndex % cMaxViews) * (int)mFramesInFlight
			+ (int)(frameIndex % mFramesInFlight);

		// The last two are the edge thresholds: the relative one, and the absolute floor
		// below which a difference is noise rather than an edge.
		float[cPushFloats] push = .(texelSize.X, texelSize.Y, uvScale.X, uvScale.Y, uvOffset.X,
			uvOffset.Y, subpixelQuality, 0.166f, 0.0312f, 0.0f);

		let load = clearColor ? LoadOp.Clear : LoadOp.Load;

		graph.AddRenderPass("fxaa", scope (builder) =>
			{
				builder.SetColorTarget(0, ldr, load, .Store, clear);
				builder.ReadTexture(source);
				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(slot, graph.GetTextureView(source),
							graph.GetTextureGeneration(source));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(float) * cPushFloats,
							&constants[0]);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	private IRenderPipeline EnsurePipeline(TextureFormat format)
	{
		let shaderVersion = mShaders.Version("fxaa");

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

		let vertex = mShaders.GetVariant("fxaa", .Vertex, .None);
		let fragment = mShaders.GetVariant("fxaa", .Fragment, .None);
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
		desc.Label = "fxaa";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipelines[index].Pipeline = pipeline;
		mPipelines[index].Format = format;
		mPipelines[index].ShaderVersion = shaderVersion;
		return pipeline;
	}

	private IBindGroup EnsureBindGroup(int slot, ITextureView sourceView, uint64 generation)
	{
		if ((slot < 0) || (slot >= cMaxSlots) || (sourceView == null))
			return null;

		if ((mBindGroups[slot] != null) && (mBindGroupViews[slot] == sourceView)
			&& (mBindGroupGeneration[slot] == generation))
			return mBindGroups[slot];

		if (mBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[slot]);

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(sourceView),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[slot] = bindGroup;
		mBindGroupViews[slot] = sourceView;
		mBindGroupGeneration[slot] = generation;
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int slot < cMaxSlots)
		{
			if (mBindGroups[slot] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[slot]);
		}

		for (int i < cMaxPipelineFormats)
		{
			if (mPipelines[i].Pipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipelines[i].Pipeline);
		}

		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
