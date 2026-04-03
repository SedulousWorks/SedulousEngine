namespace Sedulous.Textures;

/// Texture filtering mode.
enum TextureFilter
{
	Nearest,
	Linear,
	MipmapNearest,
	MipmapLinear
}

/// Texture wrap mode.
enum TextureWrap
{
	Repeat,
	ClampToEdge,
	ClampToBorder,
	MirroredRepeat
}