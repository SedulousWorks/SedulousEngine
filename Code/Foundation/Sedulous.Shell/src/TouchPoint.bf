namespace Sedulous.Shell;

/// One finger. The id follows a single contact from down to up, so a gesture can be
/// tracked across frames while other fingers come and go.
struct TouchPoint
{
	public uint64 Id;
	public float X;
	public float Y;
	public float Pressure = 1.0f;

	public this() { Id = 0; X = 0; Y = 0; Pressure = 1.0f; }

	public this(uint64 id, float x, float y, float pressure = 1.0f)
	{
		Id = id; X = x; Y = y; Pressure = pressure;
	}
}
