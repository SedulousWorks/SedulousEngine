namespace Sedulous.RHI;

/// A transition of part of a texture between two uses.
struct TextureBarrier
{
	public ITexture Texture = null;
	public ResourceState OldState = .Undefined;
	public ResourceState NewState = .Undefined;
	public uint32 BaseMipLevel = 0;
	/// Every remaining level, by default.
	public uint32 MipLevelCount = uint32.MaxValue;
	public uint32 BaseArrayLayer = 0;
	public uint32 ArrayLayerCount = uint32.MaxValue;

	public this() {}
}
