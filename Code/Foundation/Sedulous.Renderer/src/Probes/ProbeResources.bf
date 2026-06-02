namespace Sedulous.Renderer.Probes;

using System;
using Sedulous.RHI;
using Sedulous.Renderer.IBL;

/// GPU resources for a single reflection probe.
/// Owns the captured cubemap, convolved irradiance and prefilter cubemaps,
/// and all associated views. Created on first capture, destroyed on scene teardown.
class ProbeResources
{
	// Captured scene cubemap (RGBA16Float, 6 layers)
	public ITexture CapturedCubemap;
	public ITextureView CapturedCubemapView;   // TextureCube view for IBL convolution input
	public ITextureView[6] CapturedFaceViews;  // Texture2D views for blit target

	// Convolved irradiance cubemap (diffuse IBL, small: 32x32)
	public ITexture IrradianceCubemap;
	public ITextureView IrradianceCubemapView;
	public ITextureView[6] IrradianceFaceViews;

	// Convolved prefilter cubemap (specular IBL with mip chain)
	public ITexture PrefilterCubemap;
	public ITextureView PrefilterCubemapView;
	// Per-face-per-mip views: index = mip * 6 + face
	public ITextureView[30] PrefilterFaceViews;

	// Per-face-per-mip params buffers for prefilter convolution
	// Each contains (FaceIndex, Roughness, pad, pad) — 16 bytes
	public IBuffer[6] IrradianceParamsBuffers;
	public IBuffer[30] PrefilterParamsBuffers;

	public uint32 FaceSize;
	public float PrefilterMaxLod;
	public bool IsCaptured = false;    // True after first successful capture
	public bool NeedsCapture = true;   // True when capture is pending

	/// Create all GPU resources for this probe.
	public Result<void> Create(IDevice device, uint32 faceSize)
	{
		FaceSize = faceSize;

		// --- Captured cubemap ---
		let captureDesc = TextureDesc.Cube(.RGBA16Float, faceSize, .Sampled | .RenderTarget,
			label: "Probe Capture Cubemap");

		if (device.CreateTexture(captureDesc) case .Ok(let tex))
			CapturedCubemap = tex;
		else
			return .Err;

		if (device.CreateTextureView(CapturedCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			Label = "Probe Capture CubeView"
		}) case .Ok(let captureView))
			CapturedCubemapView = captureView;
		else
			return .Err;

		for (uint32 face = 0; face < 6; face++)
		{
			if (device.CreateTextureView(CapturedCubemap, .()
			{
				Format = .RGBA16Float, Dimension = .Texture2D,
				BaseArrayLayer = face, ArrayLayerCount = 1,
				Label = "Probe Capture Face"
			}) case .Ok(let faceView))
				CapturedFaceViews[face] = faceView;
			else
				return .Err;
		}

		// --- Irradiance cubemap ---
		let irradSize = IBLSystem.IrradianceFaceSize;
		let irradDesc = TextureDesc.Cube(.RGBA16Float, irradSize, .Sampled | .RenderTarget,
			label: "Probe Irradiance Cubemap");

		if (device.CreateTexture(irradDesc) case .Ok(let irradTex))
			IrradianceCubemap = irradTex;
		else
			return .Err;

		if (device.CreateTextureView(IrradianceCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			Label = "Probe Irradiance CubeView"
		}) case .Ok(let irradView))
			IrradianceCubemapView = irradView;
		else
			return .Err;

		for (uint32 face = 0; face < 6; face++)
		{
			if (device.CreateTextureView(IrradianceCubemap, .()
			{
				Format = .RGBA16Float, Dimension = .Texture2D,
				BaseArrayLayer = face, ArrayLayerCount = 1,
				Label = "Probe Irradiance Face"
			}) case .Ok(let irradFaceView))
				IrradianceFaceViews[face] = irradFaceView;
			else
				return .Err;
		}

		// --- Prefilter cubemap with mip chain ---
		let mipCount = IBLSystem.PrefilterMipLevels;
		let prefiltSize = IBLSystem.PrefilterFaceSize;
		PrefilterMaxLod = (float)(mipCount - 1);

		let prefiltDesc = TextureDesc.Cube(.RGBA16Float, prefiltSize, .Sampled | .RenderTarget,
			mipLevels: (uint32)mipCount, label: "Probe Prefilter Cubemap");

		if (device.CreateTexture(prefiltDesc) case .Ok(let prefiltTex))
			PrefilterCubemap = prefiltTex;
		else
			return .Err;

		if (device.CreateTextureView(PrefilterCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			BaseMipLevel = 0, MipLevelCount = (uint32)mipCount,
			Label = "Probe Prefilter CubeView"
		}) case .Ok(let prefiltView))
			PrefilterCubemapView = prefiltView;
		else
			return .Err;

		for (int mip = 0; mip < mipCount; mip++)
		{
			for (uint32 face = 0; face < 6; face++)
			{
				int idx = mip * 6 + (int)face;
				if (device.CreateTextureView(PrefilterCubemap, .()
				{
					Format = .RGBA16Float, Dimension = .Texture2D,
					BaseMipLevel = (uint32)mip, MipLevelCount = 1,
					BaseArrayLayer = face, ArrayLayerCount = 1,
					Label = "Probe Prefilter Face"
				}) case .Ok(let prefiltFaceView))
					PrefilterFaceViews[idx] = prefiltFaceView;
				else
					return .Err;
			}
		}

		// --- Params buffers for convolution ---
		// Irradiance: 6 buffers, each (FaceIndex, pad, pad, pad)
		for (int i = 0; i < 6; i++)
		{
			BufferDesc bufDesc = .()
			{
				Label = "Probe Irradiance Params",
				Size = 16,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(bufDesc) case .Ok(let buf))
			{
				IrradianceParamsBuffers[i] = buf;
				uint32[4] data = .((uint32)i, 0, 0, 0);
				TransferHelper.WriteMappedBuffer(buf, 0, Span<uint8>((uint8*)&data[0], 16));
			}
			else
				return .Err;
		}

		// Prefilter: 30 buffers, each (FaceIndex, Roughness, pad, pad)
		for (int mip = 0; mip < mipCount; mip++)
		{
			float roughness = (float)mip / (float)(mipCount - 1);

			for (uint32 face = 0; face < 6; face++)
			{
				int idx = mip * 6 + (int)face;
				BufferDesc bufDesc = .()
				{
					Label = "Probe Prefilter Params",
					Size = 16,
					Usage = .Uniform,
					Memory = .CpuToGpu
				};

				if (device.CreateBuffer(bufDesc) case .Ok(let buf))
				{
					PrefilterParamsBuffers[idx] = buf;
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

	/// Release all GPU resources.
	public void Destroy(IDevice device)
	{
		if (device == null) return;

		let mipCount = IBLSystem.PrefilterMipLevels;

		// Prefilter params + face views
		for (int i = 0; i < mipCount * 6; i++)
		{
			if (PrefilterParamsBuffers[i] != null) device.DestroyBuffer(ref PrefilterParamsBuffers[i]);
			if (PrefilterFaceViews[i] != null) device.DestroyTextureView(ref PrefilterFaceViews[i]);
		}

		// Irradiance params + face views
		for (int i = 0; i < 6; i++)
		{
			if (IrradianceParamsBuffers[i] != null) device.DestroyBuffer(ref IrradianceParamsBuffers[i]);
			if (IrradianceFaceViews[i] != null) device.DestroyTextureView(ref IrradianceFaceViews[i]);
		}

		// Prefilter cubemap
		if (PrefilterCubemapView != null) device.DestroyTextureView(ref PrefilterCubemapView);
		if (PrefilterCubemap != null) device.DestroyTexture(ref PrefilterCubemap);

		// Irradiance cubemap
		if (IrradianceCubemapView != null) device.DestroyTextureView(ref IrradianceCubemapView);
		if (IrradianceCubemap != null) device.DestroyTexture(ref IrradianceCubemap);

		// Captured cubemap
		for (int i = 0; i < 6; i++)
			if (CapturedFaceViews[i] != null) device.DestroyTextureView(ref CapturedFaceViews[i]);
		if (CapturedCubemapView != null) device.DestroyTextureView(ref CapturedCubemapView);
		if (CapturedCubemap != null) device.DestroyTexture(ref CapturedCubemap);
	}
}
