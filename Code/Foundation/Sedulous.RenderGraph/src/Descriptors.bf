using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Describes a transient texture resource in the render graph
public struct RGTextureDesc
{
	/// Pixel format
	public TextureFormat Format;
	/// How dimensions are resolved relative to graph output
	public SizeMode SizeMode = .FullSize;
	/// Explicit width (only used when SizeMode == .Custom)
	public uint32 Width;
	/// Explicit height (only used when SizeMode == .Custom)
	public uint32 Height;
	/// Number of array layers
	public uint32 ArrayLayerCount = 1;
	/// Number of mip levels
	public uint32 MipLevelCount = 1;
	/// MSAA sample count
	public uint32 SampleCount = 1;
	/// Usage flags (graph may add flags as needed)
	public TextureUsage Usage = .None;

	public this(TextureFormat format, SizeMode sizeMode = .FullSize)
	{
		Format = format;
		SizeMode = sizeMode;
		Width = 0;
		Height = 0;
	}

	public this(TextureFormat format, uint32 width, uint32 height)
	{
		Format = format;
		SizeMode = .Custom;
		Width = width;
		Height = height;
	}

	/// Resolve actual dimensions based on output size
	public void Resolve(uint32 outputWidth, uint32 outputHeight) mut
	{
		switch (SizeMode)
		{
		case .FullSize:
			Width = outputWidth;
			Height = outputHeight;
		case .HalfSize:
			Width = Math.Max(1, outputWidth / 2);
			Height = Math.Max(1, outputHeight / 2);
		case .QuarterSize:
			Width = Math.Max(1, outputWidth / 4);
			Height = Math.Max(1, outputHeight / 4);
		case .Custom:
			// Already set
			break;
		}
	}

	/// Convert to an RHI TextureDesc for GPU allocation
	public TextureDesc ToTextureDesc(StringView label)
	{
		var desc = TextureDesc();
		desc.Format = Format;
		desc.Width = Width;
		desc.Height = Height;
		desc.ArrayLayerCount = ArrayLayerCount;
		desc.MipLevelCount = MipLevelCount;
		desc.SampleCount = SampleCount;
		desc.Usage = Usage;
		desc.Label = label;
		return desc;
	}
}

/// Describes a transient buffer resource in the render graph
public struct RGBufferDesc
{
	/// Buffer size in bytes
	public uint64 Size;
	/// Usage flags
	public BufferUsage Usage = .None;

	public this(uint64 size, BufferUsage usage = .None)
	{
		Size = size;
		Usage = usage;
	}
}

/// Color target attachment for a render pass
public struct RGColorTarget
{
	/// Resource handle for the color target
	public RGHandle Handle = .Invalid;
	/// Load operation
	public LoadOp LoadOp = .Clear;
	/// Store operation
	public StoreOp StoreOp = .Store;
	/// Clear color (used when LoadOp == .Clear)
	public ClearColor ClearValue = .Black;
	/// Subresource range (for rendering to specific array layer/mip)
	public RGSubresourceRange Subresource;

	public this(RGHandle handle, LoadOp loadOp = .Clear, StoreOp storeOp = .Store, ClearColor clearValue = .Black, RGSubresourceRange subresource = default)
	{
		Handle = handle;
		LoadOp = loadOp;
		StoreOp = storeOp;
		ClearValue = clearValue;
		Subresource = subresource;
	}
}

/// Depth/stencil target attachment for a render pass
public struct RGDepthTarget
{
	/// Resource handle for the depth target
	public RGHandle Handle = .Invalid;
	/// Depth load operation
	public LoadOp DepthLoadOp = .Clear;
	/// Depth store operation
	public StoreOp DepthStoreOp = .Store;
	/// Depth clear value
	public float DepthClearValue = 1.0f;
	/// Whether depth is read-only
	public bool ReadOnly;
	/// Stencil load operation
	public LoadOp StencilLoadOp = .Clear;
	/// Stencil store operation
	public StoreOp StencilStoreOp = .Store;
	/// Stencil clear value
	public uint32 StencilClearValue = 0;
	/// Subresource range
	public RGSubresourceRange Subresource;

	public this(RGHandle handle)
	{
		Handle = handle;
		ReadOnly = false;
		Subresource = default;
	}
}

/// Configuration for the render graph
public struct RenderGraphConfig
{
	/// Number of frame buffer slots for multi-buffering (typically 2 or 3)
	public int32 FrameBufferCount = 2;
}
