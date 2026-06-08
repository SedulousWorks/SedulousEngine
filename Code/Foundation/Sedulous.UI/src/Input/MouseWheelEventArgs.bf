namespace Sedulous.UI;

/// Pooled mouse wheel event args.
public class MouseWheelEventArgs
{
	/// Mouse position in UI logical coordinates.
	public float X;
	public float Y;

	/// Scroll deltas (positive = scroll up/right).
	public float DeltaX;
	public float DeltaY;

	/// Modifier keys held during this event.
	public KeyModifiers Modifiers;

	/// Set by handler to stop event propagation.
	public bool Handled;

	/// Current phase of event propagation.
	public EventPhase Phase;

	public void Reset()
	{
		X = 0; Y = 0;
		DeltaX = 0; DeltaY = 0;
		Modifiers = .None;
		Handled = false;
		Phase = .Target;
	}
}
