namespace Sedulous.RHI;

using System;

/// RHI-wide limits.
static class RHILimits
{
	/// Maximum number of simultaneous color attachments in a render pass / pipeline.
	public const int MaxColorAttachments = 8;
}

/// 3D extent (width, height, depth).
struct Extent3D
{
	public uint32 Width;
	public uint32 Height;
	public uint32 Depth;

	public this()
	{
		Width = 0;
		Height = 0;
		Depth = 0;
	}

	public this(uint32 w, uint32 h = 1, uint32 d = 1)
	{
		Width = w;
		Height = h;
		Depth = d;
	}
}

/// 3D origin (texel offset) for copy operations.
struct Origin3D
{
	public uint32 X;
	public uint32 Y;
	public uint32 Z;

	public this(uint32 x = 0, uint32 y = 0, uint32 z = 0)
	{
		X = x;
		Y = y;
		Z = z;
	}
}

/// Clear color value.
struct ClearColor
{
	public float R, G, B, A;

	public this(float r, float g, float b, float a)
	{
		R = r;
		G = g;
		B = b;
		A = a;
	}

	public static ClearColor Black => .(0, 0, 0, 1);
	public static ClearColor White => .(1, 1, 1, 1);
	public static ClearColor CornflowerBlue => .(0.392f, 0.584f, 0.929f, 1);
}

/// Information about a GPU adapter.
/// Owns a heap-allocated Name string - caller must `delete` when done.
class AdapterInfo
{
	public String Name = new .() ~ delete _;
	public uint32 VendorId;
	public uint32 DeviceId;
	public AdapterType Type;
	public DeviceFeatures SupportedFeatures;
}

/// Device features and limits.
/// Query via IAdapter.GetInfo() before device creation, or IDevice.Features after.
struct DeviceFeatures
{
	// --- Feature flags ---

	/// Supports bindless descriptor indexing (large descriptor arrays, non-uniform access).
	public bool BindlessDescriptors;
	/// Supports GPU timestamp queries.
	public bool TimestampQueries;
	/// Supports pipeline statistics queries (vertex count, fragment invocations, etc.).
	public bool PipelineStatisticsQueries;
	/// Supports multi-draw indirect (drawCount > 1 in DrawIndirect/DrawIndexedIndirect).
	public bool MultiDrawIndirect;
	/// Supports clamping depth values instead of clipping.
	public bool DepthClamp;
	/// Supports wireframe fill mode.
	public bool FillModeWireframe;
	/// Supports BC (Block Compression) texture formats.
	public bool TextureCompressionBC;
	/// Supports ASTC texture formats.
	public bool TextureCompressionASTC;
	/// Supports different blend state per color attachment.
	public bool IndependentBlend;
	/// Supports multiple viewports and scissor rects.
	public bool MultiViewport;
	/// Whether the mesh shader extension is supported.
	public bool MeshShaders;
	/// Whether the ray tracing extension is supported.
	public bool RayTracing;

	// --- Limits ---

	/// Maximum number of bind groups per pipeline layout.
	public uint32 MaxBindGroups;
	/// Maximum number of bindings per bind group.
	public uint32 MaxBindingsPerGroup;
	/// Maximum push constant block size in bytes.
	public uint32 MaxPushConstantSize;
	/// Maximum 2D texture dimension (width or height).
	public uint32 MaxTextureDimension2D;
	/// Maximum number of array layers in a texture.
	public uint32 MaxTextureArrayLayers;
	/// Maximum compute workgroup size in X dimension.
	public uint32 MaxComputeWorkgroupSizeX;
	/// Maximum compute workgroup size in Y dimension.
	public uint32 MaxComputeWorkgroupSizeY;
	/// Maximum compute workgroup size in Z dimension.
	public uint32 MaxComputeWorkgroupSizeZ;
	/// Maximum number of workgroups per Dispatch dimension.
	public uint32 MaxComputeWorkgroupsPerDimension;
	/// Maximum buffer size in bytes.
	public uint64 MaxBufferSize;
	/// Minimum alignment (bytes) for dynamic uniform buffer offsets.
	public uint32 MinUniformBufferOffsetAlignment;
	/// Minimum alignment (bytes) for dynamic storage buffer offsets.
	public uint32 MinStorageBufferOffsetAlignment;
	/// Multiply GPU timestamp values by this to get nanoseconds.
	public uint32 TimestampPeriodNs;

	// --- Mesh shader limits (0 if not supported) ---

	/// Maximum vertices a mesh shader can output per workgroup.
	public uint32 MaxMeshOutputVertices;
	/// Maximum primitives a mesh shader can output per workgroup.
	public uint32 MaxMeshOutputPrimitives;
	/// Maximum workgroup size for mesh shaders.
	public uint32 MaxMeshWorkgroupSize;
	/// Maximum workgroup size for task (amplification) shaders.
	public uint32 MaxTaskWorkgroupSize;
}

/// Descriptor for device creation.
struct DeviceDesc
{
	/// Required features. Device creation fails if not supported.
	public DeviceFeatures RequiredFeatures;
	/// Number of graphics queues (default 1). Clamped to hardware max.
	public uint32 GraphicsQueueCount = 1;
	/// Number of dedicated compute queues (default 0).
	public uint32 ComputeQueueCount = 0;
	/// Number of dedicated transfer queues (default 0).
	public uint32 TransferQueueCount = 0;
	public StringView Label;

	public bool DeviceValidationEnabled = false;
}

/// Texture data layout for copy operations.
struct TextureDataLayout
{
	/// Byte offset into the source/destination buffer.
	public uint64 Offset;
	/// Number of bytes per row of texels.
	public uint32 BytesPerRow;
	/// Number of rows per image (for 3D textures / texture arrays).
	public uint32 RowsPerImage;
}

/// Region for texture-to-texture copies.
struct TextureCopyRegion
{
	/// Source mip level to copy from.
	public uint32 SrcMipLevel;
	/// Source array layer to copy from.
	public uint32 SrcArrayLayer;
	/// Destination mip level to copy into.
	public uint32 DstMipLevel;
	/// Destination array layer to copy into.
	public uint32 DstArrayLayer;
	/// Size of the region to copy (in texels).
	public Extent3D Extent;
}

/// Region for buffer-to-texture or texture-to-buffer copies.
struct BufferTextureCopyRegion
{
	/// Byte offset into the buffer.
	public uint64 BufferOffset;
	/// Bytes per row of texels in the buffer. Must be aligned to format block size.
	public uint32 BytesPerRow;
	/// Number of rows per image slice in the buffer (for 3D textures / arrays).
	public uint32 RowsPerImage;
	/// Mip level of the texture to copy.
	public uint32 TextureMipLevel;
	/// Array layer of the texture to copy.
	public uint32 TextureArrayLayer;
	/// Origin (texel offset) within the texture. Defaults to (0,0,0).
	public Origin3D TextureOrigin;
	/// Size of the texture region (in texels).
	public Extent3D TextureExtent;
}

/// Push constant range within a pipeline layout.
struct PushConstantRange
{
	/// Shader stages that access this range.
	public ShaderStage Stages;
	/// Byte offset within the push constant block.
	public uint32 Offset;
	/// Size in bytes.
	public uint32 Size;
}
