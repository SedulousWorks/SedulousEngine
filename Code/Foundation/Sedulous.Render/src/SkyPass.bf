using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Draws the sky behind everything else.
///
/// A fullscreen triangle that reconstructs the world ray through each pixel and samples the
/// environment cube along it, DEPTH TESTED but not writing: it fills only where nothing was
/// drawn, which is what makes it a backdrop rather than an overdraw of the whole screen.
class SkyPass
{
	private const int cMaxFramesInFlight = 4;
	/// Room for the main views and for the probe capture faces beside them.
	private const int cMaxViews = 16;
	private const int cMaxSlots = cMaxViews * cMaxFramesInFlight;
	/// How long a replaced pipeline is kept before it is freed.
	private const uint32 cRetireFrames = 3;

	/// One slot's uniform buffer and the group over it.
	private struct Slot
	{
		public IBuffer Ubo;
		public IBindGroup BindGroup;
		public ITextureView Env;
		public uint64 EnvUid;
	}

	private struct RetiredPipeline
	{
		public IRenderPipeline Pipeline;
		public uint32 FramesLeft;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight = 2;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private TextureFormat mColorFormat = .Undefined;
	private TextureFormat mDepthFormat = .Undefined;
	/// The sample count the cached pipeline was built for.
	private uint32 mPipelineSampleCount = 1;
	private uint64 mPipelineShaderVersion = 0;

	/// A rebuild may replace a pipeline that in flight commands still refer to, so the old
	/// one waits here rather than the render path draining the device, which is hostile on
	/// the web.
	private List<RetiredPipeline> mRetiredPipelines = new .() ~ delete _;
	private uint32 mLastRetireFrame = 0xFFFFFFFF;

	private ISampler mSampler = null;
	private Slot[cMaxSlots] mSlots = .();

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
		var entries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment, .TextureCube),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "sky.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		return .Ok;
	}

	/// Declares the sky: load the colour, test against the depth without writing it, and draw
	/// the fullscreen triangle.
	public void DeclareSky(RenderGraph graph, RGHandle color, RGHandle velocity, RGHandle depth,
		RGHandle env, ITextureView envView, TextureFormat colorFormat, TextureFormat depthFormat,
		Float4x4 invViewProj, Float4x4 prevViewProj, Float2 jitter, Float2 prevJitter,
		Float3 cameraPos, float backgroundIntensity, Float3 sunDir, float sunSize,
		Float3 sunColor, float sunIntensity, int32 viewportX, int32 viewportY,
		uint32 viewportWidth, uint32 viewportHeight, uint32 frameIndex, uint32 viewIndex,
		uint64 envUid, uint32 samples = 1, RGSubresourceRange colorSub = .())
	{
		DrainRetiredPipelines(frameIndex);

		let pipeline = EnsurePipeline(colorFormat, depthFormat, samples);
		if ((pipeline == null) || (envView == null))
			return;

		let slot = (int)(viewIndex % cMaxViews) * (int)mFramesInFlight
			+ (int)(frameIndex % mFramesInFlight);

		var uniform = SkyUniform();
		uniform.InvViewProj = invViewProj;
		uniform.PrevViewProj = prevViewProj;
		uniform.CamPosIntensity = .(cameraPos.X, cameraPos.Y, cameraPos.Z, backgroundIntensity);
		uniform.SunDir = .(sunDir.X, sunDir.Y, sunDir.Z, sunSize);
		uniform.SunColor = .(sunColor.X, sunColor.Y, sunColor.Z, sunIntensity);
		uniform.Jitter = .(jitter.X, jitter.Y, prevJitter.X, prevJitter.Y);
		uniform.SkyFlags = .(mDevice.NeedsClipSpaceYFlip ? -1.0f : 1.0f, 0.0f, 0.0f, 0.0f);

		let uid = envUid;
		graph.AddRenderPass("sky", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store, .Black, colorSub);
				// The camera's own motion, which the temporal resolve needs even where
				// nothing was drawn.
				builder.SetColorTarget(1, velocity, .Load, .Store);
				builder.SetReadOnlyDepthTarget(depth);
				// Orders the environment precompute ahead of this, and barriers it readable.
				builder.ReadTexture(env);

				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(slot, envView, uid, uniform);
						if (bindGroup == null)
							return;

						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	/// Frees the pipelines that have waited out their frames. Once per frame.
	private void DrainRetiredPipelines(uint32 frameIndex)
	{
		if (frameIndex == mLastRetireFrame)
			return;

		mLastRetireFrame = frameIndex;
		for (int i = mRetiredPipelines.Count - 1; i >= 0; i--)
		{
			var retired = mRetiredPipelines[i];
			if (retired.FramesLeft <= 1)
			{
				mDevice.DestroyRenderPipeline(ref retired.Pipeline);
				mRetiredPipelines.RemoveAt(i);
				continue;
			}

			retired.FramesLeft--;
			mRetiredPipelines[i] = retired;
		}
	}

	private IRenderPipeline EnsurePipeline(TextureFormat colorFormat, TextureFormat depthFormat,
		uint32 samples)
	{
		let sampleCount = Max(samples, (uint32)1);
		let shaderVersion = mShaders.Version("sky");

		if ((mPipeline != null) && (mColorFormat == colorFormat) && (mDepthFormat == depthFormat)
			&& (mPipelineSampleCount == sampleCount) && (mPipelineShaderVersion == shaderVersion))
			return mPipeline;

		let vertex = mShaders.GetVariant("sky", .Vertex, .None);
		let fragment = mShaders.GetVariant("sky", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		if (mPipeline != null)
		{
			mRetiredPipelines.Add(.() { Pipeline = mPipeline, FramesLeft = cRetireFrames });
			mPipeline = null;
		}

		var targets = ColorTargetState[2](.(), .());
		targets[0].Format = colorFormat;
		targets[1].Format = RenderFormats.GVelocity;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&targets[0], 2);

		// Tested but NOT written, and passing at the far plane: the sky fills only what
		// nothing else covered.
		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = false;
		depthStencil.DepthCompare = .LessEqual;

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		// The sky draws into the scene's own attachments, so it matches their sample count.
		desc.Multisample.Count = sampleCount;
		desc.Label = "sky";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipeline = pipeline;
		mColorFormat = colorFormat;
		mDepthFormat = depthFormat;
		mPipelineSampleCount = sampleCount;
		mPipelineShaderVersion = shaderVersion;
		return mPipeline;
	}

	/// The environment's identity is the view AND the context's own id: the id catches an
	/// address that came back around after a context was evicted.
	private IBindGroup EnsureBindGroup(int slot, ITextureView envView, uint64 envUid,
		SkyUniform uniform)
	{
		if ((slot < 0) || (slot >= cMaxSlots))
			return null;

		if (mSlots[slot].Ubo == null)
		{
			var desc = BufferDesc();
			desc.Size = sizeof(SkyUniform);
			desc.Usage = .Uniform;
			desc.Memory = .CpuToGpu;
			desc.Label = "sky.ubo";

			if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
				return null;
			mSlots[slot].Ubo = buffer;
		}

		let mapped = mSlots[slot].Ubo.Map();
		if (mapped != null)
		{
			var value = uniform;
			Internal.MemCpy(mapped, &value, sizeof(SkyUniform));
			mSlots[slot].Ubo.Unmap();
		}

		if ((mSlots[slot].BindGroup == null) || (mSlots[slot].Env != envView)
			|| (mSlots[slot].EnvUid != envUid))
		{
			if (mSlots[slot].BindGroup != null)
				mDevice.DestroyBindGroup(ref mSlots[slot].BindGroup);

			var entries = BindGroupEntry[3](
				BindGroupEntry.BufferEntry(mSlots[slot].Ubo, 0, sizeof(SkyUniform)),
				BindGroupEntry.TextureEntry(envView),
				BindGroupEntry.SamplerEntry(mSampler));

			var desc = BindGroupDesc();
			desc.Layout = mLayout;
			desc.Entries = .(&entries[0], 3);

			if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
				return null;

			mSlots[slot].BindGroup = bindGroup;
			mSlots[slot].Env = envView;
			mSlots[slot].EnvUid = envUid;
		}

		return mSlots[slot].BindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int slot < cMaxSlots)
		{
			if (mSlots[slot].BindGroup != null)
				mDevice.DestroyBindGroup(ref mSlots[slot].BindGroup);
			if (mSlots[slot].Ubo != null)
				mDevice.DestroyBuffer(ref mSlots[slot].Ubo);
		}

		for (var retired in ref mRetiredPipelines)
		{
			if (retired.Pipeline != null)
				mDevice.DestroyRenderPipeline(ref retired.Pipeline);
		}
		mRetiredPipelines.Clear();

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
