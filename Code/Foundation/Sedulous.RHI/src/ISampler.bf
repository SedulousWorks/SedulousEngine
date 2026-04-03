namespace Sedulous.RHI;

/// A texture sampler.
/// Destroyed via IDevice.DestroySampler().
interface ISampler
{
	/// The descriptor this sampler was created with.
	SamplerDesc Desc { get; }
}
