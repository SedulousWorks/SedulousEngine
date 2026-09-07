namespace Sedulous.Model;

/// How a vertex element is stored, as opposed to what it means.
enum VertexElementFormat : uint32
{
	case Float;
	case Float2;
	case Float3;
	case Float4;
	case Byte4;
	case UShort2;
	case UShort4;
}
