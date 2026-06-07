namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;


/// Pooled mouse event args. One instance reused per event type to avoid
/// allocation in the hot input path.
public class MouseEventArgs
{
	/// Position in UI logical coordinates.
	public float X;
	public float Y;

	/// Which button triggered the event.
	public MouseButton Button;

	/// Click count (1 = single, 2 = double, etc.).
	public int32 ClickCount;

	/// Modifier keys held during this event.
	public KeyModifiers Modifiers;

	/// Time of event in seconds (from frame clock).
	public float Timestamp;

	/// Set by handler to stop event propagation.
	public bool Handled;

	public Vector2 Position => .(X, Y);

	public void Reset()
	{
		X = 0; Y = 0;
		Button = .Left;
		ClickCount = 0;
		Modifiers = .None;
		Timestamp = 0;
		Handled = false;
	}

	public void Set(float x, float y, MouseButton button = .Left, int32 clickCount = 1,
		float timestamp = 0, KeyModifiers modifiers = .None)
	{
		X = x; Y = y;
		Button = button;
		ClickCount = clickCount;
		Modifiers = modifiers;
		Timestamp = timestamp;
		Handled = false;
	}
}
