using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Engine.Render.Tests;

/// A sequence's camera cut: a claim on the view comes before the primary camera in the camera
/// pick, the play begun last wins, and letting go passes the view back. The camera knows nothing
/// of it.
class CameraCutTests
{
	/// A gameplay camera (primary) and two cutscene cameras (not primary).
	class CameraStage
	{
		public Scene World = new .("cuts") ~ delete _;
		public CameraComponentManager Cameras;
		public EntityHandle Gameplay;
		public EntityHandle Wide;
		public EntityHandle Close;

		public this()
		{
			Cameras = World.AddSystem<CameraComponentManager>();
			Gameplay = Camera("gameplay", 0.0f, true);
			Wide = Camera("wide", 10.0f, false);
			Close = Camera("close", 20.0f, false);
			World.UpdateTransforms();
		}

		public EntityHandle Camera(StringView name, float x, bool primary)
		{
			let entity = World.CreateEntity(name);
			World.SetLocalPosition(entity, .(x, 0, 0));
			Cameras.Add(entity).Primary = primary;
			return entity;
		}

		/// The camera the view is drawn from now.
		public EntityHandle View()
		{
			var camera = ViewCamera();
			var picked = EntityHandle.Invalid;
			RenderExtract.ExtractPrimaryCamera(World, ref camera, null, 0.0f, &picked);
			return picked;
		}
	}

	static CameraCutSequenceTrack Cut(int32 binding, float start, float duration)
	{
		let track = new CameraCutSequenceTrack();
		track.Binding = binding;
		track.Sections.Add(.(start, duration));
		return track;
	}

	/// "Wide" for the first second, "Close" for the second.
	static Sedulous.Sequence.Sequence TwoShots()
	{
		let sequence = new Sedulous.Sequence.Sequence();
		sequence.Bindings.Add(new .("Wide"));
		sequence.Bindings.Add(new .("Close"));
		sequence.Tracks.Add(Cut(0, 0.0f, 1.0f));
		sequence.Tracks.Add(Cut(1, 1.0f, 1.0f));
		sequence.Duration = 2.0f;
		return sequence;
	}

	/// One shot of `duration` seconds on the camera named "Camera".
	static Sedulous.Sequence.Sequence OneShot(float duration)
	{
		let sequence = new Sedulous.Sequence.Sequence();
		sequence.Bindings.Add(new .("Camera"));
		sequence.Tracks.Add(Cut(0, 0.0f, duration));
		sequence.Duration = duration;
		return sequence;
	}

	[Test]
	public static void AClaimOnTheViewComesBeforeThePrimaryCameraTheLatestOrderWinning()
	{
		let stage = scope CameraStage();
		Test.Assert(stage.View() == stage.Gameplay);

		let first = scope Object();
		let second = scope Object();
		stage.Cameras.ClaimView(first, 1, stage.Wide);
		Test.Assert(stage.View() == stage.Wide);
		stage.Cameras.ClaimView(second, 2, stage.Close);
		Test.Assert(stage.View() == stage.Close);
		stage.Cameras.ReleaseView(second);
		Test.Assert(stage.View() == stage.Wide, "back to the claim under it");
		stage.Cameras.ReleaseView(first);
		Test.Assert(stage.View() == stage.Gameplay);

		// A lower order claimed later does not take the view.
		stage.Cameras.ClaimView(second, 2, stage.Close);
		stage.Cameras.ClaimView(first, 1, stage.Wide);
		Test.Assert(stage.View() == stage.Close);
		stage.Cameras.ReleaseView(second);

		// An inactive camera cannot be the view: the pick falls back to the primary.
		stage.World.SetActive(stage.Wide, false);
		Test.Assert(stage.View() == stage.Gameplay);
	}

	[Test]
	public static void APlayCutsBetweenItsCamerasAndGivesTheViewBackWhenItFinishes()
	{
		let stage = scope CameraStage();
		let sequence = TwoShots();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Wide", stage.Wide));
		Test.Assert(play.Bind("Close", stage.Close));

		play.Play();
		Test.Assert(stage.View() == stage.Wide);
		play.Advance(0.5f);
		Test.Assert(stage.View() == stage.Wide);
		play.Advance(0.5f); // exactly on the cut: the shot cut to takes the view
		Test.Assert(stage.View() == stage.Close);
		play.Advance(0.5f);
		Test.Assert(stage.View() == stage.Close);
		play.Advance(1.0f); // the end, released
		Test.Assert(play.IsFinished);
		Test.Assert(stage.View() == stage.Gameplay);
	}

	[Test]
	public static void BetweenSectionsTheViewGoesBack()
	{
		let stage = scope CameraStage();
		let sequence = OneShot(1.0f);
		defer delete sequence;
		sequence.Duration = 3.0f; // the shot is the first second of three
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Camera", stage.Wide));

		play.Play();
		Test.Assert(stage.View() == stage.Wide);
		play.Advance(1.5f);
		Test.Assert(!play.IsFinished);
		Test.Assert(stage.View() == stage.Gameplay, "the section is over, the play is not");
		play.Stop();
	}

	[Test]
	public static void AHeldPlayKeepsItsLastShotUntilItStops()
	{
		let stage = scope CameraStage();
		let sequence = TwoShots();
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Wide", stage.Wide));
		Test.Assert(play.Bind("Close", stage.Close));
		play.Finish = .Hold;

		play.Play();
		play.Advance(3.0f);
		Test.Assert(play.IsFinished);
		Test.Assert(stage.View() == stage.Close);
		play.Stop();
		Test.Assert(stage.View() == stage.Gameplay);
	}

	[Test]
	public static void ThePlayBegunLastHoldsTheViewAndGivesItBackToTheOneUnderIt()
	{
		let stage = scope CameraStage();
		let longShot = OneShot(10.0f);
		defer delete longShot;
		let shortShot = OneShot(1.0f);
		defer delete shortShot;

		let under = scope SequencePlay(stage.World, longShot);
		Test.Assert(under.Bind("Camera", stage.Wide));
		let over = scope SequencePlay(stage.World, shortShot);
		Test.Assert(over.Bind("Camera", stage.Close));

		under.Play();
		over.Play();
		Test.Assert(over.StartOrder > under.StartOrder);
		Test.Assert(stage.View() == stage.Close);
		under.Advance(0.5f); // the earlier play steps again: the later one keeps the view
		Test.Assert(stage.View() == stage.Close);
		over.Advance(2.0f);
		Test.Assert(over.IsFinished);
		Test.Assert(stage.View() == stage.Wide);
		under.Stop();
		Test.Assert(stage.View() == stage.Gameplay);
	}

	[Test]
	public static void ANestedPlayAnswersItsOutermostPlaysStartOrder()
	{
		let stage = scope CameraStage();
		let outerShot = OneShot(1.0f);
		defer delete outerShot;
		let innerShot = OneShot(1.0f);
		defer delete innerShot;
		let outer = scope SequencePlay(stage.World, outerShot);
		let inner = scope SequencePlay(stage.World, innerShot);
		inner.SetParent(outer);
		outer.Play();
		inner.Play(); // begun later, yet it answers for the play it is inside
		Test.Assert(inner.StartOrder == outer.StartOrder);
		outer.Stop();
		inner.Stop();
	}

	[Test]
	public static void ATrackBoundToAnEntityWithoutACameraIsSkipped()
	{
		let stage = scope CameraStage();
		let prop = stage.World.CreateEntity("prop");
		let sequence = OneShot(1.0f);
		defer delete sequence;
		let play = scope SequencePlay(stage.World, sequence);
		Test.Assert(play.Bind("Camera", prop));
		play.Play();
		Test.Assert(stage.View() == stage.Gameplay);
	}

	[Test]
	public static void ASequenceReadsItsCameraCutsBackByTheirKind()
	{
		RenderSequenceTracks.Register();
		let original = TwoShots();
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
		Test.Assert(read.Tracks.Count == 2);
		let close = read.Tracks[1] as CameraCutSequenceTrack;
		Test.Assert(close != null);
		Test.Assert(close.Binding == 1);
		Test.Assert(close.Sections.Count == 1);
		Test.Assert(Math.Abs(close.Sections[0].Start - 1.0f) < 1e-5f);
		Test.Assert(Math.Abs(close.Sections[0].Duration - 1.0f) < 1e-5f);
		Test.Assert(Math.Abs(close.Duration - 2.0f) < 1e-5f);

		// The kind is listed with the others, so the editor offers it.
		bool listed = false;
		for (let kind in SequenceTracks.Kinds)
			listed |= kind == typeof(CameraCutSequenceTrack);
		Test.Assert(listed);
	}
}
