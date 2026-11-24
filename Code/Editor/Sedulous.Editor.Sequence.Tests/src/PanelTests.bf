using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.Sequence.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Sequence;

namespace Sedulous.Editor.Sequence.Tests;

/// The sequence panel over its markup (Data/Editor/SequencePanel.xml), a scratch project's sequence
/// and a scene: the state with no sequence and the name of one opened; a part cast from the
/// selection and Track offering every kind and the part's properties; the preview posing the scene
/// at the playhead and putting it back, standing down while the scene simulates; markers and holds
/// on the ruler; the inspector editing the chosen track as one step.
class PanelTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project with one sequence, "Arrival", and a scene with one entity, "Hero", at
	/// (1, 2, 3); the panel in a root.
	private class Bed
	{
		public String Dir = new .("scratch_sequence_panel_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Sedulous.Scene.Scene Level = new .("Level") ~ delete _;
		public EntityHandle Hero;
		public Guid SequenceId;
		public SceneRoot Root;
		public SequencePanel View;

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
			SequenceId = instance.Id;
			Hero = Level.CreateEntity("Hero");
			Level.SetLocalPosition(Hero, .(1.0f, 2.0f, 3.0f));

			let gui = new GUIContext();
			Root = new SceneRoot(gui);
			gui.ReleaseRef(); // the root's keeps it
			Root.Size = .(1400.0f, 500.0f);
			let content = LoadMarkup(SequencePanel.cMarkupPath);
			Test.Assert(content != null);
			Root.AddChild(content);
			View = new SequencePanel(Context, Level, content, null);
			content.ReleaseRef(); // the root's and the panel's keep it
			let heroId = Level.GetEntityId(Hero);
			View.SelectedEntity = new [=heroId] () => heroId;
		}

		public ~this()
		{
			delete View;
			Root.ReleaseRef();
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public Float3 Position => Level.GetLocalTransform(Hero).Position;
		public Sedulous.Sequence.Sequence SequenceNow => View.Document.Sequence;

		/// The offer labelled `label` (OWNED by the caller); null when there is none.
		public SequenceTrackOffer Offer(StringView label)
		{
			let offers = scope List<SequenceTrackOffer>();
			defer { ClearAndDeleteItems!(offers); }
			View.OfferedTracks(offers);
			for (let offer in offers)
			{
				if (offer.Label == label)
					return offer.Clone();
			}
			for (let offer in offers)
				Console.WriteLine("offered: {}", offer.Label);
			return null;
		}

		public T Find<T>(StringView id) where T : Node => View.Content.FindElement(id) as T;
	}

	[Test]
	public static void WithNoSequenceAStateSaysSoASequenceOpenedShowsItsName()
	{
		let bed = scope Bed();
		let empty = bed.Find<Node>("seq-empty");
		let body = bed.Find<Node>("seq-body");
		let name = bed.Find<Sedulous.GUI.Label>("seq-name");
		Test.Assert((empty != null) && (body != null) && (name != null));
		Test.Assert(empty.Displayed);
		Test.Assert(!body.Displayed);
		Test.Assert(name.Text == "No sequence");
		let offers = scope List<SequenceTrackOffer>();
		defer { ClearAndDeleteItems!(offers); }
		bed.View.OfferedTracks(offers);
		Test.Assert(offers.IsEmpty);

		Test.Assert(bed.View.LoadSequence(bed.SequenceId));
		Test.Assert(!empty.Displayed);
		Test.Assert(body.Displayed);
		Test.Assert(name.Text == "Arrival");
	}

	[Test]
	public static void APartCastFromTheSelectionTrackOffersTheKindsAndThePartsProperties()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadSequence(bed.SequenceId));
		// Every registered kind is offered (here the sequence libraries': no domain is registered).
		let nested = bed.Offer("Sequence");
		defer delete nested;
		let events = bed.Offer("Event");
		defer delete events;
		Test.Assert((nested != null) && nested.Enabled);
		Test.Assert((events != null) && events.Enabled);

		Test.Assert(bed.View.AddPartForSelected() == 0);
		Test.Assert((bed.SequenceNow.Bindings.Count == 1) && (bed.SequenceNow.Bindings[0].Name == "Hero"));
		Test.Assert(bed.View.CastEntity("Hero") == bed.Level.GetEntityId(bed.Hero));

		// A property track starts with what the entity shows, keyed at the playhead.
		let position = bed.Offer("Hero: Transform.Position");
		Test.Assert(position != null);
		bed.View.AddTrack(position);
		delete position;
		Test.Assert(bed.SequenceNow.Tracks.Count == 1);
		let walk = bed.SequenceNow.Tracks[0] as PropertySequenceTrack;
		Test.Assert(walk != null);
		Test.Assert(walk.Binding == 0);
		Test.Assert(Near(walk.Property.Sample(0.0f).Vector.Y, 2.0f));
		// It is offered no more.
		let again = bed.Offer("Hero: Transform.Position");
		Test.Assert(again == null);
		bed.View.Undo();
		Test.Assert(bed.SequenceNow.Tracks.IsEmpty);
	}

	[Test]
	public static void ThePreviewPosesTheSceneAtThePlayheadAndPutsItBackItStandsDownWhileSimulating()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadSequence(bed.SequenceId));
		Test.Assert(bed.View.AddPartForSelected() == 0);
		let position = bed.Offer("Hero: Transform.Position");
		Test.Assert(position != null);
		bed.View.AddTrack(position);
		delete position;
		// x keyed at 1 s to 11 through the source, as a double click and a drag would.
		Test.Assert(bed.View.Source.InsertKey(0, 1.0f, let made));
		let channel = made.Channel;
		bed.View.Document.Edit("test", scope (s) => { s.Tracks[0].KeyCurve(channel).Keys[1].Value = 11.0f; });
		bed.View.Scrub(1.0f);
		Test.Assert(Near(bed.Position.X, 11.0f));
		bed.View.Scrub(0.0f);
		Test.Assert(Near(bed.Position.X, 1.0f));
		bed.View.Scrub(1.0f);
		bed.View.Update(0.016f, true); // the scene simulates: what the preview posed goes back
		Test.Assert(Near(bed.Position.X, 1.0f));
		Test.Assert(!bed.View.Preview.IsPosing);
		bed.View.Update(0.016f, false);
		bed.View.StopPreview();
		Test.Assert(Near(bed.Position.X, 1.0f));
	}

	[Test]
	public static void MarkersAndHoldsAtThePlayheadShowOnTheRulerTheInspectorEditsTheChosenTrackAsOneStep()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadSequence(bed.SequenceId));
		bed.View.Scrub(0.5f);
		bed.View.AddMarkerAtPlayhead(true);
		bed.View.Scrub(0.25f);
		bed.View.AddMarkerAtPlayhead(false);
		let markers = bed.View.Source.Markers;
		Test.Assert(markers.MarkerCount == 2);
		let marker = scope TimeMarker();
		markers.GetMarker(0, marker);
		Test.Assert(Near(marker.Time, 0.25f), "kept by time");
		markers.GetMarker(1, marker);
		Test.Assert(marker.Label == "hold (hold)");
		Test.Assert(bed.SequenceNow.Markers[1].Hold);

		let events = bed.Offer("Event");
		Test.Assert(events != null);
		bed.View.AddTrack(events);
		delete events;
		Test.Assert(bed.SequenceNow.Tracks.Count == 1);
		// Its row chosen (an event key there): the inspector shows it.
		Test.Assert(bed.View.Source.InsertKey(0, 0.5f, let made));
		Test.Assert(bed.View.Sheet != null);
		TimelineKeyRef[1] chosen = .(made);
		bed.View.Sheet.SetSelection(chosen);
		bed.View.Update(0.016f, false);
		let inspected = bed.View.Inspected;
		Test.Assert(inspected != null);
		inspected.BeginEdit("Muted");
		inspected.CommitEdit("Muted", PropertyWrite(Sedulous.GUI.Variant(true)));
		Test.Assert(bed.SequenceNow.Tracks[0].Muted);
		bed.View.Undo();
		Test.Assert(!bed.SequenceNow.Tracks[0].Muted);
		bed.View.Redo();
		Test.Assert(bed.SequenceNow.Tracks[0].Muted);
	}
}
