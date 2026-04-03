namespace Sedulous.Fonts;

/// A region within a font atlas texture
public struct AtlasRegion
{
	/// X position in atlas (pixels)
	public uint16 X;
	/// Y position in atlas (pixels)
	public uint16 Y;
	/// Width in atlas (pixels)
	public uint16 Width;
	/// Height in atlas (pixels)
	public uint16 Height;
	/// Offset from glyph origin to top-left of bitmap
	public float OffsetX;
	public float OffsetY;
	/// Advance width for this glyph
	public float AdvanceX;

	public this()
	{
		X = Y = Width = Height = 0;
		OffsetX = OffsetY = AdvanceX = 0;
	}

	public this(uint16 x, uint16 y, uint16 width, uint16 height, float offsetX, float offsetY, float advanceX)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
		OffsetX = offsetX;
		OffsetY = offsetY;
		AdvanceX = advanceX;
	}

	/// Calculate UV coordinates for this region given atlas dimensions
	public void GetUVs(uint32 atlasWidth, uint32 atlasHeight, out float u0, out float v0, out float u1, out float v1)
	{
		u0 = (float)X / atlasWidth;
		v0 = (float)Y / atlasHeight;
		u1 = (float)(X + Width) / atlasWidth;
		v1 = (float)(Y + Height) / atlasHeight;
	}

	public bool IsEmpty => Width == 0 || Height == 0;
}
