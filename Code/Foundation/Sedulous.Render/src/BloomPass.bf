using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// The bloom pyramid: what is bright enough to bloom is halved down a chain of targets and
/// then added back up it, which spreads a highlight over a wide radius for the cost of a few
/// small passes rather than one enormous blur.
///
/// The pyramid itself is graph transients; this owns only the pipelines and the sampler.
class BloomPass
{
	public const TextureFormat BloomFormat = .RGBA16Float;
	public const uint32 MaxLevels = 7;

	private struct Entry
	{
		public IBindGroup BindGroup;
		public uint64 Generation;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mDownPipeline = null;
	private IRenderPipeline mUpPipeline = null;
	private uint64 mPipelineShaderVersion = 0;
	private ISampler mSampler = null;

	/// Keyed by the source view's address, with the generation beside it: the transients are
	/// pooled and their generations are stable across frames, so this settles rather than
	/// rebuilding every frame; a resize bumps them and it rebuilds once.
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders)
	{
		mDevice = device;
		mShaders = shaders;
	}

	public ~this()
	{
		Shutdown();
	}

	public TextureFormat Format => BloomFormat;

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
		pushRange.Size = sizeof(BloomPush);

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
		samplerDesc.Label = "bloom.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		mDownPipeline = MakePipeline("bloom_ds", false);
		mUpPipeline = MakePipeline("bloom_us", true);
		if ((mDownPipeline == null) || (mUpPipeline == null))
			return .Err;

		return .Ok;
	}

	/// Declares the pyramid for one view's scene image, and answers the accumulated bloom at
	/// half resolution, which the tone map composites.
	///
	/// An invalid handle means the view is too small to be worth it.
	public RGHandle DeclareBloom(RenderGraph graph, RGHandle hdr, uint32 viewportWidth,
		uint32 viewportHeight, float threshold, float knee)
	{
		if ((viewportWidth < 4) || (viewportHeight < 4))
			return .Invalid;

		let shaderVersion = mShaders.Version("bloom_ds") + mShaders.Version("bloom_us");
		if (shaderVersion != mPipelineShaderVersion)
		{
			if (mDownPipeline != null)
				mDevice.DestroyRenderPipeline(ref mDownPipeline);
			if (mUpPipeline != null)
				mDevice.DestroyRenderPipeline(ref mUpPipeline);

			mDownPipeline = MakePipeline("bloom_ds", false);
			mUpPipeline = MakePipeline("bloom_us", true);
			mPipelineShaderVersion = shaderVersion;
		}

		if ((mDownPipeline == null) || (mUpPipeline == null))
			return .Invalid;

		// Halved until the levels get too small to say anything, and capped.
		var levels = (uint32)1;
		var width = viewportWidth / 2;
		var height = viewportHeight / 2;
		while ((levels < MaxLevels) && (width > 8) && (height > 8))
		{
			levels++;
			width /= 2;
			height /= 2;
		}

		RGHandle[MaxLevels] chain = .();
		uint32[MaxLevels] levelWidth = .();
		uint32[MaxLevels] levelHeight = .();

		width = viewportWidth;
		height = viewportHeight;
		for (uint32 i = 0; i < levels; i++)
		{
			width = Max((uint32)1, width / 2);
			height = Max((uint32)1, height / 2);
			levelWidth[i] = width;
			levelHeight[i] = height;
			chain[i] = graph.CreateTransient("bloom.mip", .(BloomFormat, width, height));
		}

		// Down the chain: the scene into the first level, thresholded, then each level into
		// the next.
		for (uint32 i = 0; i < levels; i++)
		{
			let source = (i == 0) ? hdr : chain[i - 1];
			let sourceWidth = (i == 0) ? viewportWidth : levelWidth[i - 1];
			let sourceHeight = (i == 0) ? viewportHeight : levelHeight[i - 1];

			var push = BloomPush();
			push.SrcTexel = .(1.0f / (float)sourceWidth, 1.0f / (float)sourceHeight);
			push.Threshold = threshold;
			push.Knee = knee;
			push.FirstPass = (i == 0) ? 1 : 0;

			let destination = chain[i];
			let destinationWidth = levelWidth[i];
			let destinationHeight = levelHeight[i];

			graph.AddRenderPass("bloom.down", scope [&] (builder) =>
				{
					builder.SetColorTarget(0, destination, .Clear, .Store, .Black);
					builder.ReadTexture(source);
					builder.SetViewport(0, 0, destinationWidth, destinationHeight);
					builder.NeverCull();

					builder.SetExecute(new [=] (encoder) =>
						{
							Draw(encoder, graph, source, mDownPipeline, push);
						});
				});
		}

		// And back up it, ADDING each level into the one above: that accumulation is what
		// makes the falloff wide and smooth rather than a stack of separate blurs.
		for (int32 i = (int32)levels - 2; i >= 0; i--)
		{
			let source = chain[i + 1];
			let destination = chain[i];

			var push = BloomPush();
			push.SrcTexel = .(1.0f / (float)levelWidth[i + 1], 1.0f / (float)levelHeight[i + 1]);

			let destinationWidth = levelWidth[i];
			let destinationHeight = levelHeight[i];

			graph.AddRenderPass("bloom.up", scope [&] (builder) =>
				{
					// Loaded rather than cleared, because the blend adds to what is there.
					builder.SetColorTarget(0, destination, .Load, .Store, .Black);
					builder.ReadTexture(source);
					builder.SetViewport(0, 0, destinationWidth, destinationHeight);
					builder.NeverCull();

					builder.SetExecute(new [=] (encoder) =>
						{
							Draw(encoder, graph, source, mUpPipeline, push);
						});
				});
		}

		return chain[0];
	}

	private void Draw(IRenderPassEncoder encoder, RenderGraph graph, RGHandle source,
		IRenderPipeline pipeline, BloomPush push)
	{
		let bindGroup = EnsureBindGroup(graph.GetTextureView(source),
			graph.GetTextureGeneration(source));
		if (bindGroup == null)
			return;

		encoder.SetPipeline(pipeline);
		encoder.SetBindGroup(0, bindGroup);

		var constants = push;
		encoder.SetPushConstants(.Fragment, 0, sizeof(BloomPush), &constants);
		encoder.Draw(3, 1, 0, 0);
	}

	private IRenderPipeline MakePipeline(StringView name, bool additive)
	{
		let vertex = mShaders.GetVariant(name, .Vertex, .None);
		let fragment = mShaders.GetVariant(name, .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var color = ColorTargetState();
		color.Format = BloomFormat;
		if (additive)
			color.Blend = BlendState.Additive;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = name;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		return pipeline;
	}

	private IBindGroup EnsureBindGroup(ITextureView view, uint64 generation)
	{
		if (view == null)
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(view);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mDevice.DestroyBindGroup(ref existing.BindGroup);
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(view),
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .() { BindGroup = bindGroup, Generation = generation };
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var entry in ref mBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mBindGroups.Clear();

		if (mDownPipeline != null)
			mDevice.DestroyRenderPipeline(ref mDownPipeline);
		if (mUpPipeline != null)
			mDevice.DestroyRenderPipeline(ref mUpPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
