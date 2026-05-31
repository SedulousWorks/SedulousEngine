namespace Sedulous.Renderer.IBL;

using System;
using Sedulous.RHI;

/// Manages IBL (Image-Based Lighting) GPU resources for the split-sum approximation.
/// Owns the BRDF integration LUT, default fallback cubemaps, and the environment sampler.
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

	// Active environment cubemap views (point to default or real environment)
	private ITextureView mActiveIrradianceView;
	private ITextureView mActivePrefilterView;

	// Linear-clamp sampler for environment map sampling
	private ISampler mEnvironmentSampler;

	// Maximum mip level for prefilter map LOD selection
	private float mPrefilterMaxLod = 0.0f;

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

		// Start with default (black) environment
		mActiveIrradianceView = mDefaultIrradianceView;
		mActivePrefilterView = mDefaultPrefilterView;

		return .Ok;
	}

	/// Release all GPU resources.
	public void Shutdown()
	{
		if (mDevice == null) return;

		if (mEnvironmentSampler != null)
			mDevice.DestroySampler(ref mEnvironmentSampler);

		if (mDefaultPrefilterView != null)
			mDevice.DestroyTextureView(ref mDefaultPrefilterView);
		if (mDefaultIrradianceView != null)
			mDevice.DestroyTextureView(ref mDefaultIrradianceView);
		if (mDefaultCubemap != null)
			mDevice.DestroyTexture(ref mDefaultCubemap);

		if (mBRDFLutView != null)
			mDevice.DestroyTextureView(ref mBRDFLutView);
		if (mBRDFLut != null)
			mDevice.DestroyTexture(ref mBRDFLut);

		mActiveIrradianceView = null;
		mActivePrefilterView = null;
	}

	// ==================== Internal ====================

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
		}) case .Ok(let view))
			mDefaultIrradianceView = view;
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
		}) case .Ok(let view))
			mDefaultPrefilterView = view;
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
}
