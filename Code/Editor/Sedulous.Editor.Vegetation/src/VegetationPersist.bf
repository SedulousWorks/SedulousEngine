using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Editor.Core;
using Sedulous.Vegetation.Pipeline;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Editor.Vegetation;

/// How a painted mask is written back to its source asset.
static class VegetationPersist
{
	/// Saves the painted planes into the mask's own instance, and CLEARS the file name: an
	/// imported mask becomes embedded the moment it is painted, because the sidecar is now
	/// the truth and a re-cook from the image would throw the painting away.
	public static AssetEditPersist ForMask(VegetationMask mask, Guid id)
	{
		return new [=mask, =id](db) =>
			{
				let inst = db.GetInstance(id);
				if ((inst == null) || (mask == null))
					return .Err(.NotFound);

				let object = inst.ReadObject();
				defer delete object;
				let asset = object as VegetationMaskAsset;
				if (asset == null)
					return .Err(.InvalidArgument); // not a vegetation mask asset

				asset.FileName.Set("");
				asset.Width = mask.Width;
				asset.Height = mask.Height;
				asset.PlaneCount = mask.PlaneCount;
				if (inst.WriteObject(asset) case .Err(let error))
					return .Err(error);

				return inst.WriteData(VegetationMaskSource.DensityStream,
					VegetationMaskSource.DensityBlob(mask));
			};
	}
}
