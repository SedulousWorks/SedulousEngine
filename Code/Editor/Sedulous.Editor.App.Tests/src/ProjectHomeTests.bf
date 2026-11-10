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

/// The Project page over its markup (Data/Editor/ProjectHome.xml): the project's name and summary
/// (location, engine version, the settings carrying a [SettingSummary] with an asset shown by its
/// name, an unset one by its empty text, a missing one in the warning colour, and the window), its
/// buttons, the scenes (the assets of the default scene setting's type) as cards that open them
/// with the default one marked, a project with no scenes, and the page filled again when the
/// settings are marked changed, when a cook lands and when the thumbnail changes. The Project panel
/// shows it while a project is open, the welcome after.
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

	/// The value beside the summary row labelled `label`; null when no row is.
	private static Node ValueOf(Node content, StringView label)
	{
		let summary = content.FindElement("home-summary");
		Test.Assert(summary != null);
		for (int i < summary.ChildCount)
		{
			let row = summary.GetChildAt(i);
			if (row.ChildCount != 2)
				continue;
			let name = row.GetChildAt(0) as Sedulous.GUI.Label;
			if ((name != null) && (name.Text == label))
				return row.GetChildAt(1);
		}
		return null;
	}

	/// Whether a card's picture carries the Default badge.
	private static bool Marked(Node card)
	{
		let picture = card.GetChildAt(0);
		for (int i < picture.ChildCount)
		{
			if (let label = picture.GetChildAt(i) as Sedulous.GUI.Label)
			{
				if (label.Text == "Default")
					return true;
			}
		}
		return false;
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
	public static void TheSummaryTheButtonsAndTheScenesAsCardsThatOpenThem()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let project = MakeProject(dir);
		defer delete project;
		let docks = project.SourceDb.RootGroup.GetInstance("Docks");
		let arrival = project.SourceDb.RootGroup.GetInstance("Arrival");
		Test.Assert((docks != null) && (arrival != null));
		// An input map no asset is: missing; no UI font: unset.
		project.Settings.DefaultInputMapId = Guid.Create();
		project.Settings.DefaultUiFontId = .Empty;

		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		let content = LoadHome();
		Test.Assert(content != null);
		let home = scope ProjectHomeView(context, null, content);
		let opened = scope List<Guid>();
		let shown = scope String();
		int settingsOpened = 0;
		int scenesMade = 0;
		home.SetOnOpenAsset(new [=opened] (id) => { opened.Add(id); });
		home.SetOnShowFolder(new [=shown] (folder) => { shown.Set(folder); });
		home.SetOnProjectSettings(new [&settingsOpened] () => { settingsOpened++; });
		home.SetOnNewScene(new [&scenesMade] () => { scenesMade++; });
		let name = content.FindElement("home-name") as Sedulous.GUI.Label;
		Test.Assert((name != null) && (name.Text == "Harbour"));

		// The summary: where it is, its engine, the settings marked for it (in declaration order),
		// and the window; no others.
		let rows = home.SummaryRows;
		Test.Assert(rows.Count == 6, scope $"{rows.Count} rows");
		Test.Assert(rows[0].StartsWith("Location: "));
		Test.Assert(rows[1] == scope $"Engine version: {project.Settings.EngineVersion}");
		Test.Assert(rows[2] == "Default scene: Docks", rows[2]);
		Test.Assert(rows[3] == "Input map: (missing)", rows[3]);
		Test.Assert(rows[4] == "UI font: (built-in)", rows[4]);
		Test.Assert(rows[5] == "Window: 1280 × 720, windowed", rows[5]);
		Test.Assert(!Has(rows, "Default bus layout: (built-in)"));
		// An asset the project holds, a link to it; one it does not, in the warning colour; an unset
		// one by its empty text.
		let defaultScene = ValueOf(content, "Default scene") as Sedulous.GUI.Button;
		Test.Assert((defaultScene != null) && defaultScene.HasClass("link") && (defaultScene.Text == "Docks"));
		let missing = ValueOf(content, "Input map") as Sedulous.GUI.Label;
		Test.Assert((missing != null) && missing.HasClass("missing"));
		let unset = ValueOf(content, "UI font") as Sedulous.GUI.Label;
		Test.Assert((unset != null) && unset.HasClass("dim") && !unset.HasClass("missing"));

		// Its buttons.
		Test.Assert((content.FindElement("home-show-folder") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(shown == project.Directory);
		Test.Assert((content.FindElement("home-settings") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(settingsOpened == 1);
		let newScene = content.FindElement("home-new-scene") as Sedulous.GUI.Button;
		Test.Assert(newScene != null);
		Test.Assert(newScene.Displayed);
		Test.Assert(newScene.HandleActivate());
		Test.Assert(scenesMade == 1);
		Test.Assert(!content.FindElement("home-no-scenes").Displayed);

		// A card per scene, in the asset tree's order (by name); each opens its scene, and the
		// default one is marked. With no thumbnail service, each shows the scene type's icon.
		Test.Assert(home.Scenes.Count == 2);
		Test.Assert((home.Scenes[0] == arrival.Id) && (home.Scenes[1] == docks.Id));
		Test.Assert((content.FindElement("home-scene-count") as Sedulous.GUI.Label).Text == "2");
		let grid = content.FindElement("home-scenes");
		Test.Assert((grid != null) && (grid.ChildCount == 2));
		let first = grid.GetChildAt(0) as Sedulous.GUI.Button;
		Test.Assert(first != null);
		Test.Assert(first.HandleActivate());
		Test.Assert((opened.Count == 1) && (opened[0] == arrival.Id));
		Test.Assert(!Marked(grid.GetChildAt(0)));
		Test.Assert(Marked(grid.GetChildAt(1)));
		Test.Assert(home.ThumbnailsShown == 0);

		// A change to the settings shows at the next refresh, once marked.
		project.Settings.DefaultSceneId = arrival.Id;
		home.Refresh();
		Test.Assert(Has(home.SummaryRows, "Default scene: Docks"));
		home.MarkChanged();
		home.Refresh();
		Test.Assert(Has(home.SummaryRows, "Default scene: Arrival"));
		Test.Assert(Marked(grid.GetChildAt(0)));

		// Without a project, nothing to show.
		context.SetProject(null);
		home.Rebuild();
		Test.Assert(home.Scenes.IsEmpty && home.SummaryRows.IsEmpty);
	}

	/// A project with no scenes shows a note with its own New Scene, in place of the cards.
	[Test]
	public static void AProjectWithNoScenesShowsANoteWithNewScene()
	{
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_project_home_empty", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Harbour") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		let content = LoadHome();
		Test.Assert(content != null);
		let home = scope ProjectHomeView(context, null, content);
		int scenesMade = 0;
		home.SetOnNewScene(new [&scenesMade] () => { scenesMade++; });

		Test.Assert(home.Scenes.IsEmpty);
		Test.Assert(Has(home.SummaryRows, "Default scene: (none)"));
		Test.Assert((content.FindElement("home-scene-count") as Sedulous.GUI.Label).Text == "0");
		Test.Assert(content.FindElement("home-no-scenes").Displayed);
		Test.Assert(!content.FindElement("home-scenes").Displayed);
		Test.Assert(!content.FindElement("home-new-scene").Displayed, "the note has its own");
		Test.Assert((content.FindElement("home-first-scene") as Sedulous.GUI.Button).HandleActivate());
		Test.Assert(scenesMade == 1);
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
		Test.Assert(content.FindElement("home-scenes").ChildCount == 3, "a card for the new scene");

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
		let thumbnails = scope ThumbnailService();
		ProjectHomeView home = null;
		let services = new EditorSessionServices();
		services.Context = context;
		services.Cook = cook;
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
