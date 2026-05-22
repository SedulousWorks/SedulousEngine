using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Images;

namespace Sedulous.Textures.Resources;

/// CPU-side texture resource wrapping an Image.
/// Text metadata (filter, wrap, format) is serialized via Serialize().
/// Pixel data is a binary sidecar at "<assetLocator>.bin" (derived by
/// convention - not stored).
class TextureResource : Resource
{
	public const int32 FileVersion = 1;

	public override ResourceType ResourceType => .("texture");
	public override int32 SerializationVersion => FileVersion;

	private Image mImage;
	private bool mOwnsImage;

	/// Image dimensions and format - stored for deserialization (Image created by manager after loading sidecar).
	public int32 ImageWidth;
	public int32 ImageHeight;
	public int32 ImageFormat;

	/// The underlying image data.
	public Image Image => mImage;

	/// Texture shape (2D, cubemap, array, etc.).
	public TextureShape Shape = .Texture2D;

	/// Min filter mode.
	public TextureFilter MinFilter = .Linear;

	/// Mag filter mode.
	public TextureFilter MagFilter = .Linear;

	/// Wrap mode for U coordinate.
	public TextureWrap WrapU = .Repeat;

	/// Wrap mode for V coordinate.
	public TextureWrap WrapV = .Repeat;

	/// Wrap mode for W coordinate.
	public TextureWrap WrapW = .Repeat;

	/// Whether to generate mipmaps.
	public bool GenerateMipmaps = true;

	/// Anisotropic filtering level.
	public float Anisotropy = 1.0f;

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

	/// Sets the image. Takes ownership if ownsImage is true.
	public void SetImage(Image image, bool ownsImage = false)
	{
		if (mOwnsImage && mImage != null)
			delete mImage;
		mImage = image;
		mOwnsImage = ownsImage;
	}

	/// Hot-reload helper: updates the existing `Image`'s dimensions /
	/// format / pixel buffer in place instead of swapping the `Image`
	/// pointer. Outside references (texture upload caches, debug
	/// viewers) stay valid across reload. Allocates a new owned Image
	/// on first call (when `mImage` is null).
	public void UpdateImageInPlace(uint32 width, uint32 height, PixelFormat format, Span<uint8> data)
	{
		if (mImage == null)
		{
			mImage = new Image(width, height, format);
			mOwnsImage = true;
		}
		mImage.ReplaceData(width, height, format, data);
	}

	/// Setup for UI textures (no mipmaps, linear, clamped).
	public void SetupForUI()
	{
		Shape = .Texture2D;
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	/// Setup for sprite textures (nearest, clamped).
	public void SetupForSprite()
	{
		Shape = .Texture2D;
		MinFilter = .Nearest;
		MagFilter = .Nearest;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	/// Setup for 3D textures (mipmaps, linear, anisotropic).
	public void SetupFor3D()
	{
		Shape = .Texture2D;
		MinFilter = .MipmapLinear;
		MagFilter = .Linear;
		WrapU = .Repeat;
		WrapV = .Repeat;
		GenerateMipmaps = true;
		Anisotropy = 16.0f;
	}

	/// Setup for equirectangular skybox (2D HDR map, clamped, no mipmaps).
	public void SetupForEquirectangularSkybox()
	{
		Shape = .Texture2D;
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		WrapW = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	/// Setup for cubemap skybox (6-face cube, clamped, no mipmaps).
	public void SetupForCubemapSkybox()
	{
		Shape = .Cubemap;
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		WrapW = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	// ---- Serialization ----

	/// Reloads the texture resource in place. Re-reads the metadata
	/// (filters, dimensions, format) - the manager is responsible for
	/// re-applying the pixel sidecar through `UpdateImageInPlace`, which
	/// preserves the existing `Image` instance so outside references
	/// stay valid.
	public override Result<void, ResourceLoadError> Reload(Serializer s)
	{
		let result = Serialize(s);
		if (result != .Ok)
			return .Err(.InvalidFormat);
		return .Ok;
	}

	/// Serializes texture metadata (not pixel data - that's in the binary sidecar).
	protected override SerializationResult OnSerialize(Serializer s)
	{
		var shape = (int32)Shape;
		var minFilter = (int32)MinFilter;
		var magFilter = (int32)MagFilter;
		var wrapU = (int32)WrapU;
		var wrapV = (int32)WrapV;
		var wrapW = (int32)WrapW;
		var genMips = GenerateMipmaps;
		var aniso = Anisotropy;

		s.Int32("shape", ref shape);
		s.Int32("minFilter", ref minFilter);
		s.Int32("magFilter", ref magFilter);
		s.Int32("wrapU", ref wrapU);
		s.Int32("wrapV", ref wrapV);
		s.Int32("wrapW", ref wrapW);
		s.Bool("generateMipmaps", ref genMips);
		s.Float("anisotropy", ref aniso);

		if (s.IsReading)
		{
			Shape = (TextureShape)shape;
			MinFilter = (TextureFilter)minFilter;
			MagFilter = (TextureFilter)magFilter;
			WrapU = (TextureWrap)wrapU;
			WrapV = (TextureWrap)wrapV;
			WrapW = (TextureWrap)wrapW;
			GenerateMipmaps = genMips;
			Anisotropy = aniso;
		}

		// Image properties (stored as fields so the manager can create the Image after loading sidecar)
		if (s.IsWriting && mImage != null)
		{
			ImageWidth = (int32)mImage.Width;
			ImageHeight = (int32)mImage.Height;
			ImageFormat = (int32)mImage.Format;
		}

		s.Int32("width", ref ImageWidth);
		s.Int32("height", ref ImageHeight);
		s.Int32("format", ref ImageFormat);

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
