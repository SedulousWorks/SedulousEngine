using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// The plugin registrar: property animation is authored in the scene through the persistent
/// panel, so there is no standalone clip page. This ensures the clip asset types exist and
/// contributes the "Property Animation Clip" creator.
static class PropertyAnimationEditor
{
	/// A named clip; an empty name auto-numbers "Clip N".
	public static Instance CreateClipNamed(EditorContext context, Group target, StringView requestedName)
	{
		let name = scope String();
		target.UniqueInstanceName(requestedName.IsEmpty ? "Clip" : requestedName, name);
		let inst = target.CreateInstance(name, typeof(PropertyAnimationClipAsset).GetFullName(.. scope .()));
		if (inst == null)
			return null;
		let asset = scope PropertyAnimationClipAsset();
		inst.WriteObject(asset).IgnoreError();
		return inst;
	}

	/// The New Asset creator: an empty clip in the invoked group, or the root.
	public static Instance CreateClip(EditorContext context, Group group)
	{
		var target = group;
		if (target == null)
		{
			if (context.Project == null)
				return null;
			target = context.Project.SourceDb.RootGroup;
		}
		if (target == null)
			return null;
		return CreateClipNamed(context, target, "");
	}

	/// The editor executable's entry point. The host is unused, the panel being scene-page
	/// owned, and kept for a uniform registrar signature.
	public static void Register(EditorContext context, IApplicationHost host)
	{
		PropertyAnimationPipeline.RegisterAll();
		context.RegisterCreator(new AssetCreator("Property Animation Clip", "Animation", new (ctx, group) => CreateClip(ctx, group)));
	}
}
