namespace Sedulous.RHI;

/// The colour ClampToBorder reads. A fixed set rather than a free colour, because that is
/// all the hardware descriptor can encode.
enum SamplerBorderColor : uint32
{
	TransparentBlack,
	OpaqueBlack,
	OpaqueWhite
}
