namespace Sedulous.Render;

/// A sub rectangle of a render target, in pixels. A width of zero means the whole target.
struct ViewportRect
{
	public int32 X = 0;
	public int32 Y = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;

	public this() {}

	public this(int32 x, int32 y, uint32 width, uint32 height)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}

	public bool IsFullTarget => Width == 0;
}
