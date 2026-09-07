namespace Sedulous.RHI;

/// The shape of the texture's own storage.
///
/// Distinct from TextureViewDimension: a 2D texture with six array layers is stored as
/// Texture2D and may be VIEWED as a cube.
enum TextureDimension : uint32
{
	Texture1D,
	Texture2D,
	Texture3D
}
