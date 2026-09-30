using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.RHI;

namespace Sedulous.Engine.DefaultApp;

/// The backbuffer to PNG capture behind DefaultApplication.CaptureScreenshot, the F11 hotkey
/// and the --screenshot flags.
///
/// The whole path: arm, copy the presented backbuffer inside the frame (RenderTarget to
/// CopySrc and back, so the host's own Present transition still holds), then once the GPU is
/// done map the 256 byte aligned rows into a tight RGBA8 image, swizzle a BGRA surface, and
/// write the PNG through the image loader.
///
/// Two halves so each is testable on its own: Record needs a live encoder and a copy capable
/// backbuffer (the Vulkan surface carries TRANSFER_SRC where the driver allows; the WebGPU
/// swapchain asks for CopySrc when the surface offers it); Complete needs only the mapped
/// bytes.
class ScreenshotCapture
{
	/// Vulkan and WebGPU buffer copy row pitch.
	public const uint32 cRowAlignment = 256;

	private String mPath = new .() ~ delete _;
	private bool mArmed = false;
	private bool mRecorded = false;
	private IBuffer mReadback = null;
	private uint64 mReadbackSize = 0;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	/// The size the PNG is written at, when not the captured one; nought is the captured.
	private uint32 mOutputWidth = 0;
	private uint32 mOutputHeight = 0;
	private uint32 mBytesPerRow = 0;
	private TextureFormat mFormat = .RGBA8Unorm;

	/// A capture left recorded at destruction was never completed; the owning application
	/// releases the buffer through Release(device) in its shutdown, since there is no device
	/// here.
	public ~this()
	{
		mRecorded = false;
	}

	/// Arms: the next Record copies the frame to `path`.
	public void Request(StringView path)
	{
		mPath.Set(path);
		mArmed = true;
	}

	public bool Armed => mArmed;
	/// A copy was recorded and awaits Complete once the GPU has run it.
	public bool Recorded => mRecorded;
	public StringView Path => mPath;

	/// Whether a surface format can be written as an 8 bit PNG: the 8 bit RGBA and BGRA
	/// surfaces straight through, and RGBA16Float, the viewports' LINEAR target (the tonemap
	/// and the UI both write linear there), encoded to sRGB bytes.
	public static bool CanCapture(TextureFormat format)
	{
		switch (format)
		{
		case .RGBA8Unorm, .RGBA8UnormSrgb, .BGRA8Unorm, .BGRA8UnormSrgb, .RGBA16Float:
			return true;
		default:
			return false;
		}
	}

	public static uint32 BytesPerPixel(TextureFormat format) => (format == .RGBA16Float) ? 8 : 4;

	public static bool IsBgra(TextureFormat format)
	{
		return (format == .BGRA8Unorm) || (format == .BGRA8UnormSrgb);
	}

	/// Records the copy into `encoder` while `backbuffer` sits in `state`, and leaves it there:
	/// RenderTarget for a presented backbuffer (the state the host hands the frame over in and
	/// expects back), ShaderRead for an editor viewport's finished colour target. Disarms; false
	/// when nothing was armed, the format cannot be captured, or the readback buffer could not
	/// be made, each logged, so a silent no-op never passes for a screenshot.
	/// `originX` / `originY` capture a sub rectangle of that size from there: a letterboxed
	/// game's image without its bars. `outputWidth` x `outputHeight` writes the PNG resampled
	/// to that size (the game's render resolution, whatever size it was shown at).
	public bool Record(IDevice device, ICommandEncoder encoder, ITexture backbuffer,
		TextureFormat format, uint32 width, uint32 height, ResourceState state = .RenderTarget,
		uint32 originX = 0, uint32 originY = 0, uint32 outputWidth = 0, uint32 outputHeight = 0)
	{
		if (!mArmed)
			return false;
		mArmed = false;

		if ((backbuffer == null) || (width == 0) || (height == 0))
		{
			GlobalLog(.Error, "Screenshot: no backbuffer to capture");
			return false;
		}
		if (!CanCapture(format))
		{
			GlobalLog(.Error, scope $"Screenshot: backbuffer format {format} is not an 8 bit RGBA/BGRA or an RGBA16Float surface");
			return false;
		}

		let bytesPerRow = (width * BytesPerPixel(format) + (cRowAlignment - 1)) & ~(cRowAlignment - 1);
		let needed = (uint64)bytesPerRow * height;
		if ((mReadback == null) || (mReadbackSize < needed))
		{
			Release(device);
			var desc = BufferDesc();
			desc.Size = needed;
			desc.Usage = .CopyDst;
			desc.Memory = .GpuToCpu;
			desc.Label = "screenshot.readback";
			if (!(device.CreateBuffer(desc) case .Ok(let readback)))
			{
				GlobalLog(.Error, scope $"Screenshot: could not create the {needed} byte readback buffer");
				mReadback = null;
				return false;
			}
			mReadback = readback;
			mReadbackSize = needed;
		}

		encoder.TransitionTexture(backbuffer, state, .CopySrc);
		var region = BufferTextureCopyRegion();
		region.BytesPerRow = bytesPerRow;
		region.RowsPerImage = height;
		region.TextureOrigin = .(originX, originY, 0);
		region.TextureExtent = .(width, height, 1);
		encoder.CopyTextureToBuffer(backbuffer, mReadback, region);
		encoder.TransitionTexture(backbuffer, .CopySrc, state);

		mWidth = width;
		mHeight = height;
		mOutputWidth = outputWidth;
		mOutputHeight = outputHeight;
		mBytesPerRow = bytesPerRow;
		mFormat = format;
		mRecorded = true;
		return true;
	}

	/// Copies the aligned rows the GPU wrote into a tight RGBA8 image: BGRA swizzled, a 16 bit
	/// float texel clamped to [0, 1] and sRGB encoded, as the editor encodes it for the screen
	/// (the float target holds linear values; alpha is coverage and stays linear).
	public static void UnpackRows(uint8* mapped, uint32 bytesPerRow, uint32 width, uint32 height,
		TextureFormat format, Span<uint8> outRgba)
	{
		let bgra = IsBgra(format);
		let half = format == .RGBA16Float;
		let bytesPerPixel = BytesPerPixel(format);
		for (uint32 y = 0; y < height; y++)
		{
			let src = mapped + (int)y * (int)bytesPerRow;
			let dst = outRgba.Ptr + (int)y * (int)width * 4;
			for (uint32 x = 0; x < width; x++)
			{
				let s = src + (int)x * (int)bytesPerPixel;
				let d = dst + (int)x * 4;
				if (half)
				{
					let texel = (uint16*)s;
					for (int c < 3)
					{
						let linear = Math.Clamp(PixelFormats.HalfToFloat(texel[c]), 0.0f, 1.0f);
						float encoded = LinearToSrgb(linear) * 255.0f + 0.5f;
						d[c] = (uint8)encoded;
					}
					d[3] = PixelFormats.HalfToUnorm8(texel[3]);
					continue;
				}
				d[0] = bgra ? s[2] : s[0];
				d[1] = s[1];
				d[2] = bgra ? s[0] : s[2];
				d[3] = s[3];
			}
		}
	}

	/// After the GPU has finished the recorded copy, which the caller waits for with a fence
	/// or WaitIdle: maps the readback, unpacks it into `outImage` as RGBA8 and writes the PNG
	/// at Path. Consumes the recording. The image is filled as well so a test can look at it.
	public Result<void, ErrorCode> Complete(IDevice device, Image outImage)
	{
		if (!mRecorded)
			return .Err(.Internal); // nothing recorded
		mRecorded = false;

		let mapped = (uint8*)mReadback.Map();
		if (mapped == null)
		{
			GlobalLog(.Error, "Screenshot: could not map the readback buffer");
			Release(device);
			return .Err(.Unknown);
		}

		let rgba = scope List<uint8>();
		rgba.Resize((int)mWidth * (int)mHeight * 4);
		UnpackRows(mapped, mBytesPerRow, mWidth, mHeight, mFormat, .(rgba.Ptr, rgba.Count));
		mReadback.Unmap();

		var width = mWidth;
		var height = mHeight;
		if ((mOutputWidth > 0) && (mOutputHeight > 0) && ((mOutputWidth != mWidth) || (mOutputHeight != mHeight)))
		{
			let resampled = scope List<uint8>();
			Resample(.(rgba.Ptr, rgba.Count), mWidth, mHeight, mOutputWidth, mOutputHeight, resampled);
			rgba.Clear();
			rgba.AddRange(resampled);
			width = mOutputWidth;
			height = mOutputHeight;
		}
		outImage.ReplaceData(width, height, .RGBA8, .(rgba.Ptr, rgba.Count));
		let saved = ImageIO.SaveImage(outImage, mPath, .PNG);
		if (saved case .Err)
			GlobalLog(.Error, scope $"Screenshot: could not write '{mPath}'");
		else
			GlobalLog(.Information, scope $"Screenshot: wrote '{mPath}' ({width}x{height})");
		return saved;
	}

	/// Bilinear, texel centres to texel centres, RGBA8 to RGBA8.
	public static void Resample(Span<uint8> source, uint32 sourceWidth, uint32 sourceHeight,
		uint32 width, uint32 height, List<uint8> outPixels)
	{
		outPixels.Resize((int)width * (int)height * 4);
		let sx = (float)sourceWidth / (float)width;
		let sy = (float)sourceHeight / (float)height;
		for (uint32 y < height)
		{
			let fy = Math.Clamp(((float)y + 0.5f) * sy - 0.5f, 0.0f, (float)(sourceHeight - 1));
			let y0 = (uint32)fy;
			let y1 = Math.Min(y0 + 1, sourceHeight - 1);
			let ty = fy - (float)y0;
			for (uint32 x < width)
			{
				let fx = Math.Clamp(((float)x + 0.5f) * sx - 0.5f, 0.0f, (float)(sourceWidth - 1));
				let x0 = (uint32)fx;
				let x1 = Math.Min(x0 + 1, sourceWidth - 1);
				let tx = fx - (float)x0;
				for (int c < 4)
				{
					let a = (float)source[((int)y0 * (int)sourceWidth + (int)x0) * 4 + c];
					let b = (float)source[((int)y0 * (int)sourceWidth + (int)x1) * 4 + c];
					let d = (float)source[((int)y1 * (int)sourceWidth + (int)x0) * 4 + c];
					let e = (float)source[((int)y1 * (int)sourceWidth + (int)x1) * 4 + c];
					let top = a + (b - a) * tx;
					let bottom = d + (e - d) * tx;
					outPixels[((int)y * (int)width + (int)x) * 4 + c] = (uint8)Math.Clamp(top + (bottom - top) * ty + 0.5f, 0.0f, 255.0f);
				}
			}
		}
	}

	/// Drops the readback buffer, for device teardown.
	public void Release(IDevice device)
	{
		if (mReadback != null)
			device.DestroyBuffer(ref mReadback);
		mReadback = null;
		mReadbackSize = 0;
		mRecorded = false;
	}
}
