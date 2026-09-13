namespace Sedulous.Geometry.Pipeline;

/// What the optimisation pass did, which the cook log prints and the cook tests assert.
struct MeshOptimizeStats
{
	/// The submeshes the reorder passes ran on.
	public uint32 TriangleSubmeshes = 0;
	public uint32 VerticesBefore = 0;
	/// Below the count before it when vertices no index referenced were compacted away.
	public uint32 VerticesAfter = 0;
	/// The average cache miss ratio over every triangle range.
	public float AcmrBefore = 0.0f;
	public float AcmrAfter = 0.0f;

	public this() {}
}
