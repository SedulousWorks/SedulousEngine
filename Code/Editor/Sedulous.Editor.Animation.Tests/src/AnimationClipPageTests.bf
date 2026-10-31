using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Animation.Tests;

/// The animation clip page over its markup (Data/Editor/AnimationClipPage.xml) and a scratch project,
/// without a host (no preview): the clip's rows its own (Looping, the root motion, the events a list
/// named by each event's name and summed up by its time), its facts read only; each edit one undo
/// step; a new event at the playhead; the events as the ruler's markers, a marker's move one step and
/// a cancelled one none; the preview starting on the skeleton its import names; Travel and the clock
/// the page's own, never the clip's. And the preview rig's preference in the settings store.
class AnimationClipPageTests
{
	private static bool Near(double a, double b, double epsilon = 1e-4) => Math.Abs(a - b) <= epsilon;

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

	static Guid SkeletonId => Guid(0x5d2b1c7e, 0x9a41, 0x4f0e, 0x8a, 0x3b, 0x0c, 0x6d, 0x7e, 0x8f, 0x9a, 0x10);

	/// A scratch project holding one clip, "Walk": 1.2 s, two tracks, its events a footstep each side.
	private class Bed
	{
		public String Dir = new .("scratch_clip_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public AnimationClipEditorPage Page;

		public this()
		{
			AnimationPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Walk", typeof(AnimationClipAsset).GetFullName(.. scope .()));
			Test.Assert(instance != null);
			let asset = scope AnimationClipAsset();
			asset.Skeleton = SkeletonId;
			let source = asset.Source;
			source.Name.Set("walk");
			source.Duration = 1.2f;
			source.TrackBone.Add(0);
			source.TrackBone.Add(1);
			source.TrackKindValue.Add(0);
			source.TrackKindValue.Add(1);
			source.TrackInterp.Add(0);
			source.TrackInterp.Add(0);
			source.TrackStart.Add(0);
			source.TrackStart.Add(2);
			source.TrackCount.Add(2);
			source.TrackCount.Add(2);
			for (let time in float[4](0.0f, 1.2f, 0.0f, 1.2f))
				source.KeyTime.Add(time);
			for (let value in Float4[4](.(0, 0, 0, 0), .(0, 0, 0, 0), .(0, 0, 0, 1), .(0, 0, 0, 1)))
				source.KeyValue.Add(value);
			source.EventTime.Add(0.3f);
			source.EventTime.Add(0.9f);
			source.EventName.Add(new String("FootLeft"));
			source.EventName.Add(new String("FootRight"));
			Test.Assert(instance.WriteObject(asset) case .Ok);
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new AnimationClipEditorPage(Context, services, instance);
			Test.Assert(!Page.LoadFailed);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public AnimationClipSource Source => Page.Clip.Source;

		public static void Edit(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
		{
			rows.BeginEdit(path);
			rows.CommitEdit(path, PropertyWrite(value));
		}

		/// The row `name` under `parent`, into `outInfo`; false when there is none.
		public static bool Info(Sedulous.GUI.PropertyBag rows, StringView parent, StringView name, PropertyInfo outInfo)
		{
			let found = scope List<PropertyInfo>();
			defer { ClearAndDeleteItems!(found); }
			rows.GetProperties(parent, found);
			for (let info in found)
			{
				if (info.Name == name)
				{
					outInfo.Set(info);
					return true;
				}
			}
			return false;
		}

		public String Fact(StringView name, String outText)
		{
			Page.Fact(name, outText);
			return outText;
		}
	}

	[Test]
	public static void TheClipsRowsItsOwnItsFactsReadOnlyItsEventsNamedByTheirNames()
	{
		let bed = scope Bed();
		Test.Assert(bed.Fact("Name", .. scope .()) == "walk");
		Test.Assert(bed.Fact("Duration", .. scope .()) == "1.20 s");
		Test.Assert(bed.Fact("Tracks", .. scope .()) == "2");
		Test.Assert(bed.Fact("Keys", .. scope .()) == "4");
		Test.Assert(!bed.Page.ClipRows.GetValue("looping", 0).AsBool);
		Test.Assert(!bed.Page.RootRows.GetValue("yaw", 0).AsBool);

		// The events as a list of groups, each named by its name, closed showing when it fires.
		let first = scope PropertyInfo();
		Test.Assert(Bed.Info(bed.Page.EventRows, "events", "0", first));
		Test.Assert(first.DisplayName == "FootLeft");
		Test.Assert(first.Summary == "at 0.30 s", first.Summary);
		var eventName = bed.Page.EventRows.GetValue("events.1.name", 0); // an owned copy
		defer eventName.Dispose();
		Test.Assert(eventName.AsString == "FootRight");
		Test.Assert(Near(bed.Page.EventRows.GetValue("events.1.time", 0).AsFloat, 0.9));
	}

	[Test]
	public static void EachEditOneUndoStepANewEventAtThePlayhead()
	{
		let bed = scope Bed();
		Bed.Edit(bed.Page.ClipRows, "looping", .(true));
		Test.Assert(bed.Source.IsLooping);
		Test.Assert(bed.Page.IsDirty);
		Bed.Edit(bed.Page.RootRows, "yaw", .(true));
		Test.Assert(bed.Source.RootYaw);
		Bed.Edit(bed.Page.RootRows, "bone", .(" Hips "));
		Test.Assert(bed.Source.RootBone == "Hips");
		Bed.Edit(bed.Page.EventRows, "events.1.name", .("Land"));
		Test.Assert(bed.Source.EventName[1] == "Land");
		Bed.Edit(bed.Page.EventRows, "events.0.time", .(5.0)); // kept within the clip
		Test.Assert(Near(bed.Source.EventTime[0], 1.2));

		bed.Page.Commands.Undo();
		Test.Assert(Near(bed.Source.EventTime[0], 0.3));
		Test.Assert(Near(bed.Page.EventRows.GetValue("events.0.time", 0).AsFloat, 0.3), "the row follows");
		bed.Page.Commands.Undo();
		Test.Assert(bed.Source.EventName[1] == "FootRight");
		bed.Page.Commands.Undo();
		bed.Page.Commands.Undo();
		Test.Assert(!bed.Source.RootYaw);
		bed.Page.Commands.Undo();
		Test.Assert(!bed.Source.IsLooping);

		// Added where the playhead is, named to be renamed; removed by its place.
		bed.Page.SetTime(0.6f);
		Test.Assert(bed.Page.EventRows.EditList("events", scope ListEdit(.Insert, 2)));
		Test.Assert(bed.Source.EventTime.Count == 3);
		Test.Assert(Near(bed.Source.EventTime[2], 0.6));
		Test.Assert(bed.Source.EventName[2] == "Event");
		Test.Assert(bed.Page.EventRows.EditList("events", scope ListEdit(.Remove, 0)));
		Test.Assert(bed.Source.EventTime.Count == 2);
		Test.Assert(bed.Source.EventName[0] == "FootRight");
		bed.Page.Commands.Undo();
		bed.Page.Commands.Undo();
		Test.Assert(bed.Source.EventTime.Count == 2);
		Test.Assert(bed.Source.EventName[0] == "FootLeft");
	}

	[Test]
	public static void TheEventsAreTheRulersMarkersAMarkersMoveIsOneStepACancelledOneNone()
	{
		let bed = scope Bed();
		Test.Assert(bed.Page.Ruler != null);
		Test.Assert(bed.Page.Ruler.MarkerSource === bed.Page.Markers);
		Test.Assert(bed.Page.MarkerCount == 2);
		let marker = scope TimeMarker();
		bed.Page.GetMarker(0, marker);
		Test.Assert(marker.Label == "FootLeft");
		bed.Page.GetMarker(1, marker);
		Test.Assert(Near(marker.Time, 0.9));

		bed.Page.BeginMarkerMove(1);
		bed.Page.PreviewMarkerMove(1, 0.7f);
		Test.Assert(Near(bed.Source.EventTime[1], 0.7));
		Test.Assert(Near(bed.Page.EventRows.GetValue("events.1.time", 0).AsFloat, 0.7), "live in its row");
		bed.Page.PreviewMarkerMove(1, 0.75f);
		bed.Page.CommitMarkerMove();
		Test.Assert(Near(bed.Source.EventTime[1], 0.75));
		Test.Assert(bed.Page.IsDirty);
		bed.Page.Commands.Undo();
		Test.Assert(Near(bed.Source.EventTime[1], 0.9));
		bed.Page.Commands.Redo();
		Test.Assert(Near(bed.Source.EventTime[1], 0.75));
		bed.Page.Commands.Undo();

		bed.Page.BeginMarkerMove(0);
		bed.Page.PreviewMarkerMove(0, 1.0f);
		bed.Page.CancelMarkerMove();
		Test.Assert(Near(bed.Source.EventTime[0], 0.3));
		Test.Assert(Near(bed.Page.EventRows.GetValue("events.0.time", 0).AsFloat, 0.3));
		Test.Assert(!bed.Page.Commands.CanUndo);

		// Chosen on the page: the same event chosen on the ruler.
		bed.Page.ChooseEvent(1);
		Test.Assert(bed.Page.Ruler.ChosenMarker == 1);
	}

	[Test]
	public static void ThePreviewStartsOnTheSkeletonItsImportNamesTravelAndTheClockAreThePagesOwn()
	{
		let bed = scope Bed();
		Test.Assert(bed.Page.Rig != null);
		Test.Assert(bed.Page.Rig.SkeletonId == SkeletonId);
		Test.Assert(bed.Page.Rig.MeshId.IsNil);
		Test.Assert(bed.Page.Rig.SkeletonSlot != null);
		Test.Assert(bed.Page.Rig.MeshSlot != null);

		// Not cooked here: nothing to play, the clock still the page's to move.
		Test.Assert(!bed.Page.CanPlay);
		bed.Page.SetTime(0.5f);
		Test.Assert(Near(bed.Page.Time, 0.5));
		Test.Assert(Near(bed.Page.Ruler.TimeAxis.Playhead, 0.5));
		bed.Page.Stop();
		Test.Assert(bed.Page.Time == 0.0f);
		Test.Assert(!bed.Page.IsPlaying);

		// A scrub of the ruler pauses the clock where it is put.
		bed.Page.Restart();
		Test.Assert(bed.Page.IsPlaying);
		bed.Page.Ruler.TimeAxis.Playhead = 0.4f;
		Test.Assert(Near(bed.Page.Time, 0.4));
		Test.Assert(!bed.Page.IsPlaying);

		bed.Page.SetTravel(true);
		Test.Assert(bed.Page.Travels);
		Test.Assert(!bed.Page.IsDirty, "never the clip's");
	}

	[Test]
	public static void ThePreviewRigRoundTripsThroughTheSettingsStore()
	{
		AnimationEditorSerializables.Register();
		let clipA = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let clipB = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let rig = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
		let mesh = Guid(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8);

		let store = scope Settings();
		Guid skeleton = .();
		Guid meshOut = .();
		Test.Assert(!ClipPreviewPrefs.Load(store, clipA, ref skeleton, ref meshOut));
		Test.Assert(ClipPreviewPrefs.Save(store, clipA, rig, mesh));
		Test.Assert(ClipPreviewPrefs.Save(store, clipB, rig, .()));
		Test.Assert(!ClipPreviewPrefs.Save(store, Guid(), rig, mesh));
		Test.Assert(!ClipPreviewPrefs.Save(null, clipA, rig, mesh));
		Test.Assert(ClipPreviewPrefs.Load(store, clipA, ref skeleton, ref meshOut));
		Test.Assert((skeleton == rig) && (meshOut == mesh));
		Test.Assert(ClipPreviewPrefs.Load(store, clipB, ref skeleton, ref meshOut));
		Test.Assert((skeleton == rig) && meshOut.IsNil);

		// A second save updates in place.
		Test.Assert(ClipPreviewPrefs.Save(store, clipA, .(), mesh));
		Test.Assert(store.Section<ClipPreviewSettings>().Prefs.Count == 2);

		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(ClipPreviewPrefs.Load(loaded, clipA, ref skeleton, ref meshOut));
		Test.Assert(skeleton.IsNil && (meshOut == mesh));
	}

	/// The preview preferences moved from Editor.Scene with their page: a file saved before
	/// the move, every name and type id the old one, still loads.
	[Test]
	public static void APreviewRigSavedBeforeThePagesMoveStillLoads()
	{
		AnimationEditorSerializables.Register();
		let clip = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let rig = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
		let store = scope Settings();
		Test.Assert(ClipPreviewPrefs.Save(store, clip, rig, .()));
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);

		// The file as the build before the move wrote it.
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		for (let name in StringView[?]("ClipPreviewSettings", "ClipPreviewPref"))
		{
			let current = scope $"Sedulous.Editor.Animation.{name}";
			let former = scope $"Sedulous.Editor.Scene.{name}";
			let currentId = scope $"{Sedulous.Core.Serialization.TypeIdOf(current)}";
			Test.Assert(text.Contains(currentId), scope $"{name}'s id is written as {currentId}: {text}");
			text.Replace(currentId, scope $"{Sedulous.Core.Serialization.TypeIdOf(former)}");
			text.Replace(current, former);
		}
		let old = scope Sedulous.Core.IO.MemoryStream();
		old.Write(.((uint8*)text.Ptr, text.Length));
		old.Seek(0, .Begin);

		let loaded = scope Settings();
		Test.Assert(loaded.Load(old, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		Guid skeleton = .();
		Guid mesh = .();
		Test.Assert(ClipPreviewPrefs.Load(loaded, clip, ref skeleton, ref mesh));
		Test.Assert(skeleton == rig);
	}
}
