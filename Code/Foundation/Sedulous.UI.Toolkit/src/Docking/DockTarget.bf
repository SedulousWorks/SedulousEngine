using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// One drop zone offered during a dock drag: the chip you aim at, and what dropping there would
/// do.
struct DockTarget
{
	public DockPosition Position = .Center;
	/// The chip itself, which is what the pointer is tested against.
	public Rectangle Rect = .();
	/// BORROWED: the view this zone would dock relative to.
	public View RelativeTo = null;
	/// Where the panel would END UP, drawn as a translucent wash while this zone is hovered so
	/// the outcome is visible before committing. A zero area rectangle means no preview.
	public Rectangle PreviewRect = .();

	public this() {}
}
