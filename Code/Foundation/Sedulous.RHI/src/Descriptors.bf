namespace Sedulous.RHI;

using System;

// =============================================================================
// Resource Descriptors
// =============================================================================

/// Describes a buffer to create.
struct BufferDesc
{
	/// Size of the buffer in bytes.
	public uint64 Size;
	/// How the buffer will be used.
	public BufferUsage Usage;
	/// Memory location hint.
	public MemoryLocation Memory = .GpuOnly;
	/// Debug label.
	public StringView Label;

	public this() { Size = 0; Usage = default; Label = default; }

	public this(uint64 size, BufferUsage usage, MemoryLocation memory = .GpuOnly, StringView label = default)
	{
		Size = size;
		Usage = usage;
		Memory = memory;
		Label = label;
	}
}

/// Describes a texture to create.
struct TextureDesc
{
	public TextureDimension Dimension = .Texture2D;
	public TextureFormat Format;
	public uint32 Width;
	public uint32 Height = 1;
	/// Depth for 3D textures. 1 for 2D/cube textures.
	public uint32 Depth = 1;
	/// Number of array layers. 6 for cubemaps, 6*N for cubemap arrays, 1 for non-array textures.
	public uint32 ArrayLayerCount = 1;
	/// Number of mip levels. 1 = no mipmaps.
	public uint32 MipLevelCount = 1;
	/// MSAA sample count. 1 = no multisampling.
	public uint32 SampleCount = 1;
	/// How the texture will be used (combination of flags).
	public TextureUsage Usage;
	/// Debug label.
	public StringView Label;

	/// Creates a 2D texture descriptor.
	public static Self Tex2D(TextureFormat format, uint32 width, uint32 height,
		TextureUsage usage, uint32 mipLevels = 1, StringView label = default) => .()
	{
		Dimension = .Texture2D, Format = format, Width = width, Height = height,
		Usage = usage, MipLevelCount = mipLevels, Label = label
	};

	/// Serenity-compatible alias: Texture2D(width, height, format, usage, mips).
	public static Self Texture2D(uint32 width, uint32 height, TextureFormat format,
		TextureUsage usage, uint32 mipLevels = 1, StringView label = default) =>
		Tex2D(format, width, height, usage, mipLevels, label);

	/// Creates a 2D texture array descriptor.
	public static Self Tex2DArray(TextureFormat format, uint32 width, uint32 height,
		uint32 arrayLayers, TextureUsage usage, uint32 mipLevels = 1, StringView label = default) => .()
	{
		Dimension = .Texture2D, Format = format, Width = width, Height = height,
		ArrayLayerCount = arrayLayers, Usage = usage, MipLevelCount = mipLevels, Label = label
	};

	/// Creates a cube map descriptor (6 array layers).
	public static Self Cube(TextureFormat format, uint32 size,
		TextureUsage usage, uint32 mipLevels = 1, StringView label = default) => .()
	{
		Dimension = .Texture2D, Format = format, Width = size, Height = size,
		ArrayLayerCount = 6, Usage = usage, MipLevelCount = mipLevels, Label = label
	};

	/// Serenity-compatible alias: Cubemap(size, format, usage, mips).
	public static Self Cubemap(uint32 size, TextureFormat format,
		TextureUsage usage, uint32 mipLevels = 1, StringView label = default) =>
		Cube(format, size, usage, mipLevels, label);

	/// Creates a 3D texture descriptor.
	public static Self Tex3D(TextureFormat format, uint32 width, uint32 height, uint32 depth,
		TextureUsage usage, uint32 mipLevels = 1, StringView label = default) => .()
	{
		Dimension = .Texture3D, Format = format, Width = width, Height = height,
		Depth = depth, Usage = usage, MipLevelCount = mipLevels, Label = label
	};

	/// Creates a render target descriptor.
	public static Self RenderTarget(TextureFormat format, uint32 width, uint32 height,
		uint32 sampleCount = 1, StringView label = default) => .()
	{
		Dimension = .Texture2D, Format = format, Width = width, Height = height,
		SampleCount = sampleCount, Usage = .RenderTarget | .Sampled, Label = label
	};

	/// Creates a depth buffer descriptor.
	public static Self DepthBuffer(TextureFormat format, uint32 width, uint32 height,
		uint32 sampleCount = 1, StringView label = default) => .()
	{
		Dimension = .Texture2D, Format = format, Width = width, Height = height,
		SampleCount = sampleCount, Usage = .DepthStencil | .Sampled, Label = label
	};
}

/// Describes a texture view to create.
/// A view selects a subset of a texture's mip levels and array layers.
struct TextureViewDesc
{
	/// Format override. .Undefined = inherit from texture.
	public TextureFormat Format;
	/// View dimension. Must be compatible with the texture's dimension.
	public TextureViewDimension Dimension = .Texture2D;
	/// First mip level accessible through this view.
	public uint32 BaseMipLevel = 0;
	/// Number of mip levels. 0 = all remaining from BaseMipLevel.
	public uint32 MipLevelCount = 1;
	/// First array layer accessible through this view.
	public uint32 BaseArrayLayer = 0;
	/// Number of array layers. 0 = all remaining from BaseArrayLayer.
	public uint32 ArrayLayerCount = 1;
	/// Which aspect to view. Only meaningful for depth/stencil formats.
	public TextureAspect Aspect = .All;
	/// Debug label.
	public StringView Label;
}

/// Describes a sampler to create.
/// Controls texture filtering, addressing, and LOD behavior.
struct SamplerDesc
{
	/// Filter used when texture is minified (texel > pixel).
	public FilterMode MinFilter = .Linear;
	/// Filter used when texture is magnified (texel < pixel).
	public FilterMode MagFilter = .Linear;
	/// Filter used between mip levels.
	public MipmapFilterMode MipmapFilter = .Linear;
	/// Addressing mode for U (horizontal) texture coordinate.
	public AddressMode AddressU = .Repeat;
	/// Addressing mode for V (vertical) texture coordinate.
	public AddressMode AddressV = .Repeat;
	/// Addressing mode for W (depth) texture coordinate.
	public AddressMode AddressW = .Repeat;
	/// Offset added to the computed mip LOD level.
	public float MipLodBias = 0;
	/// Minimum mip LOD level to use.
	public float MinLod = 0;
	/// Maximum mip LOD level to use.
	public float MaxLod = 1000;
	/// Maximum anisotropy level. 1 = no anisotropic filtering.
	public uint16 MaxAnisotropy = 1;
	/// Comparison function for comparison samplers (shadow maps). null = normal sampler.
	public CompareFunction? Compare;
	/// Border color used when address mode is ClampToBorder.
	public SamplerBorderColor BorderColor = .TransparentBlack;
	/// Debug label.
	public StringView Label;
}

/// Describes a shader module to create.
struct ShaderModuleDesc
{
	/// SPIR-V bytecode (Vulkan) or DXIL bytecode (DX12).
	public Span<uint8> Code;
	public StringView Label;
}

// =============================================================================
// Binding Descriptors
// =============================================================================

/// Describes a single binding within a bind group layout.
struct BindGroupLayoutEntry
{
	/// Binding index (matches shader binding).
	public uint32 Binding;
	/// Shader stages that can access this binding.
	public ShaderStage Visibility;
	/// Type of resource bound.
	public BindingType Type;
	/// Texture view dimension (for texture bindings).
	public TextureViewDimension TextureDimension = .Texture2D;
	/// Alias for TextureDimension (Serenity compatibility).
	public TextureViewDimension TextureViewDimension
	{
		get => TextureDimension;
		set mut => TextureDimension = value;
	}
	/// Whether the texture is multisampled (for texture bindings).
	public bool TextureMultisampled = false;
	/// Required format for storage textures. .Undefined = any compatible format.
	public TextureFormat StorageTextureFormat = .Undefined;
	/// Whether this buffer binding has a dynamic offset.
	public bool HasDynamicOffset = false;
	/// Structure byte stride for storage buffers. When non-zero, the backend
	/// creates a StructuredBuffer SRV/UAV with this stride (DX12). When zero
	/// (default), creates a raw buffer (ByteAddressBuffer/RWByteAddressBuffer).
	/// Vulkan ignores this (SSBOs are unstructured).
	public uint32 StorageBufferStride = 0;
	/// Number of bindings. 1 = single, >1 = array, uint32.MaxValue = bindless.
	public uint32 Count = 1;
	public StringView Label;

	/// Creates a uniform buffer binding.
	public static Self UniformBuffer(uint32 binding, ShaderStage visibility, bool dynamicOffset = false)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = .UniformBuffer;
		entry.HasDynamicOffset = dynamicOffset;
		entry.Count = 1;
		return entry;
	}

	/// Creates a sampled texture binding.
	public static Self SampledTexture(uint32 binding, ShaderStage visibility,
		TextureViewDimension dimension = .Texture2D)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = .SampledTexture;
		entry.TextureDimension = dimension;
		entry.Count = 1;
		return entry;
	}

	/// Creates a sampler binding.
	public static Self Sampler(uint32 binding, ShaderStage visibility)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = .Sampler;
		entry.Count = 1;
		return entry;
	}

	/// Creates a comparison sampler binding (for shadow maps).
	public static Self ComparisonSampler(uint32 binding, ShaderStage visibility)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = .ComparisonSampler;
		entry.Count = 1;
		return entry;
	}

	/// Creates a storage buffer binding.
	/// When structureByteStride > 0, the DX12 backend creates a StructuredBuffer
	/// SRV/UAV with that stride. When 0 (default), creates a raw buffer
	/// (ByteAddressBuffer/RWByteAddressBuffer).
	public static Self StorageBuffer(uint32 binding, ShaderStage visibility,
		bool readWrite = false, bool dynamicOffset = false, uint32 structureByteStride = 0)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = readWrite ? .StorageBufferReadWrite : .StorageBufferReadOnly;
		entry.HasDynamicOffset = dynamicOffset;
		entry.StorageBufferStride = structureByteStride;
		entry.Count = 1;
		return entry;
	}

	/// Creates a storage texture binding.
	public static Self StorageTexture(uint32 binding, ShaderStage visibility,
		TextureFormat format, bool readWrite = false,
		TextureViewDimension dimension = .Texture2D)
	{
		Self entry = default;
		entry.Binding = binding;
		entry.Visibility = visibility;
		entry.Type = readWrite ? .StorageTextureReadWrite : .StorageTextureReadOnly;
		entry.StorageTextureFormat = format;
		entry.TextureDimension = dimension;
		entry.Count = 1;
		return entry;
	}
}

/// Describes a bind group layout.
struct BindGroupLayoutDesc
{
	public Span<BindGroupLayoutEntry> Entries;
	public StringView Label;

	public this() { Entries = default; Label = default; }

	public this(Span<BindGroupLayoutEntry> entries, StringView label = default)
	{
		Entries = entries;
		Label = label;
	}
}

/// Describes a single resource binding within a bind group.
/// Entries are positional: entry[i] provides the resource for layout entry[i].
/// Only used for regular (non-bindless) bindings.
struct BindGroupEntry
{
	/// Buffer to bind (for buffer bindings).
	public IBuffer Buffer;
	/// Byte offset into the buffer.
	public uint64 BufferOffset;
	/// Size of the buffer range. 0 = entire buffer from offset.
	public uint64 BufferSize;
	/// Texture view to bind (for texture bindings).
	public ITextureView TextureView;
	/// Sampler to bind (for sampler bindings).
	public ISampler Sampler;
	/// Acceleration structure to bind (for ray tracing bindings).
	public IAccelStruct AccelStruct;

	/// Creates a buffer binding entry.
	public static Self Buffer(IBuffer buffer, uint64 offset = 0, uint64 size = 0)
	{
		Self entry = default;
		entry.Buffer = buffer;
		entry.BufferOffset = offset;
		entry.BufferSize = size;
		return entry;
	}

	/// Creates a texture view binding entry.
	public static Self Texture(ITextureView textureView)
	{
		Self entry = default;
		entry.TextureView = textureView;
		return entry;
	}

	/// Creates a texture binding entry (state hint ignored — for Serenity compatibility).
	public static Self Texture(ITextureView textureView, ResourceState stateHint)
	{
		Self entry = default;
		entry.TextureView = textureView;
		return entry;
	}

	/// Creates a sampler binding entry.
	public static Self Sampler(ISampler sampler)
	{
		Self entry = default;
		entry.Sampler = sampler;
		return entry;
	}

	/// Creates an acceleration structure binding entry (for ray tracing TLAS).
	public static Self AccelStruct(IAccelStruct accelStruct)
	{
		Self entry = default;
		entry.AccelStruct = accelStruct;
		return entry;
	}
}

/// Describes a single bindless descriptor update.
/// Used with IBindGroup.UpdateBindless() to write into bindless arrays.
struct BindlessUpdateEntry
{
	/// Index of the layout entry that defines the bindless array.
	public uint32 LayoutIndex;
	/// Array element index within the bindless array.
	public uint32 ArrayIndex;
	/// Buffer to bind (for storage buffer bindless arrays).
	public IBuffer Buffer;
	public uint64 BufferOffset;
	public uint64 BufferSize;
	/// Texture view to bind (for texture/storage texture bindless arrays).
	public ITextureView TextureView;
	/// Sampler to bind (for sampler bindless arrays).
	public ISampler Sampler;

	/// Creates a bindless texture update.
	public static Self Texture(uint32 layoutIndex, uint32 arrayIndex, ITextureView textureView)
	{
		Self entry = default;
		entry.LayoutIndex = layoutIndex;
		entry.ArrayIndex = arrayIndex;
		entry.TextureView = textureView;
		return entry;
	}

	/// Creates a bindless sampler update.
	public static Self Sampler(uint32 layoutIndex, uint32 arrayIndex, ISampler sampler)
	{
		Self entry = default;
		entry.LayoutIndex = layoutIndex;
		entry.ArrayIndex = arrayIndex;
		entry.Sampler = sampler;
		return entry;
	}

	/// Creates a bindless storage buffer update.
	public static Self StorageBuffer(uint32 layoutIndex, uint32 arrayIndex, IBuffer buffer, uint64 offset = 0, uint64 size = 0)
	{
		Self entry = default;
		entry.LayoutIndex = layoutIndex;
		entry.ArrayIndex = arrayIndex;
		entry.Buffer = buffer;
		entry.BufferOffset = offset;
		entry.BufferSize = size;
		return entry;
	}

	/// Creates a bindless storage texture update.
	public static Self StorageTexture(uint32 layoutIndex, uint32 arrayIndex, ITextureView textureView)
	{
		Self entry = default;
		entry.LayoutIndex = layoutIndex;
		entry.ArrayIndex = arrayIndex;
		entry.TextureView = textureView;
		return entry;
	}
}

/// Describes a bind group.
struct BindGroupDesc
{
	/// The layout this bind group conforms to.
	public IBindGroupLayout Layout;
	/// Resource binding entries.
	public Span<BindGroupEntry> Entries;
	public StringView Label;

	public this() { Layout = null; Entries = default; Label = default; }

	public this(IBindGroupLayout layout, Span<BindGroupEntry> entries, StringView label = default)
	{
		Layout = layout;
		Entries = entries;
		Label = label;
	}
}

// =============================================================================
// Pipeline Descriptors
// =============================================================================

/// Describes a pipeline layout (bind group layouts + push constant ranges).
struct PipelineLayoutDesc
{
	/// Bind group layouts, indexed by group number.
	public Span<IBindGroupLayout> BindGroupLayouts;
	/// Push constant ranges.
	public Span<PushConstantRange> PushConstantRanges;
	public StringView Label;

	public this() { BindGroupLayouts = default; PushConstantRanges = default; Label = default; }

	public this(Span<IBindGroupLayout> bindGroupLayouts, StringView label = default)
	{
		BindGroupLayouts = bindGroupLayouts;
		PushConstantRanges = default;
		Label = label;
	}
}

/// Describes a vertex attribute within a vertex buffer layout.
struct VertexAttribute
{
	/// Format of the attribute.
	public VertexFormat Format;
	/// Byte offset of this attribute within the vertex.
	public uint32 Offset;
	/// Shader input location.
	public uint32 ShaderLocation;

	public this()
	{
		Format = default;
		Offset = default;
		ShaderLocation = default;
	}

	public this(VertexFormat format, uint32 offset, uint32 shaderLocation)
	{
		Format = format;
		Offset = offset;
		ShaderLocation = shaderLocation;
	}
}

/// Describes the layout of a single vertex buffer.
struct VertexBufferLayout
{
	/// Byte stride between consecutive vertices.
	public uint32 Stride;
	/// Whether to advance per vertex or per instance.
	public VertexStepMode StepMode = .Vertex;
	/// Attributes within this buffer.
	public Span<VertexAttribute> Attributes;

	public this()
	{
		Stride = default;
		Attributes = default;
	}

	public this(uint32 stride, Span<VertexAttribute> attributes, VertexStepMode stepMode = .Vertex)
	{
		Stride = stride;
		Attributes = attributes;
		StepMode = stepMode;
	}
}

/// Describes a blend operation for a single color component pair.
struct BlendComponent
{
	public BlendFactor SrcFactor = .One;
	public BlendFactor DstFactor = .Zero;
	public BlendOperation Operation = .Add;

	public this() {}

	public this(BlendOperation operation, BlendFactor srcFactor, BlendFactor dstFactor)
	{
		Operation = operation;
		SrcFactor = srcFactor;
		DstFactor = dstFactor;
	}
}

/// Describes blend state for a color/alpha pair.
struct BlendState
{
	public BlendComponent Color;
	public BlendComponent Alpha;

	/// Standard alpha blending: srcAlpha * src + (1 - srcAlpha) * dst.
	public static BlendState AlphaBlend => .()
	{
		Color = .() { SrcFactor = .SrcAlpha, DstFactor = .OneMinusSrcAlpha, Operation = .Add },
		Alpha = .() { SrcFactor = .One, DstFactor = .OneMinusSrcAlpha, Operation = .Add }
	};

	/// Premultiplied alpha: src + (1 - srcAlpha) * dst.
	public static BlendState PremultipliedAlpha => .()
	{
		Color = .() { SrcFactor = .One, DstFactor = .OneMinusSrcAlpha, Operation = .Add },
		Alpha = .() { SrcFactor = .One, DstFactor = .OneMinusSrcAlpha, Operation = .Add }
	};

	/// Additive blending: src + dst.
	public static BlendState Additive => .()
	{
		Color = .() { SrcFactor = .One, DstFactor = .One, Operation = .Add },
		Alpha = .() { SrcFactor = .One, DstFactor = .One, Operation = .Add }
	};

	/// Multiply blending: src * dst.
	public static BlendState Multiply => .()
	{
		Color = .() { SrcFactor = .Dst, DstFactor = .Zero, Operation = .Add },
		Alpha = .() { SrcFactor = .DstAlpha, DstFactor = .Zero, Operation = .Add }
	};
}

/// Describes a color target (render target) for a pipeline.
struct ColorTargetState
{
	public TextureFormat Format;
	/// Blend state. null = blending disabled.
	public BlendState? Blend;
	public ColorWriteMask WriteMask = .All;

	public this() { Format = default; Blend = null; }

	public this(TextureFormat format)
	{
		Format = format;
		Blend = null;
	}

	public this(TextureFormat format, BlendState blend)
	{
		Format = format;
		Blend = blend;
	}
}

/// Describes a single face of stencil state.
struct StencilFaceState
{
	public CompareFunction Compare = .Always;
	public StencilOperation FailOp = .Keep;
	public StencilOperation DepthFailOp = .Keep;
	public StencilOperation PassOp = .Keep;
}

/// Describes depth/stencil state for a pipeline.
struct DepthStencilState
{
	public TextureFormat Format;
	public bool DepthTestEnabled = true;
	public bool DepthWriteEnabled = true;
	public CompareFunction DepthCompare = .Less;
	public bool StencilEnabled = false;
	public uint8 StencilReadMask = 0xFF;
	public uint8 StencilWriteMask = 0xFF;
	public StencilFaceState StencilFront;
	public StencilFaceState StencilBack;
	public int32 DepthBias = 0;
	public float DepthBiasSlopeScale = 0;
	public float DepthBiasClamp = 0;

	/// Depth test + write enabled (Less). Standard opaque rendering.
	public static DepthStencilState DepthDefault(TextureFormat format = .Depth24Plus) => .()
	{
		Format = format, DepthWriteEnabled = true, DepthCompare = .Less
	};

	/// Depth test enabled, write disabled. Uses LessEqual so fragments matching
	/// a depth prepass still pass. Also works for transparent objects after opaques.
	public static DepthStencilState DepthReadOnly(TextureFormat format = .Depth24Plus) => .()
	{
		Format = format, DepthWriteEnabled = false, DepthCompare = .LessEqual
	};

	/// Reversed-Z depth (GreaterEqual) + write. Better precision distribution.
	public static DepthStencilState DepthReversedZ(TextureFormat format = .Depth32Float) => .()
	{
		Format = format, DepthWriteEnabled = true, DepthCompare = .GreaterEqual
	};

	/// Depth disabled (no test, no write).
	public static DepthStencilState Disabled(TextureFormat format = .Depth24Plus) => .()
	{
		Format = format, DepthTestEnabled = false, DepthWriteEnabled = false, DepthCompare = .Always
	};

	/// Opaque preset: depth test + write, Less compare.
	public static DepthStencilState Opaque => DepthDefault();

	/// Transparent preset: depth test (LessEqual), no write.
	public static DepthStencilState Transparent => DepthReadOnly();

	/// Skybox preset: depth test (LessEqual), no write.
	public static DepthStencilState Skybox => DepthReadOnly();

	/// No depth attachment.
	public static DepthStencilState None => Disabled();
}

/// Describes primitive assembly state.
struct PrimitiveState
{
	public PrimitiveTopology Topology = .TriangleList;
	public FrontFace FrontFace = .CCW;
	public CullMode CullMode = .None;
	public FillMode FillMode = .Solid;
	public bool DepthClipEnabled = true;
}

/// Describes multisample state.
struct MultisampleState
{
	public uint32 Count = 1;
	public uint32 Mask = uint32.MaxValue;
	public bool AlphaToCoverageEnabled = false;
}

/// Describes a programmable shader stage.
struct ProgrammableStage
{
	/// Compiled shader module.
	public IShaderModule Module;
	/// Entry point function name.
	public StringView EntryPoint = "main";
	/// Shader stage type. Required for ray tracing pipelines where each stage
	/// must declare its type (RayGen, ClosestHit, Miss, etc.).
	/// For render/compute pipelines this is inferred from context and can be left as None.
	public ShaderStage Stage = .None;

	public this() { Module = null; EntryPoint = "main"; }

	public this(IShaderModule module, StringView entryPoint = "main")
	{
		Module = module;
		EntryPoint = entryPoint;
	}
}

/// Describes the vertex stage of a render pipeline.
struct VertexState
{
	/// Vertex shader stage.
	public ProgrammableStage Shader;
	/// Vertex buffer layouts.
	public Span<VertexBufferLayout> Buffers;

	public this() { Shader = .(); Buffers = default; }
}

/// Describes the fragment stage of a render pipeline.
struct FragmentState
{
	/// Fragment shader stage.
	public ProgrammableStage Shader;
	/// Color targets.
	public Span<ColorTargetState> Targets;

	public this() { Shader = .(); Targets = default; }
}

/// Describes a render (graphics) pipeline.
struct RenderPipelineDesc
{
	public IPipelineLayout Layout;
	/// Vertex stage.
	public VertexState Vertex;
	/// Fragment stage (optional for depth-only passes).
	public FragmentState? Fragment;
	public PrimitiveState Primitive = .();
	/// Depth/stencil state. null = no depth/stencil.
	public DepthStencilState? DepthStencil;
	public MultisampleState Multisample = .();
	/// Optional pipeline cache for faster creation.
	public IPipelineCache Cache;
	public StringView Label;

	public this()
	{
		Layout = null;
		Vertex = .();
		Fragment = null;
		Primitive = .();
		DepthStencil = null;
		Multisample = .();
		Cache = null;
		Label = default;
	}
}

/// Describes a compute pipeline.
struct ComputePipelineDesc
{
	public IPipelineLayout Layout;
	public ProgrammableStage Compute;
	/// Optional pipeline cache for faster creation.
	public IPipelineCache Cache;
	public StringView Label;

	public this()
	{
		Layout = null;
		Compute = default;
		Cache = null;
		Label = default;
	}

	public this(IPipelineLayout layout, IShaderModule module, StringView entryPoint = "main")
	{
		Layout = layout;
		Compute = .(module, entryPoint);
		Cache = null;
		Label = default;
	}
}

/// Describes a pipeline cache.
struct PipelineCacheDesc
{
	/// Initial data from a previous cache (via IPipelineCache.GetData()).
	/// Empty span = start fresh.
	public Span<uint8> InitialData;
	public StringView Label;
}

// =============================================================================
// Render Pass Descriptors
// =============================================================================

/// Describes a color attachment in a render pass.
struct ColorAttachment
{
	/// Texture view to render into.
	public ITextureView View;
	/// Texture view for MSAA resolve. null = no resolve.
	public ITextureView ResolveTarget;
	public LoadOp LoadOp = .Clear;
	public StoreOp StoreOp = .Store;
	public ClearColor ClearValue = .Black;
}

/// Describes a depth/stencil attachment in a render pass.
struct DepthStencilAttachment
{
	/// Texture view for depth/stencil.
	public ITextureView View;
	public LoadOp DepthLoadOp = .Clear;
	public StoreOp DepthStoreOp = .Store;
	public float DepthClearValue = 1.0f;
	public bool DepthReadOnly = false;
	public LoadOp StencilLoadOp = .Clear;
	public StoreOp StencilStoreOp = .Store;
	public uint32 StencilClearValue = 0;
	public bool StencilReadOnly = false;
}

typealias ColorAttachmentList = FixedList<ColorAttachment, const RHILimits.MaxColorAttachments>;

/// Describes a render pass.
struct RenderPassDesc
{
	/// Color attachments.
	public ColorAttachmentList ColorAttachments;
	/// Depth/stencil attachment. null = no depth/stencil.
	public DepthStencilAttachment? DepthStencilAttachment;
	/// Query set for timestamp queries at pass begin/end. null = no timestamps.
	public IQuerySet TimestampQuerySet;
	public uint32 BeginTimestampIndex;
	public uint32 EndTimestampIndex;
	public StringView Label;
}

// =============================================================================
// Swap Chain Descriptor
// =============================================================================

/// Describes a swap chain.
struct SwapChainDesc
{
	public uint32 Width;
	public uint32 Height;
	public TextureFormat Format = .BGRA8UnormSrgb;
	public PresentMode PresentMode = .Fifo;
	/// Number of back buffers (2 = double buffering, 3 = triple).
	public uint32 BufferCount = 2;
	public StringView Label;
}

// =============================================================================
// Barrier Descriptors
// =============================================================================

/// Describes a buffer state transition barrier.
struct BufferBarrier
{
	public IBuffer Buffer;
	public ResourceState OldState;
	public ResourceState NewState;
	public uint64 Offset = 0;
	/// uint64.MaxValue = whole buffer.
	public uint64 Size = uint64.MaxValue;
}

/// Describes a texture state transition barrier.
struct TextureBarrier
{
	public ITexture Texture;
	public ResourceState OldState;
	public ResourceState NewState;
	public uint32 BaseMipLevel = 0;
	/// uint32.MaxValue = all mip levels.
	public uint32 MipLevelCount = uint32.MaxValue;
	public uint32 BaseArrayLayer = 0;
	/// uint32.MaxValue = all array layers.
	public uint32 ArrayLayerCount = uint32.MaxValue;
}

/// Describes a global memory barrier.
struct MemoryBarrier
{
	public ResourceState OldState;
	public ResourceState NewState;
}

/// Groups barriers for a single pipeline barrier command.
struct BarrierGroup
{
	public Span<BufferBarrier> BufferBarriers;
	public Span<TextureBarrier> TextureBarriers;
	public Span<MemoryBarrier> MemoryBarriers;
}

// =============================================================================
// Query Descriptor
// =============================================================================

/// Describes a query set.
struct QuerySetDesc
{
	public QueryType Type;
	public uint32 Count;
	public StringView Label;
}
