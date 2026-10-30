using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Particles.Pipeline;

/// The authored effect.
///
/// Embedded rather than imported: there is no external source file the way an imported texture
/// has one, so the file name a plain asset carries goes unused. This is a DISTINCT type from
/// the cooked resource, and the builder is what turns one into the other.
///
/// Describes ITSELF rather than carrying [Serializable], for the same reason the cooked
/// resource does: the effect is a graph of polymorphic modules, and only the effect
/// serializer knows how to rebuild them.
[DisplayName("Particle Effect")]
class ParticleEffectAsset : Asset, ISerializable
{
	public static readonly uint64 TypeId = TypeIdOf("Sedulous.Particles.Pipeline.ParticleEffectAsset");
	/// One (2026-10-29): each system its sub-emitters. Version 0 (stored before the asset had an
	/// envelope of its own) kept the effect's links, each into a system on every other system's
	/// births or deaths: its legacy reader moves them onto the systems (SerializeEffect's
	/// effectLinks), which a keyed backend (the source assets' text) can tell has no envelope.
	public const uint32 DataVersion = 1;

	public ParticleEffect Effect = new .() ~ delete _;

	/// The edit time texture reference for each system, as an asset PATH, which is a SOFT
	/// reference. The build resolves each to the cooked texture's identity. Empty means
	/// untextured.
	private List<String> mSystemTexturePaths = new .() ~ DeleteContainerAndItems!(_);

	public void SetSystemTexturePath(int32 systemIndex, StringView path)
	{
		if (systemIndex < 0)
			return;
		while (mSystemTexturePaths.Count <= systemIndex)
			mSystemTexturePaths.Add(new String());
		mSystemTexturePaths[systemIndex].Set(path);
	}

	public StringView SystemTexturePath(int32 systemIndex)
		=> ((systemIndex >= 0) && (systemIndex < mSystemTexturePaths.Count))
			? mSystemTexturePaths[systemIndex]
			: StringView();

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		BeginVersionedPayload(ar, TypeId, DataVersion, 0, true);
		if (ar.IsPayloadOk)
		{
			ar.Key("fileName");
			FileName.Serialize(ar);
			// A version 0 asset's effect-level links read onto its systems.
			ParticleEffectSerialization.SerializeEffect(ar, Effect, (ar.Mode == .Read) && (ar.Version < 1));
			ar.Key("texturePaths");
			SerializeList(ar, mSystemTexturePaths);
		}
		EndVersionedPayload(ar);
		ar.EndObject();
	}
}
