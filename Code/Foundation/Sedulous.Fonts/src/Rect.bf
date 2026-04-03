namespace Sedulous.Fonts;

/// Simple rectangle structure for glyph bounds
public struct Rect
{
	public float X, Y, Width, Height;

	public this()
	{
		X = Y = Width = Height = 0;
	}

	public this(float x, float y, float width, float height)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}

	public float Left => X;
	public float Top => Y;
	public float Right => X + Width;
	public float Bottom => Y + Height;

	public bool IsEmpty => Width <= 0 || Height <= 0;

	public bool Contains(float px, float py)
	{
		return px >= X && px < X + Width && py >= Y && py < Y + Height;
	}

	public static Rect FromBounds(float left, float top, float right, float bottom)
	{
		return .(left, top, right - left, bottom - top);
	}
}
