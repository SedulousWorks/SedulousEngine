using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;

namespace Sedulous.Render.Pipeline;

/// An authored Environment Profile: the value fields of a scene's environment block, which a
/// block whose source is Profile uses.
///
/// Describes ITSELF rather than carrying [Serializable]: the values are written by the block's
/// own serializer, so a field added to the block reaches its profile.
[Category("Rendering")]
[DisplayName("Environment Profile")]
class EnvironmentProfileAsset : Asset, ISerializable
{
	public EnvironmentSettings Values = .();

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		ar.Key("fileName");
		FileName.Serialize(ar);
		RenderSettingsValues.SerializeEnvironment(ar, ref Values, true);
		ar.EndObject();
	}
}

/// An authored Post Process Profile.
[Category("Rendering")]
[DisplayName("Post Process Profile")]
class PostProcessProfileAsset : Asset, ISerializable
{
	public PostProcessSettings Values = .();

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		ar.Key("fileName");
		FileName.Serialize(ar);
		RenderSettingsValues.SerializePost(ar, ref Values);
		ar.EndObject();
	}
}
