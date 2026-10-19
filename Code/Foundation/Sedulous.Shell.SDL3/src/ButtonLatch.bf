namespace Sedulous.Shell.SDL3;

/// One button's state and the edges the frame's events brought, latched until the next
/// frame begins.
///
/// A press and its release arriving in one frame (a quick click while a frame takes long)
/// read as both pressed and released, never as neither, which comparing the state at the
/// frame's two ends alone would give.
struct ButtonLatch
{
	public bool Down;
	public bool Pressed;
	public bool Released;

	public void Set(bool down) mut
	{
		if (down && !Down)
			Pressed = true;
		else if (!down && Down)
			Released = true;
		Down = down;
	}

	public void BeginFrame() mut
	{
		Pressed = false;
		Released = false;
	}
}
