using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Script.Facades;
using Sedulous.Resource;
using Sedulous.Runtime;

namespace Sedulous.Engine.DefaultApp.Tests;

/// A run's Audio facade: its bus volumes and mutes are the run's own and its music stop is
/// its run's, while a facade outside every run works the engine's buses. The application
/// installs one per GameInstance on its run host.
class AudioFacadeRunTests
{
	/// A sine encoded as a real wav, decoded as a cooked clip would be. THE CALLER OWNS it.
	private static AudioClip MakeToneClip(float seconds, uint32 sampleRate = 8000)
	{
		let samples = scope List<int16>();
		for (int frame < (int)(seconds * (float)sampleRate))
			samples.Add((int16)(0.5f * Math.Sin(2.0f * 3.14159265f * 440.0f * (float)frame / (float)sampleRate) * 32000.0f));
		let clip = new AudioClip();
		Test.Assert(AudioCodec.EncodeWav(samples, 1, sampleRate, clip.EncodedData));
		Test.Assert(AudioCodec.Probe(clip.EncodedBytes, let metadata));
		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		return clip;
	}

	[Test]
	public static void ARunsFacadeSetsItsRunsBusesAndStopsItsRunsMusic()
	{
		let settings = new AudioEngineSettings();
		settings.Headless = true;
		settings.DedupeWindowSeconds = 0.0f;
		let audio = new AudioSubsystem(settings);
		let context = new Context();
		context.RegisterSubsystem<AudioSubsystem>(audio);
		context.Startup();
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;

		let run = scope Object(); // a GameInstance is the real key
		let inRun = scope AudioFacade(audio, new () => (ResourceManager)null, run);
		let outside = scope AudioFacade(audio, new () => (ResourceManager)null);

		// In a run the bus volumes and mutes are the run's: the editor's buses do not move.
		inRun.SetBusVolume(.Music, 0.5f);
		inRun.SetBusMuted(.Effects, true);
		let group = audio.FindRunGroup(run);
		Test.Assert(group != 0, "the run's group was made on first use");
		Test.Assert(engine.RunBusVolume(group, .Music) == 0.5f);
		Test.Assert(engine.RunBusMuted(group, .Effects));
		Test.Assert(engine.BusVolume(.Music) == 1.0f);
		Test.Assert(!engine.BusMuted(.Effects));
		Test.Assert(inRun.BusVolume(.Music) == 0.5f);
		Test.Assert(inRun.BusMuted(.Effects));

		// Outside every run, the engine's.
		outside.SetBusVolume(.Music, 0.75f);
		Test.Assert(engine.BusVolume(.Music) == 0.75f);
		Test.Assert(outside.BusVolume(.Music) == 0.75f);
		Test.Assert(inRun.BusVolume(.Music) == 0.5f, "the run keeps its own");

		// The run's music stops through its facade, not the music outside the run.
		let clip = MakeToneClip(2.0f);
		defer delete clip;
		let other = MakeToneClip(2.0f, 4000);
		defer delete other;
		let runMusic = audio.PlayMusic(clip, 0.0f, 1.0f, group);
		let editorMusic = audio.PlayMusic(other, 0.0f);
		Test.Assert(runMusic.IsValid && editorMusic.IsValid);
		inRun.StopMusic(0.05f);
		for (int i < 3)
			audio.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(runMusic));
		Test.Assert(engine.IsPlaying(editorMusic));
		context.Shutdown();
	}
}
