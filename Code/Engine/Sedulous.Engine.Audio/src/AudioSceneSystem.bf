using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The per scene audio runtime.
///
/// It owns the scene's VOICE GROUP, which is what makes pausing or stopping one scene's sound
/// fall out of the engine's own graph rather than needing a list of voices here: playing in an
/// editor needs exactly that.
///
/// The tick runs after the transforms are final: it plays what activation armed, syncs each
/// live voice's position and velocity, reaps the finished one shots, works out the listener
/// pose, and settles the reverb.
class AudioSceneSystem : SceneSystem
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// BORROWED from the subsystem, or injected directly by a headless test.
	private AudioEngine mEngine = null;

	private uint64 mSceneGroup = 0;
	private bool mStarted = false;
	private bool mWasSimulating = true;

	/// The cue variant selection, one sequence per scene.
	private Sedulous.Core.Random mCueRandom = .();

	private bool mListenerValid = false;
	private Float3 mListenerPosition = .(0.0f, 0.0f, 0.0f);
	private Float3 mListenerForward = .(0.0f, 0.0f, -1.0f);
	private Float3 mListenerUp = .(0.0f, 1.0f, 0.0f);
	private Float3 mListenerVelocity = .(0.0f, 0.0f, 0.0f);
	private List<ListenerPose> mListenerPoses = new .() ~ delete _;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The subsystem wires its engine in right after the system is added. A test injects a
	/// headless one the same way.
	public void SetEngine(AudioEngine engine)
	{
		mEngine = engine;
	}

	public AudioEngine Engine => mEngine;
	public uint64 SceneGroup => mSceneGroup;
	public Scene OwningScene => mScene;
	public bool Started => mStarted;

	// ---- the play lifecycle ----

	public override void OnSceneStarted()
	{
		mStarted = true;
		mWasSimulating = true;
		if (mEngine == null)
			return;

		mSceneGroup = mEngine.CreateSceneGroup();

		let sources = mScene.GetSystem<AudioSourceComponentManager>();
		if (sources == null)
			return;

		// The world matrices are current before this fires, so a positional voice starts
		// where it was authored rather than at the origin.
		sources.ForEach(scope (component, entity) =>
			{
				if (!component.AutoPlay)
					return;

				if (mScene.IsEffectivelyActive(entity))
					PlayComponent(component, entity);
				else
					// Starts inactive: arm the latch so the ACTIVATION edge plays it.
					component.ActiveSuspended = true;
			});
	}

	public override void OnSceneStopped()
	{
		mStarted = false;

		if (let sources = mScene.GetSystem<AudioSourceComponentManager>())
		{
			sources.ForEach(scope (component, entity) =>
				{
					component.Voice = .();
					component.HasPreviousPosition = false;
					component.ActiveSuspended = false;
				});
		}

		// Destroying the group stops the scene's voices.
		if ((mEngine != null) && (mSceneGroup != 0))
			mEngine.DestroySceneGroup(mSceneGroup);

		mSceneGroup = 0;
		mListenerValid = false;
	}

	// ---- the control surface ----

	/// Starts, or restarts, the entity's source.
	public VoiceHandle Play(EntityHandle entity)
	{
		let component = Component(entity);
		if (component == null)
			return .();

		return PlayComponent(component, entity);
	}

	public void Stop(EntityHandle entity)
	{
		let component = Component(entity);
		if (component == null)
			return;

		if (mEngine != null)
			mEngine.Stop(component.Voice);

		component.Voice = .();
		component.HasPreviousPosition = false;
	}

	public void SetPaused(EntityHandle entity, bool paused)
	{
		let component = Component(entity);
		if ((component == null) || (mEngine == null))
			return;

		mEngine.SetPaused(component.Voice, paused);
	}

	public bool IsPlaying(EntityHandle entity)
	{
		let component = Component(entity);
		return (component != null) && (mEngine != null) && mEngine.IsPlaying(component.Voice);
	}

	/// Swaps the source's clip to the resource with this id, bound through the manager the
	/// scene was resolved with. A playing voice runs on; the next Play uses the new clip.
	public void SetClip(EntityHandle entity, Guid id)
	{
		let sources = (mScene != null) ? mScene.GetSystem<AudioSourceComponentManager>() : null;
		let component = (sources != null) ? sources.Get(entity) : null;
		if (component == null)
			return;

		component.Clip.SetId(id);
		component.Clip.Rebind(sources.Resources);
	}

	// ---- the per frame sync, with the final transforms ready ----

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase != .PostTransform)
			return;
		if ((mEngine == null) || (mScene == null) || !mStarted)
			return;

		using (ProfileScope("Audio.Sources"))
		{
			// A scene's simulation pausing and resuming maps onto its group, which fades both
			// ways rather than cutting.
			let simulating = mScene.SimulationEnabled;
			if ((simulating != mWasSimulating) && (mSceneGroup != 0))
				mEngine.SetSceneGroupPaused(mSceneGroup, !simulating);
			mWasSimulating = simulating;

			if (!simulating)
				return;

			if (let sources = mScene.GetSystem<AudioSourceComponentManager>())
			{
				sources.ForEach(scope (component, entity) =>
					{
						SyncSource(component, entity, deltaTime);
					});
			}

			UpdateListenerPose(deltaTime);
			UpdateReverbZones();
		}
	}

	private void SyncSource(AudioSourceComponent* component, EntityHandle entity, float deltaTime)
	{
		// The entity active EDGES: deactivating STOPS the voice, which is silence rather than
		// a skipped update, and reactivating restarts an automatic source. A one shot stopped
		// this way does not resume mid buffer.
		if (!mScene.IsEffectivelyActive(entity))
		{
			if (component.Voice.IsValid)
			{
				mEngine.Stop(component.Voice);
				component.Voice = .();
				component.HasPreviousPosition = false;
				component.ActiveSuspended = true;
			}
			return;
		}

		if (component.ActiveSuspended)
		{
			component.ActiveSuspended = false;
			if (component.AutoPlay)
				PlayComponent(component, entity);
		}

		if (!component.Voice.IsValid)
			return;

		if (!mEngine.IsValidHandle(component.Voice))
		{
			// A finished one shot: reap the handle.
			component.Voice = .();
			component.HasPreviousPosition = false;
			return;
		}

		if (!component.Spatial)
			return;

		let position = EntityPosition(entity);
		// The velocity is the PREVIOUS frame's delta, which is what feeds the doppler shift.
		let velocity = (component.HasPreviousPosition && (deltaTime > 0.0f))
			? Float3((position.X - component.PreviousPosition.X) / deltaTime,
				(position.Y - component.PreviousPosition.Y) / deltaTime,
				(position.Z - component.PreviousPosition.Z) / deltaTime)
			: Float3(0.0f, 0.0f, 0.0f);

		mEngine.SetVoicePosition(component.Voice, position, velocity);
		component.PreviousPosition = position;
		component.HasPreviousPosition = true;
	}

	// ---- the listener ----

	/// The scene's pose this frame. The SUBSYSTEM pushes the winning scene's to the engine.
	public bool ListenerValid => mListenerValid;
	public Float3 ListenerPosition => mListenerPosition;
	public Float3 ListenerForward => mListenerForward;
	public Float3 ListenerUp => mListenerUp;
	public Float3 ListenerVelocity => mListenerVelocity;
	public Span<ListenerPose> ListenerPoses => .(mListenerPoses.Ptr, mListenerPoses.Count);

	private AudioSourceComponent* Component(EntityHandle entity)
	{
		let sources = (mScene != null) ? mScene.GetSystem<AudioSourceComponentManager>() : null;
		return (sources != null) ? sources.Get(entity) : null;
	}

	private Float3 EntityPosition(EntityHandle entity)
		=> TransformPoint(Float3(0.0f, 0.0f, 0.0f), mScene.GetWorldMatrix(entity));

	private VoiceHandle PlayComponent(AudioSourceComponent* component, EntityHandle entity)
	{
		if (mEngine == null)
			return .();

		// An inactive entity makes no sound.
		if ((mScene != null) && !mScene.IsEffectivelyActive(entity))
			return .();

		// The discriminant decides. A CUE resolves one weighted variant plus this trigger's
		// jitter; a CLIP plays the one clip. An EMPTY cue stays a silent no operation, its
		// pick naming no variant and leaving the clip null.
		AudioClip clip = null;
		var cuePitch = 1.0f;
		var cueVolume = 1.0f;

		if (component.SourceType == .Cue)
		{
			if (let cue = component.Cue.Get)
			{
				let pick = SoundCue.Resolve(cue, ref mCueRandom, component.LastCueVariant,
					ref component.CueSequentialCursor);
				if (pick.IsValid)
				{
					component.LastCueVariant = pick.VariantIndex;
					clip = cue.Variants[pick.VariantIndex].Clip;
					cuePitch = pick.Pitch;
					cueVolume = pick.Volume;
				}
			}
		}
		else
		{
			clip = component.Clip.Get;
		}

		if (clip == null)
		{
			GlobalLog(.Warning, "Audio: '{}' has no clip or cue", mScene.GetEntityName(entity));
			return .();
		}

		if (mEngine.IsValidHandle(component.Voice))
			mEngine.Stop(component.Voice);

		var parameters = AudioPlayParams();
		parameters.Bus = component.Bus;
		parameters.BusName = component.BusName;
		parameters.Volume = component.Volume * cueVolume;
		parameters.Pitch = component.Pitch * cuePitch;
		parameters.Loop = component.Loop;
		parameters.Priority = component.Priority;
		parameters.SceneGroup = mSceneGroup;
		// A persistent authored source is NEVER merged with another: four torches sharing one
		// clip are four voices, and automatic playback starts them in the same instant, which
		// the one shot merge window would otherwise collapse into one.
		parameters.AllowDedupe = false;
		parameters.ReverbSend = component.ReverbSend;
		parameters.Spatial = component.Spatial;

		if (component.Spatial)
		{
			parameters.DistanceLowpassHz = component.DistanceLowpassHz;
			parameters.Position = EntityPosition(entity);
			parameters.MinDistance = component.MinDistance;
			parameters.MaxDistance = component.MaxDistance;
			parameters.AttenuationModel = component.AttenuationModel;
			parameters.Rolloff = component.Rolloff;
			parameters.DopplerFactor = component.DopplerFactor;
			parameters.ConeInnerAngleDegrees = component.ConeInnerAngleDegrees;
			parameters.ConeOuterAngleDegrees = component.ConeOuterAngleDegrees;
			parameters.ConeOuterGain = component.ConeOuterGain;
		}

		component.Voice = mEngine.Play(clip, parameters);
		component.PreviousPosition = parameters.Position;
		component.HasPreviousPosition = component.Spatial;
		return component.Voice;
	}

	/// The WETTEST zone containing the listener drives the scene's reverb, its wet signal
	/// fading across the edge band. No listener, or no zone, means dry: the node bypasses and
	/// the tail decays on its own rather than cutting.
	private void UpdateReverbZones()
	{
		if ((mEngine == null) || (mSceneGroup == 0))
			return;

		var best = AudioReverbParams();
		best.Wet = 0.0f;

		let zones = mScene.GetSystem<AudioReverbZoneComponentManager>();
		if (mListenerValid && (zones != null))
		{
			zones.ForEach(scope [&] (zone, entity) =>
				{
					if (!zone.Enabled || (zone.Radius <= 0.0f) || (zone.WetLevel <= 0.0f))
						return;

					let center = EntityPosition(entity);
					let delta = Float3(mListenerPosition.X - center.X,
						mListenerPosition.Y - center.Y, mListenerPosition.Z - center.Z);
					let distance = Math.Sqrt(delta.X * delta.X + delta.Y * delta.Y
						+ delta.Z * delta.Z);
					if (distance >= zone.Radius)
						return;

					let fadeWidth = Math.Max(zone.EdgeFade * zone.Radius, 0.001f);
					let blend = Math.Clamp((zone.Radius - distance) / fadeWidth, 0.0f, 1.0f);
					let wet = zone.WetLevel * blend;
					if (wet > best.Wet)
					{
						best.Wet = wet;
						best.RoomSize = zone.RoomSize;
						best.Damping = zone.Damping;
					}
				});
		}

		mEngine.SetSceneReverb(mSceneGroup, best);
	}

	/// EVERY active listener collects, which is what a split screen's ears are, and the FIRST
	/// stays the scene's primary for the zones and the single pose accessors.
	private void UpdateListenerPose(float deltaTime)
	{
		mListenerValid = false;
		mListenerPoses.Clear();

		let listeners = mScene.GetSystem<AudioListenerComponentManager>();
		if (listeners == null)
			return;

		listeners.ForEach(scope [&] (component, entity) =>
			{
				if (!component.IsActive)
					return;

				let world = mScene.GetWorldMatrix(entity);

				var pose = ListenerPose();
				pose.Position = TransformPoint(Float3(0.0f, 0.0f, 0.0f), world);
				// Row vector convention: forward is the negated third row, up is the second.
				pose.Forward = Normalized(Float3(-world.M[2][0], -world.M[2][1], -world.M[2][2]));
				pose.Up = Normalized(Float3(world.M[1][0], world.M[1][1], world.M[1][2]));
				pose.Velocity = (component.HasPreviousPosition && (deltaTime > 0.0f))
					? Float3((pose.Position.X - component.PreviousPosition.X) / deltaTime,
						(pose.Position.Y - component.PreviousPosition.Y) / deltaTime,
						(pose.Position.Z - component.PreviousPosition.Z) / deltaTime)
					: Float3(0.0f, 0.0f, 0.0f);

				component.PreviousPosition = pose.Position;
				component.HasPreviousPosition = true;

				if (!mListenerValid)
				{
					mListenerPosition = pose.Position;
					mListenerForward = pose.Forward;
					mListenerUp = pose.Up;
					mListenerVelocity = pose.Velocity;
					mListenerValid = true;
				}

				mListenerPoses.Add(pose);
			});
	}
}
