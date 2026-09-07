namespace Sedulous.RHI;

/// How a sampler filters BETWEEN mip levels. Separate from FilterMode because the two are
/// chosen independently: trilinear is Linear within and Linear between.
enum MipmapFilterMode : uint32
{
	Nearest,
	Linear
}
