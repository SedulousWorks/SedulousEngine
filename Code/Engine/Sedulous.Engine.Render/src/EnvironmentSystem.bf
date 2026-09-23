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
	/// The scene's render clock, and last frame's value for the motion vectors.
	private float mTimeSeconds = 0.0f;
	private float mPrevTimeSeconds = 0.0f;

	public EnvironmentSettings* Environment => &mEnvironment;

	/// The scene's render clock: seconds accumulated from the scene's OWN delta, which is the
	/// context, group and scene time scales composed by the scene manager, so time driven
	/// shading, the WIND sway, pauses and slows with the scene it belongs to.
	///
	/// Advanced once a frame, in the update phase, and ONLY while the scene simulates: the
	/// editor's editing scene ticks every frame with simulation disabled, Simulate being what
	/// enables it, and a frozen world's grass has to stand still there. RUNTIME state, never
	/// serialized.
	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase != .Update)
			return;
		if ((Scene != null) && !Scene.SimulationEnabled)
			return;
		mPrevTimeSeconds = mTimeSeconds;
		mTimeSeconds += deltaTime;
	}

	public float TimeSeconds => mTimeSeconds;
	public float PrevTimeSeconds => mPrevTimeSeconds;

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
