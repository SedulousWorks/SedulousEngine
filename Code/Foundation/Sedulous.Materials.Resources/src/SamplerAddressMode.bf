namespace Sedulous.Materials.Resources;

/// Texture addressing mode for coordinates outside [0, 1].
/// Stored on MaterialResource for serialization. Converted to RHI AddressMode at runtime.
public enum SamplerAddressMode : int32
{
	/// Texture coordinates wrap around (tile).
	Repeat = 0,
	/// Texture coordinates mirror at boundaries.
	MirrorRepeat = 1,
	/// Texture coordinates are clamped to edge texels.
	ClampToEdge = 2,
	/// Texture coordinates outside range return border color.
	ClampToBorder = 3
}
