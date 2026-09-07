namespace Sedulous.Model;

/// What a vertex element means, as opposed to how it is stored.
enum VertexSemantic : uint32
{
	case Position;
	case Normal;
	case TexCoord;
	case Color;
	case Tangent;
	case Joints;
	case Weights;
}
