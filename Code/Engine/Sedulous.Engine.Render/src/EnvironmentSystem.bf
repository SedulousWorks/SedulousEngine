using System;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// Holds the scene's environment block and presents it through the settings seam.
///
/// A scene inspector edits it in place, and the scene's own serializer persists it inside the
/// versioned payload the seam wraps around these fields.
class EnvironmentSystem : SceneSystem
{
	private EnvironmentSettings mEnvironment = .();

	public EnvironmentSettings* Environment => &mEnvironment;

	public override Type SettingsType => typeof(EnvironmentSettings);
	public override void* SettingsInstance => &mEnvironment;
	public override StringView SettingsId => "environment";

	public override void ResolveResources(ResourceManager manager)
	{
		mEnvironment.SkyTexture.Bind(manager);
	}

	public override void SerializeSettings(ISerializer ar)
	{
		SerializeValue(ar, "skyTexture", ref mEnvironment.SkyTexture.Id);
		ar.Key("ambientColor");
		Sedulous.Core.Serialization.Serialize(ar, ref mEnvironment.AmbientColor);
		SerializeValue(ar, "ambientIntensity", ref mEnvironment.AmbientIntensity);

		var mode = (uint32)mEnvironment.SkyMode;
		SerializeValue(ar, "skyMode", ref mode);
		mEnvironment.SkyMode = (SkyMode)mode;

		SerializeValue(ar, "skyIntensity", ref mEnvironment.SkyIntensity);
		SerializeValue(ar, "skyBackgroundIntensity", ref mEnvironment.SkyBackgroundIntensity);
		SerializeValue(ar, "skyRotation", ref mEnvironment.SkyRotation);

		ar.Key("skyHorizon");
		Sedulous.Core.Serialization.Serialize(ar, ref mEnvironment.SkyHorizon);
		ar.Key("skyZenith");
		Sedulous.Core.Serialization.Serialize(ar, ref mEnvironment.SkyZenith);
		ar.Key("skyGround");
		Sedulous.Core.Serialization.Serialize(ar, ref mEnvironment.SkyGround);

		SerializeValue(ar, "sunIntensity", ref mEnvironment.SunIntensity);
		SerializeValue(ar, "sunAngularSize", ref mEnvironment.SunAngularSize);
		SerializeValue(ar, "turbidity", ref mEnvironment.Turbidity);
		SerializeValue(ar, "iblDiffuseIntensity", ref mEnvironment.IblDiffuseIntensity);
		SerializeValue(ar, "iblSpecularIntensity", ref mEnvironment.IblSpecularIntensity);
	}
}
