using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio.Tests;

/// The sound cue page over its markup (Data/Editor/SoundCuePage.xml) and a scratch project, with no
/// host (no audio engine: nothing plays): the cue's rows, its variants a list as every page's, a cue
/// with no clip said so; Add makes a variant to fill, its clip picked joins the cue, removed and
/// moved; how it picks and its ranges; each change to the cue one undo step.
class SoundCuePageTests
{
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

	/// Markup under the data root: a node with one reference, the caller's.
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

	/// A project with a cue ("Steps") whose first two slots hold clips, and one with none ("Hush").
	class Bed
	{
		public String Dir = new .("scratch_sound_cue_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Steps;
		public Instance Hush;
		public Guid Left = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		public Guid Right = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		public Guid Third = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3);

		public this()
		{
			AudioPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let type = typeof(SoundCueAsset).GetFullName(.. scope .());
			Steps = Project.SourceDb.RootGroup.CreateInstance("Steps", type);
			Hush = Project.SourceDb.RootGroup.CreateInstance("Hush", type);
			Test.Assert((Steps != null) && (Hush != null));
			let cue = scope SoundCueAsset();
			Test.Assert(Hush.WriteObject(cue) case .Ok);
			cue.Slots[0].ClipId = Left;
			cue.Slots[1].ClipId = Right;
			cue.Slots[1].Weight = 3.0f;
			Test.Assert(Steps.WriteObject(cue) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it.
		public SoundCueEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new SoundCueEditorPage(Context, services, instance);
		}
	}

	/// The variants' clips as the list shows them ("left | right | -" with one to fill), into
	/// `outText`.
	static void Clips(SoundCueEditorPage page, Bed bed, String outText)
	{
		let count = page.VariantRows.ElementCount("variants", 0);
		let text = scope String();
		for (int i < count)
		{
			text.Clear();
			TextOf(page.VariantRows, scope $"variants.{i}.clip", text);
			if (!outText.IsEmpty)
				outText.Append(" | ");
			if (text == bed.Left.ToString(.. scope .()))
				outText.Append("left");
			else if (text == bed.Right.ToString(.. scope .()))
				outText.Append("right");
			else if (text == bed.Third.ToString(.. scope .()))
				outText.Append("third");
			else
				outText.Append("-");
		}
	}

	static void TextOf(Sedulous.GUI.PropertyBag rows, StringView path, String outText)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		outText.Append(value.AsString);
	}

	static double FloatOf(Sedulous.GUI.PropertyBag rows, StringView path)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		return value.AsFloat;
	}

	[Test]
	public static void RegisteredForTheCueBesideTheClip()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		AudioEditor.Register(context, none);
		let found = context.Pages.FindFactory(typeof(SoundCueAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(SoundCueAsset)));
	}

	[Test]
	public static void TheVariantsAListAsEveryPagesEachAClipAndItsWeightNoClipSaidSo()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Steps);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.VariantCount == 2);
		let list = page.VariantRows.FindInfo("variants");
		Test.Assert(list != null);
		Test.Assert(list.Kind == .List);
		Test.Assert(list.MaxCount == 8);
		Test.Assert(Clips(page, bed, .. scope .()) == "left | right");
		Test.Assert(Math.Abs(FloatOf(page.VariantRows, "variants.1.weight") - 3.0) < 1e-5);
		let fields = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(fields); }
		page.VariantRows.GetProperties("variants.0", fields);
		Test.Assert(fields.Count == 2);
		Test.Assert(fields[0].ReferenceType == typeof(AudioClip));
		Test.Assert(page.CueRows.FindInfo("pitchMax").Hint == "slider");
		Test.Assert(page.Notice("empty", .. scope .()).IsEmpty);
		Test.Assert(!page.CanPlay, "no audio engine here");
		Test.Assert((page as IPlaybackPage) != null);
		let play = page.Content.FindElement("cue-play") as ButtonBase;
		Test.Assert((play != null) && (play.CheckedIcon == "Editor/Icons/pause.svg"), "Play shows Pause while it plays");

		let empty = bed.Open(bed.Hush);
		defer delete empty;
		Test.Assert(empty.VariantRows.ElementCount("variants", 0) == 0);
		Test.Assert(!empty.Notice("empty", .. scope .()).IsEmpty);
	}

	[Test]
	public static void AddMakesAVariantToFillItsClipPickedJoinsTheCueRemovedAndMovedEachOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Steps);
		defer delete page;
		// Add, as the list's button: a variant with no clip yet, the cue unchanged.
		Test.Assert(page.VariantRows.EditList("variants", scope ListEdit(.Insert, 2)));
		Test.Assert(Clips(page, bed, .. scope .()) == "left | right | -");
		Test.Assert(page.VariantCount == 2);
		Test.Assert(!page.Commands.CanUndo);
		// Its clip picked: it joins the cue, one step.
		page.EditRow(page.VariantRows, "variants.2.clip", Sedulous.GUI.Variant(bed.Third.ToString(.. scope .())));
		Test.Assert(page.VariantCount == 3);
		Test.Assert(Clips(page, bed, .. scope .()) == "left | right | third");
		Test.Assert(page.IsDirty);

		// Moved, as an element's grip does: the cue's order with it.
		Test.Assert(page.VariantRows.EditList("variants", scope ListEdit(.Move, 2, 0)));
		Test.Assert(Clips(page, bed, .. scope .()) == "third | left | right");
		let cue = page.AssetObject as SoundCueAsset;
		Test.Assert(cue != null);
		Test.Assert(cue.Slots[0].ClipId == bed.Third);
		Test.Assert(Math.Abs(cue.Slots[2].Weight - 3.0f) < 1e-5f, "right's weight went with it");

		// Removed, as an element's menu does.
		Test.Assert(page.VariantRows.EditList("variants", scope ListEdit(.Remove, 1)));
		Test.Assert(Clips(page, bed, .. scope .()) == "third | right");
		Test.Assert(page.VariantCount == 2);

		page.Commands.Undo(); // the removal
		Test.Assert(Clips(page, bed, .. scope .()) == "third | left | right");
		page.Commands.Undo(); // the move
		Test.Assert(Clips(page, bed, .. scope .()) == "left | right | third");
		page.Commands.Undo(); // the pick
		Test.Assert(page.VariantCount == 2);
	}

	[Test]
	public static void HowItPicksAndItsRangesEachOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Steps);
		defer delete page;
		page.EditRow(page.CueRows, "mode", Sedulous.GUI.Variant((int64)2));
		page.EditRow(page.CueRows, "pitchMax", Sedulous.GUI.Variant(1.25));
		let cue = page.AssetObject as SoundCueAsset;
		Test.Assert(cue != null);
		Test.Assert(cue.Mode == 2);
		Test.Assert(Math.Abs(cue.PitchMax - 1.25f) < 1e-5f);
		page.Commands.Undo();
		Test.Assert(Math.Abs(cue.PitchMax - 1.0f) < 1e-5f);
		Test.Assert(cue.Mode == 2);
		page.Commands.Undo();
		Test.Assert(cue.Mode == 0);
	}

	/// The clip's and the cue's factories make their pages with the one source's services (the
	/// markup here): the cue's no longer asks the clip's.
	[Test]
	public static void TheClipAndCueFactoriesMakeTheirPagesWithTheOneSourcesServices()
	{
		let source = scope AssetPageServicesSource(new () =>
			{
				let services = new AssetPageServices();
				services.LoadMarkup = new (path) => LoadMarkup(path);
				return services;
			});
		let bed = scope Bed(); // after the source: its context goes first
		AudioEditor.Register(bed.Context, source);
		let cue = bed.Context.Pages.FindFactory(typeof(SoundCueAsset)).CreatePage(bed.Context, bed.Steps);
		defer delete cue;
		Test.Assert((cue as SoundCueEditorPage).Content != null, "the cue's page made with the source's markup");
		let clip = bed.Context.Pages.FindFactory(typeof(AudioClipAsset)).CreatePage(bed.Context, bed.Steps);
		defer delete clip;
		Test.Assert((clip as AudioClipEditorPage).Content != null, "the clip's too");
	}
}
