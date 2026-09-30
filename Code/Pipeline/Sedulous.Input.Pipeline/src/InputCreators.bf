using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Input.Pipeline;

/// The input domain's New Asset creators: an input map seeded with the default sets.
static class InputCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Input Map", "", typeof(InputMapAsset), new (context) =>
			{
				let asset = scope InputMapAsset();
				asset.SeedDefaultContent();
				return AssetCreator.CreateWritten(context.Target, "InputMap", typeof(InputMapAsset), asset);
			}));
	}
}
