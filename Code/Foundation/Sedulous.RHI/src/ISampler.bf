namespace Sedulous.RHI;

/// Filtering, addressing and comparison state, bound separately from the texture it reads.
interface ISampler
{
	SamplerDesc Desc { get; }
}
