using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Heightfield.Pipeline;

/// The heightfield domain's New Asset creator: a blank heightfield at its defaults.
static class HeightfieldCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Heightfield", "Terrain", typeof(HeightfieldAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("Heightfield"), typeof(HeightfieldAsset), scope HeightfieldAsset())));
	}
}
