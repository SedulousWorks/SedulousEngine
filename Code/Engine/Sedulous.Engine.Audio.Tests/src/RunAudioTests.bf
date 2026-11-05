using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Engine.Audio;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio.Tests;

/// Run audio: the subsystem groups what one running game plays by its run. A run's scenes nest
/// under the run's group and its music plays into it; the run's stop fades all of it out and
/// leaves other runs and the editor alone; only the focused run is heard unless every run is;
/// the host's pause freezes the run. All of it follows the runs' lifecycle, through the run
/// manager on the subsystem manager: no call to the audio.
class RunAudioTests
{
	/// A run of its own (a GameInstance is the real one).
	private class TestRun : RunBase
	{
		public this() : base("test") {}
	}

	/// A scene of `run` with one looping autoplay source, wired to the subsystem as the scene
	/// subsystem would wire it.
	private class RunScene
	{
		public Scene Scene = new .("run-scene") ~ delete _;
		public EntityHandle Source;

		public this(AudioSubsystem audio, IRun run, AudioClip clip)
		{
			Scene.SetRun(run);
			AudioScene.AddAudioSceneManagers(Scene);
			audio.OnSystemsReady(Scene);
			Source = Scene.CreateEntity("source");
			let component = Scene.GetSystem<AudioSourceComponentManager>().Add(Source);
			component.Clip.SetDirect(clip);
			component.AutoPlay = true;
			component.Loop = true;
			Scene.Start();
			Scene.SetSimulationEnabled(true);
		}

		public VoiceHandle Voice => Scene.GetSystem<AudioSourceComponentManager>().Get(Source).Voice;
	}

	/// Registered, so the CALLER owns it: deleted after the context shuts down. `runs` are the
	/// host's, on the context before it starts.
	private static AudioSubsystem MakeAudio(SubsystemManager context, IRunManager runs)
	{
		let settings = new AudioEngineSettings();
		settings.Headless = true;
		settings.DedupeWindowSeconds = 0.0f;
		let audio = new AudioSubsystem(settings);
		context.RegisterSubsystem<AudioSubsystem>(audio);
		context.SetRunManager(runs);
		context.Startup();
		return audio;
	}

	/// The subsystem offers its own `Audio`: one on the application's services, and each run's among
	/// that run's, carrying the run (the runs made before it was ready too); a run's goes with the
	/// run, and the rest are taken back as the subsystem shuts down.
	[Test]
	public static void TheSharedAudioIsTheApplicationsServiceAndEachRunsItsOwnGoneWithTheRun()
	{
		let runs = scope RunRegistry();
		let first = scope TestRun();
		let second = scope TestRun();
		runs.Add(first); // before the subsystem is ready
		let context = new SubsystemManager();
		let audio = MakeAudio(context, runs);
		defer { delete context; delete audio; }
		Test.Assert(context.FindService(typeof(AudioFacade)) === audio.ScriptFacade, "the shared one");
		let firsts = first.FindService(typeof(AudioFacade));
		Test.Assert((firsts != null) && (firsts !== audio.ScriptFacade), "caught up as it got ready");
		runs.Add(second);
		let seconds = second.FindService(typeof(AudioFacade));
		Test.Assert((seconds != null) && (seconds !== firsts), "each run its own");
		Test.Assert(audio.RunScriptFacadeCount == 2);

		second.Dispose(); // the run's end reaches the subsystem
		Test.Assert(audio.RunScriptFacadeCount == 1, "gone with its run");
		Test.Assert(second.FindService(typeof(AudioFacade)) == null);

		context.Shutdown();
		Test.Assert(first.FindService(typeof(AudioFacade)) == null, "taken back as the subsystem goes");
		Test.Assert(audio.RunScriptFacadeCount == 0);
	}

	[Test]
	public static void ARunsStopFadesOutItsScenesAndItsMusicNotAnotherRuns()
	{
		// The host's runs; two games.
		let runs = scope RunRegistry();
		let runA = scope TestRun();
		let runB = scope TestRun();
		runs.Add(runA);
		runs.Add(runB);
		runA.Start();
		runB.Start();
		let context = new SubsystemManager();
		let audio = MakeAudio(context, runs);
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;
		let clips = scope List<AudioClip>();
		defer { ClearAndDeleteItems!(clips); }
		AudioClip Tone(uint32 sampleRate) => clips.Add(.. AudioPlayScene.MakeToneClip(2.0f, sampleRate));
		Test.Assert(audio.RunGroupFor(null) == 0, "outside every run");
		let groupA = audio.RunGroupFor(runA);
		Test.Assert(groupA != 0);
		Test.Assert(audio.RunGroupFor(runA) == groupA, "one group per run");

		let sceneA = scope RunScene(audio, runA, Tone(8000));
		let sceneB = scope RunScene(audio, runB, Tone(4000));
		let musicA = audio.PlayMusic(Tone(16000), 0.0f, 1.0f, groupA);
		let musicB = audio.PlayMusic(Tone(12000), 0.0f, 1.0f, audio.RunGroupFor(runB));
		let editorShot = audio.PlayOneShot(Tone(6000)); // the editor's own
		Test.Assert(sceneA.Voice.IsValid && sceneB.Voice.IsValid && musicA.IsValid && musicB.IsValid);
		let sourceA = sceneA.Voice;

		runA.Stop(); // the Game tab's Stop: no call to the audio, the run's lifecycle reaches it
		for (int i < 4)
			audio.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(musicA), "the music stopped with its run");
		Test.Assert(!engine.IsValidHandle(sourceA), "and the run's scene sources");
		Test.Assert(audio.FindRunGroup(runA) == 0, "the run is gone, its group freed");
		Test.Assert(engine.IsPlaying(musicB), "another run plays on");
		Test.Assert(engine.IsPlaying(sceneB.Voice));
		Test.Assert(engine.IsPlaying(editorShot), "and the editor");

		sceneA.Scene.Stop();
		sceneB.Scene.Stop();
		audio.OnDestroying(sceneA.Scene);
		audio.OnDestroying(sceneB.Scene);
		context.Shutdown();
	}

	[Test]
	public static void OnlyTheFocusedRunIsHeardUnlessEveryRunIsAndPauseFreezesARun()
	{
		let runs = scope RunRegistry();
		let runA = scope TestRun();
		let runB = scope TestRun();
		let runC = scope TestRun();
		runs.Add(runA);
		runs.Add(runB);
		runs.Add(runC);
		runA.Start();
		let context = new SubsystemManager();
		let audio = MakeAudio(context, runs);
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;
		let a = audio.RunGroupFor(runA);
		let b = audio.RunGroupFor(runB);

		// No focus yet: every run is heard (the player's one run never needs one).
		Test.Assert(!engine.IsRunGroupMuted(a) && !engine.IsRunGroupMuted(b));

		runs.SetFocused(runA); // clicking into a Game tab
		Test.Assert(!engine.IsRunGroupMuted(a));
		Test.Assert(engine.IsRunGroupMuted(b), "runs on, muted");
		Test.Assert(audio.IsRunAudible(null), "the editor's own sounds are always heard");
		let c = audio.RunGroupFor(runC);
		Test.Assert(engine.IsRunGroupMuted(c), "a new run while another is focused starts muted");

		runs.SetFocused(runB);
		Test.Assert(engine.IsRunGroupMuted(a));
		Test.Assert(!engine.IsRunGroupMuted(b));

		audio.SetHearAllRuns(true); // the editor's preference: every Game tab
		Test.Assert(!engine.IsRunGroupMuted(a) && !engine.IsRunGroupMuted(b) && !engine.IsRunGroupMuted(c));
		audio.SetHearAllRuns(false);

		runB.Dispose(); // the focused run goes (a tab closed, no stop first): no focus, every remaining run heard
		Test.Assert(runs.Focused == null);
		Test.Assert(!engine.IsRunGroupMuted(a));
		Test.Assert(audio.FindRunGroup(runB) == 0, "its group went with it");

		runA.SetPaused(true); // the toolbar's pause, a debugger break
		Test.Assert(engine.IsRunGroupPaused(a));
		runA.SetPaused(false);
		Test.Assert(!engine.IsRunGroupPaused(a));
		context.Shutdown();
	}

	[Test]
	public static void ASubsystemMadeAfterTheRunsCatchesUpOnTheFocusAndAPausedRun()
	{
		let runs = scope RunRegistry();
		let runA = scope TestRun();
		let runB = scope TestRun();
		runs.Add(runA);
		runs.Add(runB);
		runB.Start();
		runB.SetPaused(true);
		runs.SetFocused(runA); // before any audio exists (a plugin's subsystem arriving late)
		let context = new SubsystemManager();
		let audio = MakeAudio(context, runs);
		defer { delete context; delete audio; }
		let engine = audio.Engine;
		let b = audio.RunGroupFor(runB);
		Test.Assert(engine.IsRunGroupMuted(b), "not the focused run");
		Test.Assert(engine.IsRunGroupPaused(b), "its run is paused");
		Test.Assert(!engine.IsRunGroupMuted(audio.RunGroupFor(runA)));
		context.Shutdown();
		runs.SetFocused(null); // the audio stopped listening at its shutdown: nothing reaches it
	}
}
