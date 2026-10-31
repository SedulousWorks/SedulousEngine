using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Project Settings over its markup (Data/Editor/ProjectSettings.xml): the manifest's labelled
/// settings as the grid's rows, in their categories; an asset setting a reference to the source
/// type it names (its slot), a list setting a list of them, an enum its choices by name, MSAA the
/// render subsystem's levels, the project's engine version read only; Save writing the rows back
/// (a list's empty and repeated entries dropped) and persisting, Cancel leaving the manifest as it
/// was. Then what Sedulous adds so each behaviour has a test: the sections in the order the
/// settings first name them, each row by its label in the reflected order; a number in its range,
/// a check box, a text; MSAA's levels by their samples; the version the project's own stamp, its
/// row refusing an edit; a list's elements slots of the type it names; the context's table taking
/// a scene reference's type itself; Save keeping the path mirrors and telling the editor once, its
/// button saving; Cancel's button and the window's close leaving the manifest, nothing told.
class ProjectSettingsTests
{
	/// The dialog's body, read from the repository's Data with the elements the editor's window
	/// registers (the grid is the toolkit's); its one reference is the caller's.
	private static Node LoadSettings()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let path = PathJoin(data, ProjectSettingsDialog.cMarkupPath, .. scope .());
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	private static String Text(Guid id, String outText)
	{
		id.ToString(outText);
		return outText;
	}

	/// A project named Settings, its default scene a scene of its own, one other UI font, MSAA 4x
	/// and an older engine's stamp; the dialog open over a GUI scene, its slots over services of
	/// their own; the times the editor was told of a save.
	private class Bed
	{
		public const String cDir = "scratch_project_settings";
		public const String cOldStamp = "0.0.1-older";
		public static readonly Guid sFont = Guid(0xf0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);

		public EditorProject Project;
		public EditorContext Context = new .();
		/// Outlives the dialog: its slots borrow it.
		public ResourceRefServices Refs = new .();
		public SceneRoot Root;
		public ProjectSettingsDialog Dialog;
		public Guid Scene;
		public String ScenePath = new .() ~ delete _;
		public int Changed = 0;

		public this()
		{
			RemoveDirectoryRecursive(cDir);
			Test.Assert(EditorProject.Create(cDir, "Settings") case .Ok);
			Project = EditorProject.Open(cDir);
			Test.Assert(Project != null);
			let scene = Project.SourceDb.RootGroup.CreateInstance("Level", typeof(Sedulous.Scene.Resource.SceneDocument).GetFullName(.. scope .()));
			Test.Assert(scene != null);
			Scene = scene.Id;
			scene.GetPath(ScenePath);
			let settings = Project.Settings;
			settings.DefaultSceneId = Scene;
			settings.UiFontIds.Add(sFont);
			settings.RenderMsaaSamples = 4;
			settings.EngineVersion.Set(cOldStamp);
			Context.SetProject(Project);
			Context.OnProjectSettingsChanged = new [=this] () => { Changed++; };
			let gui = new GUIContext();
			Root = new SceneRoot(gui);
			gui.ReleaseRef(); // the root's keeps it
			Root.Size = .(900.0f, 700.0f);
			Dialog = new ProjectSettingsDialog(Context, Refs, LoadSettings());
			Test.Assert(Dialog.Open(Root));
			Root.UpdateLayout();
		}

		public ~this()
		{
			delete Dialog; // closed while the root is there, before the services its slots borrow
			Root.ReleaseRef();
			Context.SetProject(null);
			delete Context;
			delete Refs;
			delete Project;
			RemoveDirectoryRecursive(cDir);
		}

		public Sedulous.GUI.PropertyBag Bag => Dialog.Rows;

		/// One edit of `path` to `value`, as a row's gesture ends.
		public void Edit(StringView path, Sedulous.GUI.Variant value)
		{
			Bag.BeginEdit(path);
			Bag.CommitEdit(path, PropertyWrite(value));
		}

		/// Whether `path`'s value is the text `expected`.
		public bool TextIs(StringView path, StringView expected)
		{
			var value = Bag.GetValue(path, 0);
			defer value.Dispose();
			return value.AsString == expected;
		}

		public int64 IntAt(StringView path)
		{
			var value = Bag.GetValue(path, 0);
			defer value.Dispose();
			return value.AsInt;
		}

		/// Whether the grid's editor for `info` is the inspector's asset slot.
		public bool IsSlot(PropertyInfo info)
		{
			let editors = Dialog.Grid.Editors;
			let made = editors.Create(editors.Choose(info));
			defer made.ReleaseRef();
			return made is ResourceRefEditor;
		}

		public Sedulous.GUI.Button FindButton(StringView id) => Dialog.Window.Content.FindElement(id) as Sedulous.GUI.Button;
	}

	[Test]
	public static void TheLabelledSettingsAsRowsInTheirCategoriesAssetsAsReferencesToTheTypeTheyNameChoicesByName()
	{
		let bed = scope Bed();
		let bag = bed.Bag;
		let name = bag.FindInfo("name");
		Test.Assert(name != null);
		Test.Assert(name.DisplayName == "Name");
		Test.Assert(name.Category == "General");
		Test.Assert(bed.TextIs("name", "Settings"));

		let scene = bag.FindInfo("defaultSceneId");
		Test.Assert(scene != null);
		Test.Assert(scene.Kind == .Reference);
		Test.Assert(scene.ReferenceType == typeof(Sedulous.Scene.Resource.SceneDocument));
		Test.Assert(scene.Category == "Startup");
		Test.Assert(bed.TextIs("defaultSceneId", Text(bed.Scene, .. scope .())));
		Test.Assert(bed.IsSlot(scene), "its slot");

		let fonts = bag.FindInfo("uiFontIds");
		Test.Assert(fonts != null);
		Test.Assert(fonts.Kind == .List);
		Test.Assert(bag.ElementCount("uiFontIds", 0) == 1);
		Test.Assert(bed.TextIs("uiFontIds.0", Text(Bed.sFont, .. scope .())));

		let msaa = bag.FindInfo(ProjectSettingsDialog.cMsaaSetting);
		Test.Assert(msaa != null);
		Test.Assert(msaa.Kind == .Enum);
		Test.Assert(msaa.Choices.Count == 3);
		Test.Assert(msaa.Choices[2].Name == "4x");
		Test.Assert(bed.IntAt(ProjectSettingsDialog.cMsaaSetting) == 4);

		let mode = bag.FindInfo("windowMode");
		Test.Assert(mode != null);
		Test.Assert(mode.Kind == .Enum);
		Test.Assert(mode.Choices[0].Name == "Windowed");

		let width = bag.FindInfo("windowWidth");
		Test.Assert(width != null);
		Test.Assert(width.HasRange);
		Test.Assert(width.Min == 1.0);

		let version = bag.FindInfo(ProjectSettingsDialog.cEngineVersionRow);
		Test.Assert(version != null);
		Test.Assert(version.ReadOnly);
	}

	[Test]
	public static void SaveWritesTheRowsBackAListsEmptyAndRepeatedEntriesDroppedAndPersistsCancelLeavesIt()
	{
		let bed = scope Bed();
		bed.Edit("name", Sedulous.GUI.Variant("Renamed"));
		// Cancel first: the manifest is as it was.
		bed.Dialog.Close();
		Test.Assert(bed.Project.Settings.Name == "Settings");
		Test.Assert(bed.Project.Settings.DefaultSceneId == bed.Scene);

		Test.Assert(bed.Dialog.Open(bed.Root));
		Test.Assert(bed.TextIs("name", "Settings"), "the rows again, from the manifest");
		bed.Edit("name", Sedulous.GUI.Variant("Renamed"));
		bed.Edit("defaultSceneId", Sedulous.GUI.Variant(StringView()));
		bed.Edit(ProjectSettingsDialog.cMsaaSetting, Sedulous.GUI.Variant((int64)2));
		bed.Bag.ResizeList("uiFontIds", 0, 3);
		bed.Bag.SetValue("uiFontIds.1", 0, Sedulous.GUI.Variant(Text(Bed.sFont, .. scope .())));
		Test.Assert(bed.Dialog.Save());
		Test.Assert(!bed.Dialog.IsOpen);
		let saved = bed.Project.Settings;
		Test.Assert(saved.Name == "Renamed");
		Test.Assert(saved.DefaultSceneId.IsNil);
		Test.Assert(saved.RenderMsaaSamples == 2);
		Test.Assert(saved.UiFontIds.Count == 1);
		Test.Assert(saved.UiFontIds[0] == Bed.sFont);

		// Persisted: a project opened again reads it.
		let again = EditorProject.Open(Bed.cDir);
		Test.Assert(again != null);
		defer delete again;
		Test.Assert(again.Settings.Name == "Renamed");
		Test.Assert(again.Settings.RenderMsaaSamples == 2);
		Test.Assert((again.Settings.UiFontIds.Count == 1) && (again.Settings.UiFontIds[0] == Bed.sFont));
	}

	/// A section per category the settings name, in the order they first name them (General, the
	/// engine version's, among them); each setting a row by its label in its category, the rows in
	/// the reflected order, the engine version after them.
	[Test]
	public static void ASectionPerCategoryInTheOrderTheSettingsFirstNameThemEachRowByItsLabel()
	{
		let bed = scope Bed();
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let categories = scope List<StringView>();
		for (let field in fields)
		{
			let category = SettingFields.Category(field);
			if (!categories.Contains(category))
				categories.Add(category);
		}
		Test.Assert(categories.Count > 1);
		Test.Assert(categories[0] == SettingFields.cDefaultCategory);

		// The grid's section headers, in their order.
		let grid = bed.Dialog.Grid;
		let headers = scope List<String>();
		defer { ClearAndDeleteItems!(headers); }
		for (int32 i < (int32)grid.RowCount)
		{
			let row = grid.GetRow(i);
			if (row.Category)
				headers.Add(new String(row.Info.Name));
		}
		Test.Assert(headers.Count == categories.Count);
		for (int i < categories.Count)
			Test.Assert(headers[i] == categories[i], scope String(categories[i]));

		// The rows in the reflected order, each by its label in its category.
		let infos = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(infos); }
		bed.Bag.GetProperties(default, infos);
		Test.Assert(infos.Count == fields.Count + 1, "a row per setting, and the engine version");
		let key = scope String();
		for (int i < fields.Count)
		{
			SettingFields.Key(fields[i], key..Clear());
			Test.Assert(infos[i].Name == key, scope String(key));
			Test.Assert(infos[i].DisplayName == StringView(SettingFields.Setting(fields[i]).Value.Label), scope String(key));
			Test.Assert(infos[i].Category == SettingFields.Category(fields[i]), scope String(key));
		}
		Test.Assert(infos.Back.Name == ProjectSettingsDialog.cEngineVersionRow);
		Test.Assert(infos.Back.Category == SettingFields.cDefaultCategory);
	}

	/// Each kind of row: a text, a number within its range, a check box, an enum by its cases'
	/// names and values, MSAA by the render subsystem's levels and their samples, the engine version
	/// as the project's own stamp, read only, refusing an edit.
	[Test]
	public static void EachKindOfRowMsaaTheLevelsTheEngineVersionTheProjectsStampReadOnly()
	{
		let bed = scope Bed();
		let bag = bed.Bag;
		let module = bag.FindInfo("nativeModule");
		Test.Assert((module != null) && (module.Kind == .String));
		Test.Assert(module.Category == "General");

		let height = bag.FindInfo("windowHeight");
		Test.Assert((height != null) && (height.Kind == .Integer));
		Test.Assert(height.HasRange);
		Test.Assert((height.Min == 1.0) && (height.Max == 16384.0) && (height.Step == 1.0));
		Test.Assert(bed.IntAt("windowHeight") == 720);
		let render = bag.FindInfo("renderWidth");
		Test.Assert(render.HasRange && (render.Min == 0.0), "its own range");

		let resizable = bag.FindInfo("windowResizable");
		Test.Assert((resizable != null) && (resizable.Kind == .Bool));
		var flag = bag.GetValue("windowResizable", 0);
		Test.Assert(flag.AsBool);
		flag.Dispose();

		let fit = bag.FindInfo("renderFit");
		Test.Assert((fit != null) && (fit.Kind == .Enum));
		int cases = 0;
		for (let caseName in Enum.GetNames(typeof(FitMode)))
			cases++;
		Test.Assert(fit.Choices.Count == cases);
		let letterbox = scope String();
		FitMode.Letterbox.ToString(letterbox);
		bool named = false;
		for (let choice in fit.Choices)
			named = named || ((choice.Name == letterbox) && (choice.Value == (int64)FitMode.Letterbox));
		Test.Assert(named, "a case by its name and value");
		Test.Assert(bed.IntAt("renderFit") == (int64)FitMode.Letterbox);

		// MSAA: the levels, each by its label and its samples, not the counts a number takes.
		let msaa = bag.FindInfo(ProjectSettingsDialog.cMsaaSetting);
		Test.Assert(msaa.Category == "Display");
		Test.Assert(msaa.Choices.Count == Sedulous.Engine.Render.MsaaLevels.All.Count);
		for (int i < msaa.Choices.Count)
		{
			Test.Assert(msaa.Choices[i].Name == Sedulous.Engine.Render.MsaaLevels.All[i].Label);
			Test.Assert(msaa.Choices[i].Value == (int64)Sedulous.Engine.Render.MsaaLevels.All[i].Samples);
		}

		// The project's own stamp, not the running engine's; an edit of it is refused.
		let version = bag.FindInfo(ProjectSettingsDialog.cEngineVersionRow);
		Test.Assert(version.Kind == .String);
		Test.Assert(version.DisplayName == "Engine version");
		Test.Assert(bed.TextIs(ProjectSettingsDialog.cEngineVersionRow, Bed.cOldStamp));
		bed.Edit(ProjectSettingsDialog.cEngineVersionRow, Sedulous.GUI.Variant("9.9.9"));
		Test.Assert(bed.TextIs(ProjectSettingsDialog.cEngineVersionRow, Bed.cOldStamp));
	}

	/// An asset setting's row and each element of an asset list's are the inspector's slot, a
	/// reference to the source type the setting names; the context's table takes that type itself,
	/// as no builder makes it.
	[Test]
	public static void AssetRowsAndAListsElementsAreSlotsOfTheTypeTheSettingNames()
	{
		let bed = scope Bed();
		let bag = bed.Bag;
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		bag.GetProperties("uiFontIds", elements);
		Test.Assert(elements.Count == 1);
		Test.Assert(elements[0].Kind == .Reference);
		Test.Assert(elements[0].ReferenceType == typeof(Sedulous.Fonts.Pipeline.FontAsset));
		Test.Assert(bed.IsSlot(elements[0]), "a list's element is a slot");
		let sheets = bag.FindInfo("guiStyleSheetIds");
		Test.Assert((sheets != null) && (sheets.Kind == .List), "every asset list a list");

		// Every single asset setting a slot of its own.
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let key = scope String();
		int assets = 0;
		for (let field in fields)
		{
			SettingFields.KindOf(field, let kind);
			if (kind != .Asset)
				continue;
			SettingFields.Key(field, key..Clear());
			let info = bag.FindInfo(key);
			Test.Assert((info != null) && (info.Kind == .Reference) && bed.IsSlot(info), scope String(key));
			assets++;
		}
		Test.Assert(assets > 1);

		// The context's table: the scene's type, which no builder makes, taken itself.
		let icons = scope EditorIcons(new (path) => false);
		let services = ResourceRefServices.From(bed.Context, icons, null);
		defer delete services;
		let types = scope List<String>();
		defer { ClearAndDeleteItems!(types); }
		services.AcceptedTypes(bag.FindInfo("defaultSceneId").ReferenceType, types);
		Test.Assert(types.Count == 1);
		Test.Assert(types[0] == "SceneDocument");
	}

	/// Save keeps the path mirrors beside the guids and tells the editor once; its button saves.
	/// Cancel's button and the window's own close leave the manifest, nothing told.
	[Test]
	public static void ACountBeyondItsRangeIsHeldWithinItOnSave()
	{
		let bed = scope Bed();
		// The bag keeps whatever it is given: Save holds a count within the setting's range.
		bed.Edit("windowHeight", Sedulous.GUI.Variant((int64)100000));
		Test.Assert(bed.Dialog.Save());
		Test.Assert(bed.Project.Settings.WindowHeight == 16384, "held at its most");
	}

	[Test]
	public static void SaveKeepsThePathMirrorsAndTellsTheEditorCancelAndClosingLeaveTheManifest()
	{
		let bed = scope Bed();
		let settings = bed.Project.Settings;
		Test.Assert(settings.DefaultScene.IsEmpty, "no mirror until a save");

		bed.Edit("name", Sedulous.GUI.Variant("Cancelled"));
		let cancel = bed.FindButton("settings-cancel");
		Test.Assert(cancel != null);
		Test.Assert(cancel.HandleActivate());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(settings.Name == "Settings");
		Test.Assert(bed.Changed == 0);

		Test.Assert(bed.Dialog.Open(bed.Root));
		bed.Edit("name", Sedulous.GUI.Variant("Closed"));
		bed.Dialog.Window.Close(); // its close button, Escape
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(settings.Name == "Settings");
		Test.Assert(bed.Changed == 0);

		Test.Assert(bed.Dialog.Open(bed.Root));
		let save = bed.FindButton("settings-save");
		Test.Assert(save != null);
		Test.Assert(save.HandleActivate());
		Test.Assert(!bed.Dialog.IsOpen);
		Test.Assert(settings.DefaultSceneId == bed.Scene);
		Test.Assert(settings.DefaultScene == bed.ScenePath, "the path kept beside the guid");
		Test.Assert(bed.Changed == 1, "the editor told once");

		// Cleared, its mirror goes with it.
		Test.Assert(bed.Dialog.Open(bed.Root));
		bed.Edit("defaultSceneId", Sedulous.GUI.Variant(StringView()));
		Test.Assert(bed.Dialog.Save());
		Test.Assert(settings.DefaultScene.IsEmpty);
		Test.Assert(bed.Changed == 2);
	}
}
