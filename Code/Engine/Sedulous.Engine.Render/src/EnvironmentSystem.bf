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
	/// Version 2 adds the shadow reach, version 3 the source and its profile; an older block
	/// reads the defaults for what it lacks, the source Scene among them.
	public override uint32 SettingsDataVersion => 3;
	public override uint32 SettingsMinReadDataVersion => 1;

	/// The values in effect: the profile's while the source is Profile and it is loaded, the
	/// scene's own otherwise. What the renderer reads; Environment is always the scene's own
	/// block, its source and its stored values.
	public EnvironmentSettings* Effective
	{
		get
		{
			if (mEnvironment.Source == .Profile)
			{
				if (let profile = mEnvironment.Profile.Get)
					return &profile.Values;
			}
			return &mEnvironment;
		}
	}

	public override void ResolveResources(ResourceManager manager)
	{
		mEnvironment.SkyTexture.Bind(manager);
		mEnvironment.Profile.Bind(manager);
	}

	public override void SerializeSettings(ISerializer ar)
	{
		let write = ar.Mode == .Write;
		RenderSettingsValues.SerializeEnvironment(ar, ref mEnvironment, write || (ar.Version >= 2));
		if (!write && (ar.Version < 3))
			return;
		RenderSettingsValues.SerializeEnum(ar, "source", ref mEnvironment.Source);
		SerializeValue(ar, "profile", ref mEnvironment.Profile.Id);
	}
}
