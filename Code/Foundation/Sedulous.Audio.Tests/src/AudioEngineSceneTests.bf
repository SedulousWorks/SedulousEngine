using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using static Sedulous.Audio.Tests.AudioEngineFixture;

namespace Sedulous.Audio.Tests;

/// The per scene machinery: the child groups a scene pauses and tears down, the reverb its
/// zones drive, the sends its voices feed, the distance filter, music, and the streaming
/// seam.
class AudioEngineSceneTests
{
	/// A scene's pause HOLDS its voices rather than reaping them, its stop fades them, and
	/// its teardown frees them at once. A global voice is untouched throughout.
	[Test]
	public static void ASceneGroupPausesStopsAndTearsDownItsOwnVoicesOnly()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(1.0f);
		let globalClip = MakeToneClip(1.0f, 4000, 1);
		defer { delete clip; delete globalClip; }

		let sceneGroup = engine.CreateSceneGroup();
		Test.Assert(sceneGroup != 0);

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.SceneGroup = sceneGroup;
		let voice = engine.Play(clip, parameters);

		var globalParams = AudioPlayParams();
		globalParams.Loop = true;
		let globalVoice = engine.Play(globalClip, globalParams);
		Test.Assert(voice.IsValid);
		Test.Assert(globalVoice.IsValid);

		engine.SetSceneGroupPaused(sceneGroup, true);
		Test.Assert(engine.IsSceneGroupPaused(sceneGroup));
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(engine.IsValidHandle(voice));
		Test.Assert(engine.IsValidHandle(globalVoice));

		engine.SetSceneGroupPaused(sceneGroup, false);
		Test.Assert(!engine.IsSceneGroupPaused(sceneGroup));

		engine.StopSceneGroup(sceneGroup);
		engine.Update(0.2f);
		Test.Assert(!engine.IsValidHandle(voice));
		Test.Assert(engine.IsValidHandle(globalVoice));

		let again = engine.Play(clip, parameters);
		Test.Assert(again.IsValid);
		engine.DestroySceneGroup(sceneGroup);
		Test.Assert(!engine.IsValidHandle(again));
		Test.Assert(engine.IsValidHandle(globalVoice));
	}

	/// A custom bus voice routes OUTSIDE the scene's child groups, since the named tree is
	/// engine wide, so the scene's pause has to reach it one voice at a time.
	[Test]
	public static void ASceneGroupPauseFreezesItsCustomBusVoicesToo()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		let drums = new AudioNamedBus();
		drums.Name.Set("drums");
		layout.CustomBuses.Add(drums);
		engine.ApplyBusLayout(layout);

		let sceneGroup = engine.CreateSceneGroup();
		Test.Assert(sceneGroup != 0);

		let clip = MakeToneClip(1.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.SceneGroup = sceneGroup;
		parameters.BusName = "drums";
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);

		engine.SetSceneGroupPaused(sceneGroup, true);
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(engine.IsValidHandle(voice));
		Test.Assert(engine.GetVoiceStatus(voice, let status));
		Test.Assert(status.BusName == "drums");

		engine.SetSceneGroupPaused(sceneGroup, false);
		engine.Update(0.1f);
		Test.Assert(engine.IsPlaying(voice));

		engine.DestroySceneGroup(sceneGroup);
		Test.Assert(!engine.IsValidHandle(voice));
	}

	/// The cutoff glides open at the near distance down to the voice's floor at the far one,
	/// monotonically in between. A floor of nothing puts no filter in the chain at all.
	[Test]
	public static void TheDistanceFilterGlidesOpenToItsFloor()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		engine.SetListenerTransform(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0), .(0, 0, 0));

		let clip = MakeToneClip(2.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.Spatial = true;
		parameters.MinDistance = 2.0f;
		parameters.MaxDistance = 20.0f;
		parameters.DistanceLowpassHz = 4000.0f;
		// At the near distance, which is fully open.
		parameters.Position = .(0.0f, 0.0f, -2.0f);
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		engine.Update(1.0f / 60.0f);

		Test.Assert(engine.GetVoiceStatus(voice, var status));
		let openCutoff = status.LowpassCutoffHz;
		Test.Assert(openCutoff > 15000.0f);

		engine.SetVoicePosition(voice, .(0.0f, 0.0f, -20.0f), .(0, 0, 0));
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(Near(status.LowpassCutoffHz, 4000.0f, 80.0f));

		engine.SetVoicePosition(voice, .(0.0f, 0.0f, -11.0f), .(0, 0, 0));
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(status.LowpassCutoffHz > 4100.0f);
		Test.Assert(status.LowpassCutoffHz < (openCutoff - 100.0f));

		var unfiltered = parameters;
		unfiltered.DistanceLowpassHz = 0.0f;
		let plain = engine.Play(clip, unfiltered);
		Test.Assert(plain.IsValid);
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(plain, out status));
		Test.Assert(status.LowpassCutoffHz == 0.0f);
	}

	/// Music is ONE tracked voice on the Music bus: a new track fades the incumbent out over
	/// the same window the newcomer fades in, and both are alive through the overlap.
	[Test]
	public static void PlayMusicCrossFadesAndStopMusicForgetsTheVoice()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let trackA = MakeToneClip(3.0f);
		let trackB = MakeToneClip(3.0f);
		defer { delete trackA; delete trackB; }

		let first = engine.PlayMusic(trackA, 0.2f);
		Test.Assert(first.IsValid);
		Test.Assert(engine.MusicVoice == first);
		Test.Assert(engine.GetVoiceStatus(first, var status));
		Test.Assert(status.Bus == .Music);
		Test.Assert(status.Playing);

		let second = engine.PlayMusic(trackB, 0.2f);
		Test.Assert(second.IsValid);
		Test.Assert(!(second == first));
		Test.Assert(engine.MusicVoice == second);
		Test.Assert(engine.GetVoiceStatus(first, out status));
		Test.Assert(status.Stopping);
		Test.Assert(engine.GetVoiceStatus(second, out status));
		Test.Assert(status.Playing);
		Test.Assert(engine.ActiveVoiceCount == 2);

		// The fade lands: the incumbent reaps and the newcomer plays on.
		for (int i < 40)
			engine.Update(1.0f / 60.0f);
		Test.Assert(!engine.GetVoiceStatus(first, out status));
		Test.Assert(engine.GetVoiceStatus(second, out status));
		Test.Assert(status.Playing);

		engine.StopMusic(0.1f);
		Test.Assert(!engine.MusicVoice.IsValid);
		for (int i < 30)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.ActiveVoiceCount == 0);
	}

	/// The per voice send splices a splitter at the end of ONE voice's chain: the dry path
	/// still reaches the group and the wet one feeds the scene's send reverb in parallel.
	///
	/// It coexists with the distance filter, scales live and clamps, is inert on a voice
	/// played without one, and hands over whole when the voice is stolen.
	[Test]
	public static void ThePerVoiceReverbSendSplicesScalesAndHandsOverOnASteal()
	{
		let engine = scope AudioEngine(HeadlessSettings!(2, 0));
		let sceneGroup = engine.CreateSceneGroup();
		Test.Assert(sceneGroup != 0);

		let clip = MakeToneClip(1.0f);
		let other = MakeToneClip(1.0f, 4000, 1);
		let third = MakeToneClip(1.0f, 16000, 1);
		defer { delete clip; delete other; delete third; }

		var wet = AudioPlayParams();
		wet.Loop = true;
		wet.SceneGroup = sceneGroup;
		wet.ReverbSend = 0.5f;
		wet.Spatial = true;
		// The send and the distance filter share one chain.
		wet.DistanceLowpassHz = 4000.0f;
		let sending = engine.Play(clip, wet);
		Test.Assert(sending.IsValid);
		Test.Assert(engine.GetVoiceStatus(sending, var status));
		Test.Assert(Near(status.ReverbSend, 0.5f));

		var dry = AudioPlayParams();
		dry.Loop = true;
		dry.SceneGroup = sceneGroup;
		dry.AllowDedupe = false;
		let drier = engine.Play(other, dry);
		Test.Assert(drier.IsValid);
		Test.Assert(engine.GetVoiceStatus(drier, out status));
		Test.Assert(Near(status.ReverbSend, 0.0f));

		for (int i < 10)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(sending));

		engine.SetVoiceReverbSend(sending, 2.0f);
		Test.Assert(engine.GetVoiceStatus(sending, out status));
		Test.Assert(Near(status.ReverbSend, 1.0f));
		// A voice with no splitter has nothing to scale.
		engine.SetVoiceReverbSend(drier, 0.7f);
		Test.Assert(engine.GetVoiceStatus(drier, out status));
		Test.Assert(Near(status.ReverbSend, 0.0f));

		// A zone retunes the room without touching any voice's send level.
		var zone = AudioReverbParams();
		zone.RoomSize = 0.9f;
		zone.Damping = 0.2f;
		zone.Wet = 0.6f;
		engine.SetSceneReverb(sceneGroup, zone);
		Test.Assert(Near(engine.SceneReverbWet(sceneGroup), 0.6f));
		Test.Assert(engine.GetVoiceStatus(sending, out status));
		Test.Assert(Near(status.ReverbSend, 1.0f));

		// Stealing the sending voice hands its splitter over with its sound.
		var high = AudioPlayParams();
		high.Loop = true;
		high.Priority = 200;
		high.AllowDedupe = false;
		let stealer = engine.Play(third, high);
		Test.Assert(stealer.IsValid);
		Test.Assert(engine.DyingVoiceCount == 1);
		for (int i < 10)
			engine.Update(0.05f);
		Test.Assert(engine.DyingVoiceCount == 0);

		engine.DestroySceneGroup(sceneGroup);
		engine.Update(1.0f / 60.0f);

		// A send outside a scene is inert: there is no send reverb for it to feed.
		var global = AudioPlayParams();
		global.Loop = true;
		global.ReverbSend = 0.8f;
		global.AllowDedupe = false;
		let globalVoice = engine.Play(clip, global);
		Test.Assert(globalVoice.IsValid);
		Test.Assert(engine.GetVoiceStatus(globalVoice, out status));
		Test.Assert(Near(status.ReverbSend, 0.0f));
	}

	/// A streamed clip pages through its own source and lands in the STREAM pool, which is
	/// its own contention domain: it neither steals from the in memory pool nor is stolen by
	/// it, and it refuses a lower priority play when full.
	[Test]
	public static void AStreamedClipPlaysFromItsSourceInTheStreamPool()
	{
		let engine = scope AudioEngine(HeadlessSettings!(2, 1));

		let samples = scope List<int16>();
		MakeTone(0.5f, 8000, 1, samples);
		let wav = scope List<uint8>();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, 8000, wav));
		Test.Assert(AudioCodec.Probe(wav, let metadata));

		let clip = scope AudioClip();
		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		clip.Stream = true;
		clip.StreamSource = new MemoryStreamSource(wav);

		var parameters = AudioPlayParams();
		parameters.Bus = .Music;
		parameters.Loop = true;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		// The stream slots sit after the in memory pool.
		Test.Assert(voice.Slot == 2);
		Test.Assert(engine.IsPlaying(voice));
		engine.Update(0.1f);
		Test.Assert(engine.IsPlaying(voice));

		let otherClip = scope AudioClip();
		otherClip.Channels = metadata.Channels;
		otherClip.SampleRate = metadata.SampleRate;
		otherClip.FrameCount = metadata.FrameCount;
		otherClip.DurationSeconds = metadata.DurationSeconds;
		otherClip.Stream = true;
		otherClip.StreamSource = new MemoryStreamSource(wav);

		var lower = AudioPlayParams();
		lower.Bus = .Music;
		lower.Priority = 1;
		Test.Assert(!engine.Play(otherClip, lower).IsValid);

		engine.Stop(voice);
		engine.Update(0.2f);
		Test.Assert(!engine.IsValidHandle(voice));
	}
}
