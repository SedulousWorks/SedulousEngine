using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// The animation domain's New Asset creator: an animation graph from the default seed, under
/// Animation/ unless a group was picked.
static class AnimationCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Animation Graph", "Animation", typeof(AnimationGraphAsset), new (context) =>
			{
				let asset = scope AnimationGraphAsset();
				SeedDefaultGraph(asset);
				let instance = AssetCreator.CreateWritten(context.Target, context.NameOr("AnimationGraph"), typeof(AnimationGraphAsset), asset);
				if (instance != null)
					GlobalLog(.Information, "Pipeline: created animation graph '{}'", instance.GetPath(.. scope .()));
				return instance;
			}).Under("Animation"));
	}

	/// A new graph: one Base layer whose default state is an unassigned Idle clip, a Speed
	/// parameter, and the canvas layout placing them.
	public static void SeedDefaultGraph(AnimationGraphAsset asset)
	{
		let doc = scope GraphDocument();
		doc.AddParam("Speed", 0);
		let layer = doc.AddLayer("Base");
		layer.AddState("Idle", 0); // a clip, unassigned: pick in the inspector
		layer.DefaultState = 0;
		doc.Store(asset.Source);

		ClearAndDeleteItems!(asset.LayerLayouts);
		let layout = new AnimationGraphLayerLayout();
		layout.StatePositions.Add(.(280.0f, 120.0f));
		layout.AnyStatePosition = .(60.0f, 40.0f);
		asset.LayerLayouts.Add(layout);
	}
}
