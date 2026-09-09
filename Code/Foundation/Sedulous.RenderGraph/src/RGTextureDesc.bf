using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A transient texture the graph creates and destroys.
///
/// Its size is declared RELATIVE to the graph's output, so a half resolution chain follows
/// the window rather than needing every declaration rewritten when it resizes.
struct RGTextureDesc
{
	public TextureFormat Format = .Undefined;
	public SizeMode SizeMode = .FullSize;
	/// Meaningful only under the custom size mode; otherwise Resolve fills them in.
	public uint32 Width = 0;
	public uint32 Height = 0;
	public uint32 ArrayLayerCount = 1;
	public uint32 MipLevelCount = 1;
	public uint32 SampleCount = 1;
	public TextureUsage Usage = .None;

	public this() {}

	public this(TextureFormat format, SizeMode sizeMode = .FullSize)
	{
		Format = format;
		SizeMode = sizeMode;
	}

	public this(TextureFormat format, uint32 width, uint32 height)
	{
		Format = format;
		SizeMode = .Custom;
		Width = width;
		Height = height;
	}

	/// Works out the real dimensions from the graph's output size.
	///
	/// Never zero in either axis: a target with no extent is not a target, and a division
	/// down to nothing at a deep mip level would otherwise produce one.
	public void Resolve(uint32 outputWidth, uint32 outputHeight) mut
	{
		switch (SizeMode)
		{
		case .FullSize:
			Width = Max((uint32)1, outputWidth);
			Height = Max((uint32)1, outputHeight);
		case .HalfSize:
			Width = Max((uint32)1, outputWidth / 2);
			Height = Max((uint32)1, outputHeight / 2);
		case .QuarterSize:
			Width = Max((uint32)1, outputWidth / 4);
			Height = Max((uint32)1, outputHeight / 4);
		case .Custom:
			Width = Max((uint32)1, Width);
			Height = Max((uint32)1, Height);
		}
	}

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
