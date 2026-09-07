namespace Sedulous.RHI;

struct MultisampleState
{
	/// Samples per pixel. One means no multisampling.
	public uint32 Count = 1;
	/// Which samples are written. All ones by default.
	public uint32 Mask = 0xFFFFFFFF;
	/// Derives coverage from the fragment's alpha, which is how foliage gets antialiased
	/// edges without sorting.
	public bool AlphaToCoverageEnabled = false;

	public this() {}
}
