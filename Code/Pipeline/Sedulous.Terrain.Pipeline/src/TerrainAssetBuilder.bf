using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Terrain.Resource;

namespace Sedulous.Terrain.Pipeline;

/// Cooks a terrain: its references pass straight through, and its paint palette becomes the
/// texture arrays the renderer samples.
class TerrainAssetBuilder : IAssetBuilder
{
	/// The largest slice the authored size is allowed to snap up to.
	private const uint32 cMaxSliceSize = 4096;
	private const uint32 cMinSliceSize = 64;

	public Type AssetType => typeof(TerrainAsset);

	/// The SERIALIZED cooked form rather than the runtime resource, because the cook stamps
	/// this onto the instance and the runtime reconstructs by that name. The factory's product
	/// type is the runtime one a bind matches, as it is for textures and heightfields.
	public Type ProductType => typeof(TerrainSource);

	/// Nine, after a long run of output changes: the top weights model, decoding palette
	/// albedos through the SOURCE database rather than cooking every slice white, the normal
	/// and occlusion arrays, averaging the albedo's mips in linear space, the height array and
	/// its blend contrast, the coverage masks, and finally DELETING a sidecar whose map was
	/// removed instead of leaving a stale one loading forever.
	public int32 Version => 9;

	/// The palette pack READS every layer's maps, so editing one re-cooks the arrays. The
	/// base, heightfield and weights are runtime references only: they are separate products
	/// the terrain points at rather than content it bakes in.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let terrain = (TerrainAsset)asset;

		void Chain(List<Guid> ids)
		{
			for (let id in ids)
			{
				if (id != Guid.Empty)
					outDeps.Reads.Add(id);
			}
		}

		Chain(terrain.PaletteAlbedoIds);
		Chain(terrain.PaletteNormalIds);
		Chain(terrain.PaletteOrmIds);
		Chain(terrain.PaletteHeightIds);
		Chain(terrain.PaletteMaskIds);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let terrain = (TerrainAsset)asset;
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let cooked = scope TerrainSource();
		cooked.HeightfieldId = terrain.HeightfieldId;
		cooked.WeightsId = terrain.WeightsId;
		cooked.BaseAlbedoId = terrain.BaseAlbedoId;
		cooked.BaseNormalId = terrain.BaseNormalId;
		cooked.BaseOrmId = terrain.BaseOrmId;
		cooked.BaseHeightId = terrain.BaseHeightId;
		cooked.BaseTileScale = terrain.BaseTileScale;
		cooked.PaletteAlbedoIds.AddRange(terrain.PaletteAlbedoIds);
		cooked.PaletteNormalIds.AddRange(terrain.PaletteNormalIds);
		cooked.PaletteOrmIds.AddRange(terrain.PaletteOrmIds);
		cooked.PaletteHeightIds.AddRange(terrain.PaletteHeightIds);
		cooked.PaletteMaskIds.AddRange(terrain.PaletteMaskIds);
		cooked.PaletteTileScales.AddRange(terrain.PaletteTileScales);
		cooked.HeightBlendContrast = terrain.HeightBlendContrast;
		cooked.CastShadows = terrain.CastShadows;

		if (context.Output.WriteObject(cooked) case .Err(let writeError))
			return .Err(writeError);

		return CookPalette(terrain, context);
	}

	private static Result<void, ErrorCode> CookPalette(TerrainAsset terrain,
		AssetBuildContext context)
	{
		let streams = scope String[](TerrainPaletteData.AlbedoStream,
			TerrainPaletteData.NormalStream, TerrainPaletteData.OrmStream,
			TerrainPaletteData.HeightStream, TerrainPaletteData.MaskStream);

		if (terrain.PaletteAlbedoIds.IsEmpty)
		{
			// A pure base terrain: EVERY palette sidecar goes, so a terrain whose layers were
			// all removed does not keep loading the arrays it used to have.
			for (let stream in streams)
			{
				if (context.Output.DeleteData(stream) case .Err(let deleteError))
					return .Err(deleteError);
			}
			return .Ok;
		}

		// The authored size snaps up to a power of two, since the mip chain needs clean
		// halving all the way down.
		var sliceSize = cMinSliceSize;
		let authored = (uint32)Math.Max(terrain.PaletteTextureSize, (int32)cMinSliceSize);
		while ((sliceSize < authored) && (sliceSize < cMaxSliceSize))
			sliceSize *= 2;

		uint32 mipCount = 1;
		for (var d = sliceSize; d > 1; d /= 2)
			mipCount++;

		let sliceBytes = (int)TerrainPaletteData.SliceBytes(sliceSize, mipCount);
		let sliceCount = (uint32)terrain.PaletteAlbedoIds.Count;

		Result<void, ErrorCode> WriteArray(StringView stream, List<Guid> ids,
			uint8[4] defaultTexel, bool srgb)
		{
			let blob = scope List<uint8>();
			TerrainPaletteCook.CookArray(context, ids, sliceCount, sliceSize, mipCount, sliceBytes,
				defaultTexel, srgb, blob);
			return context.Output.WriteData(stream, blob);
		}

		/// An optional array is written when ANY layer supplies it, and its sidecar DELETED
		/// otherwise: a re-cook that drops a map must not leave the stale one behind, or the
		/// factory goes on loading it and the terrain still claims to have it.
		Result<void, ErrorCode> WriteOrClear(StringView stream, List<Guid> ids,
			uint8[4] defaultTexel, bool srgb)
		{
			if (TerrainPaletteCook.AnySet(ids))
				return WriteArray(stream, ids, defaultTexel, srgb);
			return context.Output.DeleteData(stream);
		}

		// The albedo is always there when the palette is not empty, and is the only sRGB one.
		if (WriteArray(TerrainPaletteData.AlbedoStream, terrain.PaletteAlbedoIds,
			TerrainPaletteCook.cWhite, true) case .Err(let albedoError))
		{
			return .Err(albedoError);
		}

		if (WriteOrClear(TerrainPaletteData.NormalStream, terrain.PaletteNormalIds,
			TerrainPaletteCook.cFlatNormal, false) case .Err(let normalError))
		{
			return .Err(normalError);
		}
		if (WriteOrClear(TerrainPaletteData.OrmStream, terrain.PaletteOrmIds,
			TerrainPaletteCook.cDefaultOrm, false) case .Err(let ormError))
		{
			return .Err(ormError);
		}
		if (WriteOrClear(TerrainPaletteData.HeightStream, terrain.PaletteHeightIds,
			TerrainPaletteCook.cMidHeight, false) case .Err(let heightError))
		{
			return .Err(heightError);
		}
		return WriteOrClear(TerrainPaletteData.MaskStream, terrain.PaletteMaskIds,
			TerrainPaletteCook.cOpaqueMask, false);
	}
}
