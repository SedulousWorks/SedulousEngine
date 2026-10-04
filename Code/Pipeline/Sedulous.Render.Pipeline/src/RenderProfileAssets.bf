using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;

namespace Sedulous.Render.Pipeline;

/// A profile asset: a settings block's values, reached without naming the block. The editor
/// edits any profile through this, the layout ValuesType over Values.
abstract class SettingsProfileAsset : Asset, ISerializable
{
	public abstract void Serialize(ISerializer ar);

	public abstract Type ValuesType { get; }
	public abstract void* ValuesAddress { get; }
	/// Takes a settings block's values, in ValuesType's layout. The block's own source and
	/// profile reference are not a profile's.
	public abstract void SetValues(void* values);
}

/// An authored Environment Profile: the value fields of a scene's environment block, which a
/// block whose source is Profile uses.
///
/// Describes ITSELF rather than carrying [Serializable]: the values are written by the block's
/// own serializer, so a field added to the block reaches its profile.
[Category("Rendering")]
[DisplayName("Environment Profile")]
class EnvironmentProfileAsset : SettingsProfileAsset
{
	public EnvironmentSettings Values = .();

	public override Type ValuesType => typeof(EnvironmentSettings);
	public override void* ValuesAddress => &Values;

	public override void SetValues(void* values)
	{
		Values = *(EnvironmentSettings*)values;
		Values.Source = .Scene;
		Values.Profile = .(Guid());
	}

	public override void Serialize(ISerializer ar)
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
class PostProcessProfileAsset : SettingsProfileAsset
{
	public PostProcessSettings Values = .();

	public override Type ValuesType => typeof(PostProcessSettings);
	public override void* ValuesAddress => &Values;

	public override void SetValues(void* values)
	{
		Values = *(PostProcessSettings*)values;
		Values.Source = .Scene;
		Values.Profile = .(Guid());
	}

	public override void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		ar.Key("fileName");
		FileName.Serialize(ar);
		RenderSettingsValues.SerializePost(ar, ref Values);
		ar.EndObject();
	}
}
