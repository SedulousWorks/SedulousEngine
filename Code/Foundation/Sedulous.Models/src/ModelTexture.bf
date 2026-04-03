using System;

namespace Sedulous.Models;

/// Texture wrapping mode
public enum TextureWrap
{
	Repeat,
	ClampToEdge,
	MirroredRepeat
}

/// Texture minification filter
public enum TextureMinFilter
{
	Nearest,
	Linear,
	NearestMipmapNearest,
	LinearMipmapNearest,
	NearestMipmapLinear,
	LinearMipmapLinear
}

/// Texture magnification filter
public enum TextureMagFilter
{
	Nearest,
	Linear
}

/// Texture sampler settings
public struct TextureSampler
{
	public TextureWrap WrapS = .Repeat;
	public TextureWrap WrapT = .Repeat;
	public TextureMinFilter MinFilter = .LinearMipmapLinear;
	public TextureMagFilter MagFilter = .Linear;

	public this()
	{
	}
}

/// Pixel format for decoded texture data
public enum TexturePixelFormat
{
	Unknown,
	R8,           // 1 byte per pixel (grayscale)
	RG8,          // 2 bytes per pixel
	RGB8,         // 3 bytes per pixel
	RGBA8,        // 4 bytes per pixel
	BGR8,         // 3 bytes per pixel (BGR order)
	BGRA8,        // 4 bytes per pixel (BGRA order)
}

/// A texture reference in a model
public class ModelTexture
{
	private String mName ~ delete _;
	private String mUri ~ delete _;
	private uint8[] mData ~ delete _;

	/// Image data format (e.g., "image/png", "image/jpeg")
	public String MimeType ~ delete _;

	/// Sampler index (-1 for default sampler)
	public int32 SamplerIndex = -1;

	/// Width in pixels (0 if not yet loaded)
	public int32 Width;

	/// Height in pixels (0 if not yet loaded)
	public int32 Height;

	/// Pixel format of decoded data
	public TexturePixelFormat PixelFormat = .Unknown;

	public StringView Name => mName;
	public StringView Uri => mUri;

	public this()
	{
		mName = new String();
		mUri = new String();
		MimeType = new String();
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	public void SetUri(StringView uri)
	{
		mUri.Set(uri);
	}

	/// Set embedded image data (takes ownership)
	public void SetData(uint8[] data)
	{
		delete mData;
		mData = data;
	}

	/// Get embedded image data
	public uint8* GetData()
	{
		if (mData == null || mData.Count == 0)
			return null;
		return &mData[0];
	}

	/// Get embedded image data size
	public int32 GetDataSize()
	{
		if (mData == null)
			return 0;
		return (int32)mData.Count;
	}

	/// Check if texture has embedded data
	public bool HasEmbeddedData => mData != null && mData.Count > 0;
}
