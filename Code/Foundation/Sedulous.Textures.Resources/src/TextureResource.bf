using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Imaging;

namespace Sedulous.Textures.Resources;

/// CPU-side texture resource wrapping an Image.
/// Text metadata (filter, wrap, format) is serialized via Serialize().
/// Pixel data is stored as a binary sidecar file referenced by BinaryPath.
class TextureResource : Resource
{
	public const int32 FileVersion = 1;

	public override ResourceType ResourceType => .("texture");
	public override int32 SerializationVersion => FileVersion;

	private Image mImage;
	private bool mOwnsImage;

	/// Relative path to the binary sidecar file (pixel data).
	/// Set during save, read during load.
	public String BinaryPath = new .() ~ delete _;

	/// Image dimensions and format - stored for deserialization (Image created by manager after loading sidecar).
	public int32 ImageWidth;
	public int32 ImageHeight;
	public int32 ImageFormat;

	/// The underlying image data.
	public Image Image => mImage;

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

	/// Setup for UI textures (no mipmaps, linear, clamped).
	public void SetupForUI()
	{
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
		MinFilter = .MipmapLinear;
		MagFilter = .Linear;
		WrapU = .Repeat;
		WrapV = .Repeat;
		GenerateMipmaps = true;
		Anisotropy = 16.0f;
	}

	/// Setup for skybox (clamped, no mipmaps).
	public void SetupForSkybox()
	{
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		WrapW = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	// ---- Serialization ----

	/// Serializes texture metadata (not pixel data - that's in the binary sidecar).
	protected override SerializationResult OnSerialize(Serializer s)
	{
		var minFilter = (int32)MinFilter;
		var magFilter = (int32)MagFilter;
		var wrapU = (int32)WrapU;
		var wrapV = (int32)WrapV;
		var wrapW = (int32)WrapW;
		var genMips = GenerateMipmaps;
		var aniso = Anisotropy;

		s.Int32("minFilter", ref minFilter);
		s.Int32("magFilter", ref magFilter);
		s.Int32("wrapU", ref wrapU);
		s.Int32("wrapV", ref wrapV);
		s.Int32("wrapW", ref wrapW);
		s.Bool("generateMipmaps", ref genMips);
		s.Float("anisotropy", ref aniso);

		if (s.IsReading)
		{
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

		// Binary sidecar path
		s.String("binaryPath", BinaryPath);

		return .Ok;
	}

	/// Saves text metadata via base class, then writes pixel data to binary sidecar.
	public override Result<void> SaveToFile(StringView path, Sedulous.Serialization.ISerializerProvider provider)
	{
		if (mImage == null)
			return .Err;

		// Set sidecar path (relative - just the filename with .bin appended)
		BinaryPath.Set(scope $"{path}.bin");

		// Write text metadata via base class
		if (base.SaveToFile(path, provider) case .Err)
			return .Err;

		// Write binary sidecar (raw pixel data)
		let binStream = scope FileStream();
		if (binStream.Create(BinaryPath, .Write) case .Err)
			return .Err;

		let pixelData = mImage.Data;
		binStream.Write(pixelData);

		return .Ok;
	}
}
