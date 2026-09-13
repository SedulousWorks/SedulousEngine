using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Engine.Audio;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio.Tests;

/// A headless engine and a scene wired to it: what every audio scene case is built from.
///
/// A HEADLESS engine opens no device, so the update pumps the mixer itself and the whole
/// voice state machine runs deterministically here and on a machine with no sound card.
class AudioPlayScene
{
	public AudioEngineSettings Settings = new .() ~ delete _;
	public AudioEngine Engine ~ delete _;
	public Scene Scene = new .("audio-test") ~ delete _;
	/// BORROWED from the scene.
	public AudioSceneSystem Audio = null;

	private List<AudioClip> mClips = new .() ~ ClearAndDeleteItems!(_);

	/// The merge window is NOUGHT by default, because these cases place explicit voices and
	/// the window would collapse them. A case about merging sets its own.
	public this(float dedupeWindowSeconds = 0.0f)
	{
		Settings.Headless = true;
		Settings.DedupeWindowSeconds = dedupeWindowSeconds;
		Engine = new AudioEngine(Settings);

		AudioScene.AddAudioSceneManagers(Scene);
		Audio = Scene.GetSystem<AudioSceneSystem>();
		Audio.SetEngine(Engine);
	}

	/// A clip THIS fixture owns, so a case need not track one.
	public AudioClip AddClip(float seconds, uint32 sampleRate = 8000, uint32 channels = 1)
	{
		let clip = MakeToneClip(seconds, sampleRate, channels);
		mClips.Add(clip);
		return clip;
	}

	public EntityHandle AddSource(AudioClip clip, Float3 position, bool autoPlay = true,
		bool loop = true)
	{
		let entity = Scene.CreateEntity("source");
		Scene.SetLocalPosition(entity, position);

		let component = Sources.Add(entity);
		component.Clip.SetDirect(clip);
		component.AutoPlay = autoPlay;
		component.Loop = loop;
		return entity;
	}

	public AudioSourceComponentManager Sources => Scene.GetSystem<AudioSourceComponentManager>();
	public AudioListenerComponentManager Listeners
		=> Scene.GetSystem<AudioListenerComponentManager>();
	public AudioReverbZoneComponentManager Zones
		=> Scene.GetSystem<AudioReverbZoneComponentManager>();

	public void Start()
	{
		Scene.Start();
		Scene.SetSimulationEnabled(true);
	}

	public void Frame(float deltaTime = 1.0f / 60.0f)
	{
		Scene.Update(deltaTime);
		Engine.Update(deltaTime);
	}

	/// A sine encoded as a real wav, so the engine decodes and registers it exactly as it
	/// would a cooked clip. THE CALLER OWNS what comes back.
	public static AudioClip MakeToneClip(float seconds, uint32 sampleRate = 8000,
		uint32 channels = 1)
	{
		let samples = scope List<int16>();
		let frameCount = (int)(seconds * (float)sampleRate);
		for (int frame < frameCount)
		{
			let t = (float)frame / (float)sampleRate;
			let sample = (int16)(0.5f * Sin(2.0f * 3.14159265f * 440.0f * t) * 32000.0f);
			for (uint32 channel < channels)
				samples.Add(sample);
		}

		let clip = new AudioClip();
		Test.Assert(AudioCodec.EncodeWav(samples, channels, sampleRate, clip.EncodedData));
		Test.Assert(AudioCodec.Probe(clip.EncodedBytes, let metadata));

		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		return clip;
	}

	public static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
}
