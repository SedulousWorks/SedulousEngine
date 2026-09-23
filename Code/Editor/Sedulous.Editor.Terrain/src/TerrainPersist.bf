using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// The closures a terrain brush registers against the source database: a painted product
/// written back over its SOURCE asset, which converts an imported one to embedded (the file
/// name cleared, the sidecars becoming the truth) and syncs the envelope's dimensions.
///
/// The product is BORROWED by the closure: it is the live cooked object the brush edited,
/// and the save that drains these runs before the recook it requests.
static class TerrainPersist
{
	/// Persists `grid` over the HeightfieldAsset `id`.
	public static AssetEditPersist ForHeightfield(Heightfield grid, Guid id)
	{
		return new [=grid, =id](db) =>
			{
				let inst = db.GetInstance(id);
				if ((inst == null) || (grid == null))
					return .Err(.NotFound); // the heightfield source vanished
				let object = inst.ReadObject();
				defer delete object;
				let asset = object as HeightfieldAsset;
				if (asset == null)
					return .Err(.InvalidArgument); // not a heightfield asset
				asset.FileName.Set("");
				asset.Size = grid.Size;
				asset.WorldSize = grid.WorldSize;
				asset.MinY = grid.MinY;
				asset.MaxY = grid.MaxY;
				if (inst.WriteObject(asset) case .Err(let error))
					return .Err(error);
				// BOTH sidecars. The heights because clearing the file name makes them the
				// truth, so an IMPORTED heightfield would otherwise lose its image born
				// heights; the holes because they are half the grid's shape and the cook
				// reads them beside it.
				if (inst.WriteData(HeightfieldSource.HeightStream,
					HeightfieldSource.HeightBlob(grid)) case .Err(let heightError))
				{
					return .Err(heightError);
				}
				return inst.WriteData(HeightfieldSource.HoleStream,
					HeightfieldSource.HoleBlob(grid));
			};
	}

	/// Persists `weights` over the SplatmapAsset `id`, both rasters.
	public static AssetEditPersist ForSplat(SplatWeights weights, Guid id)
	{
		return new [=weights, =id](db) =>
			{
				let inst = db.GetInstance(id);
				if ((inst == null) || (weights == null))
					return .Err(.NotFound);
				let object = inst.ReadObject();
				defer delete object;
				let asset = object as SplatmapAsset;
				if (asset == null)
					return .Err(.InvalidArgument); // not a splatmap asset
				asset.FileName.Set("");
				asset.Width = weights.Width;
				asset.Height = weights.Height;
				if (inst.WriteObject(asset) case .Err(let error))
					return .Err(error);
				if (inst.WriteData(SplatWeightsSource.WeightStream, SplatWeightsSource.WeightBlob(weights)) case .Err(let weightError))
					return .Err(weightError);
				return inst.WriteData(SplatWeightsSource.IndexStream, SplatWeightsSource.IndexBlob(weights));
			};
	}
}
