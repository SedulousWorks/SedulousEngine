using System;
using Sedulous.RHI;

namespace Samples.Framework;

/// A depth texture and its view, recreated on resize.
///
/// Its own type because nearly every sample needs one and none of them need it to be
/// interesting: without this each would repeat the same create, destroy and resize dance.
class DepthBuffer
{
	public ITexture Texture = null;
	public ITextureView View = null;
	public TextureFormat Format = .Depth24PlusStencil8;

	/// Destroys whatever was there and builds a new one at this size.
	///
	/// Destroy first, unconditionally, so a resize cannot leak the previous pair and a first
	/// call still works.
	public Result<void> Recreate(IDevice device, uint32 width, uint32 height,
		uint32 sampleCount = 1)
	{
		Destroy(device);

		let textureDesc = TextureDesc.DepthBuffer(Format, width, height, sampleCount, "Depth");
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		Texture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = Format;
		viewDesc.Dimension = .Texture2D;
		viewDesc.BaseMipLevel = 0;
		viewDesc.MipLevelCount = 1;
		viewDesc.BaseArrayLayer = 0;
		viewDesc.ArrayLayerCount = 1;
		viewDesc.Label = "DepthView";
		if (!(device.CreateTextureView(Texture, viewDesc) case .Ok(let view)))
		{
			// The texture would otherwise be orphaned: nothing else holds it.
			device.DestroyTexture(ref Texture);
			return .Err;
		}
		View = view;
		return .Ok;
	}

	public void Destroy(IDevice device)
	{
		if (View != null)
			device.DestroyTextureView(ref View);
		if (Texture != null)
			device.DestroyTexture(ref Texture);
	}
}
