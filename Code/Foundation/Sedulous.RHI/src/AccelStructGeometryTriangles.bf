namespace Sedulous.RHI;

/// Triangle geometry for a bottom level build.
struct AccelStructGeometryTriangles
{
	public IBuffer VertexBuffer = null;
	public uint64 VertexOffset = 0;
	public uint32 VertexCount = 0;
	public uint32 VertexStride = 0;
	public VertexFormat VertexFormat = .Float32x3;

	/// Optional. Without it the vertices are taken as an unindexed triangle list.
	public IBuffer IndexBuffer = null;
	public uint64 IndexOffset = 0;
	public uint32 IndexCount = 0;
	public IndexFormat IndexFormat = .UInt32;

	/// An optional transform applied at build time, which bakes an instance's placement
	/// into the structure rather than carrying it on a top level instance.
	public IBuffer TransformBuffer = null;
	public uint64 TransformOffset = 0;

	public GeometryFlags Flags = .Opaque;

	public this() {}
}
