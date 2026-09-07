namespace Sedulous.RHI;

/// How a pipeline assembles vertices into primitives.
enum PrimitiveTopology : uint32
{
	PointList,
	LineList,
	LineStrip,
	TriangleList,
	TriangleStrip
}
