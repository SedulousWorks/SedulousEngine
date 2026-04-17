namespace Sedulous.UI;

/// Pooled mouse wheel event args.
public class MouseWheelEventArgs
{
	public float X;           // mouse position
	public float Y;
	public float DeltaX;      // horizontal scroll
	public float DeltaY;      // vertical scroll
	public bool Handled;

	public void Reset()
	{
		X = 0; Y = 0;
		DeltaX = 0; DeltaY = 0;
		Handled = false;
	}
}
