using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Terrain.Pipeline;

namespace Sedulous.Editor.Terrain;

/// The terrain page's headless edits: the undo snapshot, the whole asset as bytes, and the
/// palette's structural verbs. The optional map lists are grown lazily to the albedo
/// list's length, so an asset authored before a map existed stays valid.
static class TerrainAssetEdit
{
	/// The tile scale a new paint layer starts with.
	public const float cNewLayerTileScale = 32.0f;

	public static void Snapshot(TerrainAsset asset, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `asset`; false when it already matched, nothing read.
	public static bool Apply(TerrainAsset asset, Span<uint8> blob)
	{
		let current = scope List<uint8>();
		Snapshot(asset, current);
		if ((current.Count == blob.Length) && (Internal.MemCmp(current.Ptr, blob.Ptr, blob.Length) == 0))
			return false;
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ISerializable serializable = asset;
		serializable.Serialize(ar);
		return true;
	}

	/// Appends an unset paint layer across every parallel list.
	public static void AddLayer(TerrainAsset asset)
	{
		asset.PaletteAlbedoIds.Add(.Empty);
		asset.PaletteTileScales.Add(cNewLayerTileScale);
		asset.PaletteNormalIds.Add(.Empty);
		asset.PaletteOrmIds.Add(.Empty);
		asset.PaletteHeightIds.Add(.Empty);
		asset.PaletteMaskIds.Add(.Empty);
	}

	/// Removes layer `index` from every parallel list that reaches it; false when there is
	/// no such layer.
	public static bool RemoveLayer(TerrainAsset asset, int index)
	{
		if ((index < 0) || (index >= asset.PaletteAlbedoIds.Count))
			return false;
		asset.PaletteAlbedoIds.RemoveAt(index);
		if (index < asset.PaletteTileScales.Count)
			asset.PaletteTileScales.RemoveAt(index);
		if (index < asset.PaletteNormalIds.Count)
			asset.PaletteNormalIds.RemoveAt(index);
		if (index < asset.PaletteOrmIds.Count)
			asset.PaletteOrmIds.RemoveAt(index);
		if (index < asset.PaletteHeightIds.Count)
			asset.PaletteHeightIds.RemoveAt(index);
		if (index < asset.PaletteMaskIds.Count)
			asset.PaletteMaskIds.RemoveAt(index);
		return true;
	}

	/// The list a map kind lives in.
	public static List<Guid> MapIds(TerrainAsset asset, PaletteMap map)
	{
		switch (map)
		{
		case .Normal: return asset.PaletteNormalIds;
		case .Orm: return asset.PaletteOrmIds;
		case .Height: return asset.PaletteHeightIds;
		case .Mask: return asset.PaletteMaskIds;
		}
	}

	/// The map id of layer `index`, Empty when that list never reached it.
	public static Guid MapId(TerrainAsset asset, PaletteMap map, int index)
	{
		let ids = MapIds(asset, map);
		return ((index >= 0) && (index < ids.Count)) ? ids[index] : .Empty;
	}

	/// Sets a per layer map, growing the list to the albedo count first; false when there
	/// is no such layer.
	public static bool SetPaletteMap(TerrainAsset asset, PaletteMap map, int index, Guid id)
	{
		if ((index < 0) || (index >= asset.PaletteAlbedoIds.Count))
			return false;
		let ids = MapIds(asset, map);
		while (ids.Count < asset.PaletteAlbedoIds.Count)
			ids.Add(.Empty);
		ids[index] = id;
		return true;
	}
}
