using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Engine.Audio;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio.Tests;

/// The scene integration, headless: what starts on a scene start, what the per frame sync
/// pushes, what a finished voice leaves behind, and how the group follows the simulation.
class AudioSceneTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> AudioPlayScene.Near(a, b, epsilon);

	[Test]
	public static void AutoplaySourcesStartWhereTheyWereAuthored()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(3.0f, 1.0f, -2.0f));
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		Test.Assert(component.Voice.IsValid);
		Test.Assert(play.Engine.IsPlaying(component.Voice));
		Test.Assert(play.Audio.SceneGroup != 0);

		Test.Assert(play.Engine.GetVoiceStatus(component.Voice, let status));
		Test.Assert(status.Spatial);
		Test.Assert(Near(status.Position.X, 3.0f));
		Test.Assert(Near(status.Position.Z, -2.0f));

		// Stopping the scene tears the group down, which frees the voice, and the component's
		// handle clears with it.
		let handle = component.Voice;
		play.Scene.Stop();
		Test.Assert(!component.Voice.IsValid);
		Test.Assert(!play.Engine.IsValidHandle(handle));
		Test.Assert(play.Audio.SceneGroup == 0);
	}

	[Test]
	public static void ThePerFrameSyncPushesPositionAndVelocity()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(0.0f, 0.0f, 0.0f));
		play.Start();
		// Primes the previous position.
		play.Frame();

		// One unit of x over one frame at sixty hertz is sixty units a second.
		play.Scene.SetLocalPosition(entity, .(1.0f, 0.0f, 0.0f));
		play.Frame();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		Test.Assert(play.Engine.GetVoiceStatus(component.Voice, let status));
		Test.Assert(Near(status.Position.X, 1.0f));
		Test.Assert(Near(component.PreviousPosition.X, 1.0f));
		Test.Assert(component.HasPreviousPosition);
	}

	[Test]
	public static void PausingTheSimulationPausesTheScenesGroup()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		play.AddSource(clip, .(0, 0, 0));
		play.Start();
		play.Frame();
		Test.Assert(!play.Engine.IsSceneGroupPaused(play.Audio.SceneGroup));

		play.Scene.SetSimulationEnabled(false);
		play.Frame();
		Test.Assert(play.Engine.IsSceneGroupPaused(play.Audio.SceneGroup));

		play.Scene.SetSimulationEnabled(true);
		play.Frame();
		Test.Assert(!play.Engine.IsSceneGroupPaused(play.Audio.SceneGroup));
	}

	[Test]
	public static void AFinishedOneShotReapsAndClearsTheHandle()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(0.1f);
		let entity = play.AddSource(clip, .(0, 0, 0), true, false);
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		Test.Assert(component.Voice.IsValid);

		for (int i = 0; (i < 30) && component.Voice.IsValid; i++)
			play.Frame(0.05f);

		Test.Assert(!component.Voice.IsValid);
		Test.Assert(play.Engine.ActiveVoiceCount == 0);
	}

	[Test]
	public static void TheComponentControlSurfaceDrivesTheVoice()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(1, 2, 3), false);
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		// No automatic playback.
		Test.Assert(!component.Voice.IsValid);

		Test.Assert(play.Audio.Play(entity).IsValid);
		Test.Assert(play.Audio.IsPlaying(entity));

		play.Audio.SetPaused(entity, true);
		Test.Assert(!play.Audio.IsPlaying(entity));
		play.Audio.SetPaused(entity, false);
		Test.Assert(play.Audio.IsPlaying(entity));

		play.Audio.Stop(entity);
		Test.Assert(!component.Voice.IsValid);
		play.Frame(0.1f);
		Test.Assert(play.Engine.ActiveVoiceCount == 0);

		// An entity without a source is inert rather than a fault.
		let bare = play.Scene.CreateEntity("bare");
		Test.Assert(!play.Audio.Play(bare).IsValid);
		Test.Assert(!play.Audio.IsPlaying(bare));
	}

	[Test]
	public static void TheFirstActiveListenerDrivesTheScenesPose()
	{
		let play = scope AudioPlayScene();

		let inactive = play.Scene.CreateEntity("inactive-listener");
		play.Listeners.Add(inactive).IsActive = false;
		play.Scene.SetLocalPosition(inactive, .(100.0f, 0.0f, 0.0f));

		let listener = play.Scene.CreateEntity("listener");
		play.Listeners.Add(listener);
		play.Scene.SetLocalPosition(listener, .(5.0f, 2.0f, 0.0f));

		play.Start();
		play.Frame();

		Test.Assert(play.Audio.ListenerValid);
		// The inactive one is skipped.
		Test.Assert(Near(play.Audio.ListenerPosition.X, 5.0f));
		// An identity orientation faces negative z.
		Test.Assert(Near(play.Audio.ListenerForward.Z, -1.0f));
		Test.Assert(Near(play.Audio.ListenerUp.Y, 1.0f));

		// The velocity comes from the transform delta: six tenths over a sixtieth of a second
		// is thirty six units a second.
		play.Scene.SetLocalPosition(listener, .(5.6f, 2.0f, 0.0f));
		play.Frame();
		Test.Assert(Near(play.Audio.ListenerVelocity.X, 36.0f, 0.5f));
	}

	/// FOUR emitters sharing one clip, started in the same instant, are four voices. The one
	/// shot merge window would otherwise collapse them and leave three gizmos silent, so this
	/// runs with a REAL window rather than the fixture's default of none.
	[Test]
	public static void SourcesSharingOneClipEachGetTheirOwnVoice()
	{
		let play = scope AudioPlayScene(1.0f / 30.0f);
		let clip = play.AddClip(1.0f);

		let entities = scope List<EntityHandle>();
		for (int i < 4)
		{
			let entity = play.Scene.CreateEntity("emitter");
			play.Scene.SetLocalPosition(entity, .((float)i * 10.0f, 0.0f, 0.0f));
			let component = play.Sources.Add(entity);
			component.Clip.SetDirect(clip);
			component.AutoPlay = true;
			component.Loop = true;
			component.Spatial = true;
			entities.Add(entity);
		}

		play.Start();

		let voices = scope List<VoiceHandle>();
		for (let entity in entities)
		{
			let component = play.Sources.Get(entity);
			Test.Assert(component != null);
			Test.Assert(component.Voice.IsValid);
			Test.Assert(play.Engine.IsPlaying(component.Voice));
			voices.Add(component.Voice);
		}

		for (int i = 1; i < voices.Count; i++)
			Test.Assert(voices[i] != voices[0]);

		Test.Assert(play.Engine.ActiveVoiceCount == 4);
		play.Scene.Stop();
	}

	[Test]
	public static void AReverbSendFeedsTheSceneReverbFromThePlay()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(1.0f, 0.0f, 0.0f));
		play.Sources.Get(entity).ReverbSend = 0.4f;
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		Test.Assert(component.Voice.IsValid);
		Test.Assert(play.Engine.GetVoiceStatus(component.Voice, let status));
		Test.Assert(Near(status.ReverbSend, 0.4f));

		play.Frame();
		Test.Assert(play.Engine.IsPlaying(component.Voice));
		play.Scene.Stop();
	}

	[Test]
	public static void ABusNameRoutesTheVoiceOntoTheLayoutsCustomBus()
	{
		let play = scope AudioPlayScene();

		let layout = scope AudioBusLayout();
		let drums = new AudioNamedBus();
		drums.Name.Set("drums");
		drums.Parent.Set("Effects");
		layout.CustomBuses.Add(drums);
		play.Engine.ApplyBusLayout(layout);

		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(0.0f, 0.0f, 0.0f));
		play.Sources.Get(entity).BusName.Set("drums");
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		Test.Assert(component.Voice.IsValid);
		Test.Assert(play.Engine.GetVoiceStatus(component.Voice, let status));
		Test.Assert(status.BusName == "drums");

		// A scene pause freezes a custom bus voice with the rest of the scene.
		play.Scene.SetSimulationEnabled(false);
		play.Frame();
		Test.Assert(play.Engine.IsValidHandle(component.Voice));
		play.Scene.SetSimulationEnabled(true);
		play.Frame();
		Test.Assert(play.Engine.IsPlaying(component.Voice));
		play.Scene.Stop();
	}

	/// A CUE on the source wins over the clip, and a repeated trigger varies: a two variant
	/// no repeat cue alternates, and the jitter lands inside the authored range.
	[Test]
	public static void ACueWinsOverTheClipAndVariesPerTrigger()
	{
		let play = scope AudioPlayScene();
		let fallback = play.AddClip(0.2f);
		let stepA = play.AddClip(0.2f);
		let stepB = play.AddClip(0.2f);

		let cue = scope SoundCue();
		cue.Variants.Add(.(stepA, 1.0f));
		cue.Variants.Add(.(stepB, 1.0f));
		cue.PitchMin = 0.8f;
		cue.PitchMax = 1.2f;

		let entity = play.AddSource(fallback, .(0, 0, 0), false, false);
		let component = play.Sources.Get(entity);
		component.Cue.SetDirect(cue);
		component.SourceType = .Cue;
		play.Start();

		int32 previous = -1;
		for (int trigger < 8)
		{
			let voice = play.Audio.Play(entity);
			Test.Assert(voice.IsValid);
			Test.Assert(play.Engine.GetVoiceStatus(voice, let status));
			Test.Assert(status.Pitch >= 0.8f);
			Test.Assert(status.Pitch <= 1.2f);

			if (previous >= 0)
				Test.Assert(component.LastCueVariant != previous);
			previous = component.LastCueVariant;

			play.Engine.Stop(voice);
			for (int f < 5)
				play.Frame();
		}
	}

	/// The wet signal follows the LISTENER's occupancy, and the wettest zone containing it
	/// wins.
	[Test]
	public static void ReverbZonesFollowTheListener()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		play.AddSource(clip, .(0, 0, 0));

		let listener = play.Scene.CreateEntity("ears");
		play.Listeners.Add(listener);

		// One wide, gentle zone at the origin, and a tighter, wetter one overlapping it.
		let hall = play.Scene.CreateEntity("hall");
		let hallZone = play.Zones.Add(hall);
		hallZone.Radius = 10.0f;
		hallZone.WetLevel = 0.5f;
		hallZone.EdgeFade = 0.5f;

		let cave = play.Scene.CreateEntity("cave");
		let caveZone = play.Zones.Add(cave);
		caveZone.Radius = 4.0f;
		caveZone.WetLevel = 0.9f;
		caveZone.EdgeFade = 0.25f;

		play.Start();
		play.Frame();

		let group = play.Audio.SceneGroup;
		Test.Assert(group != 0);

		// Deep inside both: the wetter wins, at full blend.
		Test.Assert(Near(play.Engine.SceneReverbWet(group), 0.9f, 0.02f));

		// Outside the tighter one but inside the wide one's edge band: partial.
		play.Scene.SetLocalPosition(listener, .(8.0f, 0.0f, 0.0f));
		play.Scene.UpdateTransforms();
		play.Frame();
		let edgeWet = play.Engine.SceneReverbWet(group);
		Test.Assert(edgeWet > 0.0f);
		Test.Assert(edgeWet < 0.45f);

		// Far outside every zone: dry.
		play.Scene.SetLocalPosition(listener, .(50.0f, 0.0f, 0.0f));
		play.Scene.UpdateTransforms();
		play.Frame();
		Test.Assert(Near(play.Engine.SceneReverbWet(group), 0.0f));
	}

	/// EVERY active listener collects, which is what a split screen's ears are, and the first
	/// stays the primary.
	[Test]
	public static void EveryActiveListenerCollectsAndTheFirstIsPrimary()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(0.5f);
		play.AddSource(clip, .(0, 0, 0));

		let first = play.Scene.CreateEntity("p1");
		play.Scene.SetLocalPosition(first, .(-5.0f, 0.0f, 0.0f));
		play.Listeners.Add(first);

		let second = play.Scene.CreateEntity("p2");
		play.Scene.SetLocalPosition(second, .(5.0f, 0.0f, 0.0f));
		play.Listeners.Add(second);

		// Inactive, so it is never collected.
		let spectator = play.Scene.CreateEntity("spectator");
		play.Listeners.Add(spectator).IsActive = false;

		play.Start();
		play.Scene.UpdateTransforms();
		play.Frame();

		let poses = play.Audio.ListenerPoses;
		Test.Assert(poses.Length == 2);
		Test.Assert(Near(poses[0].Position.X, -5.0f));
		Test.Assert(Near(poses[1].Position.X, 5.0f));
		Test.Assert(Near(play.Audio.ListenerPosition.X, -5.0f));
	}

	/// An entity that starts inactive is SILENT; deactivating stops the voice rather than
	/// skipping an update, and reactivating restarts an automatic source.
	[Test]
	public static void TheEntityActiveEdgesStartAndStopTheVoice()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(1.0f, 0.0f, 0.0f));

		// BEFORE the start, which is the scene starts inactive case.
		play.Scene.SetActive(entity, false);
		play.Start();

		let component = play.Sources.Get(entity);
		Test.Assert(component != null);
		// Automatic playback started nothing.
		Test.Assert(!component.Voice.IsValid);
		play.Frame();
		Test.Assert(!component.Voice.IsValid);

		// The activation edge starts it now.
		play.Scene.SetActive(entity, true);
		play.Frame();
		Test.Assert(component.Voice.IsValid);
		Test.Assert(play.Engine.IsPlaying(component.Voice));

		// The deactivation edge STOPS it, which is silence rather than a skipped update.
		let live = component.Voice;
		play.Scene.SetActive(entity, false);
		play.Frame();
		Test.Assert(!component.Voice.IsValid);
		Test.Assert(!play.Engine.IsValidHandle(live));

		// And it comes back, being a looping automatic source.
		play.Scene.SetActive(entity, true);
		play.Frame();
		Test.Assert(component.Voice.IsValid);
		Test.Assert(play.Engine.IsPlaying(component.Voice));
	}

	/// SetClip lands the identity and drops the direct object; a playing voice runs on. With
	/// no resolve behind the scene there is no manager, so nothing binds until one comes.
	[Test]
	public static void SetClipSwapsTheIdentityAndLeavesThePlayingVoiceAlone()
	{
		let play = scope AudioPlayScene();
		let clip = play.AddClip(1.0f);
		let entity = play.AddSource(clip, .(0, 0, 0));
		play.Start();
		let component = play.Sources.Get(entity);
		Test.Assert(play.Audio.IsPlaying(entity));

		let id = Guid.Create();
		play.Audio.SetClip(entity, id);
		Test.Assert(component.Clip.Id == id);
		Test.Assert(component.Clip.Get == null, "the direct override is gone");
		Test.Assert(play.Sources.Resources == null);
		Test.Assert(play.Audio.IsPlaying(entity), "the voice already started keeps going");

		// No source: a no-op.
		play.Audio.SetClip(play.Scene.CreateEntity("bare"), id);
	}
}
