using System;

namespace Sedulous.RHI;

struct RayTracingPipelineDesc
{
	public IPipelineLayout Layout = null;
	/// Every shader the pipeline contains. The groups below index into this.
	public Span<ProgrammableStage> Stages = default;
	public Span<RayTracingShaderGroup> Groups = default;

	/// How deep TraceRay may nest. Declared up front because the driver sizes the stack
	/// from it, and exceeding it is undefined rather than diagnosed.
	public uint32 MaxRecursionDepth = 1;
	public uint32 MaxPayloadSize = 0;
	public uint32 MaxAttributeSize = 0;

	public IPipelineCache Cache = null;
	public StringView Label = default;

	public this() {}
}
