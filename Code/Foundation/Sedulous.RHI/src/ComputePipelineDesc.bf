using System;

namespace Sedulous.RHI;

struct ComputePipelineDesc
{
	public IPipelineLayout Layout = null;
	public ProgrammableStage Compute = .();
	public IPipelineCache Cache = null;
	public StringView Label = default;

	public this() {}
}
