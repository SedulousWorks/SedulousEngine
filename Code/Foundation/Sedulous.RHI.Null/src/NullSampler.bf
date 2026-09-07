using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullSampler : ISampler
{
	private SamplerDesc mDesc;
	public SamplerDesc Desc => mDesc;
	public void Initialize(SamplerDesc desc) => mDesc = desc;
}
