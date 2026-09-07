using System;

namespace Sedulous.RHI;

struct TextureDesc
{
	public TextureDimension Dimension = .Texture2D;
	public TextureFormat Format = .Undefined;
	public uint32 Width = 1;
	public uint32 Height = 1;
	public uint32 Depth = 1;
	public uint32 ArrayLayerCount = 1;
	public uint32 MipLevelCount = 1;
	public uint32 SampleCount = 1;
	public TextureUsage Usage = .None;
	public StringView Label = default;

	public this() {}

	/// A two dimensional colour target that is also sampled, which is what almost every
	/// intermediate render target is.
	public static TextureDesc RenderTarget(TextureFormat format, uint32 width, uint32 height,
		uint32 samples = 1, StringView label = default)
	{
		var d = TextureDesc();
		d.Format = format;
		d.Width = width;
		d.Height = height;
		d.SampleCount = samples;
		d.Usage = .RenderTarget | .Sampled;
		d.Label = label;
		return d;
	}

	/// A depth buffer. NOT sampled: add the usage explicitly if it will be read, since
	/// declaring it costs on some backends.
	public static TextureDesc DepthBuffer(TextureFormat format, uint32 width, uint32 height,
		uint32 samples = 1, StringView label = default)
	{
		var d = TextureDesc();
		d.Format = format;
		d.Width = width;
		d.Height = height;
		d.SampleCount = samples;
		d.Usage = .DepthStencil;
		d.Label = label;
		return d;
	}
}
