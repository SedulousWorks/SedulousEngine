using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.Sequence.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Sequence;

namespace Sedulous.Editor.Sequence.Tests;

/// The sequence panel's source: rows by binding then track then channel, whatever the track kinds
/// (each says what it holds), key channels and section rows side by side; key moves, section trims
/// and curve edits as gestures that preview from where they began and become one undo step; an edit
/// that changes nothing leaves no step.
class SourceTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static CurveKey Linear(float time, float value)
	{
		var key = CurveKey(time, value, .Linear);
		key.TangentMode = .Broken;
		return key;
	}

	/// "Hero" walks (Transform.Position, x 0 to 10 over a second) and plays a nested sequence from
	/// 0.5 for a second; an event track bound to no one cues at 0.25.
	private class Bed
	{
		public String Dir = new .("scratch_sequence_source_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public SequenceDocument Document;
		public Sedulous.Editor.Sequence.SequenceSource Source;

		public this()
		{
			SequenceResources.RegisterAll();
			SequencePipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = SequenceCreators.CreateSequence(Project.SourceDb.RootGroup, "Arrival");
			Test.Assert(instance != null);
			Document = new SequenceDocument(Context);
			Test.Assert(Document.Load(instance.Id));
			Source = new Sedulous.Editor.Sequence.SequenceSource(Document);
			Document.OnChanged = new [=this] () => { Source.Refresh(); };
			Document.Edit("setup", scope (s) =>
				{
					s.Bindings.Add(new .("Hero"));
					let walk = new PropertySequenceTrack();
					walk.Binding = 0;
					walk.Property.ComponentType.Set(TrackTargets.cTransform);
					walk.Property.PropertyPath.Set("Position");
					walk.Property.Kind = .Float3;
					walk.Property.Channels[0].AddKey(Linear(0.0f, 0.0f));
					walk.Property.Channels[0].AddKey(Linear(1.0f, 10.0f));
					s.Tracks.Add(walk);
					let inner = new NestedSequenceTrack();
					inner.Binding = 0;
					inner.Start = 0.5f;
					inner.Length = 1.0f;
					s.Tracks.Add(inner);
					let cues = new EventSequenceTrack();
					cues.Keys.Add(new .(0.25f, "cue", "gate"));
					s.Tracks.Add(cues);
				});
		}

		public ~this()
		{
			delete Source;
			delete Document;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public PropertySequenceTrack Walk => Document.Sequence.Tracks[0] as PropertySequenceTrack;
		public NestedSequenceTrack Inner => Document.Sequence.Tracks[1] as NestedSequenceTrack;
		public EventSequenceTrack Cues => Document.Sequence.Tracks[2] as EventSequenceTrack;
	}

	[Test]
	public static void RowsByBindingTrackAndChannelATrackWithoutKeyChannelsIsARowOfSections()
	{
		let bed = scope Bed();
		Test.Assert(bed.Source.ChannelCount == 5, "x, y, z, the nested section row, the events");
		Test.Assert(bed.Source.GetChannelPath(0, .. scope .()) == "Hero.Transform.Position.x");
		Test.Assert(bed.Source.GetChannelPath(3, .. scope .()) == "Hero.Sequence");
		Test.Assert(bed.Source.GetChannelPath(4, .. scope .()) == "Sequence.Event");
		Test.Assert(!bed.Source.IsSectionChannel(0));
		Test.Assert(bed.Source.IsSectionChannel(3));
		let sections = scope List<TimelineSection>();
		defer { ClearAndDeleteItems!(sections); }
		bed.Source.GetSections(3, sections);
		Test.Assert(sections.Count == 1);
		Test.Assert(Near(sections[0].Start, 0.5f) && Near(sections[0].Length, 1.0f));
		let times = scope List<float>();
		bed.Source.GetKeyTimes(4, times);
		Test.Assert((times.Count == 1) && Near(times[0], 0.25f));
	}

	[Test]
	public static void AKeyMovePreviewsFromWhereItBeganAndIsOneUndoStep()
	{
		let bed = scope Bed();
		TimelineKeyRef[1] second = .(.(0, 1));
		let moved = scope List<TimelineKeyRef>();
		bed.Source.BeginKeysMove();
		bed.Source.PreviewKeysMove(second, 0.5f, moved);
		bed.Source.PreviewKeysMove(second, 0.25f, moved); // from the start, not from 1.5
		Test.Assert((moved.Count == 1) && (moved[0].Index == 1));
		bed.Source.CommitKeysMove();
		let times = scope List<float>();
		bed.Source.GetKeyTimes(0, times);
		Test.Assert(Near(times[1], 1.25f));
		bed.Document.Commands.Undo();
		bed.Source.GetKeyTimes(0, times);
		Test.Assert(Near(times[1], 1.0f));
	}

	[Test]
	public static void ASectionTrimsThroughItsKindADeletionThatChangesNothingLeavesNoStep()
	{
		let bed = scope Bed();
		bed.Source.BeginSectionEdit();
		bed.Source.PreviewSectionEdit(.(3, 0), 0.75f, 0.75f);
		bed.Source.CommitSectionEdit();
		Test.Assert(Near(bed.Inner.Start, 0.75f) && Near(bed.Inner.Length, 0.75f));

		bed.Document.Commands.Undo();
		Test.Assert(Near(bed.Inner.Start, 0.5f));
		bed.Document.Commands.Redo();
		Test.Assert(!bed.Document.Commands.CanRedo);
		// A nested track has one section and keeps it: no change, so nothing to undo but the trim.
		bed.Source.DeleteSection(.(3, 0));
		bed.Document.Commands.Undo();
		Test.Assert(Near(bed.Inner.Start, 0.5f), "the undo took the trim, not an empty step");

		// A drag that ends where it began leaves no step either.
		bed.Document.Commands.Redo();
		bed.Source.BeginSectionEdit();
		bed.Source.PreviewSectionEdit(.(3, 0), 0.75f, 0.75f);
		bed.Source.CommitSectionEdit();
		bed.Document.Commands.Undo();
		Test.Assert(Near(bed.Inner.Start, 0.5f), "the undo took the earlier trim");
	}

	[Test]
	public static void InsertingAndDeletingKeysAreOneStepEachTheCurveViewEditsAShownTracksCurves()
	{
		let bed = scope Bed();
		Test.Assert(bed.Source.InsertKey(4, 0.75f, let made));
		Test.Assert((made.Channel == 4) && (made.Index == 1));
		Test.Assert(bed.Cues.Keys.Count == 2);
		Test.Assert(bed.Cues.Keys[1].Name == "event");
		TimelineKeyRef[1] first = .(.(4, 0));
		Test.Assert(bed.Source.DeleteKeys(first));
		Test.Assert(bed.Cues.Keys.Count == 1);
		Test.Assert(bed.Cues.Keys[0].Name == "event");

		int[1] walk = .(0);
		bed.Source.ShowTracks(walk);
		Test.Assert(bed.Source.CurveCount == 3);
		let info = scope CurveInfo();
		bed.Source.GetCurveInfo(0, info);
		Test.Assert(info.Name == "Transform.Position.x");
		Test.Assert(bed.Source.GetKeys(0).Length == 2);
		CurveKey[2] raised = .(Linear(0.0f, 0.0f), Linear(1.0f, 20.0f));
		bed.Source.BeginKeysEdit();
		bed.Source.PreviewKeys(0, raised);
		bed.Source.CommitKeysEdit();
		Test.Assert(Near(bed.Walk.Property.Channels[0].Evaluate(1.0f), 20.0f));
		bed.Document.Commands.Undo();
		Test.Assert(Near(bed.Walk.Property.Channels[0].Evaluate(1.0f), 10.0f));
	}

	[Test]
	public static void AChangeMadeInPlaceIsRecordedAsOneStepFromWhereItStood()
	{
		let bed = scope Bed();
		bed.Inner.Loop = true; // as the inspector writes a field
		bed.Document.RecordEdit("sequence-inspector");
		Test.Assert(bed.Inner.Loop);
		bed.Document.Commands.Undo();
		Test.Assert(!bed.Inner.Loop);
		bed.Document.Commands.Redo();
		Test.Assert(bed.Inner.Loop);
		let steps = bed.Document.Commands.UndoIndex;
		bed.Document.RecordEdit("sequence-inspector"); // nothing changed since: no step
		Test.Assert(bed.Document.Commands.UndoIndex == steps);
		bed.Document.Commands.Undo();
		Test.Assert(!bed.Inner.Loop);

		// The kinds show their fields to the inspector: reflected, the base's with them, the binding
		// the panel's.
		Test.Assert(typeof(NestedSequenceTrack).GetField("Nested") case .Ok);
		Test.Assert(typeof(SequenceTrack).GetField("Name") case .Ok);
		Test.Assert(typeof(EventSequenceTrack).GetField("Keys") case .Ok);
		Test.Assert(typeof(SequenceEventKey).GetField("Value") case .Ok);
		if (typeof(SequenceTrack).GetField("Binding") case .Ok(let binding))
			Test.Assert(binding.GetCustomAttribute<HiddenAttribute>() case .Ok);
		else
			Test.FatalError("the binding is reflected, hidden");
	}

	[Test]
	public static void ASectionRowTakesANewSectionThroughItsKindANestedTrackTakesNone()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Source.InsertSection(3, 0.25f, ?), "a nested track has its one section");
		Test.Assert(!bed.Source.InsertSection(0, 0.25f, ?), "a row of keys");
		Test.Assert(!bed.Document.Commands.CanRedo);
	}
}
