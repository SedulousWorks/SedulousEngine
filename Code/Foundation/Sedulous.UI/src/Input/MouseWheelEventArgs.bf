namespace Sedulous.UI;

/// Mouse wheel event data. Pooled, like the rest of the event args.
class MouseWheelEventArgs
{
	public float X = 0.0f;
	public float Y = 0.0f;
	/// Positive scrolls up, or right.
	public float DeltaX = 0.0f;
	public float DeltaY = 0.0f;
	public KeyModifiers Modifiers = .None;
	public bool Handled = false;
	public EventPhase Phase = .Target;

	public void Reset()
	{
		X = 0.0f;
		Y = 0.0f;
		DeltaX = 0.0f;
		DeltaY = 0.0f;
		Modifiers = .None;
		Handled = false;
		Phase = .Target;
	}
}
