namespace Sedulous.Texture.Compression;

/// What a source texture is FOR, which is the SEMANTIC hint the format policy keys on.
///
/// Authored on the asset and never on the runtime struct: a model import sets it from the
/// material slot it arrived in, and a standalone import defaults to colour.
enum TextureUsage : uint8
{
	/// Albedo or interface art, in sRGB or linear colour.
	Color,
	/// A tangent space normal map, linear.
	Normal,
	/// A single channel mask, height or roughness.
	Mask,
	/// Linear radiance, which is BC6H unsigned on a BC target.
	HDR,
}
