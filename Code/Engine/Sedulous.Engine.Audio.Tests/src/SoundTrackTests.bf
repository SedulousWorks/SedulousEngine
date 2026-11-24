using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Audio;
using Sedulous.Sequence;

namespace Sedulous.Engine.Audio.Tests;

/// A sequence's sound track on a playing scene: a section entered part way starts its voice there,
/// a voice that wanders is moved back to the playhead and a jump moves it at once, the voice pauses
/// with the play and plays on at a hold, and the play letting go stops it.
class SoundTrackTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) <= epsilon;

	private class SoundStage
	{
		public AudioPlayScene Audio = new .() ~ delete _;
		/// BORROWED from the fixture.
		public AudioClip Line;

		public this()
		{
			Line = Audio.AddClip(2.0f);
			Audio.Start();
		}

		/// The one voice playing (the track's); invalid when none.
		public VoiceHandle Voice()
		{
			let voices = scope List<VoiceHandle>();
			Audio.Engine.ActiveVoices(voices);
			return (voices.Count == 1) ? voices[0] : .();
		}

		public float Cursor()
		{
			Test.Assert(Audio.Engine.GetVoiceStatus(Voice(), let status));
			return status.CursorSeconds;
		}

		/// Mixes `seconds` in small steps, as a frame loop would.
		public void Mix(float seconds)
		{
			for (float t = 0.0f; t < seconds - 1.0e-4f; t += 0.05f)
				Audio.Engine.Update(0.05f);
		}

		/// Plays the sequence and the mixer on together.
		public void Run(SequencePlay play, float seconds)
		{
			for (float t = 0.0f; t < seconds - 1.0e-4f; t += 0.05f)
			{
				play.Advance(0.05f);
				Audio.Engine.Update(0.05f);
			}
		}
	}

	/// The line from `start` on the timeline, from its own start.
	private static Sedulous.Sequence.Sequence Line(AudioClip clip, float start)
	{
		let track = new SoundSequenceTrack();
		var section = SoundSection();
		section.Clip.SetDirect(clip);
		section.Start = start;
		track.Sections.Add(section);
		let sequence = new Sedulous.Sequence.Sequence();
		sequence.Tracks.Add(track);
		sequence.Duration = track.Duration;
		return sequence;
	}

	[Test]
	public static void ASectionsVoiceStartsWithItPartWayInWhenEnteredPartWay()
	{
		let stage = scope SoundStage();
		let sequence = Line(stage.Line, 1.0f);
		defer delete sequence;
		Test.Assert(Near(sequence.Duration, 3.0f, 1e-4f));
		let play = scope SequencePlay(stage.Audio.Scene, sequence);
		play.Play();
		stage.Run(play, 0.5f);
		Test.Assert(!stage.Voice().IsValid, "before the section");
		play.Seek(2.0f); // a second into the line
		Test.Assert(stage.Voice().IsValid);
		Test.Assert(Near(stage.Cursor(), 1.0f, 0.03f), scope $"entered at {stage.Cursor()}");
		stage.Run(play, 0.5f);
		Test.Assert(Near(stage.Cursor(), 1.5f, 0.075f), scope $"played on to {stage.Cursor()}");
		play.Stop();
		stage.Audio.Engine.Update(0.05f);
		Test.Assert(!stage.Voice().IsValid);
	}

	[Test]
	public static void AVoiceThatWandersFromThePlayheadIsMovedBack()
	{
		let stage = scope SoundStage();
		let sequence = Line(stage.Line, 0.0f);
		defer delete sequence;
		let play = scope SequencePlay(stage.Audio.Scene, sequence);
		play.Play();
		stage.Run(play, 0.5f);
		Test.Assert(stage.Voice().IsValid);
		stage.Audio.Engine.SeekVoice(stage.Voice(), 1.5f); // a second ahead of the playhead
		play.Advance(0.05f);
		Test.Assert(Near(stage.Cursor(), 0.55f, 0.03f), scope $"moved back to {stage.Cursor()}");
		play.Stop();
	}

	[Test]
	public static void TheVoicePausesWithThePlayAndPlaysOnAtAHold()
	{
		let stage = scope SoundStage();
		let sequence = Line(stage.Line, 0.0f);
		defer delete sequence;
		sequence.Markers.Add(new .(0.5f, "wait", true));
		let play = scope SequencePlay(stage.Audio.Scene, sequence);
		play.Play();
		stage.Run(play, 0.25f);
		play.Pause();
		stage.Audio.Engine.Update(0.05f); // the declick lands
		let pausedAt = stage.Cursor();
		stage.Mix(0.5f);
		Test.Assert(Near(stage.Cursor(), pausedAt, 0.01f), scope $"paused at {pausedAt}, now {stage.Cursor()}");
		play.Resume();
		stage.Run(play, 0.5f); // reaches the hold at 0.5
		Test.Assert(play.IsHeld);
		let heldAt = stage.Cursor();
		stage.Mix(0.5f);
		Test.Assert(stage.Cursor() > heldAt + 0.4f, "the line carries on while the game waits");
		play.Stop();
	}

	[Test]
	public static void ASequenceReadsItsSoundSectionsBackByTheirKind()
	{
		AudioSequenceTracks.Register();
		let track = new SoundSequenceTrack();
		track.Binding = 0;
		var section = SoundSection();
		let clipId = Guid(0x56, 0x78, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		section.Clip.SetId(clipId);
		section.Start = 0.5f;
		section.Length = 4.0f;
		section.Offset = 0.25f;
		section.Volume = 0.75f;
		section.Bus = .Music;
		section.Loop = true;
		track.Sections.Add(section);
		let original = scope Sedulous.Sequence.Sequence();
		original.Bindings.Add(new .("Speaker"));
		original.Tracks.Add(track);

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			original.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let read = scope Sedulous.Sequence.Sequence();
		{
			let reader = scope BinarySerializer(stream, .Read);
			read.Serialize(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(read.Tracks.Count == 1);
		let sounds = read.Tracks[0] as SoundSequenceTrack;
		Test.Assert((sounds != null) && (sounds.Sections.Count == 1));
		let back = sounds.Sections[0];
		Test.Assert(back.Clip.Id == clipId);
		Test.Assert(Near(back.Start, 0.5f, 1e-4f) && Near(back.Length, 4.0f, 1e-4f) && Near(back.Offset, 0.25f, 1e-4f));
		Test.Assert(Near(back.Volume, 0.75f, 1e-4f));
		Test.Assert(back.Bus == .Music);
		Test.Assert(back.Loop);
		Test.Assert(Near(sounds.Duration, 4.5f, 1e-4f));
	}

	[Test]
	public static void AStartTrimmedLaterMovesTheSoundsOffsetWithIt()
	{
		let track = scope SoundSequenceTrack();
		Test.Assert(track.AddSection(1.0f) == 0);
		track.SetSection(0, 1.25f, 0.75f);
		Test.Assert(Near(track.Sections[0].Offset, 0.25f, 1e-4f));
		Test.Assert(Near(track.Sections[0].Length, 0.75f, 1e-4f));
		track.RemoveSection(0);
		Test.Assert(track.SectionCount == 0);
	}
}
