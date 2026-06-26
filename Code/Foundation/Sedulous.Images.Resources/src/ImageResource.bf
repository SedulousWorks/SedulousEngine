using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Images;

namespace Sedulous.Images.Resources;

/// CPU-side image resource wrapping an `Image`. Cooked at bootstrap /
/// editor time so the runtime never has to decode PNG / JPG / etc.
///
/// Text body (`.image`) carries the metadata: width, height, format,
/// color space. Pixel bytes live in the conventional
/// "<assetLocator>.bin" sidecar derived by `ImageResourceManager`. The
/// same shape `TextureResource` uses, but without sampler / shape /
/// mipmap fields - this is the raw 2D image data, not a sampler-bound
/// texture.
///
/// Loading via `ResourceSystem` replaces direct `ImageLoaderFactory`
/// use at runtime: applications that don't author images (just consume
/// cooked ones) can ship without an STB / SDL image loader registered.
class ImageResource : Resource
{
	public const int32 FileVersion = 1;

	public override ResourceType ResourceType => .("image");
	public override int32 SerializationVersion => FileVersion;

	private Image mImage;
	private bool mOwnsImage;

	/// Image dimensions / format / color-space mirrored as fields so the
	/// manager can rebuild the `Image` after reading the binary sidecar.
	/// Written from `mImage` on save; populated from disk on load.
	public int32 ImageWidth;
	public int32 ImageHeight;
	public int32 ImageFormat;
	public int32 ImageColorSpaceField;

	/// The underlying image data.
	public Image Image => mImage;

	public this()
	{
		mImage = null;
		mOwnsImage = false;
	}

	public this(Image image, bool ownsImage = false)
	{
		mImage = image;
		mOwnsImage = ownsImage;
	}

	public ~this()
	{
		if (mOwnsImage && mImage != null)
			delete mImage;
	}

	/// Sets the image. Takes ownership if `ownsImage` is true.
	public void SetImage(Image image, bool ownsImage = false)
	{
		if (mOwnsImage && mImage != null)
			delete mImage;
		mImage = image;
		mOwnsImage = ownsImage;
	}

	/// Hot-reload helper: updates the existing `Image`'s dimensions /
	/// format / pixel buffer in place instead of swapping the `Image`
	/// pointer. Outside references stay valid across reload. Allocates a
	/// new owned Image on first call (when `mImage` is null).
	public void UpdateImageInPlace(uint32 width, uint32 height, PixelFormat format, Span<uint8> data, ImageColorSpace colorSpace)
	{
		if (mImage == null)
		{
			mImage = new Image(width, height, format, null, colorSpace);
			mOwnsImage = true;
		}
		else
		{
			mImage.ColorSpace = colorSpace;
		}
		mImage.ReplaceData(width, height, format, data);
	}

	// ---- Serialization ----

	/// Reloads the image resource in place. Pixel sidecar is applied by
	/// the manager via `UpdateImageInPlace` so outside references stay
	/// valid.
	public override Result<void, ResourceLoadError> Reload(Serializer s)
	{
		let result = Serialize(s);
		if (result != .Ok)
			return .Err(.InvalidFormat);
		return .Ok;
	}

	/// Serialises image metadata only. Pixel bytes live in the binary
	/// sidecar handled by the manager.
	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting && mImage != null)
		{
			ImageWidth = (int32)mImage.Width;
			ImageHeight = (int32)mImage.Height;
			ImageFormat = (int32)mImage.Format;
			ImageColorSpaceField = (int32)mImage.ColorSpace;
		}

		s.Int32("width", ref ImageWidth);
		s.Int32("height", ref ImageHeight);
		s.Int32("format", ref ImageFormat);
		s.Int32("colorSpace", ref ImageColorSpaceField);

		return .Ok;
	}

	/// Writes the raw pixel bytes to `stream`. Caller writes the text
	/// metadata via `WriteToStream` and saves these bytes to the
	/// conventional "<assetLocator>.bin" sidecar.
	public Result<void> WritePixelsToStream(Stream stream)
	{
		if (mImage == null)
			return .Err;
		if (stream.TryWrite(mImage.Data) case .Err)
			return .Err;
		return .Ok;
	}
}
