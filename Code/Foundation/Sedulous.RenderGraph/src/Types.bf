using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Handle to a render graph resource (texture or buffer).
/// Validated via generation counter to detect stale handles.
public struct RGHandle : IHashable, IEquatable<RGHandle>
{
	public uint32 Index;
	public uint32 Generation;

	public const RGHandle Invalid = .(index: uint32.MaxValue, generation: 0);

	public this(uint32 index, uint32 generation)
	{
		Index = index;
		Generation = generation;
	}

	public bool IsValid => Index != uint32.MaxValue;

	public int GetHashCode()
	{
		return (int)(Index * 2654435761 ^ Generation);
	}

	public bool Equals(RGHandle other)
	{
		return Index == other.Index && Generation == other.Generation;
	}

	public static bool operator ==(RGHandle a, RGHandle b)
	{
		return a.Index == b.Index && a.Generation == b.Generation;
	}

	public static bool operator !=(RGHandle a, RGHandle b)
	{
		return !(a == b);
	}
}

/// Handle to a render graph pass
public struct PassHandle : IHashable, IEquatable<PassHandle>
{
	public uint32 Index;

	public const PassHandle Invalid = .(uint32.MaxValue);

	public this(uint32 index)
	{
		Index = index;
	}

	public bool IsValid => Index != uint32.MaxValue;

	public int GetHashCode()
	{
		return (int)Index;
	}

	public bool Equals(PassHandle other)
	{
		return Index == other.Index;
	}

	public static bool operator ==(PassHandle a, PassHandle b)
	{
		return a.Index == b.Index;
	}

	public static bool operator !=(PassHandle a, PassHandle b)
	{
		return a.Index != b.Index;
	}
}

/// Type of render graph pass
public enum RGPassType : uint8
{
	/// Render pass with color/depth targets and draw commands
	Render,
	/// Compute pass with dispatch commands
	Compute,
	/// Copy/transfer pass
	Copy
}

/// Type of resource access declared by a pass
public enum RGAccessType : uint8
{
	// --- Reads ---
	/// Sampled texture read in fragment or compute shader
	ReadTexture,
	/// Uniform or storage buffer read
	ReadBuffer,
	/// Depth/stencil read-only in shader
	ReadDepthStencil,
	/// Copy source
	ReadCopySrc,

	// --- Writes ---
	/// Render target (color attachment) write
	WriteColorTarget,
	/// Depth/stencil attachment write
	WriteDepthTarget,
	/// Storage (UAV) write
	WriteStorage,
	/// Copy destination
	WriteCopyDst,

	// --- Read + Write ---
	/// Storage (UAV) simultaneous read and write
	ReadWriteStorage
}

extension RGAccessType
{
	/// Whether this access type reads from the resource
	public bool IsRead
	{
		get
		{
			switch (this)
			{
			case .ReadTexture, .ReadBuffer, .ReadDepthStencil, .ReadCopySrc, .ReadWriteStorage:
				return true;
			default:
				return false;
			}
		}
	}

	/// Whether this access type writes to the resource
	public bool IsWrite
	{
		get
		{
			switch (this)
			{
			case .WriteColorTarget, .WriteDepthTarget, .WriteStorage, .WriteCopyDst, .ReadWriteStorage:
				return true;
			default:
				return false;
			}
		}
	}

	/// Map to the corresponding RHI ResourceState
	public ResourceState ToResourceState()
	{
		switch (this)
		{
		case .ReadTexture:      return .ShaderRead;
		case .ReadBuffer:       return .ShaderRead;
		case .ReadDepthStencil: return .DepthStencilRead;
		case .ReadCopySrc:      return .CopySrc;
		case .WriteColorTarget: return .RenderTarget;
		case .WriteDepthTarget: return .DepthStencilWrite;
		case .WriteStorage:     return .ShaderWrite;
		case .WriteCopyDst:     return .CopyDst;
		case .ReadWriteStorage: return .ShaderWrite | .ShaderRead;
		}
	}
}

/// Subresource range for fine-grained access tracking (e.g., individual shadow cascade layers)
public struct RGSubresourceRange : IEquatable<RGSubresourceRange>
{
	/// First mip level (0 = from start)
	public uint32 BaseMipLevel;
	/// Number of mip levels (0 = all remaining from BaseMipLevel)
	public uint32 MipLevelCount;
	/// First array layer (0 = from start)
	public uint32 BaseArrayLayer;
	/// Number of array layers (0 = all remaining from BaseArrayLayer)
	public uint32 ArrayLayerCount;

	/// Whole resource (all mips, all layers)
	public static RGSubresourceRange All => default;

	public this(uint32 baseMip, uint32 mipCount, uint32 baseLayer, uint32 layerCount)
	{
		BaseMipLevel = baseMip;
		MipLevelCount = mipCount;
		BaseArrayLayer = baseLayer;
		ArrayLayerCount = layerCount;
	}

	/// Whether this represents the whole resource
	public bool IsAll => BaseMipLevel == 0 && MipLevelCount == 0 && BaseArrayLayer == 0 && ArrayLayerCount == 0;

	/// Whether two subresource ranges overlap
	public bool Overlaps(RGSubresourceRange other, uint32 totalMips = 1, uint32 totalLayers = 1)
	{
		let myMipEnd = MipLevelCount == 0 ? totalMips : BaseMipLevel + MipLevelCount;
		let otherMipEnd = other.MipLevelCount == 0 ? totalMips : other.BaseMipLevel + other.MipLevelCount;
		let myLayerEnd = ArrayLayerCount == 0 ? totalLayers : BaseArrayLayer + ArrayLayerCount;
		let otherLayerEnd = other.ArrayLayerCount == 0 ? totalLayers : other.BaseArrayLayer + other.ArrayLayerCount;

		let mipOverlap = BaseMipLevel < otherMipEnd && other.BaseMipLevel < myMipEnd;
		let layerOverlap = BaseArrayLayer < otherLayerEnd && other.BaseArrayLayer < myLayerEnd;

		return mipOverlap && layerOverlap;
	}

	public bool Equals(RGSubresourceRange other)
	{
		return BaseMipLevel == other.BaseMipLevel && MipLevelCount == other.MipLevelCount &&
			   BaseArrayLayer == other.BaseArrayLayer && ArrayLayerCount == other.ArrayLayerCount;
	}
}

/// A single resource access declared by a pass
public struct RGResourceAccess
{
	/// The resource being accessed
	public RGHandle Handle = .Invalid;
	/// Type of access
	public RGAccessType Type;
	/// Subresource range (default = whole resource)
	public RGSubresourceRange Subresource;

	public this(RGHandle handle, RGAccessType type, RGSubresourceRange subresource = default)
	{
		Handle = handle;
		Type = type;
		Subresource = subresource;
	}

	/// Whether this access reads from the resource
	public bool IsRead => Type.IsRead;

	/// Whether this access writes to the resource
	public bool IsWrite => Type.IsWrite;

	/// Map to the corresponding RHI ResourceState
	public ResourceState ToResourceState() => Type.ToResourceState();
}

/// How transient resource dimensions are resolved relative to the graph output
public enum SizeMode : uint8
{
	/// Same dimensions as graph output
	FullSize,
	/// Half dimensions of graph output
	HalfSize,
	/// Quarter dimensions of graph output
	QuarterSize,
	/// Explicit custom dimensions
	Custom
}

/// Resource lifetime type
public enum RGResourceLifetime : uint8
{
	/// Per-frame, pooled and aliased
	Transient,
	/// Survives across frames, state tracked
	Persistent,
	/// External resource, per-frame, not owned
	Imported
}

/// Resource type (texture or buffer)
public enum RGResourceType : uint8
{
	Texture,
	Buffer
}
