using System;
using Sedulous.RHI;

namespace Samples.Sandbox;

/// A checkerboard of opaque cells and fully transparent holes, uploaded once.
///
/// It exists to drive the masked material's alpha test: a colour alone would show nothing,
/// because what is being demonstrated is the DISCARD, and that needs real holes.
class CutoutTexture
{
	private const uint32 cSize = 64;
	private const uint32 cCell = 8;

	private IDevice mDevice = null;
	private ITexture mTexture = null;
	private ITextureView mView = null;

	/// Null when the upload failed, in which case the masked demo is skipped.
	public ITextureView View => mView;

	public this(IDevice device)
	{
		mDevice = device;
		if (device == null)
			return;

		TextureDesc textureDesc = .();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Depth = 1;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.MipLevelCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "masked.cutout";
		if (!(device.CreateTexture(textureDesc) case .Ok(out mTexture)))
			return;

		TextureViewDesc viewDesc = .();
		viewDesc.Format = .RGBA8UnormSrgb;
		viewDesc.Dimension = .Texture2D;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(device.CreateTextureView(mTexture, viewDesc) case .Ok(out mView)))
		{
			Release();
			return;
		}

		let pixels = new uint8[cSize * cSize * 4];
		defer delete pixels;
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				let solid = ((((x / cCell) + (y / cCell)) & 1) == 0);
				let index = (int)((y * cSize + x) * 4);
				pixels[index + 0] = 255;
				pixels[index + 1] = 255;
				pixels[index + 2] = 255;
				pixels[index + 3] = solid ? 255 : 0;
			}
		}

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return;
		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return;
		defer queue.DestroyTransferBatch(ref batch);

		var layout = TextureDataLayout();
		layout.BytesPerRow = cSize * 4;
		layout.RowsPerImage = cSize;
		batch.WriteTexture(mTexture, pixels, layout, .(cSize, cSize, 1));
		batch.Submit().IgnoreError();
	}

	/// EXPLICIT, because the device has to still be alive and a destructor gives no ordering.
	public void Release()
	{
		if (mDevice == null)
			return;

		if (mView != null)
			mDevice.DestroyTextureView(ref mView);
		if (mTexture != null)
			mDevice.DestroyTexture(ref mTexture);
		mDevice = null;
	}
}
