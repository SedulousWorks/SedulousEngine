namespace Sedulous.RHI;

/// One entry of a ray tracing pipeline's shader table.
///
/// The indices refer to the pipeline's `Stages` span. An unused slot is left at
/// UnusedShader rather than zero, since zero is a legitimate index.
struct RayTracingShaderGroup
{
	/// What an unset shader index reads as.
	public const uint32 UnusedShader = uint32.MaxValue;

	public RayTracingShaderGroupType Type = .General;
	public uint32 GeneralShaderIndex = UnusedShader;
	public uint32 ClosestHitShaderIndex = UnusedShader;
	public uint32 AnyHitShaderIndex = UnusedShader;
	public uint32 IntersectionShaderIndex = UnusedShader;

	public this() {}
}
