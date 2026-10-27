using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
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
/// captured into it included; a close is idempotent and runs in the destructor.
class EditorSessionTests
{
	/// The services a session runs on; the status lines land in Said, the hooks in Events.
	class Bench
	{
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public EditorJobService Jobs = new .() ~ delete _;
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
			services.Jobs = Jobs;
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
					let context = bench.Context;
					bench.OpenedSawServicesUp = (bench.Session.Project == project) && (context.Project == project)
						&& (context.Resources != null) && (context.Resources == bench.Session.Resources)
						&& (context.ProjectEditorSettings != null) && (context.ProjectEditorSettings == bench.Session.Store)
						&& (context.Jobs == bench.Jobs) && bench.Cook.IsReady;
					bench.Events.Add(new .("opened"));
				};
			services.OnClosing = new [=bench]() =>
				{
					let context = bench.Context;
					bench.ClosingSawServicesUp = (bench.Session.Project != null) && (context.Project == bench.Session.Project)
						&& (context.Resources != null) && (context.ProjectEditorSettings == bench.Session.Store) && bench.Cook.IsReady;
					if (!bench.PagesToCapture.IsEmpty)
						ProjectEditorSettings.CaptureOpenPages(bench.Session.Store, bench.PagesToCapture, bench.PagesToCapture[0]);
					bench.Events.Add(new .("closing"));
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
		Test.Assert(context.Jobs == bench.Jobs);
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
}
