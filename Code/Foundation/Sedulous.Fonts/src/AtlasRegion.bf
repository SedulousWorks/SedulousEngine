using Sedulous.Core;

namespace Sedulous.Fonts;

/// Where one glyph lives in an atlas texture, and how to place it.
struct AtlasRegion
{
	public uint16 X, Y, Width, Height;
	public float OffsetX, OffsetY, AdvanceX;

	public this() { X = 0; Y = 0; Width = 0; Height = 0; OffsetX = 0; OffsetY = 0; AdvanceX = 0; }

	public this(uint16 x, uint16 y, uint16 width, uint16 height, float offsetX, float offsetY, float advanceX)
	{
		X = x; Y = y; Width = width; Height = height;
		OffsetX = offsetX; OffsetY = offsetY; AdvanceX = advanceX;
	}

	public bool IsEmpty => (Width == 0) || (Height == 0);

	/// The texture coordinates of this region, which depend on the atlas it sits in.
	public void GetUVs(uint32 atlasWidth, uint32 atlasHeight, out float u0, out float v0,
		out float u1, out float v1)
	{
		u0 = (float)X / (float)atlasWidth;
		v0 = (float)Y / (float)atlasHeight;
		u1 = (float)(X + Width) / (float)atlasWidth;
		v1 = (float)(Y + Height) / (float)atlasHeight;
	}
}
