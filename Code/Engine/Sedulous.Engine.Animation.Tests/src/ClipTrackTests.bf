using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Engine.Animation.Tests;

/// A sequence's clip track: its sections play skeletal clips over the entity's own pose through
/// the overlay, at the frame the playhead names (a seek lands on it), blended in and out, looped
/// over a section, and let go when the play ends.
class ClipTrackTests
{
	private static bool Near(float a, float b, float epsilon = 1e-3f) => Math.Abs(a - b) <= epsilon;

	/// The bone climbs from 0 to 2 over the clip's second.
	private static AnimationClip Rise()
	{
		let clip = new AnimationClip("Rise", 1.0f, false);
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 2, 0));
		return clip;
	}

	private class Stage
	{
		public Scene Level = new .("clips") ~ delete _;
		public Skeleton Skeleton = new .(1) ~ delete _;
		public AnimationClip Stand = new .("Stand", 1.0f, true) ~ delete _;
		public AnimationClip Clip = Rise() ~ delete _;
		public EntityHandle Hero;
		public SkeletalAnimationComponent* Animator;

		public this()
		{
			Skeleton.Bones[0].Index = 0;
			Skeleton.Bones[0].ParentIndex = -1;
			Skeleton.FindRootBones();
			Skeleton.BuildChildIndices();
			Skeleton.ComputeInverseBindPoses();
			Stand.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
			Stand.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 0, 0));
			Level.AddSystem<MeshComponentManager>();
			AnimationScene.AddAnimationSceneManagers(Level);
			Hero = Level.CreateEntity("Hero");
			Animator = Level.GetSystem<SkeletalAnimationComponentManager>().Add(Hero);
			Animator.Skeleton.SetDirect(Skeleton);
			Animator.Clip.SetDirect(Stand);
			Level.Update(0.01f); // the player is built
			Test.Assert(Animator.Player != null);
		}

		public float Height()
		{
			Animator.Player.GetSkinningMatrices(); // evaluates
			return Animator.Player.GetFinalPoses()[0].Position.Y;
		}

		/// A section of the stage's clip at `start`, with no blends.
		public ClipSection Section(float start)
		{
			var section = ClipSection();
			section.Clip.SetDirect(Clip);
			section.Start = start;
			section.BlendIn = 0.0f;
			section.BlendOut = 0.0f;
			return section;
		}
	}

	private static Sedulous.Sequence.Sequence OneSection(ClipSection section)
	{
		let track = new ClipSequenceTrack();
		track.Binding = 0;
		track.Sections.Add(section);
		let sequence = new Sedulous.Sequence.Sequence();
		sequence.Bindings.Add(new .("Hero"));
		sequence.Tracks.Add(track);
		sequence.Duration = track.Duration;
		return sequence;
	}

	[Test]
	public static void ASectionShowsItsClipAtThePlayheadsFrameAndTheEndLetsGo()
	{
		let stage = scope Stage();
		let sequence = OneSection(stage.Section(1.0f));
		defer delete sequence;
		Test.Assert(Near(sequence.Duration, 2.0f));
		let play = scope SequencePlay(stage.Level, sequence);
		Test.Assert(play.Bind("Hero", stage.Hero));

		play.Play();
		play.Advance(0.5f); // before the section: the pose underneath
		Test.Assert(Near(stage.Height(), 0.0f));
		play.Seek(1.5f); // half way through the clip
		stage.Level.Update(0.01f); // the player's own tick does not move a driven clip
		Test.Assert(Near(stage.Height(), 1.0f));
		play.Advance(0.25f);
		Test.Assert(Near(stage.Height(), 1.5f));
		play.Advance(1.0f); // the end: released
		Test.Assert(play.IsFinished);
		stage.Level.Update(0.01f);
		Test.Assert(Near(stage.Height(), 0.0f));
	}

	[Test]
	public static void ASectionBlendsInOverThePoseAndLoopsItsClipOverItsLength()
	{
		let stage = scope Stage();
		var section = stage.Section(0.0f);
		section.BlendIn = 0.5f;
		section.Length = 3.0f;
		section.Loop = true;
		let sequence = OneSection(section);
		defer delete sequence;
		let play = scope SequencePlay(stage.Level, sequence);
		Test.Assert(play.Bind("Hero", stage.Hero));

		play.Play();
		play.Advance(0.25f); // the clip at 0.25 (height 0.5), half blended in
		Test.Assert(Near(stage.Height(), 0.25f));
		play.Seek(2.5f); // the third time round, half way: in full
		Test.Assert(Near(stage.Height(), 1.0f));
		play.Stop();
	}

	/// Between two sections the overlay lets go, and the pose underneath shows.
	[Test]
	public static void BetweenSectionsThePoseUnderneathShows()
	{
		let stage = scope Stage();
		let first = stage.Section(0.0f);
		let second = stage.Section(2.0f);
		let sequence = OneSection(first);
		defer delete sequence;
		(sequence.Tracks[0] as ClipSequenceTrack).Sections.Add(second);
		sequence.Duration = 3.0f;
		let play = scope SequencePlay(stage.Level, sequence);
		Test.Assert(play.Bind("Hero", stage.Hero));

		play.Play();
		play.Advance(0.5f);
		Test.Assert(Near(stage.Height(), 1.0f));
		play.Advance(1.0f); // 1.5: between them
		stage.Level.Update(0.01f);
		Test.Assert(Near(stage.Height(), 0.0f));
		play.Advance(1.0f); // 2.5: the second, half way
		Test.Assert(Near(stage.Height(), 1.0f));
		play.Stop();
	}

	/// A section starts its clip at its offset; a play that ends on a section and holds keeps the
	/// section's last frame until it stops.
	[Test]
	public static void ASectionStartsAtItsOffsetAndAHeldPlayKeepsItsLastFrame()
	{
		let stage = scope Stage();
		var section = stage.Section(0.0f);
		section.Offset = 0.5f; // the second half of the clip, over half a second
		let sequence = OneSection(section);
		defer delete sequence;
		Test.Assert(Near(sequence.Duration, 0.5f));
		let play = scope SequencePlay(stage.Level, sequence);
		Test.Assert(play.Bind("Hero", stage.Hero));
		play.Finish = .Hold;

		play.Play();
		play.Advance(0.25f); // the clip at 0.75
		Test.Assert(Near(stage.Height(), 1.5f));
		play.Advance(1.0f);
		Test.Assert(play.IsFinished);
		stage.Level.Update(0.01f);
		Test.Assert(Near(stage.Height(), 2.0f), "held on the clip's last frame");
		play.Stop();
		stage.Level.Update(0.01f);
		Test.Assert(Near(stage.Height(), 0.0f));
	}

	[Test]
	public static void StoppingMidSectionEasesBackToThePoseUnderneath()
	{
		let stage = scope Stage();
		var section = stage.Section(0.0f);
		section.BlendOut = 0.2f;
		section.Length = 1.0f;
		let sequence = OneSection(section);
		defer delete sequence;
		let play = scope SequencePlay(stage.Level, sequence);
		Test.Assert(play.Bind("Hero", stage.Hero));

		play.Play();
		play.Advance(0.5f);
		Test.Assert(Near(stage.Height(), 1.0f));
		play.Stop();
		stage.Level.Update(0.1f); // half way out
		Test.Assert((stage.Height() > 0.1f) && (stage.Height() < 1.1f), scope $"half way out: {stage.Height()}");
		stage.Level.Update(0.2f);
		Test.Assert(Near(stage.Height(), 0.0f));
	}

	[Test]
	public static void ASequenceReadsItsClipSectionsBackByTheirKind()
	{
		AnimationSequenceTracks.Register();
		let track = new ClipSequenceTrack();
		track.Binding = 0;
		var section = ClipSection();
		let clipId = Guid(0x12, 0x34, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		section.Clip.SetId(clipId);
		section.Start = 1.5f;
		section.Length = 2.0f;
		section.Offset = 0.25f;
		section.Speed = 2.0f;
		section.BlendIn = 0.1f;
		section.BlendOut = 0.3f;
		section.Loop = true;
		track.Sections.Add(section);
		let original = scope Sedulous.Sequence.Sequence();
		original.Bindings.Add(new .("Hero"));
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
		let clips = read.Tracks[0] as ClipSequenceTrack;
		Test.Assert((clips != null) && (clips.Sections.Count == 1));
		let back = clips.Sections[0];
		Test.Assert(back.Clip.Id == clipId);
		Test.Assert(Near(back.Start, 1.5f) && Near(back.Length, 2.0f) && Near(back.Offset, 0.25f));
		Test.Assert(Near(back.Speed, 2.0f) && Near(back.BlendIn, 0.1f) && Near(back.BlendOut, 0.3f));
		Test.Assert(back.Loop);
		Test.Assert(Near(clips.Duration, 3.5f));

		bool listed = false;
		for (let kind in SequenceTracks.Kinds)
			listed |= kind == typeof(ClipSequenceTrack);
		Test.Assert(listed);
	}

	[Test]
	public static void AStartTrimmedLaterMovesTheClipsOffsetWithItSoWhatPlaysStaysPut()
	{
		let track = scope ClipSequenceTrack();
		Test.Assert(track.AddSection(2.0f) == 0);
		Test.Assert(track.AddSection(1.0f) == 0, "sorted by start");
		Test.Assert(track.SectionCount == 2);
		track.Sections[1].Speed = 2.0f;
		track.SetSection(1, 2.5f, 0.5f); // trimmed half a second at double speed
		Test.Assert(Near(track.Sections[1].Offset, 1.0f));
		let label = scope String();
		track.GetSection(1, let start, let length, label);
		Test.Assert(Near(start, 2.5f) && Near(length, 0.5f));
		Test.Assert(label == "Clip", "no clip yet");
		track.RemoveSection(0);
		Test.Assert(track.SectionCount == 1);
	}
}
