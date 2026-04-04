namespace Sedulous.Engine.Render;

using System;
using System.IO;
using Sedulous.RHI;
using Sedulous.Shaders;

/// Creates and manages resources for blitting a source texture to a render target.
/// Used by RenderSubsystem to copy the pipeline output to the swapchain.
class BlitHelper : IDisposable
{
	private const int MAX_FRAMES = 2;
	private IDevice mDevice;
	private Sedulous.RHI.IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;
	private ISampler mSampler;
	private IBindGroup[MAX_FRAMES] mBindGroups;

	public bool IsReady => mPipeline != null;

	/// Initializes the blit helper using the shader system for compilation + caching.
	public Result<void> Initialize(IDevice device, TextureFormat outputFormat, ShaderSystem shaderSystem)
	{
		mDevice = device;

		// Get blit shader pair (shader system handles source lookup + caching)
		let shaderResult = shaderSystem.GetShaderPair("blit");
		if (shaderResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to get blit shader pair");
			return .Err;
		}

		let (vertModule, fragModule) = shaderResult.Value;

		// Bind group layout: t0 = source texture, s0 = sampler
		BindGroupLayoutEntry[2] entries = .(
			.SampledTexture(0, .Fragment),
			.Sampler(0, .Fragment)
		);

		BindGroupLayoutDesc layoutDesc = .()
		{
			Label = "Blit BindGroup Layout",
			Entries = entries
		};

		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let bgLayout))
			mBindGroupLayout = bgLayout;
		else
			return .Err;

		// Pipeline layout
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PipelineLayoutDesc plDesc = .(layouts);

		if (device.CreatePipelineLayout(plDesc) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Sampler
		SamplerDesc samplerDesc = .()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};

		if (device.CreateSampler(samplerDesc) case .Ok(let sampler))
			mSampler = sampler;
		else
			return .Err;

		// Render pipeline
		ColorTargetState[1] colorTargets = .(.() { Format = outputFormat });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Blit Pipeline",
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(vertModule.Module, "main"),
				Buffers = default
			},
			Fragment = .()
			{
				Shader = .(fragModule.Module, "main"),
				Targets = colorTargets
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				CullMode = .None
			},
			DepthStencil = null,
			Multisample = .()
			{
				Count = 1,
				Mask = uint32.MaxValue
			}
		};

		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let renderPipeline))
			mPipeline = renderPipeline;
		else
			return .Err;

		return .Ok;
	}

	/// Blits a source texture view to the current render pass.
	/// The caller must have already begun a render pass targeting the destination.
	public void Blit(IRenderPassEncoder encoder, ITextureView sourceView, uint32 width, uint32 height, int32 frameIndex)
	{
		if (mPipeline == null || sourceView == null)
			return;

		let slot = frameIndex % MAX_FRAMES;

		// Destroy previous bind group for this frame slot (GPU is done with it by now)
		if (mBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[slot]);

		BindGroupEntry[2] bgEntries = .(
			BindGroupEntry.Texture(sourceView),
			BindGroupEntry.Sampler(mSampler)
		);

		BindGroupDesc bgDesc = .()
		{
			Label = "Blit BindGroup",
			Layout = mBindGroupLayout,
			Entries = bgEntries
		};

		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bindGroup))
		{
			mBindGroups[slot] = bindGroup;

			encoder.SetViewport(0, 0, (float)width, (float)height, 0, 1);
			encoder.SetScissor(0, 0, width, height);
			encoder.SetPipeline(mPipeline);
			encoder.SetBindGroup(0, bindGroup, default);
			encoder.Draw(3, 1, 0, 0);
		}
	}

	public void Dispose()
	{
		if (mDevice == null)
			return;

		for (int i = 0; i < MAX_FRAMES; i++)
		{
			if (mBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[i]);
		}

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
	}
}
