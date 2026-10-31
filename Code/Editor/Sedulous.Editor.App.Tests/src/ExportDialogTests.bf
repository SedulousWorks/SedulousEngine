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
/// under the card naming the template it exports with (or why none), a template picked by name
/// deciding the platform and config, edits applied as made and saved when the selection moves, an
/// override's rows shown only while it overrides, add, duplicate and remove (after asking), and
/// Export running the selected preset after saving. Then what Sedulous adds so each behaviour has a
/// test: the card naming a template the preset picks that is not installed, and what to do; the
/// platform and config read only under a template and editable again under Any; the extra files a
/// list, edited, shortened and an empty row dropped; the render and window overrides' rows; a save
/// as it closes; Export Templates opened over it, the card following what it installed.
class ExportDialogTests
{
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

	/// The presets, their settings in their sections, and the template each exports with, or why
	/// none; a template picked by name decides the platform and config, which are then read only.
	[Test]
	public static void ThePresetsTheirSettingsInSectionsAndTheTemplateEachExportsWith()
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

		// Linux resolves to the installed template; Web has none here, and says so.
		Test.Assert((dialog.Resolved != null) && (dialog.Resolved.Id == "t-linux"));
		Test.Assert(dialog.ResolveText == "Exports with Linux Release", scope String(dialog.ResolveText));
		Test.Assert(dialog.ExportButton.Enabled);
		dialog.Select(1);
		Test.Assert(dialog.Resolved == null);
		Test.Assert(dialog.ResolveText == "No template for Web Release here", scope String(dialog.ResolveText));
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

	/// A preset picking a template by an id not installed here says so on the card, and what to do.
	[Test]
	public static void TheCardSaysWhyThereIsNoTemplate()
	{
		let f = scope Fixture();
		f.Presets.At(1).TemplateId.Set("t-gone");
		let dialog = f.Open();
		dialog.Select(1);
		Test.Assert(dialog.Resolved == null);
		Test.Assert(dialog.ResolveText == "Template 't-gone' is not installed here", scope String(dialog.ResolveText));
		Test.Assert(dialog.ResolveDetail == "Install or create one in Export Templates, or pick another platform.");
		dialog.Select(0);
		Test.Assert(dialog.ResolveDetail.StartsWith("Linux64 · Release"));
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

	/// Export Templates opens over it from its button, and once it closes the card follows what it
	/// installed: a preset that had no template here exports with the new one.
	[Test]
	public static void ExportTemplatesOpensOverItAndTheCardFollowsWhatChanged()
	{
		let f = scope Fixture();
		let dialog = f.Open();
		dialog.Select(1);
		Test.Assert(dialog.ResolveText == "No template for Web Release here");
		Test.Assert(!dialog.ExportButton.Enabled);

		Test.Assert(f.FindButton("export-templates").HandleActivate());
		Test.Assert(f.TemplatesOpened == 1);
		Test.Assert(f.TemplatesClosed != null);
		Test.Assert(dialog.ResolveText == "No template for Web Release here", "nothing read until it closes");

		f.WriteTemplate("t-web", "Web Release", "Web");
		f.TemplatesClosed();
		Test.Assert(dialog.SelectedIndex == 1, "the selection kept");
		Test.Assert((dialog.Resolved != null) && (dialog.Resolved.Id == "t-web"));
		Test.Assert(dialog.ResolveText == "Exports with Web Release", scope String(dialog.ResolveText));
		Test.Assert(dialog.ExportButton.Enabled);
		bool listed = false;
		for (let choice in dialog.Rows.FindInfo("template").Choices)
		{
			if (choice.Name == "Web Release")
				listed = true;
		}
		Test.Assert(listed, "the template row offers it");
	}
}
