namespace Sedulous.Engine.Audio;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Core.Mathematics;

/// Manages audio source components: resolves clip resources, creates/destroys
/// IAudioSource handles, syncs 3D positions from entity transforms, and
/// applies volume category multipliers.
///
/// Updates in PostTransform phase - after transforms are finalized so 3D
/// positions are correct.
class AudioSourceComponentManager : ComponentManager<AudioSourceComponent>
{
	/// Audio system for creating/destroying sources.
	public IAudioSystem AudioSystem { get; set; }

	/// Resource system for resolving clip refs.
	public ResourceSystem ResourceSystem { get; set; }

	/// Reference to the subsystem for volume category access.
	public AudioSubsystem Subsystem { get; set; }

	/// Per-component resource resolution tracking.
	private Dictionary<EntityHandle, AudioResolveState> mResolveStates = new .() ~ {
		for (let kv in _)
		{
			kv.value.Release();
			delete kv.value;
		}
		delete _;
	};

	public override StringView SerializationTypeId => "Sedulous.AudioSourceComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		// PostTransform: after transforms are finalized, sync 3D positions
		RegisterUpdate(.PostTransform, new => UpdateAudioSources);
	}

	private void UpdateAudioSources(float deltaTime)
	{
		if (AudioSystem == null || ResourceSystem == null) return;
		let scene = Scene;
		if (scene == null) return;

		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;

			// Resolve clip resource
			ResolveResources(comp);

			// Create source once clip is ready
			if (comp.Source == null && comp.Clip != null)
			{
				comp.Source = AudioSystem.CreateSource();
				if (comp.Source != null && comp.AutoPlay)
					comp.PlayRequested = true;
			}

			if (comp.Source == null) continue;

			// Apply properties - bus volumes are handled by the graph, not here
			comp.Source.Volume = comp.Volume;
			comp.Source.Pitch = comp.Pitch;
			comp.Source.Loop = comp.Loop;
			comp.Source.MinDistance = comp.MinDistance;
			comp.Source.MaxDistance = comp.MaxDistance;
			comp.Source.BusName = comp.BusName;

			// Apply attenuator
			if (comp.UseAttenuator)
				comp.Source.Attenuator = comp.AttenuatorConfig;
			else
				comp.Source.Attenuator = null;

			// Sync 3D position and direction from entity transform
			if (comp.Spatial)
			{
				let worldMatrix = scene.GetWorldMatrix(comp.Owner);
				comp.Source.Position = worldMatrix.Translation;

				// Forward direction for cone attenuation (negative Z in row-major)
				comp.Source.Direction = Vector3.Normalize(Vector3(worldMatrix.M31, worldMatrix.M32, worldMatrix.M33));
			}

			// Handle play request - prefer cue over clip
			if (comp.PlayRequested)
			{
				comp.PlayRequested = false;
				if (comp.Cue != null)
				{
					// Play through cue system (handles selection, randomization, voice limits)
					if (comp.Spatial)
						AudioSystem.PlayCue3D(comp.Cue, comp.Source.Position, comp.Volume);
					else
						AudioSystem.PlayCue(comp.Cue, comp.Volume);
				}
				else if (comp.Clip != null)
				{
					comp.Source.Play(comp.Clip);
				}
			}
		}
	}

	private void ResolveResources(AudioSourceComponent comp)
	{
		let state = GetOrCreateResolveState(comp.Owner);

		// Resolve clip
		let clipRef = comp.ClipRef;
		if (state.Clip.Resolve(ResourceSystem, clipRef))
		{
			let res = state.Clip.Handle.Resource;
			if (res != null && res.Clip != null)
				comp.Clip = res.Clip;
			else
				comp.Clip = null;
		}
		else if (!clipRef.IsValid && comp.Clip != null)
		{
			comp.Clip = null;
		}

		// Resolve cue
		let cueRef = comp.CueRef;
		if (state.Cue.Resolve(ResourceSystem, cueRef))
		{
			let res = state.Cue.Handle.Resource;
			if (res != null && res.Cue != null)
				comp.Cue = res.Cue;
			else
				comp.Cue = null;
		}
		else if (!cueRef.IsValid && comp.Cue != null)
		{
			comp.Cue = null;
		}
	}

	private AudioResolveState GetOrCreateResolveState(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let existing))
			return existing;
		let state = new AudioResolveState();
		mResolveStates[entity] = state;
		return state;
	}

	protected override void OnComponentDestroyed(AudioSourceComponent comp)
	{
		// Destroy the audio source if the audio system is still alive
		if (comp.Source != null && AudioSystem != null)
		{
			AudioSystem.DestroySource(comp.Source);
			comp.Source = null;
		}
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		if (mResolveStates.TryGetValue(entity, let state))
		{
			state.Release();
			delete state;
			mResolveStates.Remove(entity);
		}
		base.OnEntityDestroyed(entity);
	}
}

/// Per-component resource resolution tracking for audio sources.
class AudioResolveState
{
	public ResolvedResource<AudioClipResource> Clip;
	public ResolvedResource<SoundCueResource> Cue;

	public void Release()
	{
		Clip.Release();
		Cue.Release();
	}
}
