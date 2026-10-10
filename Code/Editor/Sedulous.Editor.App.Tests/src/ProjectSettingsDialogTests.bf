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

	/// Every view of type T under `view`, in tree order, through the visual children: a
	/// dialog's layout and a scroll view's content are those.
	private static void Collect<T>(View view, List<T> outViews) where T : View
	{
		if (let typed = view as T)
			outViews.Add(typed);
		if (let group = view as ViewGroup)
		{
			for (int i < group.VisualChildCount)
			{
				if (let child = group.GetVisualChild(i))
					Collect(child, outViews);
			}
		}
	}

	/// The display settings are rows the dialog builds from their reflection (a field per
	/// size, a combo per enum, a check box per flag), seeded from the manifest; Save writes
	/// their edits back, a size clamped to its range.
	[Test]
	public static void NumberChoiceAndFlagRowsSaveTheirEdits()
	{
		RemoveDirectoryRecursive("settings_dialog_values");
		defer RemoveDirectoryRecursive("settings_dialog_values");
		Test.Assert(EditorProject.Create("settings_dialog_values", "P") case .Ok);
		let project = EditorProject.Open("settings_dialog_values");
		Test.Assert(project != null);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		{
			let dialog = new ProjectSettingsDialog(context);
			defer dialog.ReleaseRef();
			let numbers = scope List<NumericField>();
			let choices = scope List<ComboBox>();
			let flags = scope List<CheckBox>();
			let buttons = scope List<Button>();
			Collect(dialog, numbers);
			Collect(dialog, choices);
			Collect(dialog, flags);
			Collect(dialog, buttons);
			// Render width, height; window width, height. MSAA's own, then render fit and
			// window mode, in the settings' order.
			Test.Assert(numbers.Count == 4);
			Test.Assert(choices.Count == 3);
			Test.Assert(flags.Count == 1);
			Test.Assert(numbers[2].Value == 1280.0, "seeded from the manifest");
			Test.Assert(choices[1].SelectedIndex == (int32)FitMode.Letterbox);
			Test.Assert(flags[0].IsChecked.Value);

			numbers[0].SetValue(640.0);
			numbers[1].SetValue(360.0);
			numbers[2].SetValue(0.0); // a window takes at least one pixel: the range clamps
			choices[1].SetSelectedIndex((int32)FitMode.IntegerScale);
			choices[2].SetSelectedIndex((int32)WindowMode.Fullscreen);
			flags[0].IsChecked.Value = false;
			Button save = null;
			for (let button in buttons)
			{
				if (button.Text.Value == "Save")
					save = button;
			}
			Test.Assert(save != null);
			save.FireClick();
		}
		let settings = project.Settings;
		Test.Assert(settings.RenderWidth == 640);
		Test.Assert(settings.RenderHeight == 360);
		Test.Assert(settings.WindowWidth == 1);
		Test.Assert(settings.RenderFit == .IntegerScale);
		Test.Assert(settings.WindowMode == .Fullscreen);
		Test.Assert(!settings.WindowResizable);
	}

	/// An asset list setting (the other UI fonts) is a list of slots, one per entry the
	/// manifest holds, beside a slot per single asset setting.
	[Test]
	public static void AnAssetListSettingIsASlotPerEntry()
	{
		RemoveDirectoryRecursive("settings_dialog_lists");
		defer RemoveDirectoryRecursive("settings_dialog_lists");
		Test.Assert(EditorProject.Create("settings_dialog_lists", "P") case .Ok);
		let project = EditorProject.Open("settings_dialog_lists");
		Test.Assert(project != null);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);

		var single = 0;
		let fields = scope List<System.Reflection.FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		for (let field in fields)
		{
			SettingFields.KindOf(field, let kind);
			single += (kind == .Asset) ? 1 : 0;
		}
		{
			let dialog = new ProjectSettingsDialog(context);
			defer dialog.ReleaseRef();
			let slots = scope List<AssetPickerSlot>();
			Collect(dialog, slots);
			Test.Assert(slots.Count == single, "the list is empty");
		}
		project.Settings.UiFontIds.Add(Guid.Create());
		project.Settings.UiFontIds.Add(Guid.Create());
		{
			let dialog = new ProjectSettingsDialog(context);
			defer dialog.ReleaseRef();
			let slots = scope List<AssetPickerSlot>();
			Collect(dialog, slots);
			Test.Assert(slots.Count == single + 2, "a slot per listed font");
		}
	}

	private static bool HasLabel(TabView tabs, int32 tab, StringView text)
	{
		if ((tab < 0) || (tab >= tabs.TabCount))
			return false;
		let labels = scope List<Label>();
		Collect(tabs.GetTab(tab).Content, labels);
		for (let label in labels)
		{
			if (label.Text.Value == text)
				return true;
		}
		return false;
	}

	/// A tab per category the settings name (as Preferences has), in the order they first name
	/// them; every setting's label is on its category's tab, MSAA on Display's, and the engine
	/// version on General's.
	[Test]
	public static void ATabPerCategoryTheSettingsName()
	{
		RemoveDirectoryRecursive("settings_dialog_tabs");
		defer RemoveDirectoryRecursive("settings_dialog_tabs");
		Test.Assert(EditorProject.Create("settings_dialog_tabs", "P") case .Ok);
		let project = EditorProject.Open("settings_dialog_tabs");
		Test.Assert(project != null);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);

		let dialog = new ProjectSettingsDialog(context);
		defer dialog.ReleaseRef();
		let tabs = dialog.Tabs;
		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(dialog.TabIndexOf(SettingFields.cDefaultCategory) == 0);

		// The categories, as the settings name them, in first-named order: one tab each.
		let fields = scope List<System.Reflection.FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let categories = scope List<StringView>();
		for (let field in fields)
		{
			let category = SettingFields.Category(field);
			if (!categories.Contains(category))
				categories.Add(category);
		}
		Test.Assert(categories.Count > 1);
		Test.Assert(tabs.TabCount == categories.Count);
		for (int i < categories.Count)
			Test.Assert(dialog.TabIndexOf(categories[i]) == i, scope String(categories[i]));

		// Each setting's label is on its category's tab.
		for (let field in fields)
		{
			let label = SettingFields.Setting(field).Value.Label;
			Test.Assert(HasLabel(tabs, dialog.TabIndexOf(SettingFields.Category(field)), label), label);
		}
		Test.Assert(HasLabel(tabs, 0, "Engine version"));
		Test.Assert(HasLabel(tabs, dialog.TabIndexOf("Display"), "MSAA"));
		Test.Assert(!HasLabel(tabs, 0, "MSAA"));
	}

	/// Whether `dialog` measures to one size whichever of its tabs shows.
	private static bool OneSizeAcrossTabs(Dialog dialog, TabView tabs)
	{
		Float2? first = null;
		for (int32 i < tabs.TabCount)
		{
			tabs.SetSelectedIndex(i);
			dialog.Measure(.(dialog.MinWidth.Value, dialog.MaxWidth.Value, dialog.MinHeight.Value, dialog.MaxHeight.Value));
			if (first == null)
				first = dialog.MeasuredSize;
			else if ((Math.Abs(dialog.MeasuredSize.X - first.Value.X) > 0.01f) || (Math.Abs(dialog.MeasuredSize.Y - first.Value.Y) > 0.01f))
				return false;
		}
		return tabs.TabCount > 1;
	}

	/// A tab view measures only the page it shows, so a settings dialog whose width or height
	/// may vary changed size as the tabs did: Preferences and Project Settings keep one size.
	[Test]
	public static void SettingsDialogsKeepOneSizeWhicheverTabShows()
	{
		RemoveDirectoryRecursive("settings_dialog_size");
		defer RemoveDirectoryRecursive("settings_dialog_size");
		Test.Assert(EditorProject.Create("settings_dialog_size", "P") case .Ok);
		let project = EditorProject.Open("settings_dialog_size");
		Test.Assert(project != null);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		let store = scope Sedulous.Settings.Settings();

		let preferences = new EditorPreferencesDialog(context, store);
		defer preferences.ReleaseRef();
		Test.Assert(OneSizeAcrossTabs(preferences, preferences.Tabs));
		let settings = new ProjectSettingsDialog(context);
		defer settings.ReleaseRef();
		Test.Assert(OneSizeAcrossTabs(settings, settings.Tabs));
	}
}
