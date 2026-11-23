using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.PropertyAnimation;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.Engine.Sequence;

namespace Sedulous.Engine.Sequence.Tests;

/// One bus report: its event's name and its notice.
struct HeardNotice
{
	public String Event;
	public SequenceNotice Notice;
}

/// Each entity event: its target, name, how many values and the first as text.
class EntityEventLog : IEntityEventSink
{
	public struct Entry
	{
		public EntityHandle Target;
		public String Name;
		public int Args;
		public String First;
	}

	public List<Entry> Entries = new .() ~ { for (let e in _) { delete e.Name; delete e.First; } delete _; };

	public void OnEntityEvent(Scene scene, EntityEvent entityEvent)
	{
		var entry = Entry();
		entry.Target = entityEvent.Target;
		entry.Name = new .(entityEvent.Name);
		entry.Args = entityEvent.Args.Length;
		entry.First = new .();
		if (!entityEvent.Args.IsEmpty && (entityEvent.Args[0].Kind == .String))
			entry.First.Set(entityEvent.Args[0].String);
		Entries.Add(entry);
	}
}

/// A run and a scene with the player of sequences and an actor, its bus heard.
class SequenceStage
{
	public RunBase Run = new .("sequences") ~ delete _;
	public Scene World ~ delete _;
	public SequenceSystem Sequences;
	public EntityHandle Actor;
	public List<HeardNotice> Heard = new .() ~ { for (let h in _) delete h.Event; delete _; };
	private List<delegate void(Variant)> mHandlers = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		World = new .("sequences");
		World.SetRun(Run);
		SequenceDomain.AddSequenceSceneSystems(World);
		Sequences = World.GetSystem<SequenceSystem>();
		Actor = World.CreateEntity("Actor");
		for (let name in scope String[](SequenceEvents.EventBus, SequenceEvents.HeldBus, SequenceEvents.FinishedBus))
		{
			let eventName = name;
			delegate void(Variant) handler = new [=](payload) =>
			{
				var heard = HeardNotice();
				heard.Event = new .(eventName);
				if (payload.VariantType == typeof(SequenceNotice))
					heard.Notice = payload.Get<SequenceNotice>();
				Heard.Add(heard);
			};
			mHandlers.Add(handler);
			Run.Events.Subscribe(StringHash(name), handler);
		}
		World.Start();
		World.SetSimulationEnabled(true);
	}

	public ~this()
	{
		// The scene goes before the run it reports into.
		DeleteAndNullify!(World);
	}

	public void Frame(float dt)
	{
		World.Update(dt);
		Run.Events.Drain();
	}

	public float X => World.GetLocalTransform(Actor).Position.X;
}

/// The scene's player of sequences: plays step with the scene, report on the run's bus naming
/// their play, wait at holds, report to an owner or a bound actor, and end on a stop or the scene
/// stopping.
class SequenceSystemTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// "Actor" walks X from 0 to 10 over one second; a cue at 0.5 (bound to the actor when
	/// `boundCue`), a hold named "line" at 0.25 when `hold`. Held by the caller.
	private static SequenceResource Walk(bool boundCue = false, bool hold = false)
	{
		let walk = new SequenceResource();
		let s = walk.Sequence;
		s.Bindings.Add(new .("Actor"));
		let move = new PropertySequenceTrack();
		move.Binding = 0;
		move.Property.ComponentType.Set(TrackTargets.cTransform);
		move.Property.PropertyPath.Set("Position");
		move.Property.Kind = .Float3;
		move.Property.Channels[0].AddKey(.(0.0f, 0.0f));
		move.Property.Channels[0].AddKey(.(1.0f, 10.0f));
		s.Tracks.Add(move);
		let cues = new EventSequenceTrack();
		cues.Binding = boundCue ? 0 : -1;
		cues.Keys.Add(new .(0.5f, "cue", "gate"));
		s.Tracks.Add(cues);
		if (hold)
			s.Markers.Add(new .(0.25f, "line", true));
		s.Duration = 1.0f;
		return walk;
	}

	private static Guid Id(uint32 value) => .(value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	[Test]
	public static void APlayStepsWithTheSceneAndReportsOnTheRunsBusNamingItsPlay()
	{
		let walk = Walk();
		defer delete walk;
		let stage = scope SequenceStage();
		let id = Id(0x51);
		let play = stage.Sequences.Play(walk, id);
		Test.Assert(play != 0);
		let running = stage.Sequences.Find(play);
		Test.Assert(running != null);
		Test.Assert(running.Bind("Actor", stage.Actor));

		stage.Frame(0.5f);
		Test.Assert(Near(stage.X, 5.0f));
		stage.Frame(0.75f);
		Test.Assert(Near(stage.X, 10.0f));
		Test.Assert(stage.Sequences.Find(play) == null, "finished and let go");
		Test.Assert(stage.Sequences.PlayCount == 0);

		Test.Assert(stage.Heard.Count == 2);
		Test.Assert(stage.Heard[0].Event == SequenceEvents.EventBus);
		Test.Assert(stage.Heard[0].Notice.Play == (int32)play);
		Test.Assert(stage.Heard[0].Notice.Sequence == id);
		Test.Assert(stage.Heard[0].Notice.Name == "cue");
		Test.Assert(stage.Heard[0].Notice.Value == "gate");
		Test.Assert(stage.Heard[1].Event == SequenceEvents.FinishedBus);
		Test.Assert(stage.Heard[1].Notice.Play == (int32)play);
	}

	[Test]
	public static void AHoldIsReportedAndThePlayWaitsThereUntilResumed()
	{
		let walk = Walk(false, true);
		defer delete walk;
		let stage = scope SequenceStage();
		let play = stage.Sequences.Play(walk, Id(1));
		stage.Sequences.Find(play).Bind("Actor", stage.Actor);
		stage.Frame(0.5f);
		Test.Assert(stage.Heard.Count == 1);
		Test.Assert(stage.Heard[0].Event == SequenceEvents.HeldBus);
		Test.Assert(stage.Heard[0].Notice.Name == "line");
		stage.Frame(1.0f);
		Test.Assert(Near(stage.X, 2.5f));
		stage.Sequences.Find(play).Resume();
		stage.Frame(0.25f);
		Test.Assert(Near(stage.X, 5.0f));
	}

	[Test]
	public static void AnOwnedPlayReportsToItsOwnerABoundEventTrackToItsActor()
	{
		let walk = Walk(true);
		defer delete walk;
		let stage = scope SequenceStage();
		let log = scope EntityEventLog();
		stage.World.AddEntityEventSink(log);
		defer stage.World.RemoveEntityEventSink(log);
		let director = stage.World.CreateEntity("Director");
		let play = stage.Sequences.Play(walk, Id(3), .Release, director);
		stage.Sequences.Find(play).Bind("Actor", stage.Actor);
		stage.Frame(1.5f);

		Test.Assert(log.Entries.Count == 2);
		Test.Assert(log.Entries[0].Target == stage.Actor, "the cue's track is bound to the actor");
		Test.Assert(log.Entries[0].Name == SequenceEvents.Event);
		Test.Assert(log.Entries[0].Args == 2);
		Test.Assert(log.Entries[0].First == "cue");
		Test.Assert(log.Entries[1].Target == director);
		Test.Assert(log.Entries[1].Name == SequenceEvents.Finished);
		Test.Assert(stage.Heard.IsEmpty, "nothing on the bus");
	}

	[Test]
	public static void StoppingLetsGoRestoringWhenTheFinishAsksAndTheSceneStoppingStopsAll()
	{
		let walk = Walk();
		defer delete walk;
		let stage = scope SequenceStage();
		let restored = stage.Sequences.Play(walk, Id(5), .Restore);
		stage.Sequences.Find(restored).Bind("Actor", stage.Actor);
		stage.Frame(0.5f);
		Test.Assert(Near(stage.X, 5.0f));
		stage.Sequences.Stop(restored);
		Test.Assert(Near(stage.X, 0.0f));
		Test.Assert(stage.Sequences.Find(restored) == null);

		let kept = stage.Sequences.Play(walk, Id(7));
		stage.Sequences.Find(kept).Bind("Actor", stage.Actor);
		stage.Frame(0.5f);
		stage.World.Stop();
		Test.Assert(stage.Sequences.PlayCount == 0);
		Test.Assert(Near(stage.X, 5.0f), "released: what moved stays");
	}

	[Test]
	public static void AFinishIsNamedForScripts()
	{
		Test.Assert(SequenceSystem.ParseFinish("hold") == .Hold);
		Test.Assert(SequenceSystem.ParseFinish("restore") == .Restore);
		Test.Assert(SequenceSystem.ParseFinish("release") == .Release);
		Test.Assert(SequenceSystem.ParseFinish("anything else") == .Release);
	}

	/// A play handle answers nothing once its play has ended or its scene is gone.
	[Test]
	public static void APlayHandleIsHarmlessOnceItsPlayHasEnded()
	{
		let walk = Walk();
		defer delete walk;
		let stage = scope SequenceStage();
		let handle = SequencePlay(stage.World, stage.Sequences.Play(walk, Id(9)));
		Test.Assert(handle.Bind("Actor", stage.Actor));
		Test.Assert(handle.IsPlaying());
		stage.Frame(0.5f);
		Test.Assert(Near(handle.Time(), 0.5f) && Near(handle.Duration(), 1.0f));
		handle.Stop();
		Test.Assert(!handle.IsPlaying());
		Test.Assert(!handle.Bind("Actor", stage.Actor));
		Test.Assert(handle.Time() == 0.0f);
		Test.Assert(!SequencePlay().IsPlaying(), "no play at all");
	}
}
