using Sedulous.Core;

namespace Sedulous.UI;

/// Mouse event data.
///
/// POOLED: one instance is reused per event type rather than allocated per event, because
/// this is the hot input path and a mouse move fires every frame.
///
/// Carries data ONLY, with no reference to the view it reached. That is what lets it sit
/// below View in the dependency graph.
class MouseEventArgs
{
	/// In UI logical coordinates.
	public float X = 0.0f;
	public float Y = 0.0f;
	public MouseButton Button = .Left;
	/// One is a single click, two a double, and so on.
	public int32 ClickCount = 0;
	public KeyModifiers Modifiers = .None;
	public float Timestamp = 0.0f;
	/// Set by a handler to stop the event propagating further.
	public bool Handled = false;
	public EventPhase Phase = .Target;

	public Float2 Position => .(X, Y);

	public void Reset()
	{
		X = 0.0f;
		Y = 0.0f;
		Button = .Left;
		ClickCount = 0;
		Modifiers = .None;
		Timestamp = 0.0f;
		Handled = false;
		Phase = .Target;
	}

	public void Set(float x, float y, MouseButton button = .Left, int32 clickCount = 1,
		float timestamp = 0.0f, KeyModifiers modifiers = .None)
	{
		X = x;
		Y = y;
		Button = button;
		ClickCount = clickCount;
		Modifiers = modifiers;
		Timestamp = timestamp;
		Handled = false;
		Phase = .Target;
	}
}
