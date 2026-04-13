using System;
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

	/// Creates a runtime instance of this effect.
	public ParticleEffectInstance CreateInstance()
	{
		if (mEffect == null) return null;
		return new ParticleEffectInstance(mEffect);
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
