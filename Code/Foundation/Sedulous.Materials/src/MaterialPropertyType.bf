namespace Sedulous.Materials;

/// The kind of a declared material property.
///
/// This is the whole point of the data driven model: a material DECLARES what it exposes,
/// and the material system infers the GPU bind group layout from the declarations. Scalars,
/// vectors and matrices pack into the material's uniform buffer; textures and samplers
/// become bind group entries of their own. A new material with a new shader then needs no
/// renderer change at all.
enum MaterialPropertyType : uint8
{
	case Float;
	case Float2;
	case Float3;
	case Float4;
	case Int;
	case Int2;
	case Int3;
	case Int4;
	case Matrix4x4;
	case Texture2D;
	case TextureCube;
	case Sampler;
}
