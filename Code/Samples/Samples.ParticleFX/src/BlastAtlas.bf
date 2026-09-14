using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Samples.ParticleFX;

/// The explosion's 4x4 flipbook, generated on the CPU and uploaded once.
///
/// Generated rather than shipped, for the same reason the renderer generates its soft dot: the
/// point is the flipbook PLAYBACK, and a file on disk would only add something to go missing.
class BlastAtlas
{
	private const uint32 cColumns = 4;
	private const uint32 cRows = 4;
	private const uint32 cFrameSize = 64;
	private const uint32 cWidth = cColumns * cFrameSize;
	private const uint32 cHeight = cRows * cFrameSize;

	private IDevice mDevice = null;
	private ITexture mTexture = null;
	private ITextureView mView = null;

	/// The view to bind on the blast component, or null when the upload failed. THIS OBJECT
	/// owns the texture; Release must run while the device is still alive.
	public ITextureView View => mView;

	public this(IDevice device)
	{
		mDevice = device;
		if (device == null)
			return;

		TextureDesc textureDesc = .();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cWidth;
		textureDesc.Height = cHeight;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "particle.blastatlas";
		if (!(device.CreateTexture(textureDesc) case .Ok(out mTexture)))
			return;

		TextureViewDesc viewDesc = .();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.Dimension = .Texture2D;
		if (!(device.CreateTextureView(mTexture, viewDesc) case .Ok(out mView)))
			return;

		let pixels = new uint8[cWidth * cHeight * 4];
		defer delete pixels;
		Paint(pixels);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return;
		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return;
		defer queue.DestroyTransferBatch(ref batch);

		var layout = TextureDataLayout();
		layout.BytesPerRow = cWidth * 4;
		layout.RowsPerImage = cHeight;
		batch.WriteTexture(mTexture, pixels, layout, .(cWidth, cHeight, 1));
		batch.Submit().IgnoreError();
	}

	/// Freed EXPLICITLY rather than in a destructor, because the device has to outlive the
	/// texture and an application's fields are torn down in no particular order.
	public void Release()
	{
		if (mDevice == null)
			return;

		mDevice.WaitIdle();
		if (mView != null)
			mDevice.DestroyTextureView(ref mView);
		if (mTexture != null)
			mDevice.DestroyTexture(ref mTexture);
		mDevice = null;
	}

	/// Sixteen frames of an expanding, dissipating fireball. The radius grows and the whole
	/// frame fades, and the sine terms break the circle so it does not read as a disc.
	private static void Paint(uint8[] pixels)
	{
		for (uint32 frame < cColumns * cRows)
		{
			let column = frame % cColumns;
			let row = frame / cColumns;
			let t = (float)frame / (float)(cColumns * cRows - 1);
			let radius = 0.18f + 0.85f * t;
			let fade = Pow(1.0f - t, 0.6f);

			for (uint32 y < cFrameSize)
			{
				for (uint32 x < cFrameSize)
				{
					let nx = ((float)x + 0.5f) / cFrameSize * 2.0f - 1.0f;
					let ny = ((float)y + 0.5f) / cFrameSize * 2.0f - 1.0f;

					var distance = Sqrt(nx * nx + ny * ny);
					distance += 0.11f * Sin(nx * 9.0f + (float)frame * 0.8f)
						+ 0.11f * Cos(ny * 9.0f - (float)frame * 0.6f);

					var core = Math.Clamp(1.0f - distance / Math.Max(radius, 1.0e-3f), 0.0f, 1.0f);
					core *= core;

					// A white hot core grading to an orange rim: the green channel carries the
					// grade, and the blue only lifts in the very centre.
					let green = Math.Clamp(0.35f + 0.65f * core, 0.0f, 1.0f);
					let blue = Math.Clamp(0.12f * core * core, 0.0f, 1.0f);
					let alpha = core * fade;

					let index = (int)(((row * cFrameSize + y) * cWidth + (column * cFrameSize + x))
						* 4);
					pixels[index + 0] = 255;
					pixels[index + 1] = (uint8)(green * 255.0f);
					pixels[index + 2] = (uint8)(blue * 255.0f);
					pixels[index + 3] = (uint8)(alpha * 255.0f);
				}
			}
		}
	}
}
