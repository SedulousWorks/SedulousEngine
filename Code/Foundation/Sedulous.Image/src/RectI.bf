namespace Sedulous.Image;

/// An integer rectangle, for a region in pixel space.
struct RectI
{
	public int32 X;
	public int32 Y;
	public int32 Width;
	public int32 Height;

	public this() { X = 0; Y = 0; Width = 0; Height = 0; }

	public this(int32 x, int32 y, int32 width, int32 height)
	{
		X = x; Y = y; Width = width; Height = height;
	}
}
