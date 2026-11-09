using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The export dialog over its markup (Data/Editor/Export.xml), a presets controller and a scratch
/// templates root: the presets listed and the selected one's settings on the grid in their sections
/// under the card naming the player its export builds (or why none builds here), a template picked
/// by name deciding the platform and config, edits applied as made and saved when the selection
/// moves, an override's rows shown only while it overrides, add, duplicate and remove (after
/// asking), and Export running the selected preset after saving, never one whose player cannot be
/// built here. Then: the card saying why for another host's platform and a Test config; the
/// platform and config read only under a template and editable again under Any; the extra files a
/// list, edited, shortened and an empty row dropped; the render and window overrides' rows; a save
/// as it closes; Export Templates opened over it, the template row following what it installed.
class ExportDialogTests
{
	/// Why the fixture's web preset builds no player: what the dialog is told for want of
	/// Emscripten, which no test machine is assumed to have.
	private const String cNoEmscripten = "a web build needs Emscripten (the fixture has none)";

	/// Another host's desktop platform: Win64 on Linux, Linux64 on Windows.
	private static StringView OtherHost => (BuildLayout.HostPlatformName == "Win64") ? "Linux64" : "Win64";

	private class Fixture
	{
		public String Root = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_export_dialog_root", .. new .()) ~ delete _;
		/// An empty directory: no player there, so the host build resolves nothing a test asks for.
		public String HostDir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_export_dialog_host", .. new .()) ~ delete _;
		public SceneRoot Ui;
		public ExportPresetsController Presets = new .() ~ delete _;
		public int Saves = 0;
		public List<String> Exported = new .() ~ DeleteContainerAndItems!(_);
		public bool ExportedAll = false;
		/// What Export Templates was told to tell as it closes; null until it opens. Owned.
		public delegate void() TemplatesClosed = null ~ delete _;
		public int TemplatesOpened = 0;
		public ExportDialog Dialog = null;
		public String Project = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_export_dialog_project", .. new .()) ~ delete _;
		/// The pickers the dialog opened, owned.
		public List<PickerRequest> Picks = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Notices = new .() ~ DeleteContainerAndItems!(_);
		/// What the system's dialog answers.
		public List<String> FromDisk = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(HostDir);
			Test.Assert(CreateDirectory(Root));
			Test.Assert(CreateDirectory(HostDir));
			WriteTemplate("t-linux", "Linux Release", "Linux64");

			let linuxPreset = scope ExportPreset();
			linuxPreset.Name.Set("Linux");
			linuxPreset.Platform.Set("Linux64");
			Presets.Add(linuxPreset);
			// A platform no machine running the tests hosts (the registry always adds the running
			// build as a template, so a Win64 preset finds one on a Windows runner).
			let web = scope ExportPreset();
			web.Name.Set("Web");
			web.Platform.Set("Web");
			Presets.Add(web);

			let gui = new GUIContext();
			Ui = new SceneRoot(gui);
			gui.ReleaseRef(); // the root's keeps it
			Ui.Size = .(1000.0f, 700.0f);
		}

		public ~this()
		{
			delete Dialog; // closed while the root is there
			Ui.ReleaseRef();
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(HostDir);
			RemoveDirectoryRecursive(Project);
		}

		/// An installed template's bundle (its manifest) under the root.
		public void WriteTemplate(StringView id, StringView name, StringView platform)
		{
			let dir = PathJoin(Root, id, .. scope .());
			Test.Assert(CreateDirectory(dir));
			let template = scope ExportTemplate();
			template.Id.Set(id);
			template.Name.Set(name);
			template.Platform.Set(platform);
			template.Config.Set("Release");
			template.EngineVersion.Set(EngineVersion.String);
			template.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
			Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(dir), template) case .Ok);
		}

		public ExportDialogSeams Seams()
		{
			let seams = new ExportDialogSeams();
			seams.Refresh = new [=this](registry) => { registry.Refresh(Root, HostDir); };
			seams.Save = new [=this]() => { Saves++; };
			seams.RunExport = new [=this](preset, all) =>
				{
					Exported.Add(new .(preset));
					ExportedAll = all;
				};
			seams.OpenTemplates = new [=this](closed) =>
				{
					TemplatesOpened++;
					delete TemplatesClosed;
					TemplatesClosed = closed;
				};
			seams.Pick = new [=this](request) => { Picks.Add(request); };
			seams.Notify = new [=this](message) => { Notices.Add(new .(message)); };
			seams.PickFiles = new [=this](chosen) =>
				{
					chosen(FromDisk);
					delete chosen;
				};
			seams.ProjectRoot.Set(Project);
			// The web wants Emscripten, which the fixture says is not here; the rest is the
			// dialog's own check (another host's platform, a Test config).
			seams.CanBuild = new (preset, outWhy) =>
				{
					if (preset.Platform == "Web")
					{
						outWhy.Set(cNoEmscripten);
						return false;
					}
					return ProjectPlayerBuilder.CanBuild(preset, outWhy);
				};
			seams.ProjectName.Set("Sky");
			seams.HostPlatform.Set("Linux64");
			seams.OutputRoot.Set("/tmp/project/Dist");
			return seams;
		}

		/// The dialog open over the root, laid out.
		public ExportDialog Open()
		{
			Dialog = new ExportDialog(Presets, Seams(), TemplatesDialogTests.LoadDialog(ExportDialog.cMarkupPath));
			Test.Assert(Dialog.Open(Ui));
			Ui.UpdateLayout();
			return Dialog;
		}

		public Sedulous.GUI.PropertyBag Bag => Dialog.Rows;

		/// One edit of `path` to `value`, as a row's gesture ends.
		public void Edit(StringView path, Sedulous.GUI.Variant value)
		{
			Bag.BeginEdit(path);
			Bag.CommitEdit(path, PropertyWrite(value));
		}

		public bool TextIs(StringView path, StringView expected)
		{
			var value = Bag.GetValue(path, 0);
			defer value.Dispose();
			return value.AsString == expected;
		}

		public bool FlagAt(StringView path)
		{
			var value = Bag.GetValue(path, 0);
			defer value.Dispose();
			return value.AsBool;
		}

		public int64 IntAt(StringView path)
		{
			var value = Bag.GetValue(path, 0);
			defer value.Dispose();
			return value.AsInt;
		}

		public bool Shows(StringView path) => Bag.FindInfo(path).Visible;

		public Sedulous.GUI.Button FindButton(StringView id) => Dialog.Window.Content.FindElement(id) as Sedulous.GUI.Button;
	}

	/// The presets, their settings in their sections, and the player each one's export builds, or
	/// why none builds here; a template picked by name decides the platform and config, which are
	/// then read only.
	[Test]
	public static void ThePresetsTheirSettingsInSectionsAndThePlayerEachBuilds()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.PresetCount == 2);
		Test.Assert(dialog.SelectedIndex == 0);
		let rows = dialog.Rows;
		Test.Assert(f.TextIs("name", "Linux"));
		Test.Assert(rows.FindInfo("name").Category == "General");
		Test.Assert(rows.FindInfo("stageSymbols").Category == "Content");
		Test.Assert(rows.FindInfo("orientation").Category == "Display");

		// Linux builds the game's player in the shipping config; Web cannot be built here, and
		// the card says why under the player it would build.
		Test.Assert(dialog.ResolveText == "SkyPlayer, ShippingRelease, Linux64", scope String(dialog.ResolveText));
		Test.Assert(dialog.ResolveDetail.StartsWith("Built as it exports"), scope String(dialog.ResolveDetail));
		Test.Assert(dialog.SelectedBuildable);
		Test.Assert(dialog.ExportButton.Enabled);
		dialog.Select(1);
		Test.Assert(!dialog.SelectedBuildable);
		Test.Assert(dialog.ResolveText == "SkyPlayerWeb, ShippingRelease, wasm32", scope String(dialog.ResolveText));
		Test.Assert(dialog.ResolveDetail == cNoEmscripten, scope String(dialog.ResolveDetail));
		Test.Assert(!dialog.ExportButton.Enabled);

		// A template picked by name decides the platform and config, which then are read only.
		let template = dialog.Rows.FindInfo("template");
		Test.Assert(template != null);
		Test.Assert(template.Choices.Count >= 2, "Any, then each template");
		Test.Assert(f.IntAt("template") == 0);
		int64 installed = -1;
		for (let choice in template.Choices)
		{
			if (choice.Name == "Linux Release")
				installed = choice.Value;
		}
		Test.Assert(installed > 0);
		f.Edit("template", Sedulous.GUI.Variant(installed));
		Test.Assert(f.Presets.At(1).TemplateId == "t-linux");
		Test.Assert(f.Presets.At(1).Platform == "Linux64");
		Test.Assert(dialog.Rows.FindInfo("platform").ReadOnly);
		Test.Assert(dialog.Resolved != null);
		// Now a Linux preset, its card and its Export follow.
		Test.Assert(dialog.ResolveText == "SkyPlayer, ShippingRelease, Linux64", scope String(dialog.ResolveText));
		Test.Assert(dialog.ExportButton.Enabled);
	}

	/// Edits apply as made and are saved when the selection moves; export saves first.
	[Test]
	public static void EditsApplyAsMadeAndSaveWhenTheSelectionMovesExportSavesFirst()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.SelectedIndex == 0);

		f.Edit("name", Sedulous.GUI.Variant("Linux Desktop"));
		f.Edit("pruneToReachable", Sedulous.GUI.Variant(true));
		Test.Assert(f.Presets.At(0).Name == "Linux Desktop");
		Test.Assert(f.Presets.At(0).PruneToReachable);
		Test.Assert(f.Saves == 0);
		dialog.Select(1);
		Test.Assert(f.Saves == 1, "saved as the selection moved");
		dialog.Select(0);
		Test.Assert(f.Saves == 1, "nothing new to save");

		// Export saves what is pending, then runs the selected preset.
		f.Edit("pruneToReachable", Sedulous.GUI.Variant(false));
		dialog.ExportSelected();
		Test.Assert(f.Saves == 2);
		Test.Assert(f.Exported.Count == 1);
		Test.Assert(f.Exported[0] == "Linux Desktop");
		Test.Assert(!f.ExportedAll);
		Test.Assert(!dialog.IsOpen);
	}

	/// A preset holds the game its own way (a phone-facing Web preset says Landscape), its row
	/// shown only while it does, and the dialog shows the preset's choice again when it is selected.
	[Test]
	public static void APresetOverridesTheOrientationItsRowShownOnlyWhileItDoes()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.SelectedIndex == 0);
		Test.Assert(!f.FlagAt("overridesOrientation"));
		Test.Assert(!f.Shows("orientation"));

		f.Edit("overridesOrientation", Sedulous.GUI.Variant(true));
		Test.Assert(f.Shows("orientation"));
		f.Edit("orientation", Sedulous.GUI.Variant((int64)ScreenOrientation.Landscape));
		Test.Assert(f.Presets.At(0).OverridesOrientation);
		Test.Assert(f.Presets.At(0).Orientation == .Landscape);
		Test.Assert(!f.Presets.At(1).OverridesOrientation);

		// The other preset shows its own; coming back shows this one's again.
		dialog.Select(1);
		Test.Assert(!f.FlagAt("overridesOrientation"));
		dialog.Select(0);
		Test.Assert(f.FlagAt("overridesOrientation"));
		Test.Assert(f.IntAt("orientation") == (int64)ScreenOrientation.Landscape);
	}

	/// Add takes the host's platform, Duplicate names the copy, Remove asks first and keeps a
	/// neighbour selected; each saves.
	[Test]
	public static void AddDuplicateAndRemoveAfterAsking()
	{
		let f = scope Fixture();
		let dialog = f.Open();

		dialog.AddPreset();
		Test.Assert(dialog.PresetCount == 3);
		Test.Assert(dialog.SelectedIndex == 2);
		Test.Assert(f.Presets.At(2).Platform == "Linux64", "the host's");
		Test.Assert(f.TextIs("name", "New Preset"));

		dialog.Select(0);
		dialog.DuplicateSelected();
		Test.Assert(dialog.PresetCount == 4);
		Test.Assert(dialog.SelectedIndex == 3);
		Test.Assert(f.Presets.At(3).Name == "Linux Copy");

		// Remove asks; Escape keeps it, Remove removes it.
		dialog.RemoveSelected();
		var question = PagesBed.FindBox(f.Ui);
		Test.Assert(question != null);
		Test.Assert(question.Message == "Remove the preset 'Linux Copy'? Its settings go; what it exported stays.");
		question.RequestClose();
		Test.Assert(dialog.PresetCount == 4);
		dialog.RemoveSelected();
		question = PagesBed.FindBox(f.Ui);
		Test.Assert(question != null);
		Test.Assert(question.ButtonAt(1) != null);
		Test.Assert(question.ButtonAt(1).HandleActivate());
		Test.Assert(dialog.PresetCount == 3);
		Test.Assert(dialog.SelectedIndex == 2);
		Test.Assert(f.Saves >= 3);

		dialog.ExportAll();
		Test.Assert(f.ExportedAll);
	}

	/// A preset for another host's platform, or in a config no player is built in, says on the
	/// card that no player builds for it here and why; it does not export, and the card names the
	/// player again once the preset is one this host builds.
	[Test]
	public static void TheCardSaysWhyNoPlayerBuildsHere()
	{
		let f = scope Fixture();
		let other = scope ExportPreset();
		other.Name.Set("Elsewhere");
		other.Platform.Set(OtherHost);
		f.Presets.Add(other);
		let tested = scope ExportPreset();
		tested.Name.Set("Tested");
		tested.Platform.Set("Linux64");
		tested.Config.Set("Test");
		f.Presets.Add(tested);
		let dialog = f.Open();

		dialog.Select(2);
		Test.Assert(!dialog.SelectedBuildable);
		Test.Assert(dialog.ResolveText == "No player builds for it here", scope String(dialog.ResolveText));
		Test.Assert(dialog.ResolveDetail.StartsWith(scope $"a {OtherHost} player builds on"), scope String(dialog.ResolveDetail));
		Test.Assert(!dialog.ExportButton.Enabled);
		dialog.ExportSelected();
		Test.Assert(f.Exported.IsEmpty, "a preset whose player cannot be built here does not export");
		Test.Assert(dialog.IsOpen);

		dialog.Select(3);
		Test.Assert(dialog.ResolveText == "No player builds for it here", scope String(dialog.ResolveText));
		Test.Assert(dialog.ResolveDetail.StartsWith("a Test build links the test runner"), scope String(dialog.ResolveDetail));

		// Release again: the card names the player.
		f.Edit("config", Sedulous.GUI.Variant((int64)IndexOfChoice(dialog, "config", "Release")));
		Test.Assert(f.Presets.At(3).EffectiveConfig == "Release");
		Test.Assert(dialog.ResolveText == "SkyPlayer, ShippingRelease, Linux64", scope String(dialog.ResolveText));
		Test.Assert(dialog.ExportButton.Enabled);
	}

	/// The value of the choice named `name` on the row `path`; -1 when it offers none.
	private static int64 IndexOfChoice(ExportDialog dialog, StringView path, StringView name)
	{
		for (let choice in dialog.Rows.FindInfo(path).Choices)
		{
			if (choice.Name == name)
				return choice.Value;
		}
		return -1;
	}

	/// Under a template picked by name the platform and config are read only; back on Any they may
	/// be chosen again, and the preset names no template.
	[Test]
	public static void ThePlatformAndConfigAreReadOnlyOnlyUnderATemplate()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(!dialog.Rows.FindInfo("platform").ReadOnly);
		Test.Assert(!dialog.Rows.FindInfo("config").ReadOnly);
		f.Edit("template", Sedulous.GUI.Variant((int64)1));
		Test.Assert(!f.Presets.At(0).TemplateId.IsEmpty);
		Test.Assert(dialog.Rows.FindInfo("platform").ReadOnly);
		Test.Assert(dialog.Rows.FindInfo("config").ReadOnly);
		f.Edit("template", Sedulous.GUI.Variant((int64)0));
		Test.Assert(f.Presets.At(0).TemplateId.IsEmpty);
		Test.Assert(!dialog.Rows.FindInfo("platform").ReadOnly);
		Test.Assert(!dialog.Rows.FindInfo("config").ReadOnly);
	}

	/// The extra files are a list: an element each, an edit to one applying, one removed going, and
	/// a row added and left empty dropped.
	[Test]
	public static void TheExtraFilesAreAList()
	{
		let f = scope Fixture();
		f.Presets.At(0).AdditionalFiles.Add(new .("LICENSE.txt"));
		f.Presets.At(0).AdditionalFiles.Add(new .("README.md"));
		let dialog = f.Open();
		let files = dialog.Rows.FindInfo("additionalFiles");
		Test.Assert(files != null);
		Test.Assert(files.Kind == .List);
		Test.Assert(files.Category == "Content");
		Test.Assert(dialog.Rows.ElementCount("additionalFiles", 0) == 2);
		Test.Assert(f.TextIs("additionalFiles.0", "LICENSE.txt"));
		Test.Assert(f.TextIs("additionalFiles.1", "README.md"));

		f.Edit("additionalFiles.0", Sedulous.GUI.Variant("COPYING"));
		Test.Assert(f.Presets.At(0).AdditionalFiles.Count == 2);
		Test.Assert(f.Presets.At(0).AdditionalFiles[0] == "COPYING");

		Test.Assert(dialog.Rows.EditList("additionalFiles", scope ListEdit(.Remove, 1)));
		Test.Assert(f.Presets.At(0).AdditionalFiles.Count == 1, "a removed row goes as it is removed");

		Test.Assert(dialog.Rows.EditList("additionalFiles", scope ListEdit(.Insert, 1)));
		Test.Assert(dialog.Rows.ElementCount("additionalFiles", 0) == 2);
		Test.Assert(f.Presets.At(0).AdditionalFiles.Count == 1, "an empty row is dropped");
		Test.Assert(f.Presets.At(0).AdditionalFiles[0] == "COPYING");
	}

	/// The render size's and the window's rows show only while the preset overrides them.
	[Test]
	public static void TheRenderAndWindowOverridesRowsShowOnlyWhileTheyOverride()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		Test.Assert(dialog.SelectedIndex == 0);
		Test.Assert(!f.Shows("renderWidth") && !f.Shows("renderHeight") && !f.Shows("renderFit"));
		Test.Assert(!f.Shows("windowWidth") && !f.Shows("windowMode") && !f.Shows("windowResizable"));
		Test.Assert(f.Shows("overridesRender") && f.Shows("overridesWindow"), "the switches always show");

		f.Edit("overridesRender", Sedulous.GUI.Variant(true));
		Test.Assert(f.Shows("renderWidth") && f.Shows("renderHeight") && f.Shows("renderFit"));
		Test.Assert(!f.Shows("windowWidth"), "the window's still hidden");
		f.Edit("renderWidth", Sedulous.GUI.Variant((int64)1280));
		Test.Assert(f.Presets.At(0).OverridesRender && (f.Presets.At(0).RenderWidth == 1280));

		f.Edit("overridesWindow", Sedulous.GUI.Variant(true));
		Test.Assert(f.Shows("windowWidth") && f.Shows("windowHeight") && f.Shows("windowMode") && f.Shows("windowResizable"));
		f.Edit("overridesRender", Sedulous.GUI.Variant(false));
		Test.Assert(!f.Shows("renderWidth") && !f.Shows("renderFit"));
		Test.Assert(f.Shows("windowWidth"));
	}

	/// What was edited is saved as it closes, however it closes; nothing edited, nothing saved.
	[Test]
	public static void ClosingSavesWhatWasEdited()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		dialog.Close();
		Test.Assert(f.Saves == 0, "nothing edited");

		Test.Assert(dialog.Open(f.Ui));
		f.Edit("stageSymbols", Sedulous.GUI.Variant(true));
		Test.Assert(f.Saves == 0);
		Test.Assert(f.FindButton("export-close").HandleActivate());
		Test.Assert(!dialog.IsOpen);
		Test.Assert(f.Saves == 1);
		Test.Assert(f.Presets.At(0).StageSymbols);
	}

	/// Export Templates opens over it from its button, and once it closes the template row follows
	/// what it installed; the card still names the player the export builds, which no template
	/// decides.
	[Test]
	public static void ExportTemplatesOpensOverItAndTheTemplateRowFollowsWhatChanged()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		dialog.Select(1);
		Test.Assert(dialog.Resolved == null);

		Test.Assert(f.FindButton("export-templates").HandleActivate());
		Test.Assert(f.TemplatesOpened == 1);
		Test.Assert(f.TemplatesClosed != null);

		f.WriteTemplate("t-web", "Web Release", "Web");
		f.TemplatesClosed();
		Test.Assert(dialog.SelectedIndex == 1, "the selection kept");
		Test.Assert((dialog.Resolved != null) && (dialog.Resolved.Id == "t-web"));
		Test.Assert(dialog.ResolveText == "SkyPlayerWeb, ShippingRelease, wasm32", scope String(dialog.ResolveText));
		Test.Assert(!dialog.ExportButton.Enabled, "a template does not build the web player");
		bool listed = false;
		for (let choice in dialog.Rows.FindInfo("template").Choices)
		{
			if (choice.Name == "Web Release")
				listed = true;
		}
		Test.Assert(listed, "the template row offers it");
	}

	/// Extra files are the project's: Add Files lists its own files (not the folders the editor, a
	/// cook or an export writes) and adds the one picked by its project-relative path; From Disk
	/// takes a file inside the project the same way (once) and refuses one outside it.
	[Test]
	public static void ExtraFilesComeFromTheProjectNamedRelativeToIt()
	{
		let f = scope Fixture();
		RemoveDirectoryRecursive(f.Project);
		for (let file in StringView[6]("CREDITS.md", "Docs/manual.txt", "Cooked/a.bin", "Cooked-android/b.bin", ".cache/c.bin",
			"Dist/Linux64/game"))
		{
			let full = PathJoin(f.Project, file, .. scope .());
			Test.Assert(CreateDirectory(PathParent(full, .. scope .())));
			Test.Assert(WriteFile(full, .()) case .Ok);
		}
		let dialog = f.Open();
		Test.Assert(dialog.SelectedIndex == 0);

		dialog.AddFiles();
		Test.Assert(f.Picks.Count == 1);
		let items = f.Picks[0].Items;
		Test.Assert(items.Count == 2, "the generated folders' files are not offered");
		Test.Assert(items[0].Key == "CREDITS.md");
		Test.Assert(items[1].Key == "Docs/manual.txt");
		f.Picks[0].OnPicked("Docs/manual.txt");
		Test.Assert(f.Presets.At(0).AdditionalFiles.Count == 1);
		Test.Assert(f.Presets.At(0).AdditionalFiles[0] == "Docs/manual.txt");

		// From Disk: inside the project it joins by its relative path (once); outside, it is refused.
		f.FromDisk.Add(PathJoin(f.Project, "CREDITS.md", .. new .()));
		f.FromDisk.Add(PathJoin(f.Project, "Docs/manual.txt", .. new .()));
		f.FromDisk.Add(new .("/elsewhere/licence.txt"));
		dialog.AddFilesFromDisk();
		Test.Assert(f.Presets.At(0).AdditionalFiles.Count == 2);
		Test.Assert(f.Presets.At(0).AdditionalFiles[1] == "CREDITS.md");
		Test.Assert(f.Notices.Count == 1);
		Test.Assert(f.Notices[0].StartsWith("/elsewhere/licence.txt is outside the project"), f.Notices[0]);
	}
}
