namespace Sedulous.Geometry;

/// The topology a submesh is drawn with.
enum PrimitiveType : uint8
{
	case Triangles;
	case TriangleStrip;
	case TriangleFan;
	case Lines;
	case LineStrip;
	case Points;
}
