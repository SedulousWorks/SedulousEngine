namespace Sedulous.UI.Runtime;

/// One icon at one size, placed in the atlas.
///
/// The coordinates are FINAL atlas coordinates. The render happens supersampled, so the cell is
/// scaled up on the way in and the box filter brings it back down.
struct IconBakeCell
{
	/// BORROWED: the drawable the caller handed in.
	public BakedSVGDrawable Drawable;
	public uint32 Size;
	public uint32 X;
	public uint32 Y;

	public this(BakedSVGDrawable drawable, uint32 size, uint32 x, uint32 y)
	{
		Drawable = drawable;
		Size = size;
		X = x;
		Y = y;
	}
}
