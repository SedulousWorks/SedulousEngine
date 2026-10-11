namespace Sedulous.Shell;

/// One finger. The id follows a single contact from down to up, so a gesture can be
/// tracked across frames while other fingers come and go; a browser numbers its first finger
/// 0, so 0 is a real id.
///
/// X and Y are NORMALIZED over the space its source's mouse reports in (0 to 1 across the
/// window, or the content a surface fits): what the touch bindings' regions read. PointerX and
/// PointerY are the same place in that mouse's own coordinates: what a pointer consumer, the UI,
/// reads, so a finger lands where the cursor would.
struct TouchPoint
{
	public uint64 Id;
	public float X;
	public float Y;
	public float Pressure = 1.0f;
	public float PointerX = 0.0f;
	public float PointerY = 0.0f;

	public this() { Id = 0; X = 0; Y = 0; Pressure = 1.0f; PointerX = 0; PointerY = 0; }

	public this(uint64 id, float x, float y, float pressure = 1.0f, float pointerX = 0.0f, float pointerY = 0.0f)
	{
		Id = id; X = x; Y = y; Pressure = pressure; PointerX = pointerX; PointerY = pointerY;
	}
}
