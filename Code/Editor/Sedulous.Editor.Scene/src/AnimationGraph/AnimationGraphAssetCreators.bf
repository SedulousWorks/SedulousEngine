using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A new animation graph from the default seed, under Animation/ unless a browser group was
/// given, uniquely named. Answers the instance, borrowed.
static class AnimationGraphAssetCreators
{
	public static Instance CreateAnimationGraphInstance(EditorContext context, Group group)
	{
		let project = context.Project;
		if (project == null)
			return null;
		var target = group;
		if (target == null)
		{
			let root = project.SourceDb.RootGroup;
			target = root.GetGroup("Animation");
			if (target == null)
				target = root.CreateGroup("Animation");
		}
		if (target == null)
			return null;

		let name = target.UniqueInstanceName("AnimationGraph", .. scope .());
		let instance = target.CreateInstance(name, typeof(AnimationGraphAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope AnimationGraphAsset();
		AnimationGraphEdit.SeedDefault(asset);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		GlobalLog(.Information, "Editor: created animation graph '{}'", instance.GetPath(.. scope .()));
		context.RequestCook(false);
		return instance;
	}
}
