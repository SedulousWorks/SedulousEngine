namespace Sedulous.Engine.Audio;

using System;
using Sedulous.Runtime;
using Sedulous.Scenes;
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

	public this(Sedulous.Resources.ResourceSystem resourceSystem)
	{
		mResourceSystem = resourceSystem;
	}
	/// Current music stream (owned by IAudioSystem, not by us - don't delete).
	private IAudioStream mCurrentMusic;

	// --- Volume Categories ---

	private float mMasterVolume = 1.0f;
	private float mSFXVolume = 1.0f;
	private float mMusicVolume = 1.0f;

	/// Master volume affecting all audio (0.0 to 1.0).
	public float MasterVolume
	{
		get => mMasterVolume;
		set
		{
			mMasterVolume = Math.Clamp(value, 0.0f, 1.0f);
			SyncMasterVolume();
		}
	}

	/// SFX volume category (0.0 to 1.0). Multiplied by MasterVolume.
	public float SFXVolume
	{
		get => mSFXVolume;
		set => mSFXVolume = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// Music volume category (0.0 to 1.0). Multiplied by MasterVolume.
	public float MusicVolume
	{
		get => mMusicVolume;
		set
		{
			mMusicVolume = Math.Clamp(value, 0.0f, 1.0f);
			SyncMusicVolume();
		}
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

		// Register clip resource manager (needs audio system for clip loading)
		mClipResourceManager = new AudioClipResourceManager(mAudioSystem);
		mResourceSystem.AddResourceManager(mClipResourceManager);
	}

	protected override void OnPrepareShutdown()
	{
		// Stop music before shutdown
		StopMusic();
	}

	protected override void OnShutdown()
	{
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
			mCurrentMusic.Volume = volume * mMusicVolume * mMasterVolume;
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
	/// Volume is multiplied by MasterVolume × SFXVolume.
	public void PlayOneShot(AudioClip clip, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayOneShot(clip, volume * mSFXVolume * mMasterVolume);
	}

	/// Plays a clip at a 3D position with fire-and-forget.
	/// Volume is multiplied by MasterVolume × SFXVolume.
	public void PlayOneShot3D(AudioClip clip, Vector3 position, float volume = 1.0f)
	{
		if (mAudioSystem != null)
			mAudioSystem.PlayOneShot3D(clip, position, volume * mSFXVolume * mMasterVolume);
	}

	// ==================== Internal ====================

	private void SyncMasterVolume()
	{
		if (mAudioSystem != null)
			mAudioSystem.MasterVolume = mMasterVolume;
		SyncMusicVolume();
	}

	private void SyncMusicVolume()
	{
		if (mCurrentMusic != null)
			mCurrentMusic.Volume = mMusicVolume * mMasterVolume;
	}
}
