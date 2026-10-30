using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio.Tests;

/// The bus layout's rules (the cycle guard, the tree, adding, removing, renaming and moving a bus)
/// as pure functions over the asset, the assets round-tripping through the pages' undo snapshot, and
/// the page over its markup with no host: its tree, the chosen bus's rows, an edit one undo step.
class BusLayoutPageTests
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

	/// Effects < Footsteps < Steps (a custom bus under a custom one), and Music < Ambience.
	static void FillLayout(AudioBusLayoutAsset asset)
	{
		asset.Custom[0].Name.Set("Footsteps");
		asset.Custom[0].Parent.Set("Effects");
		asset.Custom[1].Name.Set("Ambience");
		asset.Custom[1].Parent.Set("music"); // a fixed bus's name in any case
		asset.Custom[2].Name.Set("Steps");
		asset.Custom[2].Parent.Set("Footsteps");
	}

	/// The tree as one line ("Master | .Effects | ..Footsteps"), into `outText`.
	static void TreeOf(AudioBusLayoutAsset asset, String outText)
	{
		let rows = scope List<BusRow>();
		defer { ClearAndDeleteItems!(rows); }
		BusLayoutModel.BusTree(asset, rows);
		for (let row in rows)
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			for (int32 d < row.Depth)
				outText.Append('.');
			outText.Append(row.Name);
		}
	}

	[Test]
	public static void WouldCycleCatchesDirectAndTransitiveCycles()
	{
		let asset = scope AudioBusLayoutAsset();
		// A -> B -> C (parents point up the chain).
		asset.Custom[0].Name.Set("A");
		asset.Custom[0].Parent.Set("B");
		asset.Custom[1].Name.Set("B");
		asset.Custom[1].Parent.Set("C");
		asset.Custom[2].Name.Set("C");
		asset.Custom[2].Parent.Set("Master");
		// C under A closes the loop (transitively), under B likewise; under a fixed bus never.
		Test.Assert(BusLayoutModel.WouldCycle(asset, 2, "A"));
		Test.Assert(BusLayoutModel.WouldCycle(asset, 2, "B"));
		Test.Assert(!BusLayoutModel.WouldCycle(asset, 2, "Effects"));
		Test.Assert(!BusLayoutModel.WouldCycle(asset, 2, "Master"));
		// A under itself is the direct case; under an unused name no slot resolves.
		Test.Assert(BusLayoutModel.WouldCycle(asset, 0, "A"));
		Test.Assert(!BusLayoutModel.WouldCycle(asset, 0, "Nope"));
	}

	/// The layout and the cue round-trip through the pages' undo snapshot (ObjectSnapshot): every
	/// field an undo restores.
	[Test]
	public static void TheLayoutAndTheCueRoundTripThroughTheUndoSnapshot()
	{
		AudioPipeline.RegisterAll();
		let a = scope AudioBusLayoutAsset();
		a.Music.Volume = 0.3f;
		a.Effects.LowpassHz = 1500.0f;
		a.Custom[0].Name.Set("drums");
		a.Custom[0].Parent.Set("Effects");
		a.Custom[0].Bus.LowpassHz = 1200.0f;
		a.Custom[0].Bus.ReverbWet = 0.4f;
		let bytes = scope List<uint8>();
		ObjectSnapshot.Take(a, bytes);
		let b = scope AudioBusLayoutAsset();
		Test.Assert(ObjectSnapshot.Restore(b, bytes));
		Test.Assert(Math.Abs(b.Music.Volume - 0.3f) < 1e-5f);
		Test.Assert(Math.Abs(b.Effects.LowpassHz - 1500.0f) < 1e-3f);
		Test.Assert((b.Custom[0].Name == "drums") && (b.Custom[0].Parent == "Effects"));
		Test.Assert(Math.Abs(b.Custom[0].Bus.LowpassHz - 1200.0f) < 1e-3f);
		Test.Assert(Math.Abs(b.Custom[0].Bus.ReverbWet - 0.4f) < 1e-5f);

		let cue = scope SoundCueAsset();
		cue.Slots[0].ClipId = Guid(0x11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x22);
		cue.Slots[2].ClipId = Guid(0x33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x44);
		cue.Slots[0].Weight = 2.5f;
		cue.Mode = 2;
		cue.PitchMin = 0.9f;
		cue.VolumeMax = 0.8f;
		bytes.Clear();
		ObjectSnapshot.Take(cue, bytes);
		let read = scope SoundCueAsset();
		Test.Assert(ObjectSnapshot.Restore(read, bytes));
		Test.Assert(read.Slots[0].ClipId == cue.Slots[0].ClipId);
		Test.Assert(read.Slots[1].ClipId.IsNil);
		Test.Assert(read.Slots[2].ClipId == cue.Slots[2].ClipId);
		Test.Assert(Math.Abs(read.Slots[0].Weight - 2.5f) < 1e-5f);
		Test.Assert((read.Mode == 2) && (Math.Abs(read.PitchMin - 0.9f) < 1e-5f) && (Math.Abs(read.VolumeMax - 0.8f) < 1e-5f));
	}

	[Test]
	public static void TheTreeEachCustomBusUnderItsParent()
	{
		let asset = scope AudioBusLayoutAsset();
		FillLayout(asset);
		Test.Assert(TreeOf(asset, .. scope .()) == "Master | .Effects | ..Footsteps | ...Steps | .Music | ..Ambience | .UI");
		// A parent no bus has is Master, as the cook takes it.
		asset.Custom[1].Parent.Set("Nowhere");
		Test.Assert(TreeOf(asset, .. scope .()) == "Master | .Effects | ..Footsteps | ...Steps | .Music | .UI | .Ambience");
		// Buses under each other in a loop are reached from no fixed bus: shown under Master all the same.
		asset.Custom[0].Parent.Set("Steps");
		Test.Assert(BusLayoutModel.HasBusCycle(asset));
		Test.Assert(TreeOf(asset, .. scope .()) == "Master | .Effects | .Music | .UI | .Ambience | .Footsteps | .Steps");
	}

	[Test]
	public static void AddedInTheFirstFreeSlotRemovedWithItsChildrenToMasterRenamedWithItsChildrenFollowing()
	{
		let asset = scope AudioBusLayoutAsset();
		FillLayout(asset);
		Test.Assert(BusLayoutModel.AddBus(asset) == 3);
		Test.Assert(asset.Custom[3].Name == "Bus 1");
		Test.Assert(asset.Custom[3].Parent == "Master");

		Test.Assert(BusLayoutModel.RenameBus(asset, 0, "Feet"));
		Test.Assert(asset.Custom[2].Parent == "Feet", "its child followed");
		Test.Assert(!BusLayoutModel.RenameBus(asset, 0, "Music"), "a fixed bus's");
		Test.Assert(!BusLayoutModel.RenameBus(asset, 0, "Ambience"), "another's");
		Test.Assert(!BusLayoutModel.RenameBus(asset, 0, ""));
		Test.Assert(asset.Custom[0].Name == "Feet");

		Test.Assert(!BusLayoutModel.ReparentBus(asset, 0, "Steps"), "its own child: a loop");
		Test.Assert(BusLayoutModel.ReparentBus(asset, 2, "Ambience"));
		Test.Assert(asset.Custom[2].Parent == "Ambience");
		// Ambience may move under the four fixed buses, Feet and Bus 1: not itself, not Steps under it.
		let choices = scope List<String>();
		defer { ClearAndDeleteItems!(choices); }
		BusLayoutModel.BusParentChoices(asset, 1, choices);
		Test.Assert(choices.Count == 6);

		BusLayoutModel.RemoveBus(asset, 1); // Ambience: Steps under it moves to Master
		Test.Assert(asset.Custom[1].Name.IsEmpty);
		Test.Assert(asset.Custom[2].Parent == "Master");
	}

	/// A project with the layout above ("Mixer").
	class Bed
	{
		public String Dir = new .("scratch_bus_layout_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Mixer;

		public this()
		{
			AudioPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Mixer = Project.SourceDb.RootGroup.CreateInstance("Mixer", typeof(AudioBusLayoutAsset).GetFullName(.. scope .()));
			Test.Assert(Mixer != null);
			let asset = scope AudioBusLayoutAsset();
			FillLayout(asset);
			Test.Assert(Mixer.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the layout; the caller deletes it.
		public AudioBusLayoutEditorPage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new AudioBusLayoutEditorPage(Context, services, Mixer);
		}
	}

	static double FloatOf(Sedulous.GUI.PropertyBag rows, StringView path)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		return value.AsFloat;
	}

	[Test]
	public static void RegisteredBesideTheClipAndTheCue()
	{
		let none = scope AssetPageServicesSource(); // no services: the registration only, before the context it outlives
		let context = scope EditorContext();
		AudioEditor.Register(context, none);
		let found = context.Pages.FindFactory(typeof(AudioBusLayoutAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(AudioBusLayoutAsset)));
	}

	[Test]
	public static void ItsTreeTheChosenBussRowsAFixedOnesSettingsACustomOnesNameAndParentToo()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(page.Tree(.. scope .()) == "Master\n  Effects\n    Footsteps\n      Steps\n  Music\n    Ambience\n  UI");
		Test.Assert(page.Selected.Fixed == 0, "Master");
		Test.Assert(!page.BusRows.FindInfo("name").Visible);
		Test.Assert(Math.Abs(FloatOf(page.EffectRows("Mix"), "volume") - 1.0) < 1e-5);
		Test.Assert(page.EffectRows("Reverb").FindInfo("reverbWet") != null, "a section per group");

		page.Select(BusRef.OfSlot(0)); // Footsteps
		Test.Assert(page.BusRows.FindInfo("name").Visible);
		var name = page.BusRows.GetValue("name", 0);
		defer name.Dispose();
		Test.Assert(name.AsString == "Footsteps");
		let parent = page.BusRows.FindInfo("parent");
		Test.Assert(parent != null);
		Test.Assert(parent.Choices.Count == 5, "the four fixed and Ambience: not itself, not Steps under it");
		var chosen = page.BusRows.GetValue("parent", 0);
		defer chosen.Dispose();
		Test.Assert(parent.Choices[(int)chosen.AsInt].Name == "Effects");
	}

	[Test]
	public static void ASettingARenameAndAMoveEachOneUndoStepABusAddedAndRemoved()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		page.Select(BusRef.OfSlot(0)); // Footsteps
		page.EditRow(page.EffectRows("Reverb"), "reverbWet", Sedulous.GUI.Variant(0.5));
		let layout = page.AssetObject as AudioBusLayoutAsset;
		Test.Assert(layout != null);
		Test.Assert(Math.Abs(layout.Custom[0].Bus.ReverbWet - 0.5f) < 1e-5f);
		Test.Assert(page.IsDirty);

		page.EditRow(page.BusRows, "name", Sedulous.GUI.Variant("Feet"));
		Test.Assert(layout.Custom[2].Parent == "Feet", "Steps followed");
		Test.Assert(page.Tree(.. scope .()) == "Master\n  Effects\n    Feet\n      Steps\n  Music\n    Ambience\n  UI");
		page.EditRow(page.BusRows, "name", Sedulous.GUI.Variant("Music")); // a fixed bus's: refused
		Test.Assert(layout.Custom[0].Name == "Feet");

		// Moved under Music (its index among the choices offered).
		let parent = page.BusRows.FindInfo("parent");
		int64 music = -1;
		for (int i < parent.Choices.Count)
		{
			if (parent.Choices[i].Name == "Music")
				music = i;
		}
		Test.Assert(music >= 0);
		page.EditRow(page.BusRows, "parent", Sedulous.GUI.Variant(music));
		Test.Assert(page.Tree(.. scope .()) == "Master\n  Effects\n  Music\n    Feet\n      Steps\n    Ambience\n  UI");

		page.Commands.Undo(); // the move
		page.Commands.Undo(); // the rename
		page.Commands.Undo(); // the setting
		Test.Assert(layout.Custom[0].Name == "Footsteps");
		Test.Assert(Math.Abs(layout.Custom[0].Bus.ReverbWet) < 1e-5f);

		Test.Assert(page.AddBus());
		Test.Assert(page.Selected.Slot == 3);
		Test.Assert(layout.Custom[3].Name == "Bus 1");
		Test.Assert(page.RemoveSelected());
		Test.Assert(layout.Custom[3].Name.IsEmpty);
		Test.Assert(page.Selected.Fixed == 0, "Master chosen again");
		page.Commands.Undo();
		Test.Assert(layout.Custom[3].Name == "Bus 1");
	}
}
