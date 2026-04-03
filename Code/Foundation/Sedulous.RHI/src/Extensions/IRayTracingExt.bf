namespace Sedulous.RHI;

using System;

// =============================================================================
// Ray Tracing Extension
// =============================================================================
// Provides hardware ray tracing support.
// Vulkan: VK_KHR_ray_tracing_pipeline + VK_KHR_acceleration_structure.
// DX12: DXR 1.1.
//
// Query support: `if (let rtExt = device.GetRayTracingExt())`
// A backend that does not support ray tracing returns null.

/// Describes an acceleration structure.
struct AccelStructDesc
{
	/// Bottom-level (geometry) or top-level (instances).
	public AccelStructType Type;
	/// Build flags (prefer fast trace, fast build, allow updates).
	public AccelStructBuildFlags Flags;
	/// Debug label.
	public StringView Label;
}

/// Triangle geometry for bottom-level acceleration structure building.
struct AccelStructGeometryTriangles
{
	public IBuffer VertexBuffer;
	public uint64 VertexOffset;
	public uint32 VertexCount;
	public uint32 VertexStride;
	/// Position format (typically Float32x3).
	public VertexFormat VertexFormat;
	/// null = non-indexed geometry.
	public IBuffer IndexBuffer;
	public uint64 IndexOffset;
	public uint32 IndexCount;
	public IndexFormat IndexFormat;
	/// Optional transform buffer (3x4 row-major float matrix). null = identity.
	public IBuffer TransformBuffer;
	public uint64 TransformOffset;
	public GeometryFlags Flags;
}

/// AABB geometry for bottom-level acceleration structure building.
struct AccelStructGeometryAABBs
{
	public IBuffer AABBBuffer;
	public uint64 Offset;
	public uint32 Count;
	/// Byte stride per AABB entry (minimum 24: 6x float32 for min/max).
	public uint32 Stride;
	public GeometryFlags Flags;
}

/// Shader group definition for a ray tracing pipeline.
struct RayTracingShaderGroup
{
	public enum GroupType
	{
		/// For ray generation, miss, or callable shaders.
		General,
		/// Hit group for triangle geometry.
		TrianglesHitGroup,
		/// Hit group for procedural (AABB) geometry.
		ProceduralHitGroup,
	}

	public GroupType Type;
	/// Index into the stages array for General groups. uint32.MaxValue = unused.
	public uint32 GeneralShaderIndex = uint32.MaxValue;
	/// Index into the stages array for closest-hit shader. uint32.MaxValue = unused.
	public uint32 ClosestHitShaderIndex = uint32.MaxValue;
	/// Index into the stages array for any-hit shader. uint32.MaxValue = unused.
	public uint32 AnyHitShaderIndex = uint32.MaxValue;
	/// Index into the stages array for intersection shader (procedural only). uint32.MaxValue = unused.
	public uint32 IntersectionShaderIndex = uint32.MaxValue;
}

/// Describes a ray tracing pipeline.
struct RayTracingPipelineDesc
{
	public IPipelineLayout Layout;
	/// All shader stages used by this pipeline.
	public Span<ProgrammableStage> Stages;
	/// Shader groups (ray gen, miss, hit groups).
	public Span<RayTracingShaderGroup> Groups;
	/// Maximum ray recursion depth.
	public uint32 MaxRecursionDepth = 1;
	/// Maximum payload size in bytes. DX12 only; ignored on Vulkan. 0 = backend default (32).
	public uint32 MaxPayloadSize = 0;
	/// Maximum hit attribute size in bytes. DX12 only; ignored on Vulkan. 0 = backend default (8, for triangle barycentrics).
	/// Must be increased for procedural geometry with custom intersection attributes larger than 8 bytes.
	public uint32 MaxAttributeSize = 0;
	public IPipelineCache Cache;
	public StringView Label;
}

/// Extension interface for ray tracing support.
interface IRayTracingExt
{
	// --- Acceleration Structures ---

	/// Creates an acceleration structure.
	Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc);

	/// Destroys an acceleration structure.
	void DestroyAccelStruct(ref IAccelStruct accelStruct);

	// --- Pipelines ---

	/// Creates a ray tracing pipeline.
	Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc);

	/// Destroys a ray tracing pipeline.
	void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline);

	// --- Shader Binding Table ---

	/// Gets shader group handle data for building shader binding tables (SBTs).
	/// Write the returned data into a GPU buffer to form the SBT.
	Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline,
		uint32 firstGroup, uint32 groupCount, Span<uint8> outData);

	/// Size of a single shader group handle in bytes.
	uint32 ShaderGroupHandleSize { get; }

	/// Required alignment for individual shader group handles.
	uint32 ShaderGroupHandleAlignment { get; }

	/// Required alignment for the base of the SBT buffer.
	uint32 ShaderGroupBaseAlignment { get; }
}

/// An acceleration structure (BLAS or TLAS).
interface IAccelStruct
{
	/// Type of this acceleration structure.
	AccelStructType Type { get; }

	/// GPU device address for referencing this acceleration structure
	/// (e.g. when building a TLAS from BLAS instances).
	uint64 DeviceAddress { get; }
}

/// A compiled ray tracing pipeline.
interface IRayTracingPipeline
{
	IPipelineLayout Layout { get; }
}

/// Extension to ICommandEncoder for ray tracing commands.
/// Check support by casting: `if (let rtEncoder = encoder as IRayTracingEncoderExt)`
interface IRayTracingEncoderExt
{
	/// Builds a bottom-level acceleration structure from geometry.
	void BuildBottomLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		Span<AccelStructGeometryTriangles> triangleGeometries,
		Span<AccelStructGeometryAABBs> aabbGeometries);

	/// Builds a top-level acceleration structure from instances.
	void BuildTopLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount);

	/// Sets the ray tracing pipeline.
	void SetRayTracingPipeline(IRayTracingPipeline pipeline);

	/// Binds a bind group for ray tracing.
	void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default);

	/// Sets push constants for ray tracing.
	void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data);

	/// Traces rays using the bound pipeline and shader binding table buffers.
	void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1);
}
