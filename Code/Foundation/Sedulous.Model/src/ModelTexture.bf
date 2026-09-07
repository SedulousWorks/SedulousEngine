using System;
using System.Collections;

namespace Sedulous.Model;

/// A texture a model refers to, either by URI or as embedded bytes.
///
/// The embedded data is the ENCODED file, a PNG or a JPEG, not decoded pixels: width,
/// height and format stay zero and Unknown until something decodes it.
class ModelTexture
{
	public String Name = new .() ~ delete _;
	public String Uri = new .() ~ delete _;
	/// The encoded form, such as "image/png".
	public String MimeType = new .() ~ delete _;

	/// Index into the model's samplers, or -1 for the default.
	public int32 SamplerIndex = -1;

	public int32 Width;
	public int32 Height;
	public TexturePixelFormat PixelFormat = .Unknown;

	private List<uint8> mData = new .() ~ delete _;

	/// The embedded bytes, empty when the texture is referenced by URI instead.
	public Span<uint8> Data => .(mData.Ptr, mData.Count);
	public int DataSize => mData.Count;
	public bool HasEmbeddedData => !mData.IsEmpty;

	/// Copies the encoded bytes in. Passing nothing clears them.
	public void SetData(Span<uint8> data)
	{
		mData.Clear();
		if (data.Length > 0)
		{
			mData.Resize(data.Length);
			Internal.MemCpy(mData.Ptr, data.Ptr, data.Length);
		}
	}
}
