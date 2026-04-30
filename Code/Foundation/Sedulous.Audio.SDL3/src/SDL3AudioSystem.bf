using System;
using System.Collections;
using SDL3;
using Sedulous.Core.Mathematics;
using Sedulous.Audio;
using Sedulous.Audio.Graph;

namespace Sedulous.Audio.SDL3;

/// SDL3 implementation of IAudioSystem using the audio node graph and bus system.
class SDL3AudioSystem : IAudioSystem
{
	private SDL_AudioDeviceID mDeviceId;
	private AudioListener mListener = new .() ~ delete _;
	private List<AudioSource> mSources = new .() ~ DeleteContainerAndItems!(_);
	private List<AudioSource> mOneShotSources = new .() ~ DeleteContainerAndItems!(_);
	private List<SDL3AudioStream> mStreams = new .() ~ DeleteContainerAndItems!(_);
	private float mMasterVolume = 1.0f;
	private bool mOwnedAudioInit;
	private bool mPaused;

	// Graph-based mixing
	private SDL3AudioMixer mMixer ~ { if (_ != null) { _.Dispose(); delete _; } };

	/// Returns true if the audio system initialized successfully.
	public bool IsInitialized => mDeviceId != 0;

	/// The audio mixer managing the graph and device output.
	public SDL3AudioMixer Mixer => mMixer;

	/// The bus system for routing audio.
	public IAudioBusSystem BusSystem => mMixer?.BusSystem;

	/// Creates an SDL3AudioSystem with default audio device and format.
	public this()
	{
		// Initialize SDL audio subsystem if not already initialized
		if (SDL3.SDL_WasInit(.SDL_INIT_AUDIO) == 0)
		{
			if (!SDL3.SDL_InitSubSystem(.SDL_INIT_AUDIO))
			{
				LogError("Failed to initialize SDL audio subsystem");
				return;
			}
			mOwnedAudioInit = true;
		}

		// Open default playback device
		mDeviceId = SDL3.SDL_OpenAudioDevice(SDL3.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, null);
		if (mDeviceId == 0)
		{
			LogError("Failed to open audio device");
			return;
		}

		// Create mixer (owns graph + bus system)
		mMixer = new SDL3AudioMixer(mDeviceId);
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		// Stop all sources (disconnects from graph)
		for (let source in mSources)
			source.Stop();
		for (let source in mOneShotSources)
			source.Stop();

		// Delete sources (their nodes are standalone, not owned by graph)
		for (let source in mSources)
			delete source;
		mSources.Clear();

		for (let source in mOneShotSources)
			delete source;
		mOneShotSources.Clear();

		for (let stream in mStreams)
			delete stream;
		mStreams.Clear();

		// Mixer disposes bus system + graph
		if (mMixer != null)
		{
			mMixer.Dispose();
			delete mMixer;
			mMixer = null;
		}

		// Close audio device
		if (mDeviceId != 0)
		{
			SDL3.SDL_CloseAudioDevice(mDeviceId);
			mDeviceId = 0;
		}

		// Quit audio subsystem if we initialized it
		if (mOwnedAudioInit)
		{
			SDL3.SDL_QuitSubSystem(.SDL_INIT_AUDIO);
			mOwnedAudioInit = false;
		}
	}

	public AudioListener Listener => mListener;

	public float MasterVolume
	{
		get => mMasterVolume;
		set
		{
			mMasterVolume = Math.Clamp(value, 0.0f, 1.0f);

			// Set master bus volume
			if (mMixer?.BusSystem != null)
				mMixer.BusSystem.Master.Volume = mMasterVolume;

			for (let stream in mStreams)
				stream.SetMasterVolume(mMasterVolume);
		}
	}

	public IAudioSource CreateSource()
	{
		if (mDeviceId == 0)
			return null;

		let source = new AudioSource();
		RouteSourceToBus(source);
		mSources.Add(source);
		return source;
	}

	public void DestroySource(IAudioSource source)
	{
		if (let sdlSource = source as AudioSource)
		{
			sdlSource.Stop();
			mSources.Remove(sdlSource);
			delete sdlSource;
		}
	}

	public void PlayOneShot(AudioClip clip, float volume)
	{
		if (mDeviceId == 0)
			return;

		if (clip != null && clip.IsLoaded)
		{
			let source = new AudioSource();
			source.IsOneShot = true;
			source.Volume = volume;
			RouteSourceToBus(source);
			source.Play(clip);
			mOneShotSources.Add(source);
		}
	}

	public void PlayOneShot3D(AudioClip clip, Vector3 position, float volume)
	{
		if (mDeviceId == 0)
			return;

		if (clip != null && clip.IsLoaded)
		{
			let source = new AudioSource();
			source.IsOneShot = true;
			source.Volume = volume;
			source.Position = position;
			source.Update3D(mListener);
			RouteSourceToBus(source);
			source.Play(clip);
			mOneShotSources.Add(source);
		}
	}

	private Random mCueRandom = new .() ~ delete _;
	private float mCueTime;

	public void PlayCue(SoundCue cue, float volume)
	{
		if (mDeviceId == 0 || cue == null)
			return;

		if (let entry = cue.SelectEntry(mCueTime))
		{
			if (entry.Clip == null || !entry.Clip.IsLoaded)
				return;

			let source = new AudioSource();
			source.IsOneShot = true;
			source.Volume = volume * SoundCue.RandomizeVolume(entry, mCueRandom);
			source.Pitch = SoundCue.RandomizePitch(entry, mCueRandom);
			source.BusName = cue.BusName;
			RouteSourceToBus(source);
			source.Play(entry.Clip);
			mOneShotSources.Add(source);
			cue.NotifyInstanceStarted();
		}
	}

	public void PlayCue3D(SoundCue cue, Vector3 position, float volume)
	{
		if (mDeviceId == 0 || cue == null)
			return;

		if (let entry = cue.SelectEntry(mCueTime))
		{
			if (entry.Clip == null || !entry.Clip.IsLoaded)
				return;

			let source = new AudioSource();
			source.IsOneShot = true;
			source.Volume = volume * SoundCue.RandomizeVolume(entry, mCueRandom);
			source.Pitch = SoundCue.RandomizePitch(entry, mCueRandom);
			source.Position = position;
			source.BusName = cue.BusName;
			source.Update3D(mListener);
			RouteSourceToBus(source);
			source.Play(entry.Clip);
			mOneShotSources.Add(source);
			cue.NotifyInstanceStarted();
		}
	}

	public Result<AudioClip> LoadClip(Span<uint8> data)
	{
		if (mDeviceId == 0)
			return .Err;

		// Create SDL_IOStream from memory
		let io = SDL3.SDL_IOFromConstMem(data.Ptr, (.)data.Length);
		if (io == null)
			return .Err;

		// Load WAV file
		SDL_AudioSpec spec = .();
		uint8* audioData = null;
		uint32 audioLen = 0;

		if (!SDL3.SDL_LoadWAV_IO(io, true, &spec, &audioData, &audioLen))
		{
			LogError("Failed to load WAV data");
			return .Err;
		}

		// Convert SDL format to our AudioFormat
		AudioFormat format;
		switch (spec.format)
		{
		case .SDL_AUDIO_S16:
			format = .Int16;
		case .SDL_AUDIO_S32:
			format = .Int32;
		case .SDL_AUDIO_F32:
			format = .Float32;
		default:
			// Unsupported format - free SDL memory and return error
			SDL3.SDL_free(audioData);
			LogError("Unsupported audio format");
			return .Err;
		}

		// Copy data to our buffer (SDL uses SDL_free, we use delete)
		uint8* ourData = new uint8[audioLen]*;
		Internal.MemCpy(ourData, audioData, audioLen);
		SDL3.SDL_free(audioData);

		return .Ok(new AudioClip(ourData, audioLen, spec.freq, (.)spec.channels, format, ownsData: true));
	}

	public Result<IAudioStream> OpenStream(StringView filePath)
	{
		if (mDeviceId == 0)
			return .Err;

		let stream = new SDL3AudioStream(mDeviceId, filePath);
		if (!stream.IsReady)
		{
			delete stream;
			return .Err;
		}

		stream.SetMasterVolume(mMasterVolume);
		mStreams.Add(stream);
		return .Ok(stream);
	}

	public void PauseAll()
	{
		if (mDeviceId != 0 && !mPaused)
		{
			SDL3.SDL_PauseAudioDevice(mDeviceId);
			mPaused = true;
		}
	}

	public void ResumeAll()
	{
		if (mDeviceId != 0 && mPaused)
		{
			SDL3.SDL_ResumeAudioDevice(mDeviceId);
			mPaused = false;
		}
	}

	public void Update()
	{
		// Update all user-created sources
		for (let source in mSources)
		{
			// Update 3D audio (distance attenuation + stereo panning)
			source.Update3D(mListener);

			// Update playback state (feeds chunks, handles looping)
			source.UpdateState();
			UpdateSourceBusRouting(source);
		}

		// Update and clean up one-shot sources
		for (var i = mOneShotSources.Count - 1; i >= 0; i--)
		{
			let source = mOneShotSources[i];

			// Update 3D audio (distance attenuation + stereo panning)
			source.Update3D(mListener);

			// Update playback state
			source.UpdateState();

			// Clean up finished one-shots
			if (source.IsFinished)
			{
				mOneShotSources.RemoveAt(i);
				delete source;
			}
		}

		// Update streams
		for (let stream in mStreams)
			stream.Update();

		// Evaluate the audio graph and push to device
		if (mMixer != null)
			mMixer.Mix();
	}

	/// Routes a source to its target bus based on BusName.
	private void RouteSourceToBus(AudioSource source)
	{
		if (mMixer?.BusSystem == null)
			return;

		let bus = mMixer.BusSystem.GetBusInternal(source.BusName);
		if (bus != null)
			source.SetTargetBus(bus.InputNode);
		else
		{
			// Fallback to master
			let master = mMixer.BusSystem.GetBusInternal("Master");
			if (master != null)
				source.SetTargetBus(master.InputNode);
		}
	}

	/// Re-routes a source if its BusName changed.
	private void UpdateSourceBusRouting(AudioSource source)
	{
		if (mMixer?.BusSystem == null)
			return;

		let bus = mMixer.BusSystem.GetBusInternal(source.BusName);
		let targetInput = (bus != null) ? bus.InputNode : mMixer.BusSystem.GetBusInternal("Master")?.InputNode;

		if (targetInput != null)
			source.SetTargetBus(targetInput);
	}

	private void LogError(StringView message)
	{
		let sdlError = SDL3.SDL_GetError();
		if (sdlError != null && sdlError[0] != 0)
			Console.Error.WriteLine(scope $"[SDL3AudioSystem] {message}: {StringView(sdlError)}");
		else
			Console.Error.WriteLine(scope $"[SDL3AudioSystem] {message}");
	}
}
