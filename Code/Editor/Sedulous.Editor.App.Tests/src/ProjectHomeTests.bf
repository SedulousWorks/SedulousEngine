using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App.Tests;

/// The Project page: the project's scenes, its settings by their labels (an asset by its
/// name, an unset one by its empty text) and the Game and Project menus' actions, rebuilt
/// when marked changed.
class ProjectHomeTests
{
	private static bool Has(List<String> items, StringView item)
	{
		for (let entry in items)
		{
			if (entry == item)
				return true;
		}
		return false;
	}

	private static EditorActionDeclaration Action(StringView id, StringView label, StringView menuPath, int32 order, int* runs)
	{
		let d = new EditorActionDeclaration(id, label, "", menuPath, order);
		d.Execute = new (page) => { (*runs)++; };
		return d;
	}

	[Test]
	public static void TheScenesTheSettingsAndTheProjectsActions()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Harbour") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		const String cScene = "Sedulous.Scene.Resource.SceneDocument";
		let docks = project.SourceDb.RootGroup.CreateInstance("Docks", cScene);
		let arrival = project.SourceDb.RootGroup.CreateInstance("Arrival", cScene);
		Test.Assert((docks != null) && (arrival != null));
		// An asset of another type is not a scene.
		Test.Assert(project.SourceDb.RootGroup.CreateInstance("Controls", "Sedulous.Input.Pipeline.InputMapAsset") != null);
		project.Settings.DefaultSceneId = docks.Id;

		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		int plays = 0;
		int exports = 0;
		int others = 0;
		// Registered out of menu order: the page orders them as the menu does.
		Test.Assert(context.Actions.Register(Action("test.export", "Export...", "Project/Export...", 300, &exports)));
		Test.Assert(context.Actions.Register(Action("test.play", "Play", "Game/Play", 100, &plays)));
		Test.Assert(context.Actions.Register(Action("test.reset", "Reset Layout", "View/Reset Layout", 100, &others)));
		Test.Assert(context.Actions.Register(Action("test.settings", "Project Settings...", "Project/Project Settings...", 100, &others)));

		let home = scope ProjectHomeView(context, null);

		// Every scene, in the asset tree's order (by name).
		Test.Assert(home.Scenes.Count == 2);
		Test.Assert((home.Scenes[0] == arrival.Id) && (home.Scenes[1] == docks.Id));

		// Every labelled setting, an asset by its name, an unset one by its empty text.
		Test.Assert(Has(home.SettingRows, "Name: Harbour"));
		Test.Assert(Has(home.SettingRows, "Default scene: Docks"));
		Test.Assert(Has(home.SettingRows, "Default bus layout: (built-in)"));
		Test.Assert(Has(home.SettingRows, "MSAA: Off"));
		Test.Assert(Has(home.SettingRows, "Window mode: Windowed"));
		Test.Assert(Has(home.SettingRows, "Window resizable: On"));

		// The Game menu's actions, then the Project menu's, each in menu order; no others.
		Test.Assert(home.ActionIds.Count == 3);
		Test.Assert(home.ActionIds[0] == "test.play");
		Test.Assert(home.ActionIds[1] == "test.settings");
		Test.Assert(home.ActionIds[2] == "test.export");

		// A change to the settings shows at the next refresh, once marked.
		project.Settings.DefaultSceneId = arrival.Id;
		home.Refresh();
		Test.Assert(Has(home.SettingRows, "Default scene: Docks"));
		home.MarkChanged();
		home.Refresh();
		Test.Assert(Has(home.SettingRows, "Default scene: Arrival"));

		// Without a project, nothing to show.
		context.SetProject(null);
		home.Rebuild();
		Test.Assert(home.Scenes.IsEmpty && home.SettingRows.IsEmpty);
	}
}
