using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App.Tests;

/// The export dialog over a presets controller and a scratch templates root: the presets listed
/// and the selected one's settings in tabs under the card naming the template it exports with
/// (or why none), edits applied as made and saved when the selection moves, add, duplicate and
/// remove, and Export running the selected preset after saving.
class ExportDialogTests
{
	private class Fixture
	{
		public String Root = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_export_dialog_root", .. new .()) ~ delete _;
		/// An empty directory: no player there, so the host build resolves nothing a test asks for.
		public String HostDir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_export_dialog_host", .. new .()) ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public ExportPresetsController Presets = new .() ~ delete _;
		public int Saves = 0;
		public List<String> Exported = new .() ~ DeleteContainerAndItems!(_);
		public bool ExportedAll = false;

		public this()
		{
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(HostDir);
			let dir = PathJoin(Root, "t-linux", .. scope .());
			Test.Assert(CreateDirectory(dir));
			Test.Assert(CreateDirectory(HostDir));
			let template = scope ExportTemplate();
			template.Id.Set("t-linux");
			template.Name.Set("Linux Release");
			template.Platform.Set("Linux64");
			template.Config.Set("Release");
			template.EngineVersion.Set(EngineVersion.String);
			template.PlayerBinary.Set("Sedulous.Engine.Player.Desktop");
			Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(dir), template) case .Ok);

			let linuxPreset = scope ExportPreset();
			linuxPreset.Name.Set("Linux");
			linuxPreset.Platform.Set("Linux64");
			Presets.Add(linuxPreset);
			let windows = scope ExportPreset();
			windows.Name.Set("Windows");
			windows.Platform.Set("Win64");
			Presets.Add(windows);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(Root);
			RemoveDirectoryRecursive(HostDir);
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
			seams.HostPlatform.Set("Linux64");
			seams.OutputRoot.Set("/tmp/project/Dist");
			return seams;
		}
	}

	/// The presets, their tabs, and the template each exports with, or why none; a template
	/// picked by name decides the platform and config.
	[Test]
	public static void ThePresetsTheirTabsAndTheTemplateEachExportsWith()
	{
		let f = scope Fixture();
		let dialog = new ExportDialog(f.Context, f.Presets, f.Seams());
		defer dialog.ReleaseRef();
		Test.Assert(dialog.PresetCount == 2);
		Test.Assert(dialog.SelectedIndex == 0);
		Test.Assert(dialog.TabIndexOf("General") == 0);
		Test.Assert(dialog.TabIndexOf("Content") == 1);
		Test.Assert(dialog.TabIndexOf("Display") == 2);
		Test.Assert(dialog.NameField.Text == "Linux");

		// Linux resolves to the installed template; Windows has none here, and says so.
		Test.Assert((dialog.Resolved != null) && (dialog.Resolved.Id == "t-linux"));
		Test.Assert(dialog.ResolveText == "Exports with Linux Release", scope String(dialog.ResolveText));
		dialog.Select(1);
		Test.Assert(dialog.Resolved == null);
		Test.Assert(dialog.ResolveText == "No template for Win64 Release here", scope String(dialog.ResolveText));

		// A template picked by name decides the platform and config.
		let template = dialog.TemplateField;
		Test.Assert(template.ItemCount >= 2, "\"Any\", then each template (the host build's among them)");
		Test.Assert(template.SelectedIndex == 0);
		int32 installed = -1;
		for (int32 i = 1; i < template.ItemCount; i++)
		{
			template.SetSelectedIndex(i);
			if (template.SelectedText == "Linux Release")
				installed = i;
		}
		Test.Assert(installed > 0);
		template.SetSelectedIndex(installed);
		Test.Assert(f.Presets.At(1).TemplateId == "t-linux");
		Test.Assert(f.Presets.At(1).Platform == "Linux64");
		Test.Assert(dialog.Resolved != null);
	}

	/// Edits apply as made and are saved when the selection moves; export saves first.
	[Test]
	public static void EditsApplyAsMadeAndSaveWhenTheSelectionMovesExportSavesFirst()
	{
		let f = scope Fixture();
		let dialog = new ExportDialog(f.Context, f.Presets, f.Seams());
		defer dialog.ReleaseRef();
		Test.Assert(dialog.SelectedIndex == 0);

		dialog.NameField.SetText("Linux Desktop");
		dialog.NameField.OnTextChanged(dialog.NameField); // as typing does
		dialog.PruneField.IsChecked.Value = true;
		Test.Assert(f.Presets.At(0).Name == "Linux Desktop");
		Test.Assert(f.Presets.At(0).PruneToReachable);
		Test.Assert(f.Saves == 0);
		dialog.Select(1);
		Test.Assert(f.Saves == 1, "saved as the selection moved");
		dialog.Select(0);
		Test.Assert(f.Saves == 1, "nothing new to save");

		// Export saves what is pending, then runs the selected preset.
		dialog.PruneField.IsChecked.Value = false;
		dialog.ExportSelected();
		Test.Assert(f.Saves == 2);
		Test.Assert(f.Exported.Count == 1);
		Test.Assert(f.Exported[0] == "Linux Desktop");
		Test.Assert(!f.ExportedAll);
	}

	/// A preset holds the game its own way (a phone-facing Web preset says Landscape), and the
	/// dialog shows the preset's choice again when it is selected.
	[Test]
	public static void APresetOverridesTheOrientation()
	{
		let f = scope Fixture();
		let dialog = new ExportDialog(f.Context, f.Presets, f.Seams());
		defer dialog.ReleaseRef();
		Test.Assert(dialog.SelectedIndex == 0);
		Test.Assert(!dialog.OrientationOverrideField.IsChecked.Value);
		Test.Assert(dialog.OrientationField.SelectedIndex == (int32)ScreenOrientation.Any);

		dialog.OrientationOverrideField.IsChecked.Value = true;
		dialog.OrientationField.SetSelectedIndex((int32)ScreenOrientation.Landscape);
		Test.Assert(f.Presets.At(0).OverridesOrientation);
		Test.Assert(f.Presets.At(0).Orientation == .Landscape);
		Test.Assert(!f.Presets.At(1).OverridesOrientation);

		// The other preset shows its own; coming back shows this one's again.
		dialog.Select(1);
		Test.Assert(!dialog.OrientationOverrideField.IsChecked.Value);
		Test.Assert(dialog.OrientationField.SelectedIndex == (int32)ScreenOrientation.Any);
		dialog.Select(0);
		Test.Assert(dialog.OrientationOverrideField.IsChecked.Value);
		Test.Assert(dialog.OrientationField.SelectedIndex == (int32)ScreenOrientation.Landscape);
	}

	/// Add takes the host's platform, Duplicate names the copy, Remove keeps a neighbour
	/// selected; each saves.
	[Test]
	public static void AddDuplicateAndRemovePresets()
	{
		let f = scope Fixture();
		let dialog = new ExportDialog(f.Context, f.Presets, f.Seams());
		defer dialog.ReleaseRef();

		dialog.AddPreset();
		Test.Assert(dialog.PresetCount == 3);
		Test.Assert(dialog.SelectedIndex == 2);
		Test.Assert(f.Presets.At(2).Platform == "Linux64", "the host's");
		Test.Assert(dialog.NameField.Text == "New Preset");

		dialog.Select(0);
		dialog.DuplicateSelected();
		Test.Assert(dialog.PresetCount == 4);
		Test.Assert(dialog.SelectedIndex == 3);
		Test.Assert(f.Presets.At(3).Name == "Linux Copy");

		dialog.RemoveSelected();
		Test.Assert(dialog.PresetCount == 3);
		Test.Assert(dialog.SelectedIndex == 2);
		Test.Assert(f.Saves >= 3);

		dialog.ExportAll();
		Test.Assert(f.ExportedAll);
	}
}
