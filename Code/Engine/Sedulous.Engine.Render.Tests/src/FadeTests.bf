using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.Sequence;
using Sedulous.VFS;

namespace Sedulous.Engine.Render.Tests;

/// A sequence's fade: its keys give the amount over the play, the play begun last holds the fade,
/// and letting go clears it (or hands it to the play under it).
class FadeTests
{
	class FadeStage
	{
		public Scene World = new .("fades") ~ delete _;
		public PostProcessSystem Post;

		public this()
		{
			Post = World.AddSystem<PostProcessSystem>();
		}
	}

	static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// From nothing to all over `seconds`, in `color`.
	static Sedulous.Sequence.Sequence FadeOut(float seconds, Color color)
	{
		let track = new FadeSequenceTrack();
		track.Color = color;
		var from = CurveKey();
		from.Time = 0.0f;
		from.Value = 0.0f;
		from.Interpolation = .Linear;
		var to = CurveKey();
		to.Time = seconds;
		to.Value = 1.0f;
		to.Interpolation = .Linear;
		track.Amount.AddKey(from);
		track.Amount.AddKey(to);
		let sequence = new Sedulous.Sequence.Sequence();
		sequence.Tracks.Add(track);
		sequence.Duration = seconds;
		return sequence;
	}

	[Test]
	public static void ItsKeysGiveTheAmountAndThePlaysEndClearsIt()
	{
		let stage = scope FadeStage();
		Test.Assert(stage.Post.Fade.Amount == 0.0f);
		let sequence = FadeOut(1.0f, .(1.0f, 0.5f, 0.25f, 1.0f));
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);

		play.Play();
		Test.Assert(Near(stage.Post.Fade.Amount, 0.0f));
		play.Advance(0.5f);
		Test.Assert(Near(stage.Post.Fade.Amount, 0.5f));
		Test.Assert(Near(stage.Post.Fade.Color.G, 0.5f));
		play.Advance(1.0f); // the end: released
		Test.Assert(play.IsFinished);
		Test.Assert(stage.Post.Fade.Amount == 0.0f);
	}

	[Test]
	public static void AHeldPlayStaysFadedUntilItStops()
	{
		let stage = scope FadeStage();
		let sequence = FadeOut(1.0f, .(0, 0, 0, 1));
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		play.Finish = .Hold;
		play.Play();
		play.Advance(2.0f);
		Test.Assert(play.IsFinished);
		Test.Assert(Near(stage.Post.Fade.Amount, 1.0f));
		play.Stop();
		Test.Assert(stage.Post.Fade.Amount == 0.0f);
	}

	[Test]
	public static void ThePlayBegunLastHoldsTheFadeAndGivesItBackToTheOneUnderIt()
	{
		let stage = scope FadeStage();
		let black = FadeOut(10.0f, .(0, 0, 0, 1));
		defer delete black;
		let white = FadeOut(1.0f, .(1, 1, 1, 1));
		defer delete white;
		let under = scope SequencePlay(stage.World, black);
		let over = scope SequencePlay(stage.World, white);

		under.Play();
		over.Play();
		under.Advance(5.0f); // the earlier play steps on: the later one keeps the fade
		over.Advance(0.5f);
		Test.Assert(Near(stage.Post.Fade.Color.R, 1.0f));
		Test.Assert(Near(stage.Post.Fade.Amount, 0.5f));
		over.Advance(1.0f);
		Test.Assert(over.IsFinished);
		Test.Assert(Near(stage.Post.Fade.Color.R, 0.0f));
		Test.Assert(Near(stage.Post.Fade.Amount, 0.5f));
		under.Stop();
		Test.Assert(stage.Post.Fade.Amount == 0.0f);
	}

	/// A nested play fading late still counts as the play it is inside: begun before the other, it
	/// does not take the fade from the play begun after it.
	[Test]
	public static void ANestedPlaysFadeRanksAsItsOutermostPlay()
	{
		let stage = scope FadeStage();
		let outerShot = FadeOut(10.0f, .(0, 0, 0, 1));
		defer delete outerShot;
		let innerShot = FadeOut(1.0f, .(0, 1, 0, 1));
		defer delete innerShot;
		let laterShot = FadeOut(1.0f, .(1, 1, 1, 1));
		defer delete laterShot;
		let outer = scope SequencePlay(stage.World, outerShot);
		let inner = scope SequencePlay(stage.World, innerShot);
		inner.SetParent(outer);
		let later = scope SequencePlay(stage.World, laterShot);

		outer.Play();
		later.Play();
		inner.Play(); // claims last, but ranks as the outer play, begun before `later`
		Test.Assert(Near(stage.Post.Fade.Color.R, 1.0f) && Near(stage.Post.Fade.Color.G, 1.0f) && Near(stage.Post.Fade.Color.B, 1.0f));
		inner.Stop();
		later.Stop();
		outer.Stop();
	}

	[Test]
	public static void ASceneNothingRendersHasNoViewToFade()
	{
		let bare = scope Scene("bare");
		let sequence = FadeOut(1.0f, .(0, 0, 0, 1));
		defer delete sequence;
		let play = scope SequencePlay(bare, sequence);
		play.Play();
		play.Advance(0.5f);
		Test.Assert(play.IsPlaying);
	}

	[Test]
	public static void ASequenceReadsItsFadeBackByItsKind()
	{
		RenderSequenceTracks.Register();
		let original = FadeOut(2.0f, .(0.2f, 0.4f, 0.6f, 1.0f));
		defer delete original;
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
		let fade = read.Tracks[0] as FadeSequenceTrack;
		Test.Assert(fade != null);
		Test.Assert(Near(fade.Color.G, 0.4f));
		Test.Assert(fade.Amount.KeyCount == 2);
		Test.Assert(Near(fade.Amount.Evaluate(1.0f), 0.5f));
		Test.Assert(fade.Amount.Keys[1].Interpolation == .Linear);
		Test.Assert(Near(fade.Duration, 2.0f));

		bool listed = false;
		for (let kind in SequenceTracks.Kinds)
			listed |= kind == typeof(FadeSequenceTrack);
		Test.Assert(listed);
	}

	/// The render hands the scene's winning fade to the view's post config, over the authored post.
	[Test]
	public static void AViewIsGivenTheScenesWinningFade()
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return;
		let mount = scope NativeFileSystem(dataRoot);
		let backend = NullRhi.CreateBackend();
		defer { backend.Destroy(); delete backend; }
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		defer device.Destroy();
		let subsystem = scope RenderSubsystem(device, 2, mount);

		let stage = scope FadeStage();
		Test.Assert(subsystem.ViewPost(stage.World).Fade.W == 0.0f);
		let holder = scope Object();
		stage.Post.FadeClaims.Claim(holder, 1, .(.(0.25f, 0.5f, 0.75f, 1.0f), 0.4f));
		let fade = subsystem.ViewPost(stage.World).Fade;
		Test.Assert(Near(fade.X, 0.25f) && Near(fade.Y, 0.5f) && Near(fade.Z, 0.75f) && Near(fade.W, 0.4f));
		stage.Post.FadeClaims.Release(holder);
		Test.Assert(subsystem.ViewPost(stage.World).Fade.W == 0.0f);
	}

	[Test]
	public static void TheFadesAmountIsOneCurveChannelAShotIsASection()
	{
		let fade = scope FadeSequenceTrack();
		Test.Assert(fade.KeyChannelCount == 1);
		Test.Assert(fade.KeyCurve(0) === fade.Amount);
		Test.Assert(fade.InsertKey(0, 0.5f) == 0);
		Test.Assert(Near(fade.Amount.Keys[0].Value, 0.0f));

		let cuts = scope CameraCutSequenceTrack();
		Test.Assert(cuts.AddSection(2.0f) == 0);
		cuts.SetSection(0, 1.0f, 3.0f);
		Test.Assert(Near(cuts.Duration, 4.0f));
		cuts.RemoveSection(0);
		Test.Assert(cuts.SectionCount == 0);
	}
}
