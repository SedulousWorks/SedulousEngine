namespace Sedulous.RHI;

/// How a shader reads a texture through a view.
enum TextureViewDimension : uint32
{
	Texture1D,
	Texture1DArray,
	Texture2D,
	Texture2DArray,
	TextureCube,
	TextureCubeArray,
	Texture3D
}
