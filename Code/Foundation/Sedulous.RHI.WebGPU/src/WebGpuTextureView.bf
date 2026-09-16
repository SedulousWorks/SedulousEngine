using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A view onto a texture: which mips, which layers, read as which format.
class WebGpuTextureView : ITextureView
{
	private readonly uint64 mUniqueId = TextureViewIds.Next();
	private WGPUTextureView mHandle;
	private TextureViewDesc mDesc;
	private ITexture mTexture;

	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;
	public uint64 UniqueId => mUniqueId;
	public WGPUTextureView Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuTextureViewRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUTexture texture, ITexture owner, TextureViewDesc desc)
	{
		mDesc = desc;
		mTexture = owner;

		// A 1D array has no WebGPU spelling, so it fails here rather than silently
		// becoming something else.
		let dimension = WebGpuConversions.ToWgpuTextureViewDimension(desc.Dimension);
		if (dimension == .WGPUTextureViewDimension_Undefined)
			return .Err;

		WGPUTextureViewDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.format = WebGpuConversions.ToWgpuTextureFormat(desc.Format);
		wgpu.dimension = dimension;
		wgpu.baseMipLevel = desc.BaseMipLevel;
		wgpu.mipLevelCount = desc.MipLevelCount;
		wgpu.baseArrayLayer = desc.BaseArrayLayer;
		wgpu.arrayLayerCount = desc.ArrayLayerCount;
		wgpu.aspect = WebGpuConversions.ToWgpuTextureAspect(desc.Aspect);

		mHandle = wgpuTextureCreateView(texture, &wgpu);
		return (mHandle != null) ? .Ok : .Err;
	}
}
