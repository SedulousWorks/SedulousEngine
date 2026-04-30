namespace Sedulous.Engine.Audio;

using System;
using Sedulous.Runtime;
using Sedulous.Engine.Core;
using Sedulous.Engine;
using Sedulous.Resources;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Audio.Resources;
using Sedulous.Core.Mathematics;

/// Owns the audio system backend, volume categories, music streaming,
/// and injects audio component managers into scenes via ISceneAware.
///
/// Volume hierarchy: MasterVolume × CategoryVolume (SFX or Music) = effective volume.
/// Music playback is managed directly on the subsystem (typically one track).
/// One-shot API provides fire-and-forget sound effects without components.
class AudioSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => 200;

	private Sedulous.Resources.ResourceSystem mResourceSystem;
	private IAudioSystem mAudioSystem ~ { _?.Dispose(); delete _; };
	private AudioClipResourceManager mClipResourceManager ~ delete _;
	private SoundCueResourceManager mCueResourceManager ~ delete _;

	public this(Sedulous.Resources.ResourceSystem resourceSystem)
	{
		mResourceSystem = resourceSystem;
	}
	/// Current music stream (owned by IAudioSystem, not by us - don't delete).
	private IAudioStream mCurrentMusic;

	// --- Volume (bus-based) ---

	/// Master volume affecting all audio (0.0 to 1.0).
	/// Controls the Master bus volume.
	public float MasterVolume
	{
		get => GetBusVolume("Master");
		set => SetBusVolume("Master", value);
	}

	/// SFX volume (0.0 to 1.0). Controls the SFX bus volume.
	public float SFXVolume
	{
		get => GetBusVolume("SFX");
		set => SetBusVolume("SFX", value);
	}

	/// Music volume (0.0 to 1.0). Controls the Music bus volume.
	public float MusicVolume
	{
		get => GetBusVolume("Music");
		set
		{
			SetBusVolume("Music", value);
			SyncMusicVolume();
		}
	}

	/// Gets a bus volume by name.
	public float GetBusVolume(StringView busName)
	{
		if (mAudioSystem?.BusSystem != null)
			if (let bus = mAudioSystem.BusSystem.GetBus(busName))
				return bus.Volume;
		return 1.0f;
	}

	/// Sets a bus volume by name.
	public void SetBusVolume(StringView busName, float volume)
	{
		if (mAudioSystem?.BusSystem != null)
			if (let bus = mAudioSystem.BusSystem.GetBus(busName))
				bus.Volume = Math.Clamp(volume, 0.0f, 1.0f);
	}

	/// Gets the audio system (for direct access if needed).
	public IAudioSystem AudioSystem => mAudioSystem;

	// ==================== Lifecycle ====================

	protected override void OnInit()
	{
		// Create SDL3 audio backend
		mAudioSystem = new SDL3AudioSystem();
		if (!mAudioSystem.IsInitialized)
			Console.Error.WriteLine("[AudioSubsystem] Failed to initialize audio system");

		// Register resource managers
		mClipResourceManager = new AudioClipResourceManager(mAudioSystem);
		mResourceSystem.AddResourceManager(mClipResourceManager);

		mCueResourceManager = new SoundCueResourceManager();
		mResourceSystem.AddResourceManager(mCueResourceManager);
	}

	protected override void OnPrepareShutdown()
	{
		// Stop music before shutdown
		StopMusic();
	}

	protected override void OnShutdown()
	{
		if (mCueResourceManager != null)
			mResourceSystem.RemoveResourceManager(mCueResourceManager);
		if (mClipResourceManager != null)
			mResourceSystem.RemoveResourceManager(mClipResourceManager);
	}

	public override void Update(float deltaTime)
	{
		// Update audio system each frame (3D spatialization, one-shot cleanup, stream feeding)
		if (mAudioSystem != null)
			mAudioSystem.Update();
	}

	// ==================== ISceneAware ====================

	public void OnSceneCreated(Scene scene)
	{
		if (mAudioSystem == null) return;

		// Inject audio source component manager
		let sourceMgr = new AudioSourceComponentManager();
		sourceMgr.AudioSystem = mAudioSystem;
		sourceMgr.ResourceSystem = mResourceSystem;
		sourceMgr.Subsystem = this;
		scene.AddModule(sourceMgr);

		// Inject audio listener component manager
		let listenerMgr = new AudioListenerComponentManager();
		listenerMgr.AudioSystem = mAudioSystem;
		scene.AddModule(listenerMgr);
	}

	public void OnSceneReady(Scene scene) { }

	public void OnSceneDestroyed(Scene scene)
	{
	}

	// ==================== Music (Streaming) ====================

	/// Plays music from a file path (streamed from disk, not loaded into memory).
	/// Stops any currently playing music. Returns true if the stream opened successfully.
	public bool PlayMusic(StringView filePath, bool loop = true, float volume = 1.0f)
	{
		StopMusic();

		if (mAudioSystem == null) return false;

		if (mAudioSystem.OpenStream(filePath) case .Ok(let stream))
		{
			mCurrentMusic = stream;
			mCurrentMusic.Volume = volume * GetBusVolume("Music") * GetBusVolume("Master");
			mCurrentMusic.Loop = loop;
			mCurrentMusic.Play();
			return true;
		}

		return false;
	}

	/// Stops the currently playing music.
	public void StopMusic()
	{
		if (mCurrentMusic != null)
		{
			mCurrentMusic.Stop();
			mCurrentMusic = null; // owned by IAudioSystem, don't delete
		}
	}

	/// Pauses the currently playing music.
	public void PauseMusic()
	{
		if (mCurrentMusic != null)
			mCurrentMusic.Pause();
	}

	/// Resumes paused music.
	public void ResumeMusic()
	{
		if (mCurrentMusic != null)
			mCurrentMusic.Resume();
	}

	/// Whether music is currently playing.
	public bool IsMusicPlaying => mCurrentMusic != null && mCurrentMusic.State == .Playing;

	// ==================== One-Shot API ====================

	/// Plays a clip once with fire-and-forget (no component needed).
	/// Volume is the per-source volume; bus volumes are applied by the graph.
	public void PlayOneShot(AudioClip clip, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayOneShot(clip, volume);
	}

	/// Plays a clip at a 3D position with fire-and-forget.
	/// Volume is the per-source volume; bus volumes are applied by the graph.
	public void PlayOneShot3D(AudioClip clip, Vector3 position, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayOneShot3D(clip, position, volume);
	}

	// ==================== Sound Cue API ====================

	/// Plays a sound cue with fire-and-forget semantics.
	/// Selects entry, applies volume/pitch randomization, routes to cue's bus.
	public void PlayCue(SoundCue cue, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayCue(cue, volume);
	}

	/// Plays a sound cue at a 3D position with fire-and-forget.
	public void PlayCue3D(SoundCue cue, Vector3 position, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayCue3D(cue, position, volume);
	}

	// ==================== Internal ====================

	private void SyncMusicVolume()
	{
		// Streams still use SDL directly, so apply combined volume
		if (mCurrentMusic != null)
			mCurrentMusic.Volume = GetBusVolume("Music") * GetBusVolume("Master");
	}
}
