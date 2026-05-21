using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Particles;

namespace Sedulous.Particles.Resources;

/// Resource wrapper for a ParticleEffect asset.
/// Handles loading/saving of particle effect definitions including
/// all systems, emitters, behaviors, initializers, and curves.
class ParticleEffectResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("particleeffect");

	private ParticleEffect mEffect ~ delete _;

	/// The underlying particle effect.
	public ParticleEffect Effect => mEffect;

	public this()
	{
	}

	public this(ParticleEffect effect)
	{
		mEffect = effect;
		if (effect != null && Name.IsEmpty)
			Name.Set(effect.Name);
	}

	/// Rewrites texture / mesh / material ResourceRef paths on each
	/// ParticleSystem in this effect for refs whose Guid appears in
	/// `finalPaths`. Used by the asset import pipeline so renamed
	/// textures, meshes, or materials flow through to particle effects
	/// importing alongside them. The Guid is the stable identity; only
	/// Path changes. Each ParticleSystem's SetXxxRef setter copies the
	/// new ResourceRef, so the temporary on this side is freed after.
	public override void RemapReferences(Dictionary<Guid, String> finalPaths)
	{
		if (mEffect == null) return;

		for (let system in mEffect.Systems)
		{
			RemapOne(system.TextureRef, finalPaths, scope (newRef) => system.SetTextureRef(newRef));
			RemapOne(system.MeshRef,    finalPaths, scope (newRef) => system.SetMeshRef(newRef));
			RemapOne(system.MaterialRef, finalPaths, scope (newRef) => system.SetMaterialRef(newRef));
		}
	}

	private static void RemapOne(ResourceRef cur, Dictionary<Guid, String> finalPaths,
		delegate void(ResourceRef) apply)
	{
		if (cur.Id == .()) return;
		if (!finalPaths.TryGetValue(cur.Id, let newPath)) return;
		var tmp = ResourceRef(cur.Id, newPath);
		apply(tmp);
		tmp.Dispose();
	}

	/// Creates a runtime instance of this effect.
	public ParticleEffectInstance CreateInstance()
	{
		if (mEffect == null) return null;
		return new ParticleEffectInstance(mEffect);
	}

	/// The Resource-level Name mirrors the effect's Name (single source of
	/// truth - the effect's Name is the editable one). Sync before the
	/// base writes `_name` so the persisted header matches, and re-sync
	/// after a read once the effect (and its Name) has been deserialized,
	/// so a stale on-disk `_name` can't shadow the real name.
	public override SerializationResult Serialize(Serializer s)
	{
		if (s.IsWriting && mEffect != null)
			Name.Set(mEffect.Name);

		let result = base.Serialize(s);

		if (s.IsReading && mEffect != null)
			Name.Set(mEffect.Name);

		return result;
	}

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mEffect == null)
				return .InvalidData;

			int32 version = FileVersion;
			s.Int32("version", ref version);
			return ParticleEffectSerializer.Serialize(s, mEffect);
		}
		else
		{
			int32 version = 0;
			s.Int32("version", ref version);
			if (version > FileVersion)
				return .UnsupportedVersion;

			delete mEffect;
			mEffect = new ParticleEffect();
			return ParticleEffectSerializer.Serialize(s, mEffect);
		}
	}
}
