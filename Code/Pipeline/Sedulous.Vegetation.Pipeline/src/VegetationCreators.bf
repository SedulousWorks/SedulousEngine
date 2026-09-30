using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Vegetation.Pipeline;

/// The vegetation domain's New Asset creator: an empty mask for the Paint Vegetation brush to
/// fill; its page raises the plane count when a second layer wants one.
static class VegetationCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Vegetation Mask", "Terrain", typeof(VegetationMaskAsset), new (context) =>
			{
				let asset = scope VegetationMaskAsset();
				asset.Width = 1024;
				asset.Height = 1024;
				asset.PlaneCount = 1;
				return AssetCreator.CreateWritten(context.Target, context.NameOr("VegetationMask"), typeof(VegetationMaskAsset), asset);
			}));
	}
}
