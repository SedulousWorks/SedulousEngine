using System;
using System.Collections;

namespace Sedulous.Image.DDS;

/// A parsed DDS: the header's facts, plus the payload bytes exactly as the file holds them.
///
/// The payload is LAYER MAJOR, each layer's levels nought through the last concatenated and
/// each level tight, which is the file's own order, so a pass through to a cooked texture is
/// a copy rather than a repack.
class DdsImage
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public uint32 MipLevels = 1;
	/// Six times the array size for a cubemap.
	public uint32 ArrayLayers = 1;
	public bool Cubemap = false;
	public DdsFormat Format = .Unknown;
	/// A DX10 header NAMES the DXGI format, so whether it is sRGB is a fact of the file; a
	/// legacy FourCC header says nothing about colour space and a reader falls back on usage.
	public bool ColorSpaceKnown = false;
	public List<uint8> Data = new .() ~ delete _;

	public uint32 LevelWidth(uint32 level)
	{
		let w = Width >> level;
		return (w > 0) ? w : 1;
	}

	public uint32 LevelHeight(uint32 level)
	{
		let h = Height >> level;
		return (h > 0) ? h : 1;
	}

	public int LevelSize(uint32 level)
		=> DdsFormats.LevelBytes(Format, LevelWidth(level), LevelHeight(level));

	/// The bytes of one whole layer, which is its mip chain.
	public int LayerSize()
	{
		var total = 0;
		for (uint32 level = 0; level < MipLevels; level++)
			total += LevelSize(level);
		return total;
	}

	public int LevelOffset(uint32 layer, uint32 level)
	{
		var offset = LayerSize() * (int)layer;
		for (uint32 l = 0; l < level; l++)
			offset += LevelSize(l);
		return offset;
	}

	/// One level's bytes, or an empty span when the payload does not reach it.
	public Span<uint8> Level(uint32 layer, uint32 level)
	{
		let offset = LevelOffset(layer, level);
		let size = LevelSize(level);
		if ((offset + size) > Data.Count)
			return .();
		return .(Data.Ptr + offset, size);
	}
}
