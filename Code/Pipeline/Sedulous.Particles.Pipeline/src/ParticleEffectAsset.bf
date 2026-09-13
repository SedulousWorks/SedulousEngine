using System;
using System.Collections;
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
class ParticleEffectAsset : Asset, ISerializable
{
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
		ar.Key("fileName");
		FileName.Serialize(ar);
		ParticleEffectSerialization.SerializeEffect(ar, Effect);
		ar.Key("texturePaths");
		SerializeList(ar, mSystemTexturePaths);
		ar.EndObject();
	}
}
