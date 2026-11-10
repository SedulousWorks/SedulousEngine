using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;

namespace Sedulous.Editor.Projects.Tests;

/// The project registry and the manager controller: recency ordering, removal, the store
/// round trip, when each was opened and its pin, relocating, arranging and saying when, the probe, the version relation, the manifest backup and the open gates.
static class ProjectRegistryTests
{
	/// The file the recent list is saved to here; the editor's store names its own.
	private const String cStoreFile = "projects.settings.xml";

	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	/// Writes `store` as XML to `fileName` under `root`, as a user store is written.
	private static Result<void, ErrorCode> SaveStore(IWritableFileSystem root, Settings store, StringView fileName = cStoreFile)
	{
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		if (store.Save(buffer, factory) case .Err(let error))
			return .Err(error);
		return root.Save(fileName, buffer.Bytes);
	}

	/// Reads `fileName` under `root` into `outStore`; NotFound when it is absent.
	private static Result<void, ErrorCode> LoadStore(IFileSystem root, Settings outStore, StringView fileName = cStoreFile)
	{
		let stream = root.Open(fileName, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;
		let factory = XmlSerializerFactory();
		defer delete factory;
		return outStore.Load(stream, factory);
	}

	[Test]
	public static void TouchInsertsMostRecentFirstDedupesAndCaps()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		ProjectRegistry.TouchRecentProject(store, "/projects/a", "A", "0.1.0");
		ProjectRegistry.TouchRecentProject(store, "/projects/b", "B", "0.1.0");
		let registry = store.Section<RecentProjectsSettings>();
		Test.Assert((registry.Entries.Count == 2) && (registry.Entries[0].Path == "/projects/b"), "most recent first");
		// Re-touching A moves it to the front with a fresh snapshot, no duplicate row.
		ProjectRegistry.TouchRecentProject(store, "/projects/a", "A renamed", "0.2.0");
		Test.Assert(registry.Entries.Count == 2);
		Test.Assert((registry.Entries[0].Path == "/projects/a") && (registry.Entries[0].Name == "A renamed") && (registry.Entries[0].EngineVersion == "0.2.0"));
		Test.Assert(registry.Entries[1].Path == "/projects/b");
		// The cap drops the OLDEST.
		for (int i < RecentProjectsSettings.cMaxEntries + 5)
			ProjectRegistry.TouchRecentProject(store, scope $"/projects/p{i}", "P", "0.1.0");
		Test.Assert(registry.Entries.Count == RecentProjectsSettings.cMaxEntries);
		Test.Assert(registry.Entries[0].Path == scope $"/projects/p{RecentProjectsSettings.cMaxEntries + 4}");
		Test.Assert(registry.Find("/projects/a") == null, "evicted");
	}

	[Test]
	public static void RemoveDeletesARowAndTheSectionRoundTripsTheStore()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		ProjectRegistry.TouchRecentProject(store, "/projects/keep", "Keep", "0.1.0");
		ProjectRegistry.TouchRecentProject(store, "/projects/drop", "Drop", "0.1.0");
		Test.Assert(ProjectRegistry.RemoveRecentProject(store, "/projects/drop"));
		Test.Assert(!ProjectRegistry.RemoveRecentProject(store, "/projects/drop"), "already gone");
		Test.Assert(store.Section<RecentProjectsSettings>().Entries.Count == 1);

		let dir = Scratch("scratch_registry_roundtrip", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		let fs = scope NativeFileSystem(dir);
		Test.Assert(SaveStore(fs, store) case .Ok);
		let loaded = scope Settings();
		Test.Assert(LoadStore(fs, loaded) case .Ok);
		let registry = loaded.Section<RecentProjectsSettings>();
		Test.Assert((registry.Entries.Count == 1) && (registry.Entries[0].Path == "/projects/keep") && (registry.Entries[0].Name == "Keep"));
		let missing = scope Settings();
		Test.Assert(LoadStore(fs, missing, "no.such.xml") case .Err(.NotFound), "a first run reads as defaults");
	}

	[Test]
	public static void AnEntryKeepsWhenItWasOpenedAndItsPinAndTheListItsOrderAndLastLocation()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		ProjectRegistry.TouchRecentProject(store, "/projects/a", "A", "0.1.0", 1000);
		Test.Assert(ProjectRegistry.SetRecentProjectFavourite(store, "/projects/a", true));
		Test.Assert(!ProjectRegistry.SetRecentProjectFavourite(store, "/projects/none", true));
		ProjectRegistry.TouchRecentProject(store, "/projects/a", "A", "0.1.0", 2000); // opened again: the pin stays
		let registry = store.Section<RecentProjectsSettings>();
		Test.Assert(registry.Entries.Count == 1);
		Test.Assert(registry.Entries[0].LastOpened == 2000);
		Test.Assert(registry.Entries[0].Favourite);
		registry.SortByName = true;
		registry.LastLocation.Set("/home/me/Games");

		// Opened without a time: now, by the wall clock.
		let before = GetUnixTime();
		ProjectRegistry.TouchRecentProject(store, "/projects/b", "B", "0.1.0");
		Test.Assert(registry.Find("/projects/b").LastOpened >= before);

		// They round trip the store.
		let dir = Scratch("scratch_registry_fields", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		let fs = scope NativeFileSystem(dir);
		Test.Assert(SaveStore(fs, store) case .Ok);
		let loaded = scope Settings();
		Test.Assert(LoadStore(fs, loaded) case .Ok);
		let back = loaded.Section<RecentProjectsSettings>();
		let a = back.Find("/projects/a");
		Test.Assert((a != null) && (a.LastOpened == 2000) && a.Favourite);
		Test.Assert(!back.Find("/projects/b").Favourite);
		Test.Assert(back.SortByName);
		Test.Assert(back.LastLocation == "/home/me/Games");

		// A store written before these fields existed still loads, each at its default.
		let file = PathJoin(dir, cStoreFile, .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(file, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		let old = scope String();
		for (let line in text.Split('\n'))
		{
			if (line.Contains("\"lastOpened\"") || line.Contains("\"favourite\"") || line.Contains("\"sortByName\"") || line.Contains("\"lastLocation\""))
				continue;
			old.Append(line);
			old.Append('\n');
		}
		Test.Assert(old.Length < text.Length, "the new fields were in it");
		Test.Assert(WriteFile(file, .((uint8*)old.Ptr, old.Length)) case .Ok);
		let older = scope Settings();
		Test.Assert(LoadStore(fs, older) case .Ok);
		let olderRegistry = older.Section<RecentProjectsSettings>();
		Test.Assert(olderRegistry.Entries.Count == 2);
		Test.Assert(olderRegistry.Find("/projects/a").LastOpened == 0);
		Test.Assert(!olderRegistry.Find("/projects/a").Favourite);
		Test.Assert(!olderRegistry.SortByName);
		Test.Assert(olderRegistry.LastLocation.IsEmpty);
	}

	/// The names of `entries` in order, each followed by a space.
	private static void Names(List<RecentProjectEntry> entries, String outText)
	{
		for (let entry in entries)
			outText.AppendF("{} ", entry.Name);
	}

	/// The arranged names for `query` and `byName`.
	private static void Arranged(RecentProjectsSettings registry, StringView query, bool byName, String outText)
	{
		let list = scope List<RecentProjectEntry>();
		RecentProjects.Arrange(registry, query, byName, list);
		Names(list, outText);
	}

	[Test]
	public static void AMissingProjectIsRelocatedInPlaceAndArrangingPinsSortsAndSearches()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		ProjectRegistry.TouchRecentProject(store, "/games/zeta", "Zeta", "0.1.0", 10);
		ProjectRegistry.TouchRecentProject(store, "/old/Alpha", "alpha", "0.1.0", 20);
		ProjectRegistry.TouchRecentProject(store, "/games/Mid", "Mid", "0.1.0", 30);
		let registry = store.Section<RecentProjectsSettings>();

		// Locate...: the entry takes the new folder and keeps its place; a folder already listed is refused.
		Test.Assert(ProjectRegistry.RelocateRecentProject(store, "/old/Alpha", "/games/Alpha"));
		Test.Assert(registry.Entries[1].Path == "/games/Alpha");
		Test.Assert(registry.Entries[1].LastOpened == 20);
		Test.Assert(!ProjectRegistry.RelocateRecentProject(store, "/games/Alpha", "/games/zeta"));
		Test.Assert(!ProjectRegistry.RelocateRecentProject(store, "/nowhere", "/games/new"));

		// By recency (the list's order), by name in any case, and a pinned one first in both.
		Test.Assert(Arranged(registry, "", false, .. scope .()) == "Mid alpha Zeta ");
		Test.Assert(Arranged(registry, "", true, .. scope .()) == "alpha Mid Zeta ");
		Test.Assert(ProjectRegistry.SetRecentProjectFavourite(store, "/games/zeta", true));
		Test.Assert(Arranged(registry, "", false, .. scope .()) == "Zeta Mid alpha ");
		Test.Assert(Arranged(registry, "", true, .. scope .()) == "Zeta alpha Mid ");

		// Search looks at the name and the folder, in any case.
		Test.Assert(Arranged(registry, "ALP", false, .. scope .()) == "alpha ");
		Test.Assert(Arranged(registry, "games/m", false, .. scope .()) == "Mid ");
		Test.Assert(Arranged(registry, "nothing", false, .. scope .()).IsEmpty);
	}

	[Test]
	public static void WhenAProjectWasOpenedIsSaidForAPersonByTheLocalCalendar()
	{
		let now = 1793539320L; // 2026-11-01 13:22 UTC
		Test.Assert(RecentProjects.DescribeLastOpened(0, now, 0, .. scope .()).IsEmpty, "never kept one");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 20, now, 0, .. scope .()) == "Just now");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 60, now, 0, .. scope .()) == "1 minute ago");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 45 * 60, now, 0, .. scope .()) == "45 minutes ago");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 3 * 3600, now, 0, .. scope .()) == "3 hours ago");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 14 * 3600, now, 0, .. scope .()) == "Yesterday", "23:22 the day before");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 3 * 86400, now, 0, .. scope .()) == "3 days ago");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 20 * 86400, now, 0, .. scope .()) == "2 weeks ago");
		Test.Assert(RecentProjects.DescribeLastOpened(now - 60 * 86400, now, 0, .. scope .()) == "2 Sep 2026");
		// The day turns at local midnight: 14 hours ago is today where it is 10 hours later.
		Test.Assert(RecentProjects.DescribeLastOpened(now - 14 * 3600, now, 10 * 3600, .. scope .()) == "14 hours ago");

		Test.Assert(RecentProjects.DescribeTime(0, 0, .. scope .()).IsEmpty);
		Test.Assert(RecentProjects.DescribeTime(now, 0, .. scope .()) == "1 Nov 2026, 13:22");
		Test.Assert(RecentProjects.DescribeTime(now - 13 * 3600 - 20 * 60, 0, .. scope .()) == "1 Nov 2026, 00:02");
		Test.Assert(RecentProjects.DescribeTime(now, -14 * 3600, .. scope .()) == "31 Oct 2026, 23:22");
	}

	[Test]
	public static void AFolderUnderTheHomeShowsAsTildeAWholeFolderNameOnly()
	{
		Test.Assert(RecentProjects.ShortenHomePath("/home/rob/Games/Snowline", "/home/rob", .. scope .()) == "~/Games/Snowline");
		Test.Assert(RecentProjects.ShortenHomePath("/home/rob/Games", "/home/rob/", .. scope .()) == "~/Games");
		Test.Assert(RecentProjects.ShortenHomePath("/home/rob", "/home/rob", .. scope .()) == "~");
		Test.Assert(RecentProjects.ShortenHomePath("/home/robert/Games", "/home/rob", .. scope .()) == "/home/robert/Games");
		Test.Assert(RecentProjects.ShortenHomePath("/media/usb/Jam", "/home/rob", .. scope .()) == "/media/usb/Jam");
		Test.Assert(RecentProjects.ShortenHomePath("C:\\Users\\rob\\Games", "C:\\Users\\rob", .. scope .()) == "~\\Games");
		Test.Assert(RecentProjects.ShortenHomePath("/home/rob/Games", "", .. scope .()) == "/home/rob/Games");
	}

	/// New Project's check of `name` in `inFolder` (under `root`; empty: the root itself), its folders shown
	/// under `root` as ~.
	private static void Check(StringView root, StringView name, StringView inFolder, bool ownFolder, NewProjectCheck outCheck)
	{
		let location = scope String(root);
		if (!inFolder.IsEmpty)
			PathJoin(root, inFolder, location..Clear());
		ProjectManagerController.CheckNewProject(name, location, ownFolder, root, outCheck);
	}

	[Test]
	public static void AProjectsFolderIsItsNameMadeSafeForAFileSystem()
	{
		Test.Assert(ProjectManagerController.FolderNameFor("Harbour", .. scope .()) == "Harbour");
		Test.Assert(ProjectManagerController.FolderNameFor("My Great Game", .. scope .()) == "My-Great-Game");
		Test.Assert(ProjectManagerController.FolderNameFor("Bob's Game: Part 2!", .. scope .()) == "Bobs-Game-Part-2");
		Test.Assert(ProjectManagerController.FolderNameFor("a/b\\c*d?e\"f<g>h|i", .. scope .()) == "abcdefghi");
		Test.Assert(ProjectManagerController.FolderNameFor("  spaced  -  out  ", .. scope .()) == "spaced-out");
		Test.Assert(ProjectManagerController.FolderNameFor("..hidden.", .. scope .()) == "hidden");
		Test.Assert(ProjectManagerController.FolderNameFor("v1.2_final", .. scope .()) == "v1.2_final");
		Test.Assert(ProjectManagerController.FolderNameFor("Caf\u{e9} \u{65e5}\u{672c}", .. scope .()) == "Caf\u{e9}-\u{65e5}\u{672c}"); // letters past ASCII stay
		Test.Assert(ProjectManagerController.FolderNameFor("???", .. scope .()).IsEmpty);
		Test.Assert(ProjectManagerController.FolderNameFor("con", .. scope .()) == "con-Project");
		Test.Assert(ProjectManagerController.FolderNameFor("COM3", .. scope .()) == "COM3-Project");
		Test.Assert(ProjectManagerController.FolderNameFor("Console", .. scope .()) == "Console");
	}

	[Test]
	public static void NewProjectsCheckNamesWhereItGoesAndRefusesWhatCannotBeMade()
	{
		let root = Scratch("scratch_new_project_check", .. scope .());
		defer RemoveDirectoryRecursive(root);
		Test.Assert(CreateDirectory(root));
		let taken = PathJoin(root, "Taken", .. scope .());
		Test.Assert(CreateDirectory(taken));
		Test.Assert(WriteFile(PathJoin(taken, "notes.txt", .. scope .()), .()) case .Ok);
		Test.Assert(CreateDirectory(PathJoin(root, "Empty", .. scope .())));
		Test.Assert(ProjectScaffold.Create(PathJoin(root, "Made", .. scope .()), "Made") case .Ok);
		let c = scope NewProjectCheck();

		// Green: a new folder of its name in a folder that exists.
		ProjectManagerController.CheckNewProject("Harbour", root, true, root, c);
		Test.Assert(c.Level == .Ok);
		Test.Assert(c.Target == PathJoin(root, "Harbour", .. scope .()));
		Test.Assert(c.Message == "Creates ~/Harbour, and opens it.", c.Message);
		// Without its own folder, an empty folder takes the project.
		Check(root, "Harbour", "Empty", false, c);
		Test.Assert(c.Level == .Ok);
		Test.Assert(c.Target == PathJoin(root, "Empty", .. scope .()));
		Test.Assert(c.Message == "Creates Harbour in ~/Empty, and opens it.", c.Message);
		// A sample's download says what it does instead.
		ProjectManagerController.CheckNewProject("Snowline", root, true, root, c, .Download);
		Test.Assert(c.Level == .Ok);
		Test.Assert(c.Message == "Downloads into ~/Snowline.", c.Message);
		Check(root, "Snowline", "Empty", false, c);
		Test.Assert(c.Level == .Ok);
		ProjectManagerController.CheckNewProject("Snowline", PathJoin(root, "Empty", .. scope .()), false, root, c, .Download);
		Test.Assert(c.Message == "Downloads Snowline into ~/Empty.", c.Message);

		// Red: what cannot be made, and Create waits.
		ProjectManagerController.CheckNewProject("  ", root, true, "", c);
		Test.Assert(c.Message == "Give the project a name.", c.Message);
		ProjectManagerController.CheckNewProject("???", root, true, "", c);
		Test.Assert(c.Level == .Error);
		Test.Assert(c.Message == "The name needs a letter or a digit for its folder.", c.Message);
		// Without a folder of its own, the name is the project's alone: anything goes.
		Check(root, "???", "Empty", false, c);
		Test.Assert(c.Level == .Ok);
		ProjectManagerController.CheckNewProject("Harbour", " ", true, "", c);
		Test.Assert(c.Message == "Choose the folder it is made in.", c.Message);
		Check(root, "Taken", "", true, c);
		Test.Assert(c.Level == .Error);
		Test.Assert(c.Message == "~/Taken already exists and has files in it. Choose another name or folder.", c.Message);
		Check(root, "Harbour", "Taken", false, c);
		Test.Assert(c.Message == "~/Taken already has files in it. A project needs an empty folder: turn on the folder option, or choose an empty one.", c.Message);
		Check(root, "Made", "", true, c);
		Test.Assert(c.Message == "~/Made is a project already: Open Folder opens it.", c.Message);
		Check(root, "Harbour", "Taken/notes.txt", true, c);
		Test.Assert(c.Message == "~/Taken/notes.txt is a file, not a folder.", c.Message);

		// Amber: it goes ahead, but says what it will do.
		Check(root, "Harbour", "Later/Games", true, c);
		Test.Assert(c.Level == .Warning);
		Test.Assert(c.Message == "~/Later/Games does not exist yet; it will be made, then Harbour inside it.", c.Message);
		Check(root, "Harbour", "Later", false, c);
		Test.Assert(c.Message == "~/Later does not exist yet; it will be made, and the project made in it.", c.Message);
		// Green with a folder made safe from the name, which the project keeps as typed (trimmed).
		Check(root, " Bob's Game: Part 2! ", "", true, c);
		Test.Assert(c.Level == .Ok);
		Test.Assert(c.Name == "Bob's Game: Part 2!");
		Test.Assert(c.Target == PathJoin(root, "Bobs-Game-Part-2", .. scope .()));
		Test.Assert(c.Message == "Creates ~/Bobs-Game-Part-2, and opens it.", c.Message);
		Test.Assert(!DirectoryExists(PathJoin(root, "Later", .. scope .())), "checking makes nothing");
	}

	[Test]
	public static void ProbeReadsTheManifestWithoutOpeningAndNotFoundForNonProjects()
	{
		let dir = Scratch("scratch_registry_probe", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(dir, probed) case .Err(.NotFound), "no directory at all");
		Test.Assert(ProjectScaffold.Create(dir, "Probe Me") case .Ok);
		Test.Assert(ProjectRegistry.ProbeProject(dir, probed) case .Ok);
		Test.Assert((probed.Name == "Probe Me") && (probed.EngineVersion == EngineVersion.String));
	}

	[Test]
	public static void TheEngineVersionRelation()
	{
		// Relative stamps from the constants, so the test stays true when the engine bumps.
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion(EngineVersion.String) == .Same);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion(scope $"{EngineVersion.Major}.{EngineVersion.Minor}.{EngineVersion.Patch}") == .Same);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion(scope $"{EngineVersion.Major + 1}.0.0") == .ProjectNewer);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion(scope $"{EngineVersion.Major}.{EngineVersion.Minor}.{EngineVersion.Patch + 1}") == .ProjectNewer);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("0.0.9") == .ProjectOlder, "0.0.x is always below a version starting 0.1.0");
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("") == .Unstamped);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("abc") == .Unstamped);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("1.2") == .Unstamped);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("1..2") == .Unstamped);
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("1.2.3.4") == .Unstamped);
	}

	[Test]
	public static void TheManifestBackupCopiesProjectXmlBesideItself()
	{
		let dir = Scratch("scratch_registry_backup", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(ProjectScaffold.Create(dir, "Backup Me") case .Ok);
		let backup = scope String();
		Test.Assert(ProjectRegistry.BackupProjectManifest(dir, backup) case .Ok);
		Test.Assert(FileExists(backup) && backup.EndsWith(scope $".{EngineVersion.String}.bak"));
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(dir, probed) case .Ok, "the original is untouched");
		Test.Assert(ProjectRegistry.BackupProjectManifest(Scratch("scratch_registry_no_such_dir", .. scope .()), scope String()) case .Err);
	}

	[Test]
	public static void TheControllerGatesOpensComposesPromptsAndPassesThroughToTheRegistry()
	{
		EditorProjectsSerializables.RegisterAll();
		let store = scope Settings();
		let controller = scope ProjectManagerController(store);
		let decision = scope ProjectOpenDecision();
		controller.DecideOpen(Scratch("scratch_manager_no_such_dir", .. scope .()), decision);
		Test.Assert(decision.Gate == .NotAProject);

		// A freshly scaffolded project is stamped with THIS engine: opens directly.
		let dir = Scratch("scratch_manager_gate", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(controller.Create(dir, "Gate Test") case .Ok);
		controller.DecideOpen(dir, decision);
		Test.Assert((decision.Gate == .OpenDirectly) && (decision.Header.Name == "Gate Test"));

		// The manifest rewritten with a NEWER stamp by a raw text edit: Save re-stamps to
		// the current engine by design, so it cannot write a foreign version.
		let manifest = PathJoin(dir, ProjectLayout.ManifestFile, .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(manifest, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		Test.Assert(text.Contains(EngineVersion.String));
		text.Replace(EngineVersion.String, "99.0.0");
		Test.Assert(WriteFile(manifest, .((uint8*)text.Ptr, text.Length)) case .Ok);
		controller.DecideOpen(dir, decision);
		Test.Assert(decision.Gate == .PromptNewerEngine);
		// Opened anyway, a newer engine's project keeps its stamp; only an older one's is upgraded.
		Test.Assert(!ProjectManagerController.RestampsOnOpen(decision.Gate));
		Test.Assert(ProjectManagerController.RestampsOnOpen(.PromptOlderBackup));
		Test.Assert(!ProjectManagerController.RestampsOnOpen(.OpenDirectly));
		Test.Assert(decision.PromptBody.Contains("99.0.0") && decision.PromptBody.Contains(EngineVersion.String));

		// An older stamp offers the backup.
		text.Replace("99.0.0", "0.0.1");
		Test.Assert(WriteFile(manifest, .((uint8*)text.Ptr, text.Length)) case .Ok);
		controller.DecideOpen(dir, decision);
		Test.Assert((decision.Gate == .PromptOlderBackup) && decision.PromptBody.Contains("0.0.1"));

		controller.NoteOpened(dir, "Gate Test", "0.1.0");
		Test.Assert(controller.Entries.Entries.Count == 1);
		Test.Assert(controller.SetFavourite(dir, true));
		Test.Assert(controller.Entries.Entries[0].Favourite);
		controller.SetSortByName(true);
		Test.Assert(controller.SortByName);
		controller.SetLastLocation("/home/me/Games");
		Test.Assert(controller.LastLocation == "/home/me/Games");
		Test.Assert(controller.Remove(dir));
		Test.Assert(controller.Entries.Entries.IsEmpty);

		// Locate... takes only a folder holding a project, and refreshes the entry from it; Remove
		// missing takes off the list every entry whose folder holds none, and touches no files.
		controller.NoteOpened("scratch_manager_gone", "Old name", "0.0.1");
		controller.NoteOpened("scratch_manager_gone_too", "Gone", "0.0.1");
		controller.NoteOpened(dir, "Gate Test", "0.1.0");
		Test.Assert(!controller.Relocate("scratch_manager_gone", "scratch_manager_no_such_dir"));
		Test.Assert(!controller.Relocate("scratch_manager_gone", dir), "listed already");
		Test.Assert(controller.Remove(dir));
		Test.Assert(controller.Relocate("scratch_manager_gone", dir));
		let moved = controller.Entries.Find(dir);
		Test.Assert((moved != null) && (moved.Name == "Gate Test"));
		Test.Assert(controller.RemoveMissing() == 1);
		Test.Assert(controller.Entries.Entries.Count == 1);
		Test.Assert(controller.Entries.Entries[0].Path == dir);
		Test.Assert(DirectoryExists(dir));
	}
}
