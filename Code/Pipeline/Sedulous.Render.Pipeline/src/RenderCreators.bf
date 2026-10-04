using System;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Render.Pipeline;

/// The render domain's New Asset creators: the render profiles at the engine's defaults, under
/// Profiles/ unless a group was picked.
static class RenderCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Environment Profile", "Rendering", typeof(EnvironmentProfileAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("EnvironmentProfile"), typeof(EnvironmentProfileAsset), scope EnvironmentProfileAsset())).Under("Profiles"));
		registry.Register(new AssetCreator("Post Process Profile", "Rendering", typeof(PostProcessProfileAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("PostProcessProfile"), typeof(PostProcessProfileAsset), scope PostProcessProfileAsset())).Under("Profiles"));
	}
}
