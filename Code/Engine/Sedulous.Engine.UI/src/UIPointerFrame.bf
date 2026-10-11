namespace Sedulous.Engine.UI;

/// One frame of pointer for the UI: the mouse, or the first finger while one is down (its left
/// button held; where the mouse would report it). The frame a finger lifts is a release at its
/// last place, TouchLifted set.
struct UIPointerFrame
{
	public bool Present = false;
	public float X = 0.0f;
	public float Y = 0.0f;
	/// Left, right, middle.
	public bool[3] Buttons = .(false, false, false);
	public float ScrollX = 0.0f;
	public float ScrollY = 0.0f;
	/// Moved, pressed or scrolled this frame.
	public bool Used = false;
	/// The mouse is captured (look mode): aim through the centre.
	public bool Relative = false;
	/// A finger drives it: its edges are its own, not the mouse's.
	public bool Touch = false;
	/// The finger came down this frame: a press.
	public bool TouchBegan = false;
	/// It lifted this frame: a release.
	public bool TouchLifted = false;

	public this() {}
}
