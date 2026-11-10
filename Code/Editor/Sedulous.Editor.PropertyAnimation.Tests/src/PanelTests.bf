using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// The property animation panel over its markup (Data/Editor/PropertyAnimationPanel.xml), a scratch
/// project's clip and a scene: the state with no
/// clip, the clip's name and unsaved mark; an entity bound, a track added holding what it shows, keyed
/// and removed, each one step; its keys the clip's while it holds the focus; the scrub's pose, put
/// back, never while the scene simulates.
class PanelTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Math.Abs(a - b) <= epsilon;

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

	/// A scratch project with one clip, "Bounce", and a scene with one entity, "Box", at (1, 2, 3); the
	/// panel in a root, under a node standing for the scene page.
	private class Bed
	{
		public String Dir = new .("scratch_anim_panel_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Sedulous.Scene.Scene Level = new .("Level") ~ delete _;
		public EntityHandle Box;
		public Guid Clip;
		public SceneRoot Root;
		public Sedulous.GUI.Panel Page;
		public PropertyAnimationPanel View;
		public int PageUndos = 0;
		public int PageOthers = 0;

		public this()
		{
			PropertyAnimationPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = PropertyAnimationCreators.CreateClip(Project.SourceDb.RootGroup, "Bounce");
			Test.Assert(instance != null);
			Clip = instance.Id;
			Box = Level.CreateEntity("Box");
			Level.SetLocalPosition(Box, .(1.0f, 2.0f, 3.0f));

			let gui = new GUIContext();
			Root = new SceneRoot(gui);
			gui.ReleaseRef(); // the root's keeps it
			Root.Size = .(1200.0f, 400.0f);
			Page = new Sedulous.GUI.Panel();
			Root.AddChild(Page);
			Page.OnCommand("edit.undo", new [=this] (command) => { PageUndos++; });
			Page.OnCommand("scene.frame", new [=this] (command) => { PageOthers++; });
			let content = LoadMarkup(PropertyAnimationPanel.cMarkupPath);
			Test.Assert(content != null);
			Page.AddChild(content);
			View = new PropertyAnimationPanel(Context, Level, content);
			content.ReleaseRef(); // the page's and the panel's keep it
			let boxId = Level.GetEntityId(Box);
			View.SelectedEntity = new [=boxId] () => boxId;
		}

		public ~this()
		{
			delete View;
			Page.ReleaseRef();
			Root.ReleaseRef();
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public Float3 Position => Level.GetLocalTransform(Box).Position;
		public PropertyAnimationClip ClipNow => View.Document.Clip;

		/// The Transform's Position seed (OWNED by the caller).
		public AnimatablePropertyInfo PositionSeed()
		{
			let offered = scope List<AnimatablePropertyInfo>();
			defer { ClearAndDeleteItems!(offered); }
			View.OfferedTracks(offered);
			for (let seed in offered)
			{
				if (seed.PropertyPath == "Position")
					return seed.Clone();
			}
			Test.Assert(false, "no position seed");
			return null;
		}

		public int OfferedCount()
		{
			let offered = scope List<AnimatablePropertyInfo>();
			defer { ClearAndDeleteItems!(offered); }
			View.OfferedTracks(offered);
			return offered.Count;
		}

		public T Find<T>(StringView id) where T : Node => View.Content.FindElement(id) as T;
	}

	[Test]
	public static void WithNoClipAStateSaysSoAClipOpenedItsNameUnsavedOnceEdited()
	{
		let bed = scope Bed();
		let empty = bed.Find<Node>("anim-empty");
		let body = bed.Find<Node>("anim-body");
		let name = bed.Find<Sedulous.GUI.Label>("anim-clip");
		let dirty = bed.Find<Node>("anim-dirty");
		Test.Assert((empty != null) && (body != null) && (name != null) && (dirty != null));
		Test.Assert(empty.Displayed);
		Test.Assert(!body.Displayed);
		Test.Assert(name.Text == "No clip");

		Test.Assert(bed.View.LoadClip(bed.Clip));
		Test.Assert(!empty.Displayed);
		Test.Assert(body.Displayed);
		Test.Assert(name.Text == "Bounce");
		Test.Assert(!dirty.Displayed);
		bed.View.SetLength(2.0f);
		Test.Assert(dirty.Displayed);
		Test.Assert(Near(bed.View.Axis.Duration, 2.0f));
		Test.Assert(bed.View.Save() case .Ok);
		Test.Assert(!dirty.Displayed);
	}

	[Test]
	public static void AnEntityBoundATrackAddedHoldingWhatItShowsKeyedAndRemovedEachOneStep()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadClip(bed.Clip));
		Test.Assert(bed.OfferedCount() == 0, "no entity yet");
		// Use Selected is on from the start (the page's selection read as it is clicked).
		let bind = bed.Find<ButtonBase>("anim-bind");
		Test.Assert(bind != null);
		Test.Assert(bind.Enabled);
		bed.View.BindSelected();
		Test.Assert(bed.View.BoundEntity == bed.Level.GetEntityId(bed.Box));
		Test.Assert(bed.Find<Sedulous.GUI.Label>("anim-entity").Text == "Box");

		// Add Track: the transform's three first; Position added, keyed with where the box is.
		Test.Assert(bed.OfferedCount() >= 3);
		let seed = bed.PositionSeed();
		defer delete seed;
		bed.View.AddTrack(seed);
		Test.Assert(bed.ClipNow.Tracks.Count == 1);
		Test.Assert(Near(bed.ClipNow.Tracks[0].Channels[1].Evaluate(0.0f), 2.0f));
		{
			let offered = scope List<AnimatablePropertyInfo>();
			defer { ClearAndDeleteItems!(offered); }
			bed.View.OfferedTracks(offered);
			for (let other in offered)
				Test.Assert(other.PropertyPath != "Position", "offered once");
		}

		// The box moved, the playhead at 1 s: Key keys every track (none chosen) with where it is now.
		bed.View.StopPreview();
		bed.Level.SetLocalPosition(bed.Box, .(5.0f, 6.0f, 7.0f));
		bed.View.Scrub(1.0f);
		// The scrub posed the box from the clip (at 1 s it holds the first key); move it again, as a
		// gizmo would, and key that.
		bed.Level.SetLocalPosition(bed.Box, .(5.0f, 6.0f, 7.0f));
		Test.Assert(bed.View.KeyChosen() == 1);
		Test.Assert(bed.ClipNow.Tracks[0].Channels[0].KeyCount == 2);
		Test.Assert(Near(bed.ClipNow.Tracks[0].Channels[0].Evaluate(1.0f), 5.0f));

		// A key chosen in the dopesheet chooses its track; Remove takes it away; one step back.
		TimelineKeyRef[1] first = .(.(0, 0));
		bed.View.Sheet.SetSelection(first);
		let chosen = scope List<int>();
		bed.View.ChosenTracks(chosen);
		Test.Assert(chosen.Count == 1);
		Test.Assert(bed.View.RemoveChosen());
		Test.Assert(bed.ClipNow.Tracks.IsEmpty);
		bed.View.Undo();
		Test.Assert(bed.ClipNow.Tracks.Count == 1);
		bed.View.Redo();
		Test.Assert(bed.ClipNow.Tracks.IsEmpty);
	}

	[Test]
	public static void TheCurveViewsValuesFitWhatItShowsWhenThatChangesNotAsAKeyIsEdited()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadClip(bed.Clip));
		bed.View.BindSelected();
		let seed = bed.PositionSeed();
		defer delete seed;
		bed.View.AddTrack(seed); // keys at 1, 2 and 3 (where the box is)
		bed.View.Update(0.0f, false);
		let curves = bed.Find<CurveView>("anim-curves");
		Test.Assert(curves != null);
		Test.Assert(curves.ValueLow < 1.0f);
		Test.Assert(curves.ValueHigh > 3.0f);
		Test.Assert(curves.ValueHigh < 4.0f); // fitted, a tenth either side
		// A key's value edited: no refit (the view would jump under the drag).
		let high = curves.ValueHigh;
		bed.View.Document.Edit("test", scope (clip) => { clip.Tracks[0].Channels[2].Keys[0].Value = 50.0f; });
		bed.View.Update(0.0f, false);
		Test.Assert(Near(curves.ValueHigh, high));
		// Frame: everything shown, the new value too.
		bed.View.FrameCurves();
		Test.Assert(curves.ValueHigh >= 50.0f);
	}

	[Test]
	public static void ItsKeysAreTheClipsWhileItHoldsTheFocusTheRestGoOnToThePage()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadClip(bed.Clip));
		bed.View.SetLength(3.0f);
		Test.Assert(bed.View.Document.Commands.CanUndo);
		Test.Assert(bed.View.Sheet != null);
		bed.View.Sheet.RequestFocus();
		Test.Assert(bed.View.Sheet.IsFocused);

		// Ctrl+Z's command: the clip's step taken back, the page's never told.
		Test.Assert(bed.Root.RunCommand("edit.undo"));
		Test.Assert(!bed.View.Document.Commands.CanUndo);
		Test.Assert(bed.PageUndos == 0);
		// With nothing left to undo, still the clip's: it never reaches the scene.
		bed.Root.RunCommand("edit.undo");
		Test.Assert(bed.PageUndos == 0);
		// A key it does not bind goes on to the page.
		Test.Assert(bed.Root.RunCommand("scene.frame"));
		Test.Assert(bed.PageOthers == 1);

		// Focus elsewhere: Undo is the page's again.
		bed.View.Sheet.ReleaseFocus();
		let other = new Button();
		bed.Page.AddChild(other);
		other.RequestFocus();
		bed.Root.RunCommand("edit.undo");
		Test.Assert(bed.PageUndos == 1);
		other.ReleaseRef();
	}

	[Test]
	public static void AScrubPosesTheBoundEntityPutBackWhenItStopsNothingPosedWhileSimulating()
	{
		let bed = scope Bed();
		Test.Assert(bed.View.LoadClip(bed.Clip));
		bed.View.BindSelected();
		let seed = bed.PositionSeed();
		defer delete seed;
		bed.View.AddTrack(seed); // a key at 0 s: (1, 2, 3)
		bed.View.StopPreview();
		bed.Level.SetLocalPosition(bed.Box, .(9.0f, 9.0f, 9.0f));
		bed.View.Scrub(1.0f);
		bed.Level.SetLocalPosition(bed.Box, .(9.0f, 9.0f, 9.0f));
		bed.View.KeyChosen(); // a key at 1 s: (9, 9, 9)
		bed.View.StopPreview();
		bed.Level.SetLocalPosition(bed.Box, .(0.0f, 0.0f, 0.0f)); // where the scene has it

		bed.View.Scrub(0.0f);
		Test.Assert(Near(bed.Position.X, 1.0f), "posed");
		Test.Assert(bed.View.Preview.IsPosing);
		// Played on: the transport moves the playhead and the pose.
		bed.View.Play();
		bed.View.Update(0.5f, false);
		Test.Assert(Near(bed.View.Axis.Playhead, 0.5f));
		Test.Assert(bed.Position.X > 1.0f);
		bed.View.Pause();

		// Simulating: the preview stands down, the scene's own value back.
		bed.View.Update(0.0f, true);
		Test.Assert(!bed.View.Preview.IsPosing);
		Test.Assert(Near(bed.Position.X, 0.0f));
		bed.View.Scrub(0.25f);
		Test.Assert(Near(bed.Position.X, 0.0f), "no pose while simulating");
		bed.View.Update(0.0f, false);
		bed.View.Scrub(0.0f);
		Test.Assert(Near(bed.Position.X, 1.0f));
		bed.View.StopPreview();
		Test.Assert(Near(bed.Position.X, 0.0f));
	}
}
