using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image.IO;
using Sedulous.GUI;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The Project page over its markup (Data/Editor/ProjectHome.xml): the project's name, the scenes
/// (the assets of the default scene setting's type) as links that open them, the default scene's
/// button opening it, every setting by its label under its category (title case, as the settings
/// name them), an asset by its name, an unset one by its empty text, a missing one in the warning
/// colour, the Game and Project menus' actions as buttons that run through the registry, and the
/// page filled again when the settings are marked changed, when a cook lands and when the
/// thumbnail changes. The Project panel shows it while a project is open, the welcome after.
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

	/// The page's frame, read from the repository's Data with the GUI's elements; its one
	/// reference is the caller's.
	private static Node LoadHome()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let path = PathJoin(data, ProjectHomeView.cMarkupPath, .. scope .());
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(path, text) case .Ok);
		RegisterGuiElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// The value beside the setting labelled `label`; null when no row is.
	private static Node ValueOf(Node content, StringView label)
	{
		let settings = content.FindElement("home-settings");
		Test.Assert(settings != null);
		for (int i < settings.ChildCount)
		{
			let row = settings.GetChildAt(i);
			if (row.ChildCount != 2)
				continue;
			let name = row.GetChildAt(0) as Sedulous.GUI.Label;
			if ((name != null) && (name.Text == label))
				return row.GetChildAt(1);
		}
		return null;
	}

	private static EditorActionDeclaration Action(StringView id, StringView label, StringView menuPath, int32 order, int* runs)
	{
		let d = new EditorActionDeclaration(id, label, "", menuPath, order);
		d.Execute = new (page) => { (*runs)++; };
		return d;
	}

	/// A scratch project named Harbour with the scenes Docks (the default) and Arrival, and an
	/// asset of another type.
	private static EditorProject MakeProject(StringView dir)
	{
		RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Harbour") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		const String cScene = "Sedulous.Scene.Resource.SceneDocument";
		let docks = project.SourceDb.RootGroup.CreateInstance("Docks", cScene);
		Test.Assert(docks != null);
		Test.Assert(project.SourceDb.RootGroup.CreateInstance("Arrival", cScene) != null);
		// An asset of another type is not a scene.
		Test.Assert(project.SourceDb.RootGroup.CreateInstance("Controls", "Sedulous.Input.Pipeline.InputMapAsset") != null);
		project.Settings.DefaultSceneId = docks.Id;
		return project;
	}

	[Test]
	public static void TheScenesTheSettingsAndTheProjectsActions()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let project = MakeProject(dir);
		defer delete project;
		let docks = project.SourceDb.RootGroup.GetInstance("Docks");
		let arrival = project.SourceDb.RootGroup.GetInstance("Arrival");
		Test.Assert((docks != null) && (arrival != null));
		// An input map no asset is: missing.
		project.Settings.DefaultInputMapId = Guid.Create();

		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		int plays = 0;
		int exports = 0;
		int others = 0;
		bool playAllowed = true;
		// Registered out of menu order: the page orders them as the menu does.
		Test.Assert(context.Actions.Register(Action("test.export", "Export...", "Project/Export...", 300, &exports)));
		let play = Action("test.play", "Play", "Game/Play", 100, &plays);
		play.Enabled = new [&playAllowed](page) => playAllowed;
		Test.Assert(context.Actions.Register(play));
		Test.Assert(context.Actions.Register(Action("test.reset", "Reset Layout", "View/Reset Layout", 100, &others)));
		Test.Assert(context.Actions.Register(Action("test.settings", "Project Settings...", "Project/Project Settings...", 100, &others)));

		let content = LoadHome();
		Test.Assert(content != null);
		let home = scope ProjectHomeView(context, null, content);
		let opened = scope List<Guid>();
		home.SetOnOpenAsset(new [=opened](id) => { opened.Add(id); });
		let name = content.FindElement("home-name") as Sedulous.GUI.Label;
		Test.Assert((name != null) && (name.Text == "Harbour"));

		// The default scene's button opens it.
		let openDefault = content.FindElement("home-open-default") as Sedulous.GUI.Button;
		Test.Assert(openDefault != null);
		Test.Assert(openDefault.Text == "Open Docks");
		Test.Assert(openDefault.Enabled);
		Test.Assert(openDefault.HandleActivate());
		Test.Assert(opened.Count == 1);
		Test.Assert(opened[0] == docks.Id);

		// Each scene a link that opens it, the default one marked.
		let heading = content.FindElement("home-scenes-heading") as Sedulous.GUI.Label;
		Test.Assert((heading != null) && (heading.Text == "Scenes (2)"));
		let scenes = content.FindElement("home-scenes");
		Test.Assert(scenes != null);
		Test.Assert(scenes.ChildCount == 2);
		let first = scenes.GetChildAt(0) as Sedulous.GUI.Button;
		Test.Assert(first != null);
		Test.Assert(first.Text == "Arrival");
		Test.Assert(first.HandleActivate());
		Test.Assert(opened.Back == arrival.Id);
		let second = scenes.GetChildAt(1) as Sedulous.GUI.Button;
		Test.Assert((second != null) && (second.Text == "Docks (default)"));

		// The Game menu's actions as buttons that run them, through the registry: one the registry
		// no longer allows does not run.
		let game = content.FindElement("home-game-actions");
		Test.Assert(game != null);
		Test.Assert(game.ChildCount == 1);
		let playButton = game.GetChildAt(0) as Sedulous.GUI.Button;
		Test.Assert((playButton != null) && (playButton.Text == "Play"));
		Test.Assert(playButton.HandleActivate());
		Test.Assert(plays == 1);
		playAllowed = false;
		playButton.HandleActivate();
		Test.Assert(plays == 1, "the registry refuses what it does not allow");
		playAllowed = true;
		let projectActions = content.FindElement("home-project-actions");
		Test.Assert((projectActions != null) && (projectActions.ChildCount == 2));

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

		// An asset the project does not hold, in the warning colour; one it holds, a link to it.
		Test.Assert(Has(home.SettingRows, "Default input map: (missing)"));
		let missing = ValueOf(content, "Default input map") as Sedulous.GUI.Label;
		Test.Assert(missing != null);
		Test.Assert(missing.Text == "(missing)");
		Test.Assert(missing.HasClass("missing"));
		let defaultScene = ValueOf(content, "Default scene") as Sedulous.GUI.Button;
		Test.Assert((defaultScene != null) && defaultScene.HasClass("link") && (defaultScene.Text == "Docks"));
		let unset = ValueOf(content, "Default bus layout") as Sedulous.GUI.Label;
		Test.Assert((unset != null) && !unset.HasClass("missing") && unset.HasClass("dim"));

		// The categories in the order the settings first name them, in title case as they name
		// them.
		let categories = scope List<StringView>();
		let settings = content.FindElement("home-settings");
		for (int i < settings.ChildCount)
		{
			let category = settings.GetChildAt(i) as Sedulous.GUI.Label;
			if ((category != null) && category.HasClass("home-category"))
				categories.Add(category.Text);
		}
		Test.Assert(categories.Count == 5);
		Test.Assert((categories[0] == "General") && (categories[1] == "Startup") && (categories[2] == "Audio")
			&& (categories[3] == "UI") && (categories[4] == "Display"));

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
		Test.Assert(openDefault.Text == "Open Arrival");

		// Without a project, nothing to show.
		context.SetProject(null);
		home.Rebuild();
		Test.Assert(home.Scenes.IsEmpty && home.SettingRows.IsEmpty);
	}

	/// A cook that lands fills the page again (a new scene listed), as does a new thumbnail (the
	/// initial's tile giving way to the picture); neither marked changed.
	[Test]
	public static void ACookThatLandsOrANewThumbnailFillsItAgain()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home_refill", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let project = MakeProject(dir);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		let builders = scope BuilderRegistry(); // nothing buildable: an empty plan
		let cook = scope EditorCookService();
		cook.Initialize(project, builders);

		let content = LoadHome();
		Test.Assert(content != null);
		let home = scope ProjectHomeView(context, cook, content);
		Test.Assert(home.Scenes.Count == 2);
		let slot = content.FindElement("home-picture");
		Test.Assert((slot != null) && (slot.ChildCount == 1));
		let tile = slot.GetChildAt(0) as Sedulous.GUI.Panel;
		Test.Assert((tile != null) && tile.HasClass("project-initial") && tile.HasClass("home-picture"));
		let initial = tile.GetChildAt(0) as Sedulous.GUI.Label;
		Test.Assert((initial != null) && (initial.Text == "H"));

		// A scene added: not shown until the cook lands.
		Test.Assert(project.SourceDb.RootGroup.CreateInstance("Beacon", "Sedulous.Scene.Resource.SceneDocument") != null);
		home.Refresh();
		Test.Assert(home.Scenes.Count == 2);
		cook.RequestCook(false);
		let watch = scope Stopwatch(true);
		while (((cook.Revision == 0) || !cook.IsIdle) && (watch.ElapsedMilliseconds < 60000))
		{
			cook.Update();
			Thread.Sleep(1);
		}
		Test.Assert(cook.Revision == 1);
		home.Refresh();
		Test.Assert(home.Scenes.Count == 3);
		Test.Assert(content.FindElement("home-scenes").ChildCount == 3);

		// A thumbnail written: the picture shows it at the next refresh.
		let thumbnail = EditorProject.ThumbnailPath(project.Directory, .. scope .());
		CreateDirectory(PathParent(thumbnail, .. scope .()));
		let picture = scope Sedulous.Image.Image(4, 4, .RGBA8);
		Test.Assert(ImageIO.SaveImage(picture, thumbnail, .PNG) case .Ok);
		home.Refresh();
		Test.Assert(slot.ChildCount == 1);
		let shown = slot.GetChildAt(0) as Sedulous.GUI.Image;
		Test.Assert((shown != null) && shown.HasClass("project-picture") && shown.HasClass("home-picture"));
		Test.Assert(shown.Drawable != null);
	}

	/// The Project panel shows the page while a project is open, over the session's hooks as the
	/// application gives them, and the welcome again once it closes.
	[Test]
	public static void TheProjectPanelShowsThePageWhileAProjectIsOpenAndTheWelcomeAfter()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home_panel", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Harbour") case .Ok);
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();

		let bed = scope DockBed();
		let holder = bed.Dock.Controller.Content(EditorDock.cPanelProject);
		Test.Assert((holder != null) && (holder.ChildCount == 1));
		Test.Assert(holder.GetChildAt(0) == bed.Welcome);

		let context = scope EditorContext();
		let builders = scope BuilderRegistry();
		let cook = scope EditorCookService();
		let jobs = scope EditorJobService();
		let thumbnails = scope ThumbnailService();
		ProjectHomeView home = null;
		let services = new EditorSessionServices();
		services.Context = context;
		services.Cook = cook;
		services.Jobs = jobs;
		services.Builders = builders;
		services.Thumbnails = thumbnails;
		// As the application's hooks do.
		services.OnOpened = new [&home, =context, =cook, =bed](project) =>
			{
				home = new ProjectHomeView(context, cook, LoadHome());
				bed.Dock.SetProjectContent(home.Content);
			};
		services.OnClosing = new [&home, =bed]() =>
			{
				bed.Dock.SetProjectContent(null);
				DeleteAndNullify!(home);
			};
		let session = scope EditorSession(services);
		Test.Assert(session.Open(dir));
		Test.Assert(home != null);
		Test.Assert(holder.ChildCount == 1);
		Test.Assert(holder.GetChildAt(0) == home.Content);
		Test.Assert(bed.Welcome.Parent == null);
		let name = home.Content.FindElement("home-name") as Sedulous.GUI.Label;
		Test.Assert((name != null) && (name.Text == "Harbour"));

		session.Close();
		Test.Assert(home == null);
		Test.Assert(holder.ChildCount == 1);
		Test.Assert(holder.GetChildAt(0) == bed.Welcome);
	}
}
