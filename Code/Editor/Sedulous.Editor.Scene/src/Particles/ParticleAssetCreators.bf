using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A new particle effect from the default seed, under ParticleEffects/ unless a browser
/// group was given, uniquely named. Answers the instance, borrowed.
static class ParticleAssetCreators
{
	public static Instance CreateParticleEffectInstance(EditorContext context, Group group)
	{
		let project = context.Project;
		if (project == null)
			return null;
		var target = group;
		if (target == null)
		{
			let root = project.SourceDb.RootGroup;
			target = root.GetGroup("ParticleEffects");
			if (target == null)
				target = root.CreateGroup("ParticleEffects");
		}
		if (target == null)
			return null;

		let name = target.UniqueInstanceName("ParticleEffect", .. scope .());
		let instance = target.CreateInstance(name, typeof(ParticleEffectAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope ParticleEffectAsset();
		ParticleEffectEdit.SeedDefault(asset.Effect);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		GlobalLog(.Information, "Editor: created particle effect '{}'", instance.GetPath(.. scope .()));
		context.RequestCook(false);
		return instance;
	}
}
