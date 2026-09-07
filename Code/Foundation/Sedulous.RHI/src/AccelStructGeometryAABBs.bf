namespace Sedulous.RHI;

/// Bounding box geometry for a procedural bottom level build, where an intersection shader
/// decides what is actually inside each box.
struct AccelStructGeometryAABBs
{
	public IBuffer AabbBuffer = null;
	public uint64 Offset = 0;
	public uint32 Count = 0;
	/// Twenty four bytes, being six floats: the minimum and maximum corners.
	public uint32 Stride = 24;
	public GeometryFlags Flags = .Opaque;

	public this() {}
}
