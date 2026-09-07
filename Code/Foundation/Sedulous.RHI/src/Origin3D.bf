namespace Sedulous.RHI;

/// A corner in texels, used as the start of a copy region.
struct Origin3D
{
	public uint32 X = 0;
	public uint32 Y = 0;
	public uint32 Z = 0;

	public this() {}

	public this(uint32 x, uint32 y = 0, uint32 z = 0)
	{
		X = x; Y = y; Z = z;
	}
}
