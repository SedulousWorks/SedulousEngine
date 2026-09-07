using System;

namespace Sedulous.RHI;

struct PipelineLayoutDesc
{
	/// In binding order: index zero here is group zero in the shader.
	public Span<IBindGroupLayout> BindGroupLayouts = default;
	public Span<PushConstantRange> PushConstantRanges = default;
	public StringView Label = default;

	public this() {}
}
