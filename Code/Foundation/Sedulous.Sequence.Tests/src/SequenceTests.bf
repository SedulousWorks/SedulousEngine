using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;

namespace Sedulous.Sequence.Tests;

/// A lamp with a brightness, for the property tracks.
[Reflect(.All)]
struct SeqLamp
{
	public float Brightness = 1.0f;

	public this() {}
}

class SeqLampManager : ComponentManager<SeqLamp>
{
}

/// Each report as a line: "event:<name>=<value>@bound|@none", "held:<marker>", "finished".
class SequenceRecorder : ISequenceListener
{
	public List<String> Heard = new .() ~ DeleteContainerAndItems!(_);

	public void OnSequenceEvent(EntityHandle target, StringView name, StringView value) =>
		Heard.Add(new $"event:{name}={value}{target.IsAssigned ? "@bound" : "@none"}");
	public void OnSequenceHeld(StringView marker) => Heard.Add(new $"held:{marker}");
	public void OnSequenceFinished() => Heard.Add(new .("finished"));

	public int Count(StringView line)
	{
		int n = 0;
		for (let h in Heard)
		{
			if (h == line)
				n++;
		}
		return n;
	}

	public bool Has(StringView line) => Count(line) > 0;
}

/// A world with a lamp and a mentor, held by the caller.
/// What a play tells its runners of pauses.
class PauseLog
{
	public int Paused;
	public int Resumed;
}

/// A kind whose runner counts what the play tells it of pauses.
class PauseProbeTrack : SequenceTrack
{
	/// BORROWED.
	public PauseLog Log;

	public override float Duration => 1.0f;
	public override bool NeedsBinding => false;
	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new Runner(Log);

	private class Runner : SequenceTrackRunner
	{
		private PauseLog mLog;

		public this(PauseLog log) { mLog = log; }

		public override void Evaluate(SequenceStep step) {}
		public override void Release(bool restore) {}
		public override void SetPaused(bool paused)
		{
			if (paused)
				mLog.Paused++;
			else
				mLog.Resumed++;
		}
	}
}

/// A line a runner holds the play at until the test reads it.
class HoldLine
{
	public float HoldAt = 0.5f;
	public bool Read = false;
	public int Evaluated = 0;
}

/// A kind whose runner holds the play at its line's time until the line is read.
class HoldProbeTrack : SequenceTrack
{
	/// BORROWED.
	public HoldLine Line;

	public override float Duration => 1.0f;
	public override bool NeedsBinding => false;
	public override SequenceTrackRunner Begin(SequenceTrackContext context) => new Runner(Line);

	private class Runner : SequenceTrackRunner
	{
		private HoldLine mLine;

		public this(HoldLine line) { mLine = line; }

		public override void Evaluate(SequenceStep step) { mLine.Evaluated++; }
		public override void Release(bool restore) {}
		public override float HoldTime(float after, float upTo) => ((mLine.HoldAt > after) && (mLine.HoldAt <= upTo)) ? mLine.HoldAt : -1.0f;
		public override bool IsHolding => !mLine.Read;
	}
}

class SequenceStage
{
	public Sedulous.Scene.Scene World = new .("sequence") ~ delete _;
	public SeqLampManager Lamps;
	public EntityHandle Mentor;
	public EntityHandle Lamp;

	public this()
	{
		SequenceTracks.RegisterTypes();
		Lamps = World.AddSystem<SeqLampManager>();
		Mentor = World.CreateEntity("Mentor");
		Lamp = World.CreateEntity("Lamp");
		Lamps.Add(Lamp).Brightness = 1.0f;
	}

	public float Brightness(EntityHandle entity) => Lamps.Get(entity).Brightness;
	public float X(EntityHandle entity) => World.GetLocalTransform(entity).Position.X;
}

/// A play on a scene: property tracks over several bound entities, events fired only when played
/// through, holds, loops, the three finishes, rebinding, the editor's pose, serialization, and the
/// track kinds registered.
class SequenceTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// A linear `from` -> `to` property track over one second.
	private static PropertySequenceTrack Brightness(int32 binding, float from, float to)
	{
		let track = new PropertySequenceTrack();
		track.Name.Set("brightness");
		track.Binding = binding;
		track.Property.ComponentType.Set("SeqLamp");
		track.Property.PropertyPath.Set("Brightness");
		track.Property.Kind = .Float;
		track.Property.Channels[0].AddKey(.(0.0f, from));
		track.Property.Channels[0].AddKey(.(1.0f, to));
		return track;
	}

	private static PropertySequenceTrack Position(int32 binding, float toX)
	{
		let track = new PropertySequenceTrack();
		track.Name.Set("position");
		track.Binding = binding;
		track.Property.ComponentType.Set(TrackTargets.cTransform);
		track.Property.PropertyPath.Set("Position");
		track.Property.Kind = .Float3;
		track.Property.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Property.Channels[0].AddKey(.(1.0f, toX));
		return track;
	}

	private static EventSequenceTrack Events(int32 binding, params SequenceEventKey[] keys)
	{
		let track = new EventSequenceTrack();
		track.Name.Set("events");
		track.Binding = binding;
		for (let key in keys)
			track.Keys.Add(key);
		return track;
	}

	/// Mentor's position and the lamp's brightness, each over one second. Held by the caller.
	private static Sequence TwoActors()
	{
		let sequence = new Sequence();
		sequence.Bindings.Add(new .("Mentor"));
		sequence.Bindings.Add(new .("Lamp"));
		sequence.Tracks.Add(Position(0, 10.0f));
		sequence.Tracks.Add(Brightness(1, 0.0f, 4.0f));
		sequence.Duration = sequence.ComputeDuration();
		return sequence;
	}

	[Test]
	public static void OnePlayDrivesSeveralBoundEntitiesAtOnce()
	{
		let stage = scope SequenceStage();
		let sequence = TwoActors();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Mentor", stage.Mentor));
		Test.Assert(play.Bind("Lamp", stage.Lamp));
		Test.Assert(!play.Bind("Nobody", stage.Lamp));

		play.Play();
		Test.Assert(Near(stage.Brightness(stage.Lamp), 0.0f), "time 0 applied at once");
		play.Advance(0.5f);
		Test.Assert(Near(stage.X(stage.Mentor), 5.0f));
		Test.Assert(Near(stage.Brightness(stage.Lamp), 2.0f));
		play.Advance(0.75f);
		Test.Assert(play.IsFinished);
		Test.Assert(Near(stage.X(stage.Mentor), 10.0f));
	}

	[Test]
	public static void ATrackWhoseNameIsNotFilledIsSkippedTheOthersPlay()
	{
		let stage = scope SequenceStage();
		let sequence = TwoActors();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Lamp", stage.Lamp)); // Mentor left empty
		play.Play();
		play.Advance(0.5f);
		Test.Assert(Near(stage.Brightness(stage.Lamp), 2.0f));
		Test.Assert(Near(stage.X(stage.Mentor), 0.0f));
	}

	[Test]
	public static void EventsFireOnceWhenPlayedThroughNeverOnASeekOrAPose()
	{
		let stage = scope SequenceStage();
		let sequence = scope Sequence();
		sequence.Bindings.Add(new .("Mentor"));
		sequence.Tracks.Add(Events(-1, new SequenceEventKey(0.0f, "start"), new SequenceEventKey(0.5f, "cue", "gate")));
		sequence.Tracks.Add(Events(0, new SequenceEventKey(0.75f, "wave")));
		sequence.Duration = 1.0f;
		let recorder = scope SequenceRecorder();
		let play = scope SequencePlay(stage.World, sequence);
		play.SetListener(recorder);
		play.Bind("Mentor", stage.Mentor);

		play.Play();
		Test.Assert(recorder.Has("event:start=@none"), "a key at 0 fires on the first step");
		play.Advance(0.5f);
		Test.Assert(recorder.Has("event:cue=gate@none"));
		play.Advance(0.1f);
		Test.Assert(recorder.Count("event:cue=gate@none") == 1);
		play.Advance(0.2f);
		Test.Assert(recorder.Has("event:wave=@bound"), "a bound track reports its entity");

		ClearAndDeleteItems!(recorder.Heard);
		play.Seek(0.0f);
		play.Seek(0.9f); // jumps over every key
		play.Pose(0.5f);
		Test.Assert(recorder.Heard.IsEmpty);
	}

	[Test]
	public static void AHoldStopsThePlayheadUntilThePlayIsResumed()
	{
		let stage = scope SequenceStage();
		let sequence = TwoActors();
		defer delete sequence;
		sequence.Markers.Add(new .(0.25f, "line1", true));
		sequence.Markers.Add(new .(0.5f, "note", false)); // not a hold
		let recorder = scope SequenceRecorder();
		let play = scope SequencePlay(stage.World, sequence);
		play.SetListener(recorder);
		play.Bind("Lamp", stage.Lamp);
		play.Play();

		play.Advance(0.6f); // past the hold: stops at it
		Test.Assert(play.IsHeld);
		Test.Assert(Near(play.Time, 0.25f));
		Test.Assert(recorder.Has("held:line1"));
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
		play.Advance(1.0f); // held: nothing moves
		Test.Assert(Near(play.Time, 0.25f));

		play.Resume();
		play.Advance(0.25f);
		Test.Assert(Near(play.Time, 0.5f));
		Test.Assert(recorder.Count("held:line1") == 1, "the hold it left does not stop it again");
	}

	[Test]
	public static void ALoopWrapsFiringWhatIsAtItsStartAgain()
	{
		let stage = scope SequenceStage();
		let sequence = scope Sequence();
		sequence.Tracks.Add(Events(-1, new SequenceEventKey(0.0f, "top")));
		sequence.Duration = 1.0f;
		let recorder = scope SequenceRecorder();
		let play = scope SequencePlay(stage.World, sequence);
		play.SetListener(recorder);
		play.Loop = true;
		play.Play();
		play.Advance(1.25f);
		Test.Assert(Near(play.Time, 0.25f));
		Test.Assert(!play.IsFinished);
		Test.Assert(recorder.Count("event:top=@none") == 2);
		Test.Assert(!recorder.Has("finished"));
	}

	[Test]
	public static void TheFinishLetsGoHoldsOrPutsEveryValueBack()
	{
		// Release keeps what moved.
		{
			let stage = scope SequenceStage();
			let sequence = TwoActors();
			defer delete sequence;
			let recorder = scope SequenceRecorder();
			let play = scope SequencePlay(stage.World, sequence);
			play.SetListener(recorder);
			play.Bind("Lamp", stage.Lamp);
			play.Play();
			play.Advance(2.0f);
			Test.Assert(recorder.Has("finished"));
			Test.Assert(!play.IsPlaying);
			Test.Assert(Near(stage.Brightness(stage.Lamp), 4.0f));
		}
		// Restore puts back what was there before the first write.
		{
			let stage = scope SequenceStage();
			let sequence = TwoActors();
			defer delete sequence;
			let play = scope SequencePlay(stage.World, sequence);
			play.Finish = .Restore;
			play.Bind("Mentor", stage.Mentor);
			play.Bind("Lamp", stage.Lamp);
			play.Play();
			play.Advance(2.0f);
			Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
			Test.Assert(Near(stage.X(stage.Mentor), 0.0f));
		}
		// Hold keeps the last frame until stopped.
		{
			let stage = scope SequenceStage();
			let sequence = TwoActors();
			defer delete sequence;
			let play = scope SequencePlay(stage.World, sequence);
			play.Finish = .Hold;
			play.Bind("Lamp", stage.Lamp);
			play.Play();
			play.Advance(2.0f);
			Test.Assert(play.IsFinished);
			Test.Assert(Near(stage.Brightness(stage.Lamp), 4.0f));
			play.Stop();
			Test.Assert(Near(stage.Brightness(stage.Lamp), 4.0f));
		}
	}

	/// Destroying a play, or abandoning one, touches nothing in the scene, even when its finish
	/// would restore: it may be the scene going away. Stop is what releases.
	[Test]
	public static void DestroyingOrAbandoningAPlayReleasesNothing()
	{
		let stage = scope SequenceStage();
		let sequence = TwoActors();
		defer delete sequence;
		{
			let play = scope SequencePlay(stage.World, sequence);
			play.Finish = .Restore;
			play.Bind("Lamp", stage.Lamp);
			play.Play();
			play.Advance(0.5f);
			Test.Assert(Near(stage.Brightness(stage.Lamp), 2.0f));
		}
		Test.Assert(Near(stage.Brightness(stage.Lamp), 2.0f), "destroyed: nothing restored");

		let play = scope SequencePlay(stage.World, sequence);
		play.Finish = .Restore;
		play.Bind("Lamp", stage.Lamp);
		play.Play();
		play.Advance(0.75f);
		play.Abandon();
		Test.Assert(!play.IsPlaying);
		play.Stop(); // nothing left to release
		Test.Assert(Near(stage.Brightness(stage.Lamp), 3.0f), "abandoned: nothing restored");
	}

	[Test]
	public static void TwoTracksOnOnePropertyRestoreToTheValueBeforeBoth()
	{
		let stage = scope SequenceStage();
		let sequence = scope Sequence();
		sequence.Bindings.Add(new .("Lamp"));
		sequence.Tracks.Add(Brightness(0, 0.0f, 4.0f));
		sequence.Tracks.Add(Brightness(0, 10.0f, 20.0f)); // the later track, written last
		sequence.Duration = sequence.ComputeDuration();
		let play = scope SequencePlay(stage.World, sequence);
		play.Finish = .Restore;
		play.Bind("Lamp", stage.Lamp);
		play.Play();
		play.Advance(0.5f);
		Test.Assert(Near(stage.Brightness(stage.Lamp), 15.0f));
		play.Stop();
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
	}

	[Test]
	public static void BindingANameDuringAPlayMovesItsTracksToTheNewEntity()
	{
		let stage = scope SequenceStage();
		let other = stage.World.CreateEntity("Other");
		stage.Lamps.Add(other).Brightness = 7.0f;
		let sequence = TwoActors();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		play.Bind("Lamp", stage.Lamp);
		play.Play();
		play.Advance(0.25f);
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
		play.Bind("Lamp", other);
		play.Advance(0.25f);
		Test.Assert(Near(stage.Brightness(other), 2.0f));
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f), "left where it was");
	}

	[Test]
	public static void TheEditorsPoseAppliesValuesAndRestoresThemOnStop()
	{
		let stage = scope SequenceStage();
		let sequence = TwoActors();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		play.Finish = .Restore;
		play.Bind("Lamp", stage.Lamp);
		play.Pose(0.75f);
		Test.Assert(Near(stage.Brightness(stage.Lamp), 3.0f));
		play.Pose(0.25f);
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
		play.Stop();
		Test.Assert(Near(stage.Brightness(stage.Lamp), 1.0f));
	}

	[Test]
	public static void ASequenceReadsBackAsItWasWrittenEveryTrackByItsKind()
	{
		SequenceTracks.RegisterTypes();
		let original = TwoActors();
		defer delete original;
		original.FrameRate = 24.0f;
		original.Markers.Add(new .(0.5f, "line", true));
		original.Tracks.Add(Events(0, new SequenceEventKey(0.25f, "cue", "gate")));
		original.Tracks[1].Muted = true;

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			original.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let read = scope Sequence();
		{
			let reader = scope BinarySerializer(stream, .Read);
			read.Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(Near(read.Duration, original.Duration));
		Test.Assert(Near(read.FrameRate, 24.0f));
		Test.Assert((read.Bindings.Count == 2) && (read.Bindings[1].Name == "Lamp"));
		Test.Assert((read.Markers.Count == 1) && read.Markers[0].Hold);
		Test.Assert(read.Tracks.Count == 3);
		let position = read.Tracks[0] as PropertySequenceTrack;
		Test.Assert(position != null);
		Test.Assert(position.Property.ComponentType == TrackTargets.cTransform);
		Test.Assert(Near(position.Property.Sample(0.5f).Vector.X, 5.0f));
		Test.Assert(read.Tracks[1].Muted);
		Test.Assert(read.Tracks[1].Binding == 1);
		let events = read.Tracks[2] as EventSequenceTrack;
		Test.Assert((events != null) && (events.Keys.Count == 1) && (events.Keys[0].Value == "gate"));
	}

	[Test]
	public static void TheTrackKindsAreRegistered()
	{
		SequenceTracks.RegisterTypes();
		bool property = false;
		bool events = false;
		for (let kind in SequenceTracks.Kinds)
		{
			property |= kind == typeof(PropertySequenceTrack);
			events |= kind == typeof(EventSequenceTrack);
			Test.Assert(kind != typeof(SequenceTrack));
		}
		Test.Assert(property && events);
	}

	[Test]
	public static void PausingAndResumingAPlayTellsItsRunnersAndAHoldDoesNot()
	{
		let stage = scope SequenceStage();
		let log = scope PauseLog();
		let sequence = scope Sedulous.Sequence.Sequence();
		let probe = new PauseProbeTrack();
		probe.Log = log;
		sequence.Tracks.Add(probe);
		sequence.Markers.Add(new .(0.5f, "line", true));
		sequence.Duration = 1.0f;
		let play = scope SequencePlay(stage.World, sequence);

		play.Play();
		play.Pause();
		play.Pause(); // already paused: told once
		Test.Assert(log.Paused == 1);
		play.Resume();
		Test.Assert(log.Resumed == 1);
		play.Advance(0.75f); // stops at the hold: the runners carry on
		Test.Assert(play.IsHeld);
		play.Resume(); // from a hold, not a pause
		Test.Assert((log.Paused == 1) && (log.Resumed == 1));
	}

	[Test]
	public static void APropertyTracksChannelsAreItsPartsKeysMoveSortDeleteAndInsert()
	{
		let track = scope PropertySequenceTrack();
		track.Property.ComponentType.Set(TrackTargets.cTransform);
		track.Property.PropertyPath.Set("Position");
		track.Property.Kind = .Float3;
		Test.Assert(track.KeyChannelCount == 3);
		Test.Assert(track.GetKeyChannelName(1, .. scope .()) == "y");
		Test.Assert(track.KeyCurve(0) === track.Property.Channels[0]);

		// x: 0 at 0, 10 at 1. A key inserted at 0.5 takes the curve's value there.
		var first = CurveKey(0.0f, 0.0f, .Linear);
		first.TangentMode = .Broken;
		var last = CurveKey(1.0f, 10.0f, .Linear);
		last.TangentMode = .Broken;
		track.Property.Channels[0].AddKey(first);
		track.Property.Channels[0].AddKey(last);
		Test.Assert(track.InsertKey(0, 0.5f) == 1);
		Test.Assert(Math.Abs(track.Property.Channels[0].Keys[1].Value - 5.0f) < 1e-3f);
		Test.Assert(track.InsertKey(0, 0.5f) == 1, "already there: no second key");
		Test.Assert(track.Property.Channels[0].KeyCount == 3);

		// The first key moved past the others lands last; where it went is reported.
		int[1] firstKey = .(0);
		let moved = scope List<int>();
		track.MoveKeys(0, firstKey, 1.5f, moved);
		Test.Assert((moved.Count == 1) && (moved[0] == 2));
		let times = scope List<float>();
		track.GetKeyTimes(0, times);
		Test.Assert(times.Count == 3);
		Test.Assert(Math.Abs(times[0] - 0.5f) < 1e-4f);
		Test.Assert(Math.Abs(times[2] - 1.5f) < 1e-4f);
		Test.Assert(Math.Abs(track.Property.Channels[0].Keys[2].Value - 0.0f) < 1e-4f, "its value went with it");
		track.MoveKeys(0, firstKey, -5.0f, moved); // never before 0
		track.GetKeyTimes(0, times);
		Test.Assert(times[0] == 0.0f);

		track.DeleteKeys(0, firstKey);
		Test.Assert(track.Property.Channels[0].KeyCount == 2);

		// A rotation is one channel of its keys, and no curve.
		let turn = scope PropertySequenceTrack();
		turn.Property.Kind = .Quat;
		Test.Assert(turn.KeyChannelCount == 1);
		Test.Assert(turn.KeyCurve(0) == null);
		Test.Assert(turn.InsertKey(0, 0.25f) == 0);
		Test.Assert(turn.Property.QuatKeys.Count == 1);
	}

	[Test]
	public static void AnEventTrackIsOneChannelANewEventIsNamedForTheInspectorToRename()
	{
		let track = scope EventSequenceTrack();
		track.Keys.Add(new .(1.0f, "cue", "gate"));
		Test.Assert(track.InsertKey(0, 0.5f) == 0);
		Test.Assert(track.Keys[0].Name == "event");
		int[1] second = .(1);
		let moved = scope List<int>();
		track.MoveKeys(0, second, -0.75f, moved);
		Test.Assert((moved.Count == 1) && (moved[0] == 0));
		Test.Assert(track.Keys[0].Name == "cue", "the cue now first, at 0.25");
		Test.Assert(track.KeyCurve(0) == null);
		Test.Assert(track.SectionCount == 0);
		track.DeleteKeys(0, second);
		Test.Assert((track.Keys.Count == 1) && (track.Keys[0].Name == "cue"));
	}

	/// A sequence of one hold probe over a second, its line read by the test.
	static Sedulous.Sequence.Sequence HoldSequence(HoldLine line)
	{
		let sequence = new Sedulous.Sequence.Sequence();
		let probe = new HoldProbeTrack();
		probe.Line = line;
		sequence.Tracks.Add(probe);
		sequence.Duration = 1.0f;
		return sequence;
	}


	[Test]
	public static void ARunnerHoldsThePlayAtItsTimeUntilItLetsGo()
	{
		let stage = scope SequenceStage();
		let line = scope HoldLine();
		let sequence = HoldSequence(line);
		defer delete sequence;
		let recorder = scope SequenceRecorder();
		let play = scope SequencePlay(stage.World, sequence);
		play.SetListener(recorder);
		play.Play();

		play.Advance(0.75f); // past the runner's hold: it stops there
		Test.Assert(play.IsHeld);
		Test.Assert(Near(play.Time, 0.5f));
		Test.Assert(recorder.Heard.IsEmpty, "a runner's hold is its own to show, not a marker's");
		let evaluated = line.Evaluated;
		play.Advance(1.0f); // still held: nothing moves, nothing is evaluated
		Test.Assert(Near(play.Time, 0.5f));
		Test.Assert(line.Evaluated == evaluated);

		line.Read = true; // the runner lets go: the next step goes on
		play.Advance(0.25f);
		Test.Assert(!play.IsHeld);
		Test.Assert(Near(play.Time, 0.75f));
		play.Advance(0.5f); // the hold it left does not stop it again
		Test.Assert(play.IsFinished);
	}

	[Test]
	public static void ARunnersHoldAlreadyLetGoIsPassedInTheSameStep()
	{
		let stage = scope SequenceStage();
		let line = scope HoldLine();
		line.Read = true; // read before the playhead reaches it
		let sequence = HoldSequence(line);
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		play.Play();
		play.Advance(0.75f);
		Test.Assert(!play.IsHeld);
		Test.Assert(Near(play.Time, 0.75f), "the whole step was played");
	}

	[Test]
	public static void AMarkerAndARunnersHoldTheEarlierWinsResumeLetsGoOfBoth()
	{
		let stage = scope SequenceStage();
		{
			// The marker first, then the runner's.
			let line = scope HoldLine();
			let sequence = HoldSequence(line);
			defer delete sequence;
			sequence.Markers.Add(new .(0.25f, "line", true));
			let play = scope SequencePlay(stage.World, sequence);
			play.Play();
			play.Advance(0.75f);
			Test.Assert(Near(play.Time, 0.25f));
			play.Resume();
			play.Advance(0.75f);
			Test.Assert(play.IsHeld);
			Test.Assert(Near(play.Time, 0.5f));
		}
		{
			// At one time both hold; the line read, the marker still holds; Resume lets go of both.
			let line = scope HoldLine();
			let sequence = HoldSequence(line);
			defer delete sequence;
			sequence.Markers.Add(new .(0.5f, "line", true));
			let play = scope SequencePlay(stage.World, sequence);
			play.Play();
			play.Advance(0.75f);
			Test.Assert(Near(play.Time, 0.5f));
			line.Read = true;
			play.Advance(0.1f);
			Test.Assert(play.IsHeld);
			play.Resume();
			play.Advance(0.1f);
			Test.Assert(Near(play.Time, 0.6f));
		}
		{
			// The runner's first: it holds there, the marker's not told until the play reaches it.
			let line = scope HoldLine();
			let sequence = HoldSequence(line);
			defer delete sequence;
			sequence.Markers.Add(new .(0.75f, "later", true));
			let recorder = scope SequenceRecorder();
			let play = scope SequencePlay(stage.World, sequence);
			play.SetListener(recorder);
			play.Play();
			play.Advance(1.0f);
			Test.Assert(Near(play.Time, 0.5f));
			Test.Assert(!recorder.Has("held:later"));
			line.Read = true;
			play.Advance(1.0f);
			Test.Assert(Near(play.Time, 0.75f));
			Test.Assert(recorder.Has("held:later"));
		}
		{
			// Resume overrides a runner still holding.
			let line = scope HoldLine();
			let sequence = HoldSequence(line);
			defer delete sequence;
			let play = scope SequencePlay(stage.World, sequence);
			play.Play();
			play.Advance(0.75f);
			Test.Assert(play.IsHeld);
			play.Resume();
			play.Advance(0.25f);
			Test.Assert(Near(play.Time, 0.75f));
		}
	}

	[Test]
	public static void ASeekOrAStopLetsGoOfARunnersHold()
	{
		let stage = scope SequenceStage();
		let line = scope HoldLine();
		let sequence = HoldSequence(line);
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		play.Play();
		play.Advance(0.75f);
		Test.Assert(play.IsHeld);
		play.Seek(0.6f);
		Test.Assert(!play.IsHeld);
		play.Advance(0.1f);
		Test.Assert(Near(play.Time, 0.7f));
		play.Seek(0.0f);
		play.Advance(0.75f); // reaching it again holds again
		Test.Assert(play.IsHeld);
		play.Stop();
		Test.Assert(!play.IsHeld);
	}
}
