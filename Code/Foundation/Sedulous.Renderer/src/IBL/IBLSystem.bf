namespace Sedulous.Renderer.IBL;

using System;
using System.Collections;
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

	private IRenderPipeline mPrefilterPipeline;
	private IPipelineLayout mPrefilterLayout;
	private IBindGroupLayout mPrefilterBGLayout;

	// Prefilter cubemap (specular IBL with mip chain for roughness-dependent reflections)
	private ITexture mPrefilterCubemap;
	private ITextureView mPrefilterCubemapView;
	// Per-face-per-mip views, params buffers, bind groups
	// Index = mip * 6 + face, total = PrefilterMipCount * 6 = 30
	private ITextureView[30] mPrefilterFaceViews;
	private IBuffer[30] mPrefilterParamsBuffers;
	private IBindGroup[30] mPrefilterBindGroups;

	// Per-face params buffers and bind groups (equirect + irradiance)
	private IBuffer[6] mParamsBuffers;
	private IBindGroup[6] mEquirectBindGroups;
	private IBindGroup[6] mIrradianceBindGroups;

	// Deferred bind group destruction with double-buffering. Bind groups must
	// survive at least 2 frames (MaxFramesInFlight) because the command buffer
	// referencing them may still be executing on the GPU.
	// mStaleBindGroups[0] = ready to destroy (2+ frames old)
	// mStaleBindGroups[1] = deferred from last frame
	private List<IBindGroup>[2] mStaleBindGroups = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };

	// Pending sky texture for deferred IBL generation
	private ITextureView mPendingSkyView;
	private bool mPendingIsCubemap = false;
	private bool mIBLDirty = false;
	private int32 mLastFlushFrame = -1;

	// Resolution constants
	private const uint32 EnvCubemapSize = 256;
	private const uint32 IrradianceSize = 32;
	private const uint32 PrefilterSize = 256;
	private const int PrefilterMipCount = 5; // 256, 128, 64, 32, 16

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
		// Skip if the same source is already set — avoids re-triggering
		// expensive IBL convolution when nothing has changed.
		if (mPendingSkyView == skyView && mPendingIsCubemap == isCubemap)
			return;

		mPendingSkyView = skyView;
		mPendingIsCubemap = isCubemap;
		mIBLDirty = true;
	}

	/// Process any pending IBL generation. Call from Pipeline.Render()
	/// when an encoder is available. Returns true if IBL was regenerated.
	/// frameIndex is used to guard stale bind group rotation (once per frame).
	public bool ProcessPending(ICommandEncoder encoder, int32 frameIndex)
	{
		// Flush deferred bind group destructions. Only rotates the double-buffer
		// once per frame even if called multiple times.
		FlushStaleBindGroups(frameIndex);

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

		if (CreatePrefilterPipeline(shaderSystem) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("IBLSystem: Failed to create prefilter pipeline");
			return .Err;
		}

		return .Ok;
	}

	/// Generate environment cubemap from equirectangular source, convolve
	/// irradiance map, and generate prefilter mip chain. Call when the sky texture changes.
	private void GenerateFromEquirectangular(ICommandEncoder encoder, ITextureView equirectView)
	{
		if (mEquirectToCubePipeline == null || mIrradiancePipeline == null)
			return;

		// Create cubemaps if needed
		if (mEnvCubemap == null)
			if (CreateEnvCubemap() case .Err) return;
		if (mIrradianceCubemap == null)
			if (CreateIrradianceCubemap() case .Err) return;
		if (mPrefilterCubemap == null)
			if (CreatePrefilterCubemap() case .Err) return;

		// Convert equirect -> cubemap (6 render passes, one per face)
		RenderEquirectToCube(encoder, equirectView);

		// Env cubemap is now in RenderTarget state; transition to ShaderRead for sampling
		encoder.TransitionTexture(mEnvCubemap, .RenderTarget, .ShaderRead);

		// Convolve cubemap -> irradiance (6 render passes, one per face)
		RenderIrradianceConvolution(encoder, mEnvCubemapView);

		// Generate prefilter mip chain (6 faces x PrefilterMipCount mips)
		if (mPrefilterPipeline != null)
			RenderPrefilterConvolution(encoder, mEnvCubemapView);

		// Transition irradiance and prefilter cubemaps to ShaderRead for forward pass
		encoder.TransitionTexture(mIrradianceCubemap, .RenderTarget, .ShaderRead);
		if (mPrefilterCubemap != null)
			encoder.TransitionTexture(mPrefilterCubemap, .RenderTarget, .ShaderRead);

		// Update active views
		mActiveIrradianceView = mIrradianceCubemapView;
		mActivePrefilterView = (mPrefilterCubemapView != null) ? mPrefilterCubemapView : mEnvCubemapView;
		mPrefilterMaxLod = (mPrefilterCubemap != null) ? (float)(PrefilterMipCount - 1) : 0.0f;

	}

	/// Generate irradiance and prefilter maps from an already-existing cubemap source.
	private void GenerateFromCubemap(ICommandEncoder encoder, ITextureView cubemapView)
	{
		if (mIrradiancePipeline == null)
			return;

		if (mIrradianceCubemap == null)
			if (CreateIrradianceCubemap() case .Err) return;
		if (mPrefilterCubemap == null)
			if (CreatePrefilterCubemap() case .Err) return;

		RenderIrradianceConvolution(encoder, cubemapView);

		if (mPrefilterPipeline != null)
			RenderPrefilterConvolution(encoder, cubemapView);

		// Transition irradiance and prefilter cubemaps to ShaderRead for forward pass
		encoder.TransitionTexture(mIrradianceCubemap, .RenderTarget, .ShaderRead);
		if (mPrefilterCubemap != null)
			encoder.TransitionTexture(mPrefilterCubemap, .RenderTarget, .ShaderRead);

		mActiveIrradianceView = mIrradianceCubemapView;
		mActivePrefilterView = (mPrefilterCubemapView != null) ? mPrefilterCubemapView : cubemapView;
		mPrefilterMaxLod = (mPrefilterCubemap != null) ? (float)(PrefilterMipCount - 1) : 0.0f;
	}

	/// Moves a bind group to the current frame's stale list for deferred destruction.
	private void DeferBindGroup(ref IBindGroup bg)
	{
		if (bg != null)
		{
			mStaleBindGroups[1].Add(bg);
			bg = null;
		}
	}

	/// Rotates the double-buffered stale lists and destroys the oldest batch.
	/// Only rotates once per frame (ProcessPending may be called multiple times
	/// per frame from different pipelines).
	private void FlushStaleBindGroups(int32 frameIndex)
	{
		if (mLastFlushFrame == frameIndex)
			return; // Already rotated this frame
		mLastFlushFrame = frameIndex;

		// Destroy bind groups from 2 frames ago (guaranteed to be done on GPU)
		for (var bg in mStaleBindGroups[0])
			mDevice.DestroyBindGroup(ref bg);
		mStaleBindGroups[0].Clear();

		// Rotate: last frame's deferred list becomes the "old" list
		let temp = mStaleBindGroups[0];
		mStaleBindGroups[0] = mStaleBindGroups[1];
		mStaleBindGroups[1] = temp;
	}

	/// Release all GPU resources.
	public void Shutdown()
	{
		if (mDevice == null) return;

		// Flush all deferred bind groups (both slots)
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleBindGroups[s])
				mDevice.DestroyBindGroup(ref bg);
			mStaleBindGroups[s].Clear();
		}

		// Render pipelines
		if (mEquirectToCubePipeline != null) mDevice.DestroyRenderPipeline(ref mEquirectToCubePipeline);
		if (mEquirectToCubeLayout != null) mDevice.DestroyPipelineLayout(ref mEquirectToCubeLayout);
		if (mEquirectToCubeBGLayout != null) mDevice.DestroyBindGroupLayout(ref mEquirectToCubeBGLayout);

		if (mIrradiancePipeline != null) mDevice.DestroyRenderPipeline(ref mIrradiancePipeline);
		if (mIrradianceLayout != null) mDevice.DestroyPipelineLayout(ref mIrradianceLayout);
		if (mIrradianceBGLayout != null) mDevice.DestroyBindGroupLayout(ref mIrradianceBGLayout);

		if (mPrefilterPipeline != null) mDevice.DestroyRenderPipeline(ref mPrefilterPipeline);
		if (mPrefilterLayout != null) mDevice.DestroyPipelineLayout(ref mPrefilterLayout);
		if (mPrefilterBGLayout != null) mDevice.DestroyBindGroupLayout(ref mPrefilterBGLayout);

		// Per-face-per-mip prefilter resources
		for (int i = 0; i < PrefilterMipCount * 6; i++)
		{
			if (mPrefilterBindGroups[i] != null) mDevice.DestroyBindGroup(ref mPrefilterBindGroups[i]);
			if (mPrefilterParamsBuffers[i] != null) mDevice.DestroyBuffer(ref mPrefilterParamsBuffers[i]);
			if (mPrefilterFaceViews[i] != null) mDevice.DestroyTextureView(ref mPrefilterFaceViews[i]);
		}

		// Prefilter cubemap
		if (mPrefilterCubemapView != null) mDevice.DestroyTextureView(ref mPrefilterCubemapView);
		if (mPrefilterCubemap != null) mDevice.DestroyTexture(ref mPrefilterCubemap);

		// Per-face resources (equirect + irradiance)
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

	private Result<void> CreatePrefilterPipeline(Sedulous.Shaders.ShaderSystem shaderSystem)
	{
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let fragResult = shaderSystem.GetShader("prefilter_convolve", .Fragment);
		if (fragResult case .Err) return .Err;

		// Layout: b0 params (face + roughness), t0 env cubemap, s0 sampler
		BindGroupLayoutEntry[3] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment, .TextureCube),
			.Sampler(0, .Fragment)
		);

		if (mDevice.CreateBindGroupLayout(.() { Label = "Prefilter BGL", Entries = entries }) case .Ok(let bgl))
			mPrefilterBGLayout = bgl;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mPrefilterBGLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let pl))
			mPrefilterLayout = pl;
		else
			return .Err;

		ColorTargetState[1] colorTargets = .(.(TextureFormat.RGBA16Float));

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Prefilter Pipeline",
			Layout = mPrefilterLayout,
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
			mPrefilterPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	/// Create the prefilter cubemap with mip chain, per-face-per-mip views, and params buffers.
	private Result<void> CreatePrefilterCubemap()
	{
		let desc = TextureDesc.Cube(.RGBA16Float, PrefilterSize, .Sampled | .RenderTarget,
			mipLevels: (uint32)PrefilterMipCount, label: "IBL Prefilter Cubemap");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			mPrefilterCubemap = tex;
		else
			return .Err;

		// Full cubemap view for sampling (all mips, all faces)
		if (mDevice.CreateTextureView(mPrefilterCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			BaseMipLevel = 0, MipLevelCount = (uint32)PrefilterMipCount,
			Label = "IBL Prefilter View"
		}) case .Ok(let cubeView))
			mPrefilterCubemapView = cubeView;
		else
			return .Err;

		// Per-face-per-mip views for rendering as color attachments
		for (int mip = 0; mip < PrefilterMipCount; mip++)
		{
			float roughness = (float)mip / (float)(PrefilterMipCount - 1);

			for (uint32 face = 0; face < 6; face++)
			{
				int idx = mip * 6 + (int)face;

				// Texture view targeting single face at single mip
				if (mDevice.CreateTextureView(mPrefilterCubemap, .()
				{
					Format = .RGBA16Float, Dimension = .Texture2D,
					BaseMipLevel = (uint32)mip, MipLevelCount = 1,
					BaseArrayLayer = face, ArrayLayerCount = 1,
					Label = "IBL Prefilter Face"
				}) case .Ok(let faceView))
					mPrefilterFaceViews[idx] = faceView;
				else
					return .Err;

				// Params buffer with pre-written face index and roughness
				BufferDesc bufDesc = .()
				{
					Label = "IBL Prefilter Params",
					Size = 16,
					Usage = .Uniform,
					Memory = .CpuToGpu
				};

				if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
				{
					mPrefilterParamsBuffers[idx] = buf;
					uint32[4] data = .((uint32)face, 0, 0, 0);
					*((float*)&data[1]) = roughness;
					TransferHelper.WriteMappedBuffer(buf, 0, Span<uint8>((uint8*)&data[0], 16));
				}
				else
					return .Err;
			}
		}

		return .Ok;
	}

	// ==================== Render Dispatch ====================

	/// Render equirectangular map to 6 cubemap faces via fullscreen triangle passes.
	private void RenderEquirectToCube(ICommandEncoder encoder, ITextureView equirectView)
	{
		// Create/update bind groups (one per face, each with its own params buffer)
		for (int i = 0; i < 6; i++)
		{
			DeferBindGroup(ref mEquirectBindGroups[i]);

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
			DeferBindGroup(ref mIrradianceBindGroups[i]);

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

	/// Render prefilter convolution: GGX importance sampling at each mip level.
	/// Each mip maps to a roughness value: roughness = mip / (mipCount - 1).
	private void RenderPrefilterConvolution(ICommandEncoder encoder, ITextureView sourceCubemapView)
	{
		// Create/update bind groups for all mip-face combinations
		for (int mip = 0; mip < PrefilterMipCount; mip++)
		{
			for (int face = 0; face < 6; face++)
			{
				int idx = mip * 6 + face;

				DeferBindGroup(ref mPrefilterBindGroups[idx]);

				BindGroupEntry[3] entries = .(
					BindGroupEntry.Buffer(mPrefilterParamsBuffers[idx], 0, 16),
					BindGroupEntry.Texture(sourceCubemapView),
					BindGroupEntry.Sampler(mEnvironmentSampler)
				);

				if (mDevice.CreateBindGroup(.() { Label = "Prefilter BG", Layout = mPrefilterBGLayout, Entries = entries }) case .Ok(let bg))
					mPrefilterBindGroups[idx] = bg;
			}
		}

		// Render each mip level at its corresponding resolution
		for (int mip = 0; mip < PrefilterMipCount; mip++)
		{
			uint32 mipSize = PrefilterSize >> (uint32)mip;

			for (uint32 face = 0; face < 6; face++)
			{
				int idx = mip * 6 + (int)face;

				if (mPrefilterBindGroups[idx] == null || mPrefilterFaceViews[idx] == null) continue;

				ColorAttachment[1] colorAttachments = .(.()
				{
					View = mPrefilterFaceViews[idx],
					LoadOp = .DontCare,
					StoreOp = .Store
				});

				RenderPassDesc rpDesc = .()
				{
					Label = "PrefilterConvolve",
					ColorAttachments = .(colorAttachments)
				};

				let rp = encoder.BeginRenderPass(rpDesc);
				rp.SetPipeline(mPrefilterPipeline);
				rp.SetBindGroup(0, mPrefilterBindGroups[idx], default);
				rp.SetViewport(0, 0, mipSize, mipSize, 0, 1);
				rp.SetScissor(0, 0, mipSize, mipSize);
				rp.Draw(3, 1, 0, 0); // Fullscreen triangle
				rp.End();
			}
		}
	}
}
