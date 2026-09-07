namespace Sedulous.RHI;

/// What a sampler does with a coordinate outside zero to one.
enum AddressMode : uint32
{
	Repeat,
	MirrorRepeat,
	ClampToEdge,
	/// Reads the sampler's border colour. Not supported everywhere, so a sampler using it
	/// should check the device first.
	ClampToBorder
}
