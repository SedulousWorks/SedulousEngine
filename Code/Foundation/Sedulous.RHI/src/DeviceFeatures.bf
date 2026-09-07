namespace Sedulous.RHI;

/// What an adapter supports, and how far it will go.
///
/// The same type answers two questions: an adapter REPORTS its capabilities here, and a
/// DeviceDesc REQUESTS them here. That is deliberate, so a caller can copy what it read,
/// clear what it does not need, and hand it back.
///
/// This is also why creation calls carry no "not supported" reason: the question has its
/// own answer, and a caller is expected to ask before building something.
struct DeviceFeatures
{
	// ---- feature flags ----

	public bool BindlessDescriptors = false;
	public bool TimestampQueries = false;
	public bool PipelineStatisticsQueries = false;

	/// Begin and end an occlusion query anywhere inside a render pass. WebGPU cannot honour
	/// that shape until the pass descriptor declares its query set up front, so its backend
	/// reports false and callers gate on this.
	public bool OcclusionQueries = false;

	/// ClampToBorder addressing together with a border colour. Core WebGPU has no border
	/// sampling at all: its backend narrows to ClampToEdge and reports false here.
	public bool BorderSampling = false;

	public bool MultiDrawIndirect = false;
	public bool DepthClamp = false;
	public bool FillModeWireframe = false;
	public bool TextureCompressionBC = false;
	public bool TextureCompressionASTC = false;
	public bool IndependentBlend = false;
	public bool MultiViewport = false;
	public bool MeshShaders = false;
	public bool RayTracing = false;

	// ---- limits ----
	//
	// The defaults are the floor every backend is expected to clear, so a device that
	// reports nothing still describes something a caller can build against.

	public uint32 MaxBindGroups = 4;
	public uint32 MaxBindingsPerGroup = 16;
	public uint32 MaxPushConstantSize = 128;
	public uint32 MaxTextureDimension2D = 8192;
	public uint32 MaxTextureArrayLayers = 256;
	public uint32 MaxComputeWorkgroupSizeX = 256;
	public uint32 MaxComputeWorkgroupSizeY = 256;
	public uint32 MaxComputeWorkgroupSizeZ = 64;
	public uint32 MaxComputeWorkgroupsPerDimension = 65535;
	public uint32 MinUniformBufferOffsetAlignment = 256;
	public uint32 MinStorageBufferOffsetAlignment = 256;
	public uint32 TimestampPeriodNs = 1;
	public uint64 MaxBufferSize = 256 * 1024 * 1024;

	// ---- mesh shader limits ----
	//
	// Zero until a device reports mesh shader support, so reading these without checking
	// MeshShaders gives a bound nothing can satisfy rather than a plausible wrong number.

	public uint32 MaxMeshOutputVertices = 0;
	public uint32 MaxMeshOutputPrimitives = 0;
	public uint32 MaxMeshWorkgroupSize = 0;
	public uint32 MaxTaskWorkgroupSize = 0;

	public this() {}
}
