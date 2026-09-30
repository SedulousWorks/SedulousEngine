using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.PropertyAnimation.Pipeline;

/// The property animation domain's New Asset creator: an empty clip, in the picked group or
/// the root.
static class PropertyAnimationCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Property Animation Clip", "Animation", typeof(PropertyAnimationClipAsset), new (context) =>
			CreateClip(context.Target, context.Name)));
	}

	/// An empty clip in `target`, named `requestedName` made unique ("Clip" when empty): the
	/// creator's body, and the animation panel's Create Clip.
	public static Instance CreateClip(Group target, StringView requestedName)
	{
		if (target == null)
			return null;
		return AssetCreator.CreateWritten(target, requestedName.IsEmpty ? "Clip" : requestedName,
			typeof(PropertyAnimationClipAsset), scope PropertyAnimationClipAsset());
	}
}
