using System;
using Sedulous.Core;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Particles.Pipeline;

/// Bakes the authored effect into its cooked resource and resolves its soft references.
class ParticleEffectAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ParticleEffectAsset);
	public Type ProductType => typeof(ParticleEffectResource);

	/// Four, the last of a run of format changes: per system mesh and scale for the mesh render
	/// mode, then a material for it, then that material becoming a list, one per submesh with
	/// slot nought the whole mesh. The strict reader needs the new keys, so stale products have
	/// to re-cook. Five: curves of Core's keys and gradients, and size over lifetime as size,
	/// separateAxes and sizeY (the product's data version 1). Six: each system its sub-emitters
	/// (the product's data version 2).
	public int32 Version => 6;

	/// What each system draws with is a runtime REFERENCE (the factory binds it at load): its
	/// texture, its mesh and its materials, by id, or a texture by its edit time path. Declared
	/// so a cook of the effect cooks them too (a scene's first cook reached the effect but not
	/// its texture), and asset_uses and the export's reach see them.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let authored = (ParticleEffectAsset)asset;
		let effect = authored.Effect;
		for (int32 index < effect.SystemCount)
		{
			let system = effect.GetSystem(index);
			if (system == null)
				continue;
			if (system.TextureRef != Guid.Empty)
				outDeps.References.Add(system.TextureRef);
			if (system.MeshRef != Guid.Empty)
				outDeps.References.Add(system.MeshRef);
			for (let material in system.MaterialRefs)
			{
				if (material != Guid.Empty)
					outDeps.References.Add(material);
			}
			let path = authored.SystemTexturePath(index);
			if (!path.IsEmpty && (context.Database != null))
			{
				if (let named = context.Database.GetInstanceByPath(path))
					outDeps.References.Add(named.Id);
			}
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if ((context.Output == null) || (context.Serializers == null))
			return .Err(.InvalidArgument);

		let authored = (ParticleEffectAsset)asset;

		// A faithful copy, which goes out through a serializer and back: the modules are
		// polymorphic, and that is the one piece of code that already knows how to rebuild
		// every one of them.
		let cooked = scope ParticleEffectResource();
		if (ParticleEffectSerialization.CloneEffect(authored.Effect, cooked.Effect,
			context.Serializers) case .Err(let error))
		{
			return .Err(error);
		}

		// Then RESOLVE: each system's edit time texture PATH becomes the cooked texture's
		// identity, which the factory binds when it loads.
		let effect = cooked.Effect;
		for (int32 system < effect.SystemCount)
		{
			let path = authored.SystemTexturePath(system);
			if (path.IsEmpty)
				continue;

			let referenced = (context.Database != null)
				? context.Database.GetInstanceByPath(path)
				: null;
			if (referenced == null)
				return .Err(.NotFound); // the referenced asset has to be cooked first

			effect.GetSystem(system).TextureRef = referenced.Id;
		}

		return context.Output.WriteObject(cooked);
	}
}
