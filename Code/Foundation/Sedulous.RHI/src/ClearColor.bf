namespace Sedulous.RHI;

/// A clear colour, in LINEAR space.
///
/// Linear because that is what the hardware writes: clearing an sRGB target with a value
/// picked in sRGB comes out visibly wrong, and the conversion belongs to whoever chose the
/// colour rather than here.
struct ClearColor
{
	public float R = 0.0f;
	public float G = 0.0f;
	public float B = 0.0f;
	public float A = 1.0f;

	public this() {}

	public this(float r, float g, float b, float a = 1.0f)
	{
		R = r; G = g; B = b; A = a;
	}

	public static ClearColor Black => .(0, 0, 0, 1);
	public static ClearColor White => .(1, 1, 1, 1);
	public static ClearColor CornflowerBlue => .(0.392f, 0.584f, 0.929f, 1.0f);
}
