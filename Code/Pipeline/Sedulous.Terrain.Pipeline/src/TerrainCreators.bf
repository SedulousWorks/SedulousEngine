using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Terrain.Pipeline;

/// The terrain domain's New Asset creators: a terrain and a splatmap (1024 square by default).
static class TerrainCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Terrain", "Terrain", typeof(TerrainAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("Terrain"), typeof(TerrainAsset), scope TerrainAsset())));
		registry.Register(new AssetCreator("Splatmap", "Terrain", typeof(SplatmapAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("Splatmap"), typeof(SplatmapAsset), scope SplatmapAsset())));
	}
}
