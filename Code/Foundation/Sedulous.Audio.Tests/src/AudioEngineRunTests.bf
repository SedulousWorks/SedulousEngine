using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using static Sedulous.Audio.Tests.AudioEngineFixture;

namespace Sedulous.Audio.Tests;

/// Run groups: everything one running game plays, one level above its scenes. A run's stop,
/// pause, mute, music and bus gains are its own, reaching its scenes' voices and its custom bus
/// voices through the graph and leaving the editor's sounds and other runs alone.
class AudioEngineRunTests
{
	private static float Cursor(AudioEngine engine, VoiceHandle voice)
	{
		Test.Assert(engine.GetVoiceStatus(voice, let status));
		return status.CursorSeconds;
	}

	[Test]
	public static void ARunsStopEndsItsMusicOneShotsAndScenesVoicesAndNothingElse()
	{
		let engine = scope AudioEngine(HeadlessSettings!(8, 2));
		let music = MakeToneClip(2.0f);
		let shot = MakeToneClip(2.0f, 4000, 1);
		let source = MakeToneClip(2.0f, 16000, 1);
		let editorClip = MakeToneClip(2.0f, 12000, 1);
		defer { delete music; delete shot; delete source; delete editorClip; }
		let run = engine.CreateRunGroup();
		let other = engine.CreateRunGroup();
		Test.Assert((run != 0) && (other != run));
		let scene = engine.CreateSceneGroup(run);

		let runMusic = engine.PlayMusic(music, 0.0f, 1.0f, run);
		var shotParams = AudioPlayParams();
		shotParams.Loop = true;
		shotParams.RunGroup = run;
		let runShot = engine.Play(shot, shotParams);
		var sceneParams = AudioPlayParams();
		sceneParams.Loop = true;
		sceneParams.SceneGroup = scene; // a scene of the run: the run is the scene's
		let sceneVoice = engine.Play(source, sceneParams);
		let otherMusic = engine.PlayMusic(music, 0.0f, 1.0f, other);
		var globalParams = AudioPlayParams();
		globalParams.Loop = true;
		let editorVoice = engine.Play(editorClip, globalParams);
		Test.Assert(runMusic.IsValid && runShot.IsValid && sceneVoice.IsValid && otherMusic.IsValid && editorVoice.IsValid);
		// Two runs' music slots are their own: the second run's music left the first's playing.
		Test.Assert(engine.IsPlaying(runMusic));
		Test.Assert(engine.MusicVoice(run) == runMusic);
		Test.Assert(engine.MusicVoice(other) == otherMusic);

		engine.StopRunGroup(run, 0.05f);
		engine.Update(0.2f);
		Test.Assert(!engine.IsValidHandle(runMusic));
		Test.Assert(!engine.IsValidHandle(runShot));
		Test.Assert(!engine.IsValidHandle(sceneVoice));
		Test.Assert(!engine.MusicVoice(run).IsValid);
		Test.Assert(engine.IsPlaying(otherMusic), "another run plays on");
		Test.Assert(engine.IsPlaying(editorVoice), "and the editor's own sounds");

		// Destroying frees at once (no fade), its scenes' voices included.
		let again = engine.Play(source, sceneParams);
		Test.Assert(again.IsValid);
		engine.DestroyRunGroup(run);
		Test.Assert(!engine.IsValidHandle(again));
		Test.Assert(engine.IsPlaying(otherMusic));
	}

	[Test]
	public static void APausedRunFreezesItsVoicesAndAMutedRunKeepsThemAdvancing()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(4.0f);
		defer delete clip;
		let run = engine.CreateRunGroup();
		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.RunGroup = run;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		engine.Update(0.2f);

		engine.SetRunGroupPaused(run, true);
		engine.Update(0.05f); // the declick fade lands
		let pausedAt = Cursor(engine, voice);
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(engine.IsRunGroupPaused(run));
		Test.Assert(Math.Abs(Cursor(engine, voice) - pausedAt) <= pausedAt * 0.01f, "frozen in place");
		engine.SetRunGroupPaused(run, false);

		engine.SetRunGroupMuted(run, true);
		Test.Assert(engine.IsRunGroupMuted(run));
		let mutedAt = Cursor(engine, voice);
		for (int i < 5)
			engine.Update(0.1f);
		Test.Assert(Cursor(engine, voice) > mutedAt + 0.4f, "silent, but its timeline stays true");
		Test.Assert(engine.IsValidHandle(voice));
	}

	[Test]
	public static void ARunsBusGainsAreItsOwn()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let run = engine.CreateRunGroup();
		let other = engine.CreateRunGroup();
		engine.SetRunBusVolume(run, .Music, 0.25f);
		engine.SetRunBusMuted(run, .Effects, true);
		Test.Assert(engine.RunBusVolume(run, .Music) == 0.25f);
		Test.Assert(engine.RunBusMuted(run, .Effects));
		// Neither the engine's buses (the editor's) nor another run's moved.
		Test.Assert(engine.BusVolume(.Music) == 1.0f);
		Test.Assert(!engine.BusMuted(.Effects));
		Test.Assert(engine.RunBusVolume(other, .Music) == 1.0f);
		Test.Assert(!engine.RunBusMuted(other, .Effects));
		// A run that does not exist reads the neutral gain.
		Test.Assert(engine.RunBusVolume(9999, .Music) == 1.0f);
	}

	[Test]
	public static void ARunReachesItsCustomBusVoicesThroughTheGraphWithGainsOfItsOwn()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let layout = scope AudioBusLayout();
		let drums = new AudioNamedBus();
		drums.Name.Set("drums");
		drums.Parent.Set("Music");
		layout.CustomBuses.Add(drums);
		engine.ApplyBusLayout(layout);

		let run = engine.CreateRunGroup();
		let other = engine.CreateRunGroup();
		let scene = engine.CreateSceneGroup(run);
		let clip = MakeToneClip(4.0f);
		let otherClip = MakeToneClip(4.0f, 4000, 1);
		defer { delete clip; delete otherClip; }
		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.BusName = "drums";
		parameters.SceneGroup = scene; // scene child, run child, drums, Music
		let voice = engine.Play(clip, parameters);
		var otherParams = parameters;
		otherParams.SceneGroup = 0;
		otherParams.RunGroup = other;
		let otherVoice = engine.Play(otherClip, otherParams);
		Test.Assert(voice.IsValid && otherVoice.IsValid);
		engine.Update(0.2f);

		// The run's own gain for the named bus: neither the bus nor another run moves.
		engine.SetRunNamedBusVolume(run, "drums", 0.3f);
		engine.SetRunNamedBusMuted(other, "drums", true);
		Test.Assert(engine.RunNamedBusVolume(run, "drums") == 0.3f);
		Test.Assert(engine.NamedBusVolume("drums") == 1.0f);
		Test.Assert(engine.RunNamedBusVolume(other, "drums") == 1.0f);
		Test.Assert(engine.RunNamedBusMuted(other, "drums"));
		Test.Assert(!engine.RunNamedBusMuted(run, "drums"));

		// The run's pause halts its child under the custom bus: the voice's cursor freezes.
		engine.SetRunGroupPaused(run, true);
		engine.Update(0.05f);
		let pausedAt = Cursor(engine, voice);
		let otherAt = Cursor(engine, otherVoice);
		for (int i < 4)
			engine.Update(0.1f);
		Test.Assert(Math.Abs(Cursor(engine, voice) - pausedAt) <= pausedAt * 0.01f);
		Test.Assert(Cursor(engine, otherVoice) > otherAt + 0.3f, "another run plays on");
		engine.SetRunGroupPaused(run, false);

		// A rebuild that keeps the bus keeps the voice on it; one that drops it hands the voice
		// back to its fixed bus, alive, and frees the run's and the scene's children under it.
		engine.ApplyBusLayout(layout);
		Test.Assert(engine.GetVoiceStatus(voice, var status));
		Test.Assert(status.BusName == "drums");
		engine.ApplyBusLayout(scope AudioBusLayout());
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(status.BusName.IsEmpty);
		Test.Assert(engine.IsValidHandle(voice) && engine.IsValidHandle(otherVoice));

		// The run's stop still reaches it, now on its fixed bus; the other run is untouched.
		engine.StopRunGroup(run, 0.05f);
		engine.Update(0.2f);
		Test.Assert(!engine.IsValidHandle(voice));
		Test.Assert(engine.IsPlaying(otherVoice));

		// And a run destroyed while it has children under a live custom bus frees them cleanly.
		engine.ApplyBusLayout(layout);
		let again = engine.Play(clip, otherParams);
		Test.Assert(again.IsValid);
		engine.DestroyRunGroup(other);
		Test.Assert(!engine.IsValidHandle(again));
		Test.Assert(!engine.IsValidHandle(otherVoice));
	}
}
