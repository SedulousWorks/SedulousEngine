using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App.Tests;

/// The Project Settings dialog builds its rows from the settings' reflection: a row per
/// [Setting], each seeded from the manifest and written back by Save.
static class ProjectSettingsDialogTests
{
	[Test]
	public static void EverySettingHasARowSeededFromTheManifestAndSaveWritesItBack()
	{
		RemoveDirectoryRecursive("settings_dialog_project");
		defer RemoveDirectoryRecursive("settings_dialog_project");
		Test.Assert(EditorProject.Create("settings_dialog_project", "Dialog") case .Ok);
		let project = EditorProject.Open("settings_dialog_project");
		Test.Assert(project != null);
		defer delete project;
		let settings = project.Settings;
		let font = Guid.Create();
		settings.NativeModule.Set("Native/game.so");
		settings.WindowMode = .Borderless;
		settings.RenderFit = .Crop;
		settings.WindowWidth = 800;
		settings.WindowResizable = false;
		settings.RenderMsaaSamples = 4;
		settings.UiFontIds.Add(font);

		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		let dialog = new ProjectSettingsDialog(context);
		defer dialog.ReleaseRef();

		// A row per setting: the assets and the list as slots, MSAA its own, the rest values.
		let fields = scope List<System.Reflection.FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let assets = dialog.[Friend]mAssets;
		let lists = dialog.[Friend]mAssetLists;
		let values = dialog.[Friend]mValues;
		Test.Assert(assets.Count == 7);
		Test.Assert(lists.Count == 1);
		Test.Assert(assets.Count + lists.Count + values.Count + 1 == fields.Count);

		// Saved untouched, every setting is what it was.
		dialog.[Friend]Apply();
		Test.Assert(settings.NativeModule == "Native/game.so");
		Test.Assert(settings.WindowMode == .Borderless);
		Test.Assert(settings.RenderFit == .Crop);
		Test.Assert(settings.WindowWidth == 800);
		Test.Assert(!settings.WindowResizable);
		Test.Assert(settings.RenderMsaaSamples == 4);
		Test.Assert((settings.UiFontIds.Count == 1) && (settings.UiFontIds[0] == font));

		// A choice changed in its row is what Save writes.
		for (let value in values)
		{
			if (value.Field.Name == "WindowMode")
				value.Choice.SetSelectedIndex(1);
		}
		dialog.[Friend]Apply();
		Test.Assert(settings.WindowMode == .Fullscreen);
	}
}
