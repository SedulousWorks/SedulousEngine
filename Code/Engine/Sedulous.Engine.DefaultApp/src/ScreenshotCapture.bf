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
	private uint32 mBytesPerRow = 0;
	private bool mBgra = false;

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

	/// Whether a surface format can be written as an 8 bit PNG.
	public static bool CanCapture(TextureFormat format)
	{
		switch (format)
		{
		case .RGBA8Unorm, .RGBA8UnormSrgb, .BGRA8Unorm, .BGRA8UnormSrgb:
			return true;
		default:
			return false;
		}
	}

	public static bool IsBgra(TextureFormat format)
	{
		return (format == .BGRA8Unorm) || (format == .BGRA8UnormSrgb);
	}

	/// Records the copy into `encoder` while `backbuffer` sits in the RenderTarget state,
	/// which is the state the host hands the frame over in and expects back. Disarms; false
	/// when nothing was armed, the format cannot be captured, or the readback buffer could not
	/// be made, each logged, so a silent no-op never passes for a screenshot.
	public bool Record(IDevice device, ICommandEncoder encoder, ITexture backbuffer,
		TextureFormat format, uint32 width, uint32 height)
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
			GlobalLog(.Error, scope $"Screenshot: backbuffer format {format} is not an 8 bit RGBA/BGRA surface");
			return false;
		}

		let bytesPerRow = (width * 4 + (cRowAlignment - 1)) & ~(cRowAlignment - 1);
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

		encoder.TransitionTexture(backbuffer, .RenderTarget, .CopySrc);
		var region = BufferTextureCopyRegion();
		region.BytesPerRow = bytesPerRow;
		region.RowsPerImage = height;
		region.TextureExtent = .(width, height, 1);
		encoder.CopyTextureToBuffer(backbuffer, mReadback, region);
		encoder.TransitionTexture(backbuffer, .CopySrc, .RenderTarget);

		mWidth = width;
		mHeight = height;
		mBytesPerRow = bytesPerRow;
		mBgra = IsBgra(format);
		mRecorded = true;
		return true;
	}

	/// Copies the aligned rows the GPU wrote into a tight RGBA8 image, swizzling BGRA.
	public static void UnpackRows(uint8* mapped, uint32 bytesPerRow, uint32 width, uint32 height,
		bool bgra, Span<uint8> outRgba)
	{
		for (uint32 y = 0; y < height; y++)
		{
			let src = mapped + (int)y * (int)bytesPerRow;
			let dst = outRgba.Ptr + (int)y * (int)width * 4;
			for (uint32 x = 0; x < width; x++)
			{
				let s = src + (int)x * 4;
				let d = dst + (int)x * 4;
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
		UnpackRows(mapped, mBytesPerRow, mWidth, mHeight, mBgra, .(rgba.Ptr, rgba.Count));
		mReadback.Unmap();

		outImage.ReplaceData(mWidth, mHeight, .RGBA8, .(rgba.Ptr, rgba.Count));
		let saved = ImageIO.SaveImage(outImage, mPath, .PNG);
		if (saved case .Err)
			GlobalLog(.Error, scope $"Screenshot: could not write '{mPath}'");
		else
			GlobalLog(.Information, scope $"Screenshot: wrote '{mPath}' ({mWidth}x{mHeight})");
		return saved;
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
