namespace Sedulous.Fonts;

/// A rectangle in glyph and text layout space.
///
/// Distinct from Core's Rectangle for one load bearing reason: Contains here is HALF OPEN
/// on the right and bottom edges, where Core's includes them. Text hit testing runs over
/// adjacent glyph boxes, and an inclusive test makes a point on a shared edge fall inside
/// both of them, so a click between two characters picks whichever was asked first.
struct FontRect
{
	public float X;
	public float Y;
	public float Width;
	public float Height;

	public this() { X = 0; Y = 0; Width = 0; Height = 0; }
	public this(float x, float y, float width, float height)
	{
		X = x; Y = y; Width = width; Height = height;
	}

	public float Left => X;
	public float Top => Y;
	public float Right => X + Width;
	public float Bottom => Y + Height;

	public bool IsEmpty => (Width <= 0) || (Height <= 0);

	/// Half open: the right and bottom edges belong to the NEXT box along.
	public bool Contains(float x, float y)
		=> (x >= X) && (x < X + Width) && (y >= Y) && (y < Y + Height);

	public static FontRect FromBounds(float left, float top, float right, float bottom)
		=> .(left, top, right - left, bottom - top);
}
