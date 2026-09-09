namespace Sedulous.Render;

/// One scene's run of probe records within the frame's shared buffer, which is what a view
/// offsets the shader's probe loop by.
struct ProbeRange
{
	public uint32 Base = 0;
	public uint32 Count = 0;

	public this() {}

	public this(uint32 first, uint32 count)
	{
		Base = first;
		Count = count;
	}
}
