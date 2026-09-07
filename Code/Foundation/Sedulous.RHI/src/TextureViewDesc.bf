using System;

namespace Sedulous.RHI;

struct TextureViewDesc
{
	/// Undefined means the texture's own format, which is what a view usually wants. Naming
	/// a different one reinterprets, which is how an sRGB target is written as linear.
	public TextureFormat Format = .Undefined;
	public TextureViewDimension Dimension = .Texture2D;
	public uint32 BaseMipLevel = 0;
	public uint32 MipLevelCount = 1;
	public uint32 BaseArrayLayer = 0;
	public uint32 ArrayLayerCount = 1;
	public TextureAspect Aspect = .All;
	public StringView Label = default;

	public this() {}
}
