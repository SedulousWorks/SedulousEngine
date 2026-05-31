namespace Sedulous.Renderer.IBL;

using System;
using Sedulous.RHI;

/// Manages IBL (Image-Based Lighting) GPU resources for the split-sum approximation.
/// Owns the BRDF integration LUT, environment cubemaps, and render pipelines for
/// equirect-to-cubemap conversion and irradiance convolution.
///
/// Uses fragment shader render passes (not compute) to write cubemap faces,
/// avoiding the HLSL storage-image format declaration issue that prevents
/// portable RWTexture2DArray usage across DX12 and Vulkan.
///
/// Created and owned by RenderContext.
public class IBLSystem
{
	private IDevice mDevice;
	private IQueue mQueue;

	// BRDF integration lookup table (pre-baked, 256x256 RG16Float)
	private ITexture mBRDFLut;
	private ITextureView mBRDFLutView;

	// Default black 1x1 cubemap used as fallback when no environment is set
	private ITexture mDefaultCubemap;
	private ITextureView mDefaultIrradianceView;
	private ITextureView mDefaultPrefilterView;

	// Active environment cubemap (converted from equirect or set directly)
	private ITexture mEnvCubemap;
	private ITextureView mEnvCubemapView;
	// Per-face views for rendering individual cubemap faces as color attachments
	private ITextureView[6] mEnvFaceViews;

	// Irradiance cubemap (convolved from environment for diffuse IBL)
	private ITexture mIrradianceCubemap;
	private ITextureView mIrradianceCubemapView;
	private ITextureView[6] mIrradianceFaceViews;

	// Active environment cubemap views (point to default or real environment)
	private ITextureView mActiveIrradianceView;
	private ITextureView mActivePrefilterView;

	// Linear-clamp sampler for environment map sampling
	private ISampler mEnvironmentSampler;

	// Maximum mip level for prefilter map LOD selection
	private float mPrefilterMaxLod = 0.0f;

	// Render pipelines for IBL generation (fragment shader approach)
	private IRenderPipeline mEquirectToCubePipeline;
	private IPipelineLayout mEquirectToCubeLayout;
	private IBindGroupLayout mEquirectToCubeBGLayout;

	private IRenderPipeline mIrradiancePipeline;
	private IPipelineLayout mIrradianceLayout;
	private IBindGroupLayout mIrradianceBGLayout;

	// Per-face params buffers and bind groups
	private IBuffer[6] mParamsBuffers;
	private IBindGroup[6] mEquirectBindGroups;
	private IBindGroup[6] mIrradianceBindGroups;

	// Pending sky texture for deferred IBL generation
	private ITextureView mPendingSkyView;
	private bool mPendingIsCubemap = false;
	private bool mIBLDirty = false;

	// Resolution constants
	private const uint32 EnvCubemapSize = 256;
	private const uint32 IrradianceSize = 32;

	/// BRDF integration LUT texture view (RG16Float, 256x256)
	public ITextureView BRDFLutView => mBRDFLutView;

	/// Active irradiance cubemap view (diffuse IBL)
	public ITextureView IrradianceMapView => mActiveIrradianceView;

	/// Active prefilter cubemap view (specular IBL)
	public ITextureView PrefilterMapView => mActivePrefilterView;

	/// Linear-clamp sampler for environment map sampling
	public ISampler EnvironmentSampler => mEnvironmentSampler;

	/// Maximum mip LOD for prefilter roughness mapping
	public float PrefilterMaxLod => mPrefilterMaxLod;

	/// Set the sky texture for IBL generation. Accepts either an equirectangular
	/// 2D texture or a cubemap. Pass null to revert to black fallbacks (procedural sky).
	/// The actual render work is deferred to the next ProcessPending() call.
	public void SetSkyTexture(ITextureView skyView, bool isCubemap = false)
	{
		mPendingSkyView = skyView;
		mPendingIsCubemap = isCubemap;
		mIBLDirty = true;
	}

	/// Process any pending IBL generation. Call once per frame from Pipeline.Render()
	/// when an encoder is available. Returns true if IBL was regenerated.
	public bool ProcessPending(ICommandEncoder encoder)
	{
		if (!mIBLDirty)
			return false;

		mIBLDirty = false;

		if (mPendingSkyView == null)
		{
			// Procedural / no sky — revert to black fallbacks
			mActiveIrradianceView = mDefaultIrradianceView;
			mActivePrefilterView = mDefaultPrefilterView;
			mPrefilterMaxLod = 0.0f;
			return true;
		}

		if (mPendingIsCubemap)
			GenerateFromCubemap(encoder, mPendingSkyView);
		else
			GenerateFromEquirectangular(encoder, mPendingSkyView);

		return true;
	}

	/// Initialize IBL resources: upload BRDF LUT, create fallback cubemaps and sampler.
	public Result<void> Initialize(IDevice device, IQueue queue)
	{
		mDevice = device;
		mQueue = queue;

		if (CreateBRDFLut() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create BRDF LUT");
			return .Err;
		}

		if (CreateDefaultCubemap() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create default cubemap");
			return .Err;
		}

		if (CreateEnvironmentSampler() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create environment sampler");
			return .Err;
		}

		if (CreateParamsBuffers() case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create params buffers");
			return .Err;
		}

		// Start with default (black) environment
		mActiveIrradianceView = mDefaultIrradianceView;
		mActivePrefilterView = mDefaultPrefilterView;

		return .Ok;
	}

	/// Initialize render pipelines for IBL generation. Must be called after
	/// ShaderSystem is available (set separately from Initialize).
	public Result<void> InitializeRenderPipelines(Sedulous.Shaders.ShaderSystem shaderSystem)
	{
		if (shaderSystem == null) return .Err;

		if (CreateEquirectToCubePipeline(shaderSystem) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create equirect-to-cube pipeline");
			return .Err;
		}

		if (CreateIrradiancePipeline(shaderSystem) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create irradiance pipeline");
			return .Err;
		}

		return .Ok;
	}

	/// Generate environment cubemap from equirectangular source and convolve
	/// irradiance map. Call when the sky texture changes.
	private void GenerateFromEquirectangular(ICommandEncoder encoder, ITextureView equirectView)
	{
		if (mEquirectToCubePipeline == null || mIrradiancePipeline == null)
			return;

		// Create cubemaps if needed
		if (mEnvCubemap == null)
			if (CreateEnvCubemap() case .Err) return;
		if (mIrradianceCubemap == null)
			if (CreateIrradianceCubemap() case .Err) return;

		// Convert equirect -> cubemap (6 render passes, one per face)
		RenderEquirectToCube(encoder, equirectView);

		// Convolve cubemap -> irradiance (6 render passes, one per face)
		RenderIrradianceConvolution(encoder, mEnvCubemapView);

		// Update active views
		mActiveIrradianceView = mIrradianceCubemapView;
		mActivePrefilterView = mEnvCubemapView;
		mPrefilterMaxLod = 0.0f; // No mip chain yet — sample mip 0 only
	}

	/// Generate irradiance map from an already-existing cubemap source.
	private void GenerateFromCubemap(ICommandEncoder encoder, ITextureView cubemapView)
	{
		if (mIrradiancePipeline == null)
			return;

		if (mIrradianceCubemap == null)
			if (CreateIrradianceCubemap() case .Err) return;

		RenderIrradianceConvolution(encoder, cubemapView);

		mActiveIrradianceView = mIrradianceCubemapView;
		mActivePrefilterView = cubemapView;
		mPrefilterMaxLod = 0.0f;
	}

	/// Release all GPU resources.
	public void Shutdown()
	{
		if (mDevice == null) return;

		// Render pipelines
		if (mEquirectToCubePipeline != null) mDevice.DestroyRenderPipeline(ref mEquirectToCubePipeline);
		if (mEquirectToCubeLayout != null) mDevice.DestroyPipelineLayout(ref mEquirectToCubeLayout);
		if (mEquirectToCubeBGLayout != null) mDevice.DestroyBindGroupLayout(ref mEquirectToCubeBGLayout);

		if (mIrradiancePipeline != null) mDevice.DestroyRenderPipeline(ref mIrradiancePipeline);
		if (mIrradianceLayout != null) mDevice.DestroyPipelineLayout(ref mIrradianceLayout);
		if (mIrradianceBGLayout != null) mDevice.DestroyBindGroupLayout(ref mIrradianceBGLayout);

		// Per-face resources
		for (int i = 0; i < 6; i++)
		{
			if (mEquirectBindGroups[i] != null) mDevice.DestroyBindGroup(ref mEquirectBindGroups[i]);
			if (mIrradianceBindGroups[i] != null) mDevice.DestroyBindGroup(ref mIrradianceBindGroups[i]);
			if (mParamsBuffers[i] != null) mDevice.DestroyBuffer(ref mParamsBuffers[i]);
			if (mEnvFaceViews[i] != null) mDevice.DestroyTextureView(ref mEnvFaceViews[i]);
			if (mIrradianceFaceViews[i] != null) mDevice.DestroyTextureView(ref mIrradianceFaceViews[i]);
		}

		// Irradiance cubemap
		if (mIrradianceCubemapView != null) mDevice.DestroyTextureView(ref mIrradianceCubemapView);
		if (mIrradianceCubemap != null) mDevice.DestroyTexture(ref mIrradianceCubemap);

		// Environment cubemap
		if (mEnvCubemapView != null) mDevice.DestroyTextureView(ref mEnvCubemapView);
		if (mEnvCubemap != null) mDevice.DestroyTexture(ref mEnvCubemap);

		// Sampler
		if (mEnvironmentSampler != null) mDevice.DestroySampler(ref mEnvironmentSampler);

		// Defaults
		if (mDefaultPrefilterView != null) mDevice.DestroyTextureView(ref mDefaultPrefilterView);
		if (mDefaultIrradianceView != null) mDevice.DestroyTextureView(ref mDefaultIrradianceView);
		if (mDefaultCubemap != null) mDevice.DestroyTexture(ref mDefaultCubemap);

		// BRDF LUT
		if (mBRDFLutView != null) mDevice.DestroyTextureView(ref mBRDFLutView);
		if (mBRDFLut != null) mDevice.DestroyTexture(ref mBRDFLut);

		mActiveIrradianceView = null;
		mActivePrefilterView = null;
	}

	// ==================== Resource Creation ====================

	/// Upload the pre-baked BRDF integration LUT to the GPU.
	private Result<void> CreateBRDFLut()
	{
		let desc = TextureDesc.Tex2D(
			.RG16Float,
			BRDFLutData.Width, BRDFLutData.Height,
			.Sampled | .CopyDst,
			label: "BRDF LUT"
		);

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			mBRDFLut = tex;
		else
			return .Err;

		// Upload the pre-baked data
		let dataLayout = TextureDataLayout()
		{
			BytesPerRow = (uint32)(BRDFLutData.Width * 4), // RG16Float = 4 bytes per texel
			RowsPerImage = BRDFLutData.Height
		};

		TransferHelper.WriteTextureSync(
			mQueue, mDevice, mBRDFLut,
			Span<uint8>(&BRDFLutData.Data[0], BRDFLutData.DataSize),
			dataLayout,
			.(BRDFLutData.Width, BRDFLutData.Height, 1)
		);

		// Create view
		if (mDevice.CreateTextureView(mBRDFLut, .() { Format = .RG16Float, Dimension = .Texture2D }) case .Ok(let view))
			mBRDFLutView = view;
		else
			return .Err;

		return .Ok;
	}

	/// Create a 1x1 black cubemap used as fallback for irradiance and prefilter.
	private Result<void> CreateDefaultCubemap()
	{
		let desc = TextureDesc.Cube(.RGBA8Unorm, 1, .Sampled | .CopyDst, label: "IBL Default Black Cubemap");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			mDefaultCubemap = tex;
		else
			return .Err;

		// Upload 4 bytes of black (0,0,0,0) per face
		uint8[4] blackPixel = .(0, 0, 0, 0);
		let dataLayout = TextureDataLayout() { BytesPerRow = 4, RowsPerImage = 1 };

		for (uint32 face = 0; face < 6; face++)
		{
			TransferHelper.WriteTextureSync(
				mQueue, mDevice, mDefaultCubemap,
				Span<uint8>(&blackPixel[0], 4),
				dataLayout,
				.(1, 1, 1),
				arrayLayer: face
			);
		}

		// Irradiance view (cubemap)
		if (mDevice.CreateTextureView(mDefaultCubemap, .()
		{
			Format = .RGBA8Unorm,
			Dimension = .TextureCube,
			BaseArrayLayer = 0,
			ArrayLayerCount = 6,
			Label = "IBL Default Irradiance"
		}) case .Ok(let irradView))
			mDefaultIrradianceView = irradView;
		else
			return .Err;

		// Prefilter view (cubemap) — same texture, separate view for clarity
		if (mDevice.CreateTextureView(mDefaultCubemap, .()
		{
			Format = .RGBA8Unorm,
			Dimension = .TextureCube,
			BaseArrayLayer = 0,
			ArrayLayerCount = 6,
			Label = "IBL Default Prefilter"
		}) case .Ok(let prefilterView))
			mDefaultPrefilterView = prefilterView;
		else
			return .Err;

		return .Ok;
	}

	/// Create a linear-clamp sampler for environment map sampling.
	private Result<void> CreateEnvironmentSampler()
	{
		let samplerDesc = SamplerDesc()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Linear,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge,
			MaxLod = 16.0f,
			Label = "IBL Environment Sampler"
		};

		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
			mEnvironmentSampler = sampler;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreateParamsBuffers()
	{
		for (int i = 0; i < 6; i++)
		{
			BufferDesc desc = .()
			{
				Label = "IBL Face Params",
				Size = 16, // 4 x uint32
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (mDevice.CreateBuffer(desc) case .Ok(let buf))
			{
				mParamsBuffers[i] = buf;
				// Pre-write face index (it never changes)
				uint32[4] data = .((uint32)i, 0, 0, 0);
				TransferHelper.WriteMappedBuffer(buf, 0, Span<uint8>((uint8*)&data[0], 16));
			}
			else
				return .Err;
		}

		return .Ok;
	}

	/// Create the environment cubemap texture and per-face views for rendering.
	private Result<void> CreateEnvCubemap()
	{
		let desc = TextureDesc.Cube(.RGBA16Float, EnvCubemapSize, .Sampled | .RenderTarget,
			label: "IBL Environment Cubemap");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			mEnvCubemap = tex;
		else
			return .Err;

		// Cubemap view for sampling
		if (mDevice.CreateTextureView(mEnvCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			Label = "IBL Env Cubemap View"
		}) case .Ok(let cubeView))
			mEnvCubemapView = cubeView;
		else
			return .Err;

		// Per-face views for rendering as color attachments
		for (uint32 face = 0; face < 6; face++)
		{
			if (mDevice.CreateTextureView(mEnvCubemap, .()
			{
				Format = .RGBA16Float, Dimension = .Texture2D,
				BaseArrayLayer = face, ArrayLayerCount = 1,
				Label = "IBL Env Face"
			}) case .Ok(let faceView))
				mEnvFaceViews[face] = faceView;
			else
				return .Err;
		}

		return .Ok;
	}

	/// Create the irradiance cubemap texture and per-face views for rendering.
	private Result<void> CreateIrradianceCubemap()
	{
		let desc = TextureDesc.Cube(.RGBA16Float, IrradianceSize, .Sampled | .RenderTarget,
			label: "IBL Irradiance Cubemap");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			mIrradianceCubemap = tex;
		else
			return .Err;

		if (mDevice.CreateTextureView(mIrradianceCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			Label = "IBL Irradiance View"
		}) case .Ok(let irradCubeView))
			mIrradianceCubemapView = irradCubeView;
		else
			return .Err;

		for (uint32 face = 0; face < 6; face++)
		{
			if (mDevice.CreateTextureView(mIrradianceCubemap, .()
			{
				Format = .RGBA16Float, Dimension = .Texture2D,
				BaseArrayLayer = face, ArrayLayerCount = 1,
				Label = "IBL Irradiance Face"
			}) case .Ok(let faceView))
				mIrradianceFaceViews[face] = faceView;
			else
				return .Err;
		}

		return .Ok;
	}

	// ==================== Render Pipeline Creation ====================

	private Result<void> CreateEquirectToCubePipeline(Sedulous.Shaders.ShaderSystem shaderSystem)
	{
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let fragResult = shaderSystem.GetShader("equirect_to_cube", .Fragment);
		if (fragResult case .Err) return .Err;

		// Layout: b0 params, t0 equirect texture, s0 sampler
		BindGroupLayoutEntry[3] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment, .Texture2D),
			.Sampler(0, .Fragment)
		);

		if (mDevice.CreateBindGroupLayout(.() { Label = "EquirectToCube BGL", Entries = entries }) case .Ok(let bgl))
			mEquirectToCubeBGLayout = bgl;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mEquirectToCubeBGLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let pl))
			mEquirectToCubeLayout = pl;
		else
			return .Err;

		ColorTargetState[1] colorTargets = .(.(TextureFormat.RGBA16Float));

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "EquirectToCube Pipeline",
			Layout = mEquirectToCubeLayout,
			Vertex = .() { Shader = .(vertResult.Value.Module, "main") },
			Fragment = .()
			{
				Shader = .(fragResult.Value.Module, "main"),
				Targets = .(&colorTargets[0], 1)
			},
			Primitive = .() { Topology = .TriangleList, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mEquirectToCubePipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreateIrradiancePipeline(Sedulous.Shaders.ShaderSystem shaderSystem)
	{
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let fragResult = shaderSystem.GetShader("irradiance_convolve", .Fragment);
		if (fragResult case .Err) return .Err;

		// Layout: b0 params, t0 env cubemap, s0 sampler
		BindGroupLayoutEntry[3] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment, .TextureCube),
			.Sampler(0, .Fragment)
		);

		if (mDevice.CreateBindGroupLayout(.() { Label = "Irradiance BGL", Entries = entries }) case .Ok(let bgl))
			mIrradianceBGLayout = bgl;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mIrradianceBGLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let pl))
			mIrradianceLayout = pl;
		else
			return .Err;

		ColorTargetState[1] colorTargets = .(.(TextureFormat.RGBA16Float));

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Irradiance Pipeline",
			Layout = mIrradianceLayout,
			Vertex = .() { Shader = .(vertResult.Value.Module, "main") },
			Fragment = .()
			{
				Shader = .(fragResult.Value.Module, "main"),
				Targets = .(&colorTargets[0], 1)
			},
			Primitive = .() { Topology = .TriangleList, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mIrradiancePipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	// ==================== Render Dispatch ====================

	/// Render equirectangular map to 6 cubemap faces via fullscreen triangle passes.
	private void RenderEquirectToCube(ICommandEncoder encoder, ITextureView equirectView)
	{
		// Create/update bind groups (one per face, each with its own params buffer)
		for (int i = 0; i < 6; i++)
		{
			if (mEquirectBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mEquirectBindGroups[i]);

			BindGroupEntry[3] entries = .(
				BindGroupEntry.Buffer(mParamsBuffers[i], 0, 16),
				BindGroupEntry.Texture(equirectView),
				BindGroupEntry.Sampler(mEnvironmentSampler)
			);

			if (mDevice.CreateBindGroup(.() { Label = "EquirectToCube BG", Layout = mEquirectToCubeBGLayout, Entries = entries }) case .Ok(let bg))
				mEquirectBindGroups[i] = bg;
		}

		// Render each face
		for (uint32 face = 0; face < 6; face++)
		{
			if (mEquirectBindGroups[face] == null || mEnvFaceViews[face] == null) continue;

			ColorAttachment[1] colorAttachments = .(.()
			{
				View = mEnvFaceViews[face],
				LoadOp = .DontCare,
				StoreOp = .Store
			});

			RenderPassDesc rpDesc = .()
			{
				Label = "EquirectToCube",
				ColorAttachments = .(colorAttachments)
			};

			let rp = encoder.BeginRenderPass(rpDesc);
			rp.SetPipeline(mEquirectToCubePipeline);
			rp.SetBindGroup(0, mEquirectBindGroups[face], default);
			rp.SetViewport(0, 0, EnvCubemapSize, EnvCubemapSize, 0, 1);
			rp.SetScissor(0, 0, EnvCubemapSize, EnvCubemapSize);
			rp.Draw(3, 1, 0, 0); // Fullscreen triangle
			rp.End();
		}
	}

	/// Render irradiance convolution to 6 cubemap faces via fullscreen triangle passes.
	private void RenderIrradianceConvolution(ICommandEncoder encoder, ITextureView sourceCubemapView)
	{
		// Create/update bind groups
		for (int i = 0; i < 6; i++)
		{
			if (mIrradianceBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mIrradianceBindGroups[i]);

			BindGroupEntry[3] entries = .(
				BindGroupEntry.Buffer(mParamsBuffers[i], 0, 16),
				BindGroupEntry.Texture(sourceCubemapView),
				BindGroupEntry.Sampler(mEnvironmentSampler)
			);

			if (mDevice.CreateBindGroup(.() { Label = "Irradiance BG", Layout = mIrradianceBGLayout, Entries = entries }) case .Ok(let bg))
				mIrradianceBindGroups[i] = bg;
		}

		// Render each face
		for (uint32 face = 0; face < 6; face++)
		{
			if (mIrradianceBindGroups[face] == null || mIrradianceFaceViews[face] == null) continue;

			ColorAttachment[1] colorAttachments = .(.()
			{
				View = mIrradianceFaceViews[face],
				LoadOp = .DontCare,
				StoreOp = .Store
			});

			RenderPassDesc rpDesc = .()
			{
				Label = "IrradianceConvolve",
				ColorAttachments = .(colorAttachments)
			};

			let rp = encoder.BeginRenderPass(rpDesc);
			rp.SetPipeline(mIrradiancePipeline);
			rp.SetBindGroup(0, mIrradianceBindGroups[face], default);
			rp.SetViewport(0, 0, IrradianceSize, IrradianceSize, 0, 1);
			rp.SetScissor(0, 0, IrradianceSize, IrradianceSize);
			rp.Draw(3, 1, 0, 0); // Fullscreen triangle
			rp.End();
		}
	}
}
