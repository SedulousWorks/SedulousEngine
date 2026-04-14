namespace Sedulous.RHI;

using System;

enum DeviceType
{
	Vulkan,
	DX12,
	Null
}

/// Type of command queue.
enum QueueType
{
	/// Supports graphics, compute, and transfer operations.
	Graphics,
	/// Supports compute and transfer operations.
	Compute,
	/// Transfer-only (DMA engine). Supports copy operations.
	Transfer,
}

/// Flags describing how a buffer will be used.
enum BufferUsage : uint32
{
	None            = 0,
	/// Buffer can be used as source for copy operations.
	CopySrc         = 1 << 0,
	/// Buffer can be used as destination for copy operations.
	CopyDst         = 1 << 1,
	/// Buffer can be used as a vertex buffer.
	Vertex          = 1 << 2,
	/// Buffer can be used as an index buffer.
	Index           = 1 << 3,
	/// Buffer can be used as a uniform (constant) buffer.
	Uniform         = 1 << 4,
	/// Buffer can be used as a storage buffer (SSBO / UAV).
	Storage         = 1 << 5,
	/// Buffer can be used for indirect draw/dispatch arguments.
	Indirect        = 1 << 6,
	/// Buffer can be used as input for acceleration structure builds (ray tracing extension).
	AccelStructInput = 1 << 7,
	/// Buffer can be used as a shader binding table (ray tracing extension).
	ShaderBindingTable = 1 << 8,
	/// Buffer can be used as scratch memory for acceleration structure builds (ray tracing extension).
	AccelStructScratch = 1 << 9,
}

/// Flags describing how a texture will be used.
enum TextureUsage : uint32
{
	None            = 0,
	/// Texture can be used as source for copy operations.
	CopySrc         = 1 << 0,
	/// Texture can be used as destination for copy operations.
	CopyDst         = 1 << 1,
	/// Texture can be sampled in shaders (SRV).
	Sampled         = 1 << 2,
	/// Texture can be used as a storage texture in shaders (UAV).
	Storage         = 1 << 3,
	/// Texture can be used as a color attachment in render passes.
	RenderTarget    = 1 << 4,
	/// Texture can be used as a depth/stencil attachment.
	DepthStencil    = 1 << 5,
	/// Texture can be used as an input attachment (Vulkan subpasses).
	InputAttachment = 1 << 6,
}

/// Memory location hint for resource allocation.
enum MemoryLocation
{
	/// GPU-only (DEVICE_LOCAL). Fastest for GPU access. Not CPU-visible.
	GpuOnly,
	/// CPU-visible, GPU-readable. For uniform buffers, dynamic vertex data.
	/// Vulkan: HOST_VISIBLE | HOST_COHERENT. DX12: Upload heap.
	CpuToGpu,
	/// GPU-writable, CPU-readable. For readback.
	/// Vulkan: HOST_VISIBLE | HOST_CACHED. DX12: Readback heap.
	GpuToCpu,
	/// Prefer GPU-only but fall back to CPU-visible if needed.
	Auto,
}

/// Resource state flags for pipeline barriers.
enum ResourceState : uint32
{
	Undefined           = 0,
	VertexBuffer        = 1 << 0,
	IndexBuffer         = 1 << 1,
	UniformBuffer       = 1 << 2,
	/// Shader read (SRV / sampled texture).
	ShaderRead          = 1 << 3,
	/// Shader write (UAV / storage texture).
	ShaderWrite         = 1 << 4,
	RenderTarget        = 1 << 5,
	DepthStencilWrite   = 1 << 6,
	DepthStencilRead    = 1 << 7,
	IndirectArgument    = 1 << 8,
	CopySrc             = 1 << 9,
	CopyDst             = 1 << 10,
	Present             = 1 << 11,
	InputAttachment     = 1 << 12,
	/// General layout — usable for any purpose but not optimal.
	General             = 1 << 13,
	/// Acceleration structure read (ray tracing extension).
	AccelStructRead     = 1 << 14,
	/// Acceleration structure build/update (ray tracing extension).
	AccelStructWrite    = 1 << 15,
}

/// Texture dimensionality.
enum TextureDimension
{
	Texture1D,
	Texture2D,
	Texture3D,
}

/// Texture view dimensionality.
enum TextureViewDimension
{
	Texture1D,
	Texture1DArray,
	Texture2D,
	Texture2DArray,
	TextureCube,
	TextureCubeArray,
	Texture3D,
}

/// Which aspect(s) of a texture to view.
enum TextureAspect : uint32
{
	/// All aspects (color, or depth+stencil for depth/stencil formats).
	All = 0,
	/// Depth plane only.
	DepthOnly = 1,
	/// Stencil plane only.
	StencilOnly = 2,
}

/// Shader stage flags.
enum ShaderStage : uint32
{
	None         = 0,
	Vertex       = 1 << 0,
	Fragment     = 1 << 1,
	Compute      = 1 << 2,
	// Extension stages — only meaningful when the corresponding extension is supported.
	Mesh         = 1 << 3,
	/// Amplification shader (DX12) / Task shader (Vulkan).
	Task         = 1 << 4,
	RayGen       = 1 << 5,
	ClosestHit   = 1 << 6,
	Miss         = 1 << 7,
	AnyHit       = 1 << 8,
	Intersection = 1 << 9,
	AllGraphics  = Vertex | Fragment,
	All          = Vertex | Fragment | Compute,
}

/// Type of resource binding in a bind group.
enum BindingType
{
	/// Uniform (constant) buffer.
	UniformBuffer,
	/// Read-only storage buffer (SSBO / StructuredBuffer).
	StorageBufferReadOnly,
	/// Read-write storage buffer (RWStructuredBuffer).
	StorageBufferReadWrite,
	/// Sampled texture (SRV).
	SampledTexture,
	/// Read-only storage texture.
	StorageTextureReadOnly,
	/// Read-write storage texture (UAV).
	StorageTextureReadWrite,
	/// Sampler.
	Sampler,
	/// Comparison sampler (for shadow maps).
	ComparisonSampler,
	/// Unbounded array of sampled textures (bindless).
	BindlessTextures,
	/// Unbounded array of samplers (bindless).
	BindlessSamplers,
	/// Unbounded array of storage buffers (bindless).
	BindlessStorageBuffers,
	/// Unbounded array of storage textures (bindless).
	BindlessStorageTextures,
	/// Acceleration structure for ray tracing (TLAS).
	AccelerationStructure,
}

/// Texture sampling filter mode.
enum FilterMode
{
	Nearest,
	Linear,
}

/// Mipmap sampling filter mode.
enum MipmapFilterMode
{
	Nearest,
	Linear,
}

/// Texture address (wrap) mode.
enum AddressMode
{
	Repeat,
	MirrorRepeat,
	ClampToEdge,
	ClampToBorder,
}

/// Border color when using ClampToBorder address mode.
enum SamplerBorderColor
{
	TransparentBlack,
	OpaqueBlack,
	OpaqueWhite,
}

/// Primitive topology for vertex assembly.
enum PrimitiveTopology
{
	PointList,
	LineList,
	LineStrip,
	TriangleList,
	TriangleStrip,
}

/// Winding order for front-facing triangles.
enum FrontFace
{
	/// Counter-clockwise.
	CCW,
	/// Clockwise.
	CW,
}

/// Triangle culling mode.
enum CullMode
{
	None,
	Front,
	Back,
}

/// Polygon fill mode.
enum FillMode
{
	Solid,
	Wireframe,
}

/// Comparison function for depth, stencil, and sampler operations.
enum CompareFunction
{
	Never,
	Less,
	Equal,
	LessEqual,
	Greater,
	NotEqual,
	GreaterEqual,
	Always,
}

/// Stencil operation.
enum StencilOperation
{
	Keep,
	Zero,
	Replace,
	IncrementClamp,
	DecrementClamp,
	Invert,
	IncrementWrap,
	DecrementWrap,
}

/// Blend factor.
enum BlendFactor
{
	Zero,
	One,
	Src,
	OneMinusSrc,
	SrcAlpha,
	OneMinusSrcAlpha,
	Dst,
	OneMinusDst,
	DstAlpha,
	OneMinusDstAlpha,
	SrcAlphaSaturated,
	Constant,
	OneMinusConstant,
}

/// Blend operation.
enum BlendOperation
{
	Add,
	Subtract,
	ReverseSubtract,
	Min,
	Max,
}

/// Load operation for render pass attachments.
enum LoadOp
{
	/// Preserve existing contents.
	Load,
	/// Clear to a specified value.
	Clear,
	/// Contents are undefined (backend may optimize).
	DontCare,
}

/// Store operation for render pass attachments.
enum StoreOp
{
	/// Write results to memory.
	Store,
	/// Contents may be discarded (backend may optimize).
	DontCare,
}

/// Index buffer element format.
enum IndexFormat
{
	UInt16,
	UInt32,
}

/// Vertex buffer step mode.
enum VertexStepMode
{
	/// Advance per vertex.
	Vertex,
	/// Advance per instance.
	Instance,
}

/// Vertex attribute format.
[AllowDuplicates]
enum VertexFormat
{
	// 8-bit
	Uint8x2, Uint8x4,
	Sint8x2, Sint8x4,
	Unorm8x2, Unorm8x4,
	Snorm8x2, Snorm8x4,
	// 16-bit
	Uint16x2, Uint16x4,
	Sint16x2, Sint16x4,
	Unorm16x2, Unorm16x4,
	Snorm16x2, Snorm16x4,
	Float16x2, Float16x4,
	// 32-bit scalar
	Float32, Float32x2, Float32x3, Float32x4,
	Uint32, Uint32x2, Uint32x3, Uint32x4,
	Sint32, Sint32x2, Sint32x3, Sint32x4,

	// Serenity-compatible aliases
	UByte2 = Uint8x2, UByte4 = Uint8x4,
	Byte2 = Sint8x2, Byte4 = Sint8x4,
	UByte2Normalized = Unorm8x2, UByte4Normalized = Unorm8x4,
	Byte2Normalized = Snorm8x2, Byte4Normalized = Snorm8x4,
	UShort2 = Uint16x2, UShort4 = Uint16x4,
	Short2 = Sint16x2, Short4 = Sint16x4,
	UShort2Normalized = Unorm16x2, UShort4Normalized = Unorm16x4,
	Short2Normalized = Snorm16x2, Short4Normalized = Snorm16x4,
	Half2 = Float16x2, Half4 = Float16x4,
	Float = Float32, Float2 = Float32x2, Float3 = Float32x3, Float4 = Float32x4,
	UInt = Uint32, UInt2 = Uint32x2, UInt3 = Uint32x3, UInt4 = Uint32x4,
	Int = Sint32, Int2 = Sint32x2, Int3 = Sint32x3, Int4 = Sint32x4,
}

/// Color channel write mask.
enum ColorWriteMask : uint8
{
	None  = 0,
	Red   = 1 << 0,
	Green = 1 << 1,
	Blue  = 1 << 2,
	Alpha = 1 << 3,
	All   = Red | Green | Blue | Alpha,
}

/// Swap chain presentation mode.
enum PresentMode
{
	/// No vsync, tearing possible.
	Immediate,
	/// Vsync with low-latency (triple buffering).
	Mailbox,
	/// Vsync, no tearing.
	Fifo,
	/// Vsync, but may tear if late.
	FifoRelaxed,
}

/// GPU adapter type.
enum AdapterType
{
	DiscreteGpu,
	IntegratedGpu,
	Cpu,
	Unknown,
}

/// Query type.
enum QueryType
{
	/// GPU timestamp.
	Timestamp,
	/// Occlusion query.
	Occlusion,
	/// Pipeline statistics.
	PipelineStatistics,
}

// ===== Ray Tracing Extension Enums =====

/// Acceleration structure type (ray tracing extension).
enum AccelStructType
{
	TopLevel,
	BottomLevel,
}

/// Geometry type in an acceleration structure (ray tracing extension).
enum GeometryType
{
	Triangles,
	AABBs,
}

/// Geometry flags for acceleration structure building (ray tracing extension).
enum GeometryFlags : uint32
{
	None = 0,
	/// Geometry is fully opaque — skip any-hit shaders.
	Opaque = 1 << 0,
	/// Guarantee at most one any-hit invocation per primitive.
	NoDuplicateAnyHitInvocation = 1 << 1,
}

/// Acceleration structure build flags (ray tracing extension).
enum AccelStructBuildFlags : uint32
{
	None = 0,
	/// Allow updating the acceleration structure after build.
	AllowUpdate = 1 << 0,
	/// Allow compacting the acceleration structure after build.
	AllowCompaction = 1 << 1,
	/// Optimize for trace performance.
	PreferFastTrace = 1 << 2,
	/// Optimize for build speed.
	PreferFastBuild = 1 << 3,
}
