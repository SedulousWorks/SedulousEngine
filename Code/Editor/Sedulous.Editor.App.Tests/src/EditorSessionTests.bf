using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.GUI; // the dock's layout
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// EditorSession, headless: no embedded runtime (its host and application stay null, and the
/// session skips the attach, the content database and the game UI's defaults), the real cook,
/// job and thumbnail services over a scratch project. An open with no project says why on the
/// status line; a scaffold makes one, seeded only when asked and only when this open made it;
/// the context holds the project's services from before the opened hook until after the
/// closing one; a cook's finish reaches the views after the thumbnails drop; the per-project
/// store loads with the project, saves on a favourite's change and on close, what the views
/// captured into it included; the dock's layout is captured into it each time it is written and
/// before the views close, and a project that opens takes its saved layout, else the default; a
/// close is idempotent and runs in the destructor; the thumbnails' stage lives with a project over
/// an embedded runtime's host, and only then.
class EditorSessionTests
{
	/// An embedded runtime's host with no shell, graphics or subsystems: enough for the
	/// thumbnails' stage to be made over it (and to sit disabled).
	class HostOnly : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	/// The services a session runs on; the status lines land in Said, the hooks in Events.
	class Bench
	{
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public ThumbnailService Thumbnails = new .() ~ delete _;
		/// The user's project registry, never written to the user data (no UserSettings).
		public Settings Registry = new .() ~ delete _;
		public ProjectManagerController Projects ~ delete _;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Events = new .() ~ DeleteContainerAndItems!(_);
		/// Borrowed: the session under test, for the hooks to look at.
		public EditorSession Session = null;
		/// What the views capture into the store as the project closes; none when empty.
		public List<Guid> PagesToCapture = new .() ~ delete _;
		/// A dock the hooks drive as the application's do (the layout captured, taken on open);
		/// none when null.
		public DockBed DockBed = null ~ delete _;
		/// The closing hook closes the console, as views going might change the dock.
		public bool CloseConsoleOnClosing = false;
		/// How often the views' state was captured, and whether the closing hook had run by then.
		/// The open pages the views' capture writes while they are up, and that a closing view
		/// takes away, asking for a save as a scene page does as it closes.
		public List<Guid> LivePages = new .() ~ delete _;
		public bool RequestSaveOnClosing = false;
		public int Captures = 0;
		public bool CapturedAfterClosing = false;
		/// The services' state each hook saw.
		public bool OpenedSawServicesUp = false;
		public bool ClosingSawServicesUp = false;
		public int CachedAtCookFinished = -1;
		public List<String> Dirs = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			EditorAppSerializables.RegisterEditorProjectSettingsTypes();
			Projects = new .(Registry);
			let said = Said;
			Context.OnStatus = new [=said](text) => { said.Add(new String(text)); };
		}

		public ~this()
		{
			Cook.Shutdown();
			for (let dir in Dirs)
				RemoveDirectoryRecursive(dir);
		}

		/// An absolute scratch directory, emptied; removed with the bench.
		public String Scratch(StringView leaf)
		{
			let dir = new String();
			PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), leaf, dir);
			RemoveDirectoryRecursive(dir);
			Dirs.Add(dir);
			return dir;
		}

		/// A scratch project made beforehand, as one on disk the session opens.
		public String MadeProject(StringView leaf, StringView name)
		{
			let dir = Scratch(leaf);
			Test.Assert(EditorProject.Create(dir, name) case .Ok);
			return dir;
		}

		/// The services over this bench, every hook recording; the session owns them.
		public EditorSessionServices Services()
		{
			let services = new EditorSessionServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Builders = Builders;
			services.Thumbnails = Thumbnails;
			services.Projects = Projects;
			let bench = this;
			services.SeedNewProject = new [=bench](context, project) =>
				{
					Test.Assert(context == bench.Context);
					project.Settings.DefaultScene.Set("Seeded/Scene");
					bench.Events.Add(new .("seed"));
				};
			services.OnOpened = new [=bench](project) =>
				{
					if (bench.DockBed != null)
						bench.DockBed.Dock.TakeLayout(bench.Session.Store);
					let context = bench.Context;
					bench.OpenedSawServicesUp = (bench.Session.Project == project) && (context.Project == project)
						&& (context.Resources != null) && (context.Resources == bench.Session.Resources)
						&& (context.ProjectEditorSettings != null) && (context.ProjectEditorSettings == bench.Session.Store)
						&& bench.Cook.IsReady;
					bench.Events.Add(new .("opened"));
				};
			services.OnClosing = new [=bench]() =>
				{
					let context = bench.Context;
					bench.ClosingSawServicesUp = (bench.Session.Project != null) && (context.Project == bench.Session.Project)
						&& (context.Resources != null) && (context.ProjectEditorSettings == bench.Session.Store) && bench.Cook.IsReady;
					if (!bench.PagesToCapture.IsEmpty)
						ProjectEditorSettings.CaptureOpenPages(bench.Session.Store, bench.PagesToCapture, bench.PagesToCapture[0]);
					if (bench.CloseConsoleOnClosing && (bench.DockBed != null))
						Test.Assert(bench.DockBed.Dock.Controller.Close(EditorDock.cPanelConsole).Ok);
					if (bench.RequestSaveOnClosing)
					{
						bench.LivePages.Clear(); // the page goes, saving its own state as it does
						context.RequestProjectEditorSettingsSave();
					}
					bench.Events.Add(new .("closing"));
				};
			services.CaptureState = new [=bench](store) =>
				{
					Test.Assert(store == bench.Session.Store);
					bench.Captures++;
					bench.CapturedAfterClosing = bench.CapturedAfterClosing || bench.HasEvent("closing");
					if (bench.DockBed != null)
						bench.DockBed.Dock.CaptureLayout(store);
					if (bench.RequestSaveOnClosing)
						ProjectEditorSettings.CaptureOpenPages(store, bench.LivePages, bench.LivePages.IsEmpty ? Guid() : bench.LivePages[0]);
				};
			services.OnCookFinished = new [=bench]() =>
				{
					bench.CachedAtCookFinished = bench.Thumbnails.CachedCount;
					bench.Events.Add(new .("cookFinished"));
				};
			services.OnSettingsChanged = new [=bench]() => { bench.Events.Add(new .("settingsChanged")); };
			return services;
		}

		public StringView Last => Said.IsEmpty ? "" : Said.Back;

		public int Count(StringView text)
		{
			int count = 0;
			for (let line in Said)
				if (line == text)
					count++;
			return count;
		}

		public bool HasEvent(StringView name)
		{
			for (let recorded in Events)
				if (recorded == name)
					return true;
			return false;
		}

		public bool EventsAre(params StringView[] expected)
		{
			if (Events.Count != expected.Count)
				return false;
			for (int i < expected.Count)
				if (Events[i] != expected[i])
					return false;
			return true;
		}

		/// Pumps the cook until a hook says it finished; bounded so a hang fails.
		public void PumpUntilCookFinished()
		{
			let watch = scope Stopwatch(true);
			while (!HasEvent("cookFinished") && (watch.ElapsedMilliseconds < 60000))
			{
				Cook.Update();
				Thread.Sleep(1);
			}
			Test.Assert(HasEvent("cookFinished"));
		}
	}

	/// The store on disk under `dir`, read fresh.
	static void ReadStore(StringView dir, Settings outStore)
	{
		let editorDir = PathJoin(dir, "Editor", .. scope .());
		Test.Assert(ProjectEditorSettings.Load(outStore, editorDir) case .Ok);
	}

	[Test]
	public static void AnOpenWithNoProjectSaysWhyAndSetsNothingUp()
	{
		let bench = scope Bench();
		let session = scope EditorSession(bench.Services());
		bench.Session = session;

		Test.Assert(!session.Open(""));
		Test.Assert(bench.Last == "No project directory - pass one on the command line.");

		// A directory that is not there, no scaffold: said, and not made.
		let missing = bench.Scratch("scratch_editor_session_missing");
		Test.Assert(!session.Open(missing));
		Test.Assert(bench.Last == scope $"Failed to open project: {missing}");
		Test.Assert(!DirectoryExists(missing));

		// An empty one: the same, and no manifest written into it.
		let empty = bench.Scratch("scratch_editor_session_empty");
		Test.Assert(CreateDirectory(empty));
		Test.Assert(!session.Open(empty));
		Test.Assert(bench.Last == scope $"Failed to open project: {empty}");
		{
			let probe = EditorProject.Open(empty);
			defer delete probe;
			Test.Assert(probe == null);
		}

		Test.Assert(bench.Said.Count == 3);
		Test.Assert(session.Project == null);
		Test.Assert(session.Store == null);
		Test.Assert(session.Resources == null);
		Test.Assert(bench.Context.Project == null);
		Test.Assert(bench.Context.ProjectEditorSettings == null);
		Test.Assert(bench.Context.Resources == null);
		Test.Assert(!bench.Cook.IsReady);
		Test.Assert(bench.Events.IsEmpty);
		Test.Assert(bench.Projects.Entries.Entries.IsEmpty);
	}

	/// A scaffold makes the bare folder a project under the name given; it seeds only when
	/// asked, the seed's manifest defaults saved and a cook asked for, the status naming the
	/// starter content before the project's line; an open of a project already there never
	/// seeds, whatever the options say.
	[Test]
	public static void AScaffoldMakesAProjectSeededOnlyWhenAskedAndOnlyWhenMade()
	{
		let bench = scope Bench();
		let session = scope EditorSession(bench.Services());
		bench.Session = session;

		EditorSessionOpenOptions options = .();
		options.Scaffold = true;
		options.ScaffoldName = "Fresh";
		let bare = bench.Scratch("scratch_editor_session_scaffold");
		Test.Assert(session.Open(bare, options));
		Test.Assert(session.Project != null);
		Test.Assert(session.Project.Name == "Fresh");
		Test.Assert(bench.EventsAre("opened"));
		Test.Assert(bench.Cook.IsIdle, "no seed: no cook asked for");
		Test.Assert(session.Project.Settings.DefaultScene.IsEmpty);
		Test.Assert(bench.Last == scope $"Project: Fresh  ({bare})");
		Test.Assert(bench.Count("Project created with starter content.") == 0);
		session.Close();

		bench.Events.ClearAndDeleteItems();
		bench.Said.ClearAndDeleteItems();
		options.Seed = true;
		let seeded = bench.Scratch("scratch_editor_session_seeded");
		Test.Assert(session.Open(seeded, options));
		Test.Assert(bench.EventsAre("opened", "seed"));
		Test.Assert(!bench.Cook.IsIdle, "the seed's cook");
		Test.Assert(bench.Said.Count == 2);
		Test.Assert(bench.Said[0] == "Project created with starter content.");
		Test.Assert(bench.Said[1] == scope $"Project: Fresh  ({seeded})");
		{
			// Saved: a fresh read of the manifest has the seed's default.
			let reopened = EditorProject.Open(seeded);
			Test.Assert(reopened != null);
			defer delete reopened;
			Test.Assert(reopened.Settings.DefaultScene == "Seeded/Scene");
		}
		bench.PumpUntilCookFinished();
		session.Close();

		// The project is there now: opened, not made, so not seeded.
		bench.Events.ClearAndDeleteItems();
		Test.Assert(session.Open(seeded, options));
		Test.Assert(bench.EventsAre("opened"));
		Test.Assert(bench.Cook.IsIdle);

		// Without a scaffold a bare folder stays one.
		bench.Events.ClearAndDeleteItems();
		options.Scaffold = false;
		let refused = bench.Scratch("scratch_editor_session_unscaffolded");
		Test.Assert(CreateDirectory(refused));
		Test.Assert(!session.Open(refused, options));
		Test.Assert(bench.Last == scope $"Failed to open project: {refused}");
		Test.Assert(bench.EventsAre("closing"), "the open project closed first");
		Test.Assert(session.Project == null);
	}

	/// The hooks in their order: opened with the services up, a cook's finish after the
	/// thumbnails dropped, a settings save, closing with the services still up; the cook goes
	/// with the close, and the context's cook hooks with it.
	[Test]
	public static void TheHooksRunInOrderWithTheServicesUpAroundThem()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_hooks", "Hooks");
		let session = scope EditorSession(bench.Services());
		bench.Session = session;

		Test.Assert(!bench.Context.IsCookBusy);
		Test.Assert(session.Open(dir));
		Test.Assert(bench.EventsAre("opened"));
		Test.Assert(bench.OpenedSawServicesUp);
		Test.Assert(bench.Context.SourceAssetTypesOf != null);
		// A prefab reference's picker offers prefab documents.
		let accepted = scope List<Type>();
		bench.Context.SourceAssetTypesOf(typeof(Sedulous.Scene.Resource.PrefabResource), accepted);
		Test.Assert((accepted.Count == 1) && (accepted[0] == typeof(Sedulous.Scene.Resource.PrefabDocument)));

		// The thumbnails are configured: a miss on an unknown id caches a negative.
		Test.Assert(bench.Thumbnails.Get(Guid.Create()) == null);
		Test.Assert(bench.Thumbnails.CachedCount == 1);

		// The context reaches the cook; its finish drops the thumbnails before the views hear.
		bench.Context.RequestCook();
		Test.Assert(bench.Context.IsCookBusy);
		bench.PumpUntilCookFinished();
		Test.Assert(bench.CachedAtCookFinished == 0);
		Test.Assert(bench.EventsAre("opened", "cookFinished"));

		bench.Context.NotifyProjectSettingsChanged();
		Test.Assert(bench.EventsAre("opened", "cookFinished", "settingsChanged"));

		Test.Assert(bench.Thumbnails.Get(Guid.Create()) == null);
		Test.Assert(bench.Thumbnails.CachedCount == 1);
		session.Close();
		Test.Assert(bench.EventsAre("opened", "cookFinished", "settingsChanged", "closing"));
		Test.Assert(bench.ClosingSawServicesUp);

		// What the session wired goes with it.
		Test.Assert(!bench.Cook.IsReady);
		Test.Assert(bench.Cook.OnCookFinished == null);
		Test.Assert(bench.Thumbnails.CachedCount == 0);
		Test.Assert(bench.Thumbnails.Get(Guid.Create()) == null);
		Test.Assert(bench.Thumbnails.CachedCount == 0, "reset: nothing resolves");
		Test.Assert(bench.Context.OnCookRequested == null);
		Test.Assert(bench.Context.CookBusy == null);
		Test.Assert(bench.Context.OnProjectSettingsChanged == null);
		bench.Context.NotifyProjectSettingsChanged();
		Test.Assert(bench.Events.Count == 4);
	}

	/// The context holds the project, its resources and its store while it is open, the
	/// thumbnails' folder made and the open recorded in the registry; the close clears them.
	[Test]
	public static void TheContextHoldsTheProjectWhileItIsOpen()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_context", "Held");
		let session = scope EditorSession(bench.Services());
		bench.Session = session;

		Test.Assert(session.Open(dir));
		let context = bench.Context;
		Test.Assert(session.Project != null);
		Test.Assert(context.Project == session.Project);
		Test.Assert(session.Resources != null);
		Test.Assert(context.Resources == session.Resources);
		Test.Assert(session.Store != null);
		Test.Assert(context.ProjectEditorSettings == session.Store);
		Test.Assert(context.OnProjectEditorSettingsSaveRequested != null);
		Test.Assert(context.OnFavoritesChanged != null);
		Test.Assert(!context.Tasks.IsLaneBusy(context.BuildLane), "the build lane idle");
		Test.Assert(bench.Cook.IsReady);
		Test.Assert(bench.Cook.ExternalMutationLock != null);
		Test.Assert(DirectoryExists(PathJoin(dir, ".cache/thumbs", .. scope .())));
		Test.Assert(bench.Last == scope $"Project: Held  ({dir})");

		let entries = bench.Projects.Entries.Entries;
		Test.Assert(entries.Count == 1);
		Test.Assert(entries[0].Path == dir);
		Test.Assert(entries[0].Name == "Held");

		session.Close();
		Test.Assert(session.Project == null);
		Test.Assert(session.Resources == null);
		Test.Assert(session.Store == null);
		Test.Assert(context.Project == null);
		Test.Assert(context.Resources == null);
		Test.Assert(context.ProjectEditorSettings == null);
		Test.Assert(context.OnProjectEditorSettingsSaveRequested == null);
		Test.Assert(context.OnFavoritesChanged == null);
		Test.Assert(bench.Last == "Project closed.");
	}

	/// The store loads with the project (its favourites onto the context), saves when a
	/// favourite changes, and saves on close what the views captured into it as it closed.
	[Test]
	public static void TheStoreLoadsWithTheProjectAndSavesOnClose()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_store", "Stored");
		let pinned = Guid.Create();
		let added = Guid.Create();
		let page = Guid.Create();
		{
			let store = scope Settings();
			store.Section<EditorFavoritesSettings>().Favorites.Add(pinned);
			Test.Assert(ProjectEditorSettings.Save(store, PathJoin(dir, "Editor", .. scope .())) case .Ok);
		}
		let session = scope EditorSession(bench.Services());
		bench.Session = session;

		Test.Assert(session.Open(dir));
		Test.Assert(bench.Context.Favorites.Count == 1);
		Test.Assert(bench.Context.Favorites[0] == pinned);
		Test.Assert(session.Store.Find<EditorFavoritesSettings>() != null);

		// A favourite's change is captured and written at once.
		bench.Context.ToggleFavorite(added);
		{
			let read = scope Settings();
			ReadStore(dir, read);
			let favorites = read.Find<EditorFavoritesSettings>();
			Test.Assert(favorites != null);
			Test.Assert(favorites.Favorites.Count == 2);
			Test.Assert(favorites.Favorites[0] == pinned);
			Test.Assert(favorites.Favorites[1] == added);
			Test.Assert(ProjectEditorSettings.ApplyOpenPages(read, scope .(), let none) case .Err(.NotFound));
		}

		// The views capture the open pages as the project closes; the close writes them.
		bench.PagesToCapture.Add(page);
		session.Close();
		{
			let read = scope Settings();
			ReadStore(dir, read);
			let pages = scope List<Guid>();
			Test.Assert(ProjectEditorSettings.ApplyOpenPages(read, pages, let active) case .Ok);
			Test.Assert(pages.Count == 1);
			Test.Assert(pages[0] == page);
			Test.Assert(active == page);
			Test.Assert(read.Find<EditorFavoritesSettings>().Favorites.Count == 2);
		}
	}

	/// A close with nothing open does nothing, a second close nothing more; an open over an
	/// open project closes it first; the destructor closes, the store saved.
	[Test]
	public static void ACloseIsIdempotentAndTheDestructorCloses()
	{
		let bench = scope Bench();
		let first = bench.MadeProject("scratch_editor_session_first", "First");
		let second = bench.MadeProject("scratch_editor_session_second", "Second");
		let page = Guid.Create();
		{
			let session = scope EditorSession(bench.Services());
			bench.Session = session;
			session.Close();
			Test.Assert(bench.Said.IsEmpty);
			Test.Assert(bench.Events.IsEmpty);

			Test.Assert(session.Open(first));
			session.Close();
			session.Close();
			Test.Assert(bench.EventsAre("opened", "closing"));
			Test.Assert(bench.Count("Project closed.") == 1);

			// An open over an open project: the first closes before the second opens.
			Test.Assert(session.Open(first));
			Test.Assert(session.Open(second));
			Test.Assert(bench.EventsAre("opened", "closing", "opened", "closing", "opened"));
			Test.Assert(session.Project.Name == "Second");
			Test.Assert(bench.Context.Project == session.Project);
			bench.PagesToCapture.Add(page);
		}
		Test.Assert(bench.EventsAre("opened", "closing", "opened", "closing", "opened", "closing"));
		Test.Assert(bench.Last == "Project closed.");
		Test.Assert(bench.Context.Project == null);
		Test.Assert(bench.Context.Resources == null);
		Test.Assert(bench.Context.ProjectEditorSettings == null);
		Test.Assert(!bench.Cook.IsReady);
		{
			let read = scope Settings();
			ReadStore(second, read);
			let pages = scope List<Guid>();
			Test.Assert(ProjectEditorSettings.ApplyOpenPages(read, pages, let active) case .Ok);
			Test.Assert((pages.Count == 1) && (pages[0] == page));
		}
	}

	/// The saved layout's section in the store on disk under `dir`; null when none was written.
	static void ReadLayout(StringView dir, Settings outStore, out DockLayout outLayout)
	{
		ReadStore(dir, outStore);
		let section = outStore.Find<EditorDockLayoutSettings>();
		outLayout = ((section != null) && section.Captured) ? section.Document.Layout : null;
	}

	/// The console tabbed in with the assets: an arrangement the default does not make.
	static void TabConsoleWithAssets(DockBed bed)
	{
		Test.Assert(bed.Dock.Controller.Edit(scope (l) => l.MoveToTab(EditorDock.cPanelConsole, l.StackOf(EditorDock.cPanelAssets))).Ok);
		Test.Assert(bed.Layout.StackOf(EditorDock.cPanelConsole) == bed.Layout.StackOf(EditorDock.cPanelAssets));
	}

	/// Each write of the store captures the views' state into it first: a favourite's change
	/// writes the dock as it is then, a later write as it is by then.
	[Test]
	public static void TheViewsStateIsCapturedIntoTheStoreEachTimeItIsWritten()
	{
		let bench = scope Bench();
		bench.DockBed = new DockBed();
		let dir = bench.MadeProject("scratch_editor_session_capture", "Captured");
		let session = scope EditorSession(bench.Services());
		bench.Session = session;
		Test.Assert(session.Open(dir));

		TabConsoleWithAssets(bench.DockBed);
		bench.Context.ToggleFavorite(Guid.Create());
		Test.Assert(bench.Captures == 1);
		{
			let read = scope Settings();
			ReadLayout(dir, read, let layout);
			Test.Assert(layout != null);
			Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
			Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == layout.StackOf(EditorDock.cPanelAssets));
		}

		// The console closed, the store written again: the dock as it is now.
		Test.Assert(bench.DockBed.Dock.Controller.Close(EditorDock.cPanelConsole).Ok);
		session.SaveStore();
		Test.Assert(bench.Captures == 2);
		{
			let read = scope Settings();
			ReadLayout(dir, read, let layout);
			Test.Assert(layout != null);
			Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == cNoDock);
			Test.Assert(layout.StackOf(EditorDock.cPanelAssets) != cNoDock);
		}
		Test.Assert(!bench.CapturedAfterClosing);
	}

	/// A close captures the views' state while they are up, before the closing hook: what the
	/// views change as they go is not what is saved, and the write after the hook (what the
	/// views add, the open pages) captures nothing again.
	[Test]
	public static void TheViewsStateIsCapturedBeforeTheProjectCloses()
	{
		let bench = scope Bench();
		bench.DockBed = new DockBed();
		let dir = bench.MadeProject("scratch_editor_session_capture_close", "Closing");
		let page = Guid.Create();
		let session = scope EditorSession(bench.Services());
		bench.Session = session;
		Test.Assert(session.Open(dir));

		TabConsoleWithAssets(bench.DockBed);
		bench.CloseConsoleOnClosing = true;
		bench.PagesToCapture.Add(page);
		session.Close();
		Test.Assert(bench.EventsAre("opened", "closing"));
		Test.Assert(bench.Captures == 1, "once, as the close began");
		Test.Assert(!bench.CapturedAfterClosing);
		Test.Assert(bench.DockBed.Layout.StackOf(EditorDock.cPanelConsole) == cNoDock, "the views closed it as they went");
		{
			let read = scope Settings();
			ReadLayout(dir, read, let layout);
			Test.Assert(layout != null);
			// The dock as it was while the views were up.
			Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
			Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == layout.StackOf(EditorDock.cPanelAssets));
			// What the closing views captured, written after them.
			let pages = scope List<Guid>();
			Test.Assert(ProjectEditorSettings.ApplyOpenPages(read, pages, let active) case .Ok);
			Test.Assert((pages.Count == 1) && (pages[0] == page) && (active == page));
		}
	}

	/// A project closed with a page open writes that page, and the page's own save as it closes
	/// keeps it: a save asked for while the views close captures nothing again (a page saving its
	/// state as it goes would write the open pages as they close, the last leaving none to reopen:
	/// Raptor's user report, a project closed with a scene open opening with none).
	[Test]
	public static void AProjectClosedWithAPageOpenWritesThatPageItsOwnSaveAsItClosesKeepsIt()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_close_pages", "Session");
		let page = Guid.Create();
		let session = scope EditorSession(bench.Services());
		bench.Session = session;
		Test.Assert(session.Open(dir));
		bench.LivePages.Add(page);
		bench.RequestSaveOnClosing = true;
		session.Close();

		// Opened again: the page is there to reopen.
		let read = scope Settings();
		ReadStore(dir, read);
		let pages = scope List<Guid>();
		Test.Assert(ProjectEditorSettings.ApplyOpenPages(read, pages, let active) case .Ok);
		Test.Assert(pages.Count == 1);
		Test.Assert(pages[0] == page);
		Test.Assert(active == page);
	}

	/// A project that opens takes the layout saved with it; one with none saved takes the
	/// default, not what the dock showed for the project before.
	[Test]
	public static void AnOpeningProjectTakesItsSavedLayoutElseTheDefault()
	{
		let bench = scope Bench();
		bench.DockBed = new DockBed();
		let first = bench.MadeProject("scratch_editor_session_layout_first", "First");
		let second = bench.MadeProject("scratch_editor_session_layout_second", "Second");
		let session = scope EditorSession(bench.Services());
		bench.Session = session;
		let layout = bench.DockBed.Layout;

		Test.Assert(session.Open(first));
		TabConsoleWithAssets(bench.DockBed);

		// The second has none saved: the default, over the first's arrangement.
		Test.Assert(session.Open(second));
		let assets = layout.StackOf(EditorDock.cPanelAssets);
		let console = layout.StackOf(EditorDock.cPanelConsole);
		Test.Assert((assets != cNoDock) && (console != cNoDock));
		Test.Assert(assets != console);
		Test.Assert(bench.DockBed.ParentOf(console) == bench.DockBed.ParentOf(assets), "beside the assets, as the default has it");
		Test.Assert(layout.StackOf(EditorDock.cPanelProject) == layout.CentralStack);

		// The first again: its own, saved as it closed.
		Test.Assert(session.Open(first));
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) != cNoDock);
		Test.Assert(layout.StackOf(EditorDock.cPanelConsole) == layout.StackOf(EditorDock.cPanelAssets));
	}

	/// A part of the four-part plugin: records its kind as it loads and unloads, and the Editor part
	/// whether the editor's context was offered.
	class SessionPart : PluginPart
	{
		public static List<String> Log = new .() ~ DeleteContainerAndItems!(_);
		public static EditorContext ContextSeen;
		public static Sedulous.Pipeline.Importer.PipelinePluginServices PipelineSeen;
		private PluginPartKind mKind;

		public this(PluginPartKind kind) { mKind = kind; }

		public override StringView PluginId => "four_parts";
		public override PluginPartKind Kind => mKind;

		public override void Load(PluginContext context)
		{
			Log.Add(new $"load:{mKind}");
			if (mKind == .Editor)
				ContextSeen = context.Find<EditorContext>();
			if (mKind == .Pipeline)
				PipelineSeen = context.Find<Sedulous.Pipeline.Importer.PipelinePluginServices>();
		}

		public override void Unload(PluginContext context) => Log.Add(new $"unload:{mKind}");
	}

	/// A project's plugins enable with it in the embedded runtime, every part an editor takes, the
	/// Editor part offered the editor's context, and unload as it closes, in reverse.
	[Test]
	public static void AProjectsPluginsEnableWithItInTheEmbeddedRuntimeAndUnloadAsItCloses()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_plugins", "Plugins");
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let entry = new EnabledPlugin();
			entry.Id.Set("four_parts");
			project.Settings.Plugins.Add(entry);
			Test.Assert(project.SaveSettings() case .Ok);
		}
		let manifest = scope PluginManifest();
		manifest.Id.Set("four_parts");
		manifest.Version.Set("1.0");
		manifest.EngineVersion.Set(Sedulous.Engine.Project.EngineVersion.String);
		for (int i < PluginPartKind.Count)
		{
			let part = new PluginManifestPart();
			((PluginPartKind)i).ToString(part.Kind);
			manifest.Parts.Add(part);
		}
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let xml = manifest.Write(.. scope .());
		let parts = scope List<PluginPart>();
		defer { ClearAndDeleteItems!(parts); }
		for (int i < PluginPartKind.Count)
			parts.Add(new ManifestPart(new SessionPart((PluginPartKind)i), xml));

		let host = scope HostOnly();
		let embedded = scope Sedulous.Engine.DefaultApp.DefaultApplication();
		// The host's order: configured, the context started, then the application.
		embedded.Configure(host);
		host.Subsystems.Startup();
		embedded.OnStartup(host);
		ClearAndDeleteItems!(SessionPart.Log);
		SessionPart.ContextSeen = null;
		{
			let services = bench.Services();
			services.PluginParts = parts;
			let session = scope EditorSession(services);
			bench.Session = session;
			session.SetEmbedded(host, embedded);
			Test.Assert(session.Open(dir));
			let plugins = bench.Context.Plugins;
			Test.Assert(plugins != null);
			Test.Assert(plugins === embedded.Plugins);
			Test.Assert(plugins.Role == .Editor);
			Test.Assert(plugins.IsLoaded("four_parts"));
			Test.Assert(SessionPart.Log.Count == 4);
			Test.Assert(SessionPart.Log[0] == "load:Engine");
			Test.Assert(SessionPart.Log[3] == "load:Editor");
			Test.Assert(SessionPart.ContextSeen === bench.Context);
			// A Pipeline part adds to the editor's registries.
			Test.Assert(SessionPart.PipelineSeen != null);
			Test.Assert(SessionPart.PipelineSeen.Registries.Builders === bench.Builders);
			Test.Assert(SessionPart.PipelineSeen.Registries.Importers === bench.Context.Importers);
			Test.Assert(SessionPart.PipelineSeen.Registries.Creators === bench.Context.Creators);
			session.Close();
			Test.Assert(bench.Context.Plugins == null);
			Test.Assert(embedded.Plugins == null);
			Test.Assert(SessionPart.Log.Count == 8);
			Test.Assert(SessionPart.Log[4] == "unload:Editor", "the reverse of the load");
		}
		host.Subsystems.Shutdown();
		embedded.OnShutdown(host);
		host.Subsystems.Dispose();
		ClearAndDeleteItems!(SessionPart.Log);
	}

	/// A part wrapped with its manifest, so a test's parts carry one as registered parts do.
	class ManifestPart : PluginPart
	{
		private PluginPart mInner ~ delete _;
		private String mManifest = new .() ~ delete _;

		public this(PluginPart inner, StringView manifest)
		{
			mInner = inner;
			mManifest.Set(manifest);
		}

		public override StringView PluginId => mInner.PluginId;
		public override PluginPartKind Kind => mInner.Kind;
		public override StringView ManifestXml => mManifest;
		public override void Load(PluginContext context) => mInner.Load(context);
		public override void Unload(PluginContext context) => mInner.Unload(context);
	}

	/// The stage is made as a project opens over an embedded runtime's host, after its resources,
	/// and goes as it closes; a headless session, with no host, has none.
	[Test]
	public static void TheThumbnailsStageLivesWithAProjectOverAnEmbeddedHost()
	{
		let bench = scope Bench();
		let dir = bench.MadeProject("scratch_editor_session_stage", "Staged");
		let host = scope HostOnly();
		{
			let session = scope EditorSession(bench.Services());
			bench.Session = session;
			Test.Assert(session.Open(dir));
			Test.Assert(session.Stage == null, "headless: no host to render on");
			session.Close();

			session.SetEmbedded(host, null);
			Test.Assert(session.Stage == null, "no project yet");
			Test.Assert(session.Open(dir));
			Test.Assert(session.Stage != null);
			Test.Assert(!session.Stage.IsBusy);
			session.Stage.Update(); // no scene or render subsystem on this host: it stays idle
			Test.Assert(!session.Stage.IsBusy);
			session.Close();
			Test.Assert(session.Stage == null);
		}
	}
}
