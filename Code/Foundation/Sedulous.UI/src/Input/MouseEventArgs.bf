namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Pooled mouse event args. One instance reused per event type per frame
/// via Reset() to avoid allocation in the hot input path.
public class MouseEventArgs
{
	public float X;                 // position in UI logical coords
	public float Y;
	public MouseButton Button;
	public int32 ClickCount;        // 1 = single, 2 = double, etc.
	public bool Handled;

	public Vector2 Position => .(X, Y);

	public void Reset()
	{
		X = 0; Y = 0;
		Button = .Left;
		ClickCount = 0;
		Handled = false;
	}

	public void Set(float x, float y, MouseButton button = .Left, int32 clickCount = 1)
	{
		X = x; Y = y;
		Button = button;
		ClickCount = clickCount;
		Handled = false;
	}
}
