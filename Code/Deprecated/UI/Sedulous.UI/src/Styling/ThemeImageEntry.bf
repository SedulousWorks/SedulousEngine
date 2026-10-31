using Sedulous.Image;

namespace Sedulous.UI;

/// One image in a ThemeImageSet.
struct ThemeImageEntry
{
	/// BORROWED: whoever loaded the image owns it.
	public ImageData Image = null;
	public NineSlice Slices = .();
	public bool IsNineSlice = false;

	public this() {}
}
