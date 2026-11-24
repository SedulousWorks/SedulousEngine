using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;
using Sedulous.Sequence.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Sequence;

namespace Sedulous.Editor.Sequence.Tests;

/// The sequence panel's UI-free half: the document over a scratch project (its edits, gestures,
/// history, unsaved mark and save, each change rebuilding the tracks it holds), and the preview
/// posing a scene through the game's own play and putting it back.
class DocumentTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// "Actor" walks along X from 0 to `toX` over a second.
	private static PropertySequenceTrack Walk(float toX)
	{
		let track = new PropertySequenceTrack();
		track.Binding = 0;
		track.Property.ComponentType.Set(TrackTargets.cTransform);
		track.Property.PropertyPath.Set("Position");
		track.Property.Kind = .Float3;
		track.Property.Channels[0].AddKey(.(0.0f, 0.0f, .Linear));
		track.Property.Channels[0].AddKey(.(1.0f, toX, .Linear));
		return track;
	}

	private static float WalkEnd(Sedulous.Sequence.Sequence sequence)
	{
		let walk = sequence.Tracks[0] as PropertySequenceTrack;
		Test.Assert(walk != null);
		return walk.Property.Sample(1.0f).Vector.X;
	}

	/// A scratch project holding one sequence, "Arrival", read into a document.
	private class Bed
	{
		public String Dir = new .("scratch_sequence_document_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public SequenceDocument Document;
		public Guid Id;
		public int Changes = 0;

		public this()
		{
			SequenceTracks.RegisterTypes();
			SequencePipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = SequenceCreators.CreateSequence(Project.SourceDb.RootGroup, "Arrival");
			Test.Assert(instance != null);
			Id = instance.Id;
			Document = new SequenceDocument(Context);
			Document.OnChanged = new [=this] () => { Changes++; };
			Test.Assert(Document.Load(Id));
		}

		public ~this()
		{
			delete Document;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public void AddWalk(float toX)
		{
			Document.Edit("test", scope (edited) =>
				{
					if (edited.Bindings.IsEmpty)
						edited.Bindings.Add(new .("Actor"));
					edited.Tracks.Add(Walk(toX));
				});
		}
	}

	[Test]
	public static void AnEditIsOneStepUndoneAndRedoneAndTheUnsavedMarkFollowsTheHistory()
	{
		let bed = scope Bed();
		Test.Assert(bed.Document.Name == "Arrival");
		Test.Assert(!bed.Document.IsDirty);
		Test.Assert(Near(bed.Document.Length, 1.0f), "at least a second");

		let before = bed.Document.Version;
		bed.AddWalk(10.0f);
		Test.Assert(bed.Document.Version != before, "the tracks were rebuilt");
		Test.Assert(bed.Document.Sequence.Tracks.Count == 1);
		Test.Assert(Near(bed.Document.Sequence.Duration, 1.0f), "grew to cover the walk");
		Test.Assert(bed.Document.IsDirty);

		bed.Document.Commands.Undo();
		Test.Assert(bed.Document.Sequence.Tracks.IsEmpty);
		Test.Assert(!bed.Document.IsDirty, "back where it was saved");
		bed.Document.Commands.Redo();
		Test.Assert(bed.Document.Sequence.Tracks.Count == 1);
		Test.Assert(Near(WalkEnd(bed.Document.Sequence), 10.0f));
	}

	[Test]
	public static void AnUndoStepKeepsItsOwnTracksNotTheLiveOnes()
	{
		let bed = scope Bed();
		bed.AddWalk(10.0f);
		// A gesture changes the live track in place; the step before it still holds 10.
		bed.Document.BeginGesture();
		(bed.Document.GestureSequence.Tracks[0] as PropertySequenceTrack).Property.Channels[0].Keys[1].Value = 20.0f;
		bed.Document.PreviewGesture();
		bed.Document.CommitGesture("test-drag");
		Test.Assert(Near(WalkEnd(bed.Document.Sequence), 20.0f));
		bed.Document.Commands.Undo();
		Test.Assert(Near(WalkEnd(bed.Document.Sequence), 10.0f));

		// A cancelled gesture leaves no step and puts the sequence back.
		bed.Document.BeginGesture();
		(bed.Document.GestureSequence.Tracks[0] as PropertySequenceTrack).Property.Channels[0].Keys[1].Value = 30.0f;
		bed.Document.CancelGesture();
		Test.Assert(Near(WalkEnd(bed.Document.Sequence), 10.0f));
		Test.Assert(bed.Document.Commands.CanRedo, "the drag's step is still there to redo");
	}

	[Test]
	public static void ASaveWritesTheAssetAndClearsTheMarkALoadReadsItBack()
	{
		let bed = scope Bed();
		bed.AddWalk(4.0f);
		Test.Assert(bed.Document.Save() case .Ok);
		Test.Assert(!bed.Document.IsDirty);
		Test.Assert(bed.Document.Sequence.Tracks.Count == 1, "the document keeps its sequence after the save");

		let again = scope SequenceDocument(bed.Context);
		Test.Assert(again.Load(bed.Id));
		Test.Assert((again.Sequence.Bindings.Count == 1) && (again.Sequence.Bindings[0].Name == "Actor"));
		Test.Assert(again.Sequence.Tracks.Count == 1);
		Test.Assert(Near(WalkEnd(again.Sequence), 4.0f));
		Test.Assert(!again.Load(Guid(1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0)), "no such sequence");
	}

	[Test]
	public static void ThePreviewPosesTheCastBeginsAgainOnNewTracksAndPutsTheSceneBack()
	{
		let bed = scope Bed();
		bed.AddWalk(10.0f);
		let world = scope Scene("stage");
		let actor = world.CreateEntity("actor");
		world.SetLocalPosition(actor, .(-3.0f, 0.0f, 0.0f));
		float X(EntityHandle entity) => world.GetLocalTransform(entity).Position.X;

		let preview = scope SequencePreview(world);
		preview.Bind("Actor", world.GetEntityId(actor));
		Test.Assert(preview.BoundEntity("Actor") == world.GetEntityId(actor));
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 0.5f);
		Test.Assert(preview.IsPosing);
		Test.Assert(Near(X(actor), 5.0f));

		// The walk goes and comes back: the tracks the play began on are gone.
		bed.Document.Commands.Undo();
		bed.Document.Commands.Redo();
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 0.25f);
		Test.Assert(Near(X(actor), 2.5f));

		// A gesture changes the same sequence in place: its new version begins the play again.
		bed.Document.BeginGesture();
		(bed.Document.GestureSequence.Tracks[0] as PropertySequenceTrack).Property.Channels[0].Keys[1].Value = 20.0f;
		bed.Document.PreviewGesture();
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 0.5f);
		Test.Assert(Near(X(actor), 10.0f), "posed on the dragged key");
		bed.Document.CancelGesture();
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 0.25f);
		Test.Assert(Near(X(actor), 2.5f));

		preview.Stop();
		Test.Assert(!preview.IsPosing);
		Test.Assert(Near(X(actor), -3.0f), "as it was");

		// Another entity in the part: the first goes back before the second is posed.
		let stand = world.CreateEntity("stand-in");
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 1.0f);
		preview.Bind("Actor", world.GetEntityId(stand));
		Test.Assert(Near(X(actor), -3.0f));
		preview.Pose(bed.Document.Sequence, bed.Document.Version, 1.0f);
		Test.Assert(Near(X(stand), 10.0f));
	}
}
