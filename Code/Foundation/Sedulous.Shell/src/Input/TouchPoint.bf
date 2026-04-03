namespace Sedulous.Shell.Input;

/// Represents a single touch point.
public struct TouchPoint
{
	/// Unique identifier for this touch/finger.
	public uint64 ID;
	/// X position in pixels.
	public float X;
	/// Y position in pixels.
	public float Y;
	/// Touch pressure (0.0 to 1.0).
	public float Pressure;

	public this(uint64 id, float x, float y, float pressure = 1.0f)
	{
		ID = id;
		X = x;
		Y = y;
		Pressure = pressure;
	}
}
