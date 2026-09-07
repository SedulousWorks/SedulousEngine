namespace Sedulous.Model;

/// How a mesh's indices are assembled into primitives.
///
/// Order follows Raptor's exactly. These values are stored, so reordering them
/// reinterprets every model already imported.
enum PrimitiveTopology : uint32
{
	case Triangles;
	case TriangleStrip;
	case Lines;
	case LineStrip;
	case Points;
}
