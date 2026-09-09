namespace Sedulous.Render;

/// A rectangular tile within the shadow atlas, in pixels: the depth pass's viewport for one
/// caster.
struct AtlasTile
{
	public uint32 X = 0;
	public uint32 Y = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;

	public this() {}

	public this(uint32 x, uint32 y, uint32 width, uint32 height)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}
}
