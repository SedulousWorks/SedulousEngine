using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Engine.GUI;

/// Where the pointer goes this frame: a root, and the point in it (a panel's in its pixels).
struct GuiInputTarget
{
	/// BORROWED: a tier's or a texture root's, which outlives the frame.
	public SceneRoot Root = null;
	/// In the root's pixels.
	public Float2 Point = .(0.0f, 0.0f);
	/// The point is not the pointer's own (a panel's, a fitted tier's).
	public bool Mapped = false;
	public bool Panel = false;

	public this() {}

	public this(SceneRoot root, Float2 point, bool mapped, bool panel)
	{
		Root = root;
		Point = point;
		Mapped = mapped;
		Panel = panel;
	}
}
