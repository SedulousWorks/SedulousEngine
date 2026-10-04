using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Engine.Audio;
using Sedulous.Runtime;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio.Tests;

/// Run audio: the subsystem groups what one running game plays by its run. A run's scenes nest
/// under the run's group and its music plays into it; ending the run fades all of it out and
/// leaves other runs and the editor alone; only the focused run is heard unless every run is;
/// the host's pause freezes the run.
class RunAudioTests
{
	/// A scene of `run` with one looping autoplay source, wired to the subsystem as the scene
	/// subsystem would wire it.
	private class RunScene
	{
		public Scene Scene = new .("run-scene") ~ delete _;
		public EntityHandle Source;

		public this(AudioSubsystem audio, Object run, AudioClip clip)
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

	/// Registered, so the CALLER owns it: deleted after the context shuts down.
	private static AudioSubsystem MakeAudio(Context context)
	{
		let settings = new AudioEngineSettings();
		settings.Headless = true;
		settings.DedupeWindowSeconds = 0.0f;
		let audio = new AudioSubsystem(settings);
		context.RegisterSubsystem<AudioSubsystem>(audio);
		context.Startup();
		return audio;
	}

	[Test]
	public static void EndingARunFadesOutItsScenesAndItsMusicNotAnotherRuns()
	{
		let context = new Context();
		let audio = MakeAudio(context);
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;
		let clips = scope List<AudioClip>();
		defer { ClearAndDeleteItems!(clips); }
		AudioClip Tone(uint32 sampleRate) => clips.Add(.. AudioPlayScene.MakeToneClip(2.0f, sampleRate));
		// Two games' keys; a GameInstance is the real one.
		let runA = scope Object();
		let runB = scope Object();

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

		audio.EndRun(runA); // the Game tab's Stop
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
		let context = new Context();
		let audio = MakeAudio(context);
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;
		let runA = scope Object();
		let runB = scope Object();
		let runC = scope Object();
		let a = audio.RunGroupFor(runA);
		let b = audio.RunGroupFor(runB);

		// No focus yet: every run is heard (the player's one run never needs one).
		Test.Assert(!engine.IsRunGroupMuted(a) && !engine.IsRunGroupMuted(b));

		audio.SetFocusedRun(runA); // clicking into a Game tab
		Test.Assert(!engine.IsRunGroupMuted(a));
		Test.Assert(engine.IsRunGroupMuted(b), "runs on, muted");
		Test.Assert(audio.IsRunAudible(null), "the editor's own sounds are always heard");
		let c = audio.RunGroupFor(runC);
		Test.Assert(engine.IsRunGroupMuted(c), "a new run while another is focused starts muted");

		audio.SetFocusedRun(runB);
		Test.Assert(engine.IsRunGroupMuted(a));
		Test.Assert(!engine.IsRunGroupMuted(b));

		audio.SetHearAllRuns(true); // the editor's preference: every Game tab
		Test.Assert(!engine.IsRunGroupMuted(a) && !engine.IsRunGroupMuted(b) && !engine.IsRunGroupMuted(c));
		audio.SetHearAllRuns(false);

		audio.EndRun(runB); // the focused run ends: no focus, every remaining run heard
		Test.Assert(audio.FocusedRun == null);
		Test.Assert(!engine.IsRunGroupMuted(a));

		audio.SetRunPaused(runA, true); // the toolbar's pause, a debugger break
		Test.Assert(engine.IsRunGroupPaused(a));
		audio.SetRunPaused(runA, false);
		Test.Assert(!engine.IsRunGroupPaused(a));
		context.Shutdown();
	}
}
