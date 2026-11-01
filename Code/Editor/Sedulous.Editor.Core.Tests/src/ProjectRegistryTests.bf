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
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The project registry and the manager controller: recency ordering, removal, the store
/// round trip, when each was opened and its pin, relocating, arranging and saying when, the probe, the version relation, the manifest backup, the open gates, and
/// every settings section instantiable and surviving a round trip.
static class ProjectRegistryTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	[Test]
	public static void TouchInsertsMostRecentFirstDedupesAndCaps()
	{
		EditorSerializables.RegisterAll();
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
		EditorSerializables.RegisterAll();
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
		Test.Assert(EditorSettingsStore.Save(fs, store) case .Ok);
		let loaded = scope Settings();
		Test.Assert(EditorSettingsStore.Load(fs, loaded) case .Ok);
		let registry = loaded.Section<RecentProjectsSettings>();
		Test.Assert((registry.Entries.Count == 1) && (registry.Entries[0].Path == "/projects/keep") && (registry.Entries[0].Name == "Keep"));
		let missing = scope Settings();
		Test.Assert(EditorSettingsStore.Load(fs, missing, "no.such.xml") case .Err(.NotFound), "a first run reads as defaults");
	}

	[Test]
	public static void AnEntryKeepsWhenItWasOpenedAndItsPinAndTheListItsOrderAndLastLocation()
	{
		EditorSerializables.RegisterAll();
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
		Test.Assert(EditorSettingsStore.Save(fs, store) case .Ok);
		let loaded = scope Settings();
		Test.Assert(EditorSettingsStore.Load(fs, loaded) case .Ok);
		let back = loaded.Section<RecentProjectsSettings>();
		let a = back.Find("/projects/a");
		Test.Assert((a != null) && (a.LastOpened == 2000) && a.Favourite);
		Test.Assert(!back.Find("/projects/b").Favourite);
		Test.Assert(back.SortByName);
		Test.Assert(back.LastLocation == "/home/me/Games");

		// A store written before these fields existed still loads, each at its default.
		let file = PathJoin(dir, EditorSettingsStore.cFileName, .. scope .());
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
		Test.Assert(EditorSettingsStore.Load(fs, older) case .Ok);
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
		ProjectRegistry.ArrangeRecentProjects(registry, query, byName, list);
		Names(list, outText);
	}

	[Test]
	public static void AMissingProjectIsRelocatedInPlaceAndArrangingPinsSortsAndSearches()
	{
		EditorSerializables.RegisterAll();
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
		Test.Assert(ProjectRegistry.DescribeLastOpened(0, now, 0, .. scope .()).IsEmpty, "never kept one");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 20, now, 0, .. scope .()) == "Just now");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 60, now, 0, .. scope .()) == "1 minute ago");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 45 * 60, now, 0, .. scope .()) == "45 minutes ago");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 3 * 3600, now, 0, .. scope .()) == "3 hours ago");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 14 * 3600, now, 0, .. scope .()) == "Yesterday", "23:22 the day before");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 3 * 86400, now, 0, .. scope .()) == "3 days ago");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 20 * 86400, now, 0, .. scope .()) == "2 weeks ago");
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 60 * 86400, now, 0, .. scope .()) == "2 Sep 2026");
		// The day turns at local midnight: 14 hours ago is today where it is 10 hours later.
		Test.Assert(ProjectRegistry.DescribeLastOpened(now - 14 * 3600, now, 10 * 3600, .. scope .()) == "14 hours ago");

		Test.Assert(ProjectRegistry.DescribeTime(0, 0, .. scope .()).IsEmpty);
		Test.Assert(ProjectRegistry.DescribeTime(now, 0, .. scope .()) == "1 Nov 2026, 13:22");
		Test.Assert(ProjectRegistry.DescribeTime(now - 13 * 3600 - 20 * 60, 0, .. scope .()) == "1 Nov 2026, 00:02");
		Test.Assert(ProjectRegistry.DescribeTime(now, -14 * 3600, .. scope .()) == "31 Oct 2026, 23:22");
	}

	[Test]
	public static void ProbeReadsTheManifestWithoutOpeningAndNotFoundForNonProjects()
	{
		let dir = Scratch("scratch_registry_probe", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(dir, probed) case .Err(.NotFound), "no directory at all");
		Test.Assert(EditorProject.Create(dir, "Probe Me") case .Ok);
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
		Test.Assert(EditorProject.Create(dir, "Backup Me") case .Ok);
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
		EditorSerializables.RegisterAll();
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
		Test.Assert((decision.Gate == .OpenDirectly) && (decision.Probed.Name == "Gate Test"));

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

	[Test]
	public static void EveryRegisteredSectionTypeIsInstantiable()
	{
		// A section the store cannot instantiate makes every later Load abort at it and
		// drop the sections after: the empty project list incident.
		// Every type the editor's registration puts in a table, asked of the table, not a list
		// kept by hand here: a hand list is what let the shortcut section land uncovered.
		let registry = scope SerializableRegistry();
		EditorSerializables.RegisterAll(registry);
		let ids = scope List<uint64>();
		registry.CopyIds(ids);
		for (let id in ids)
		{
			let made = registry.Create(id);
			Test.Assert(made != null, scope $"type id {id}");
			delete made;
		}
		// Export, ui, mcp, shortcuts (and its entry), recent projects (and its entry), at least.
		Test.Assert(ids.Count >= 8);
		for (let type in scope Type[](typeof(EditorShortcutSettings), typeof(ShortcutOverrideEntry), typeof(RecentProjectsSettings)))
			Test.Assert(registry.IsRegistered(TypeIdOf(type.GetFullName(.. scope .()))));
	}

	[Test]
	public static void TheMcpSectionRoundTripsAndAMintedTokenIsAFreshGuid()
	{
		EditorSerializables.RegisterAll();
		// Defaults: off, the documented port, no token yet.
		{
			let store = scope Settings();
			let mcp = store.Section<EditorMcpSettings>();
			Test.Assert(!mcp.Enabled);
			Test.Assert(mcp.Port == EditorMcpSettings.DefaultPort);
			Test.Assert(mcp.Token.IsEmpty);
		}
		let store = scope Settings();
		let mcp = store.Section<EditorMcpSettings>();
		mcp.Enabled = true;
		mcp.Port = 7500;
		EditorMcpSettings.GenerateToken(mcp.Token);
		Test.Assert(mcp.Token.Length == 36);
		Test.Assert(EditorMcpSettings.GenerateToken(.. scope .()) != mcp.Token); // every mint is a new secret

		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let back = loaded.Find<EditorMcpSettings>();
		Test.Assert(back != null);
		Test.Assert(back.Enabled);
		Test.Assert(back.Port == 7500);
		Test.Assert(back.Token == mcp.Token);
	}

	[Test]
	public static void TheMcpSectionTakesThePreferencesFieldsRefusingABadPort()
	{
		let mcp = scope EditorMcpSettings();
		mcp.Token.Set("old");
		Test.Assert(mcp.ApplyFromPreferences(true, "7500", "new"));
		Test.Assert(mcp.Enabled);
		Test.Assert(mcp.Port == 7500);
		Test.Assert(mcp.Token == "new");
		// A port outside 1024..65535, or not a number, is refused and the port stands.
		Test.Assert(!mcp.ApplyFromPreferences(true, "80", "new"));
		Test.Assert(!mcp.ApplyFromPreferences(true, "70000", "new"));
		Test.Assert(!mcp.ApplyFromPreferences(true, "lots", "new"));
		Test.Assert(mcp.Port == 7500);
		// Disabling with an empty token: off, and the next enable mints a fresh secret.
		Test.Assert(mcp.ApplyFromPreferences(false, "7500", ""));
		Test.Assert(!mcp.Enabled);
		Test.Assert(mcp.Token.IsEmpty);
	}

	[Test]
	public static void AStoreWithEverySectionRoundTrips()
	{
		EditorSerializables.RegisterAll();
		let store = scope Settings();
		store.Section<EditorUiSettings>().UiScale = 1.2f;
		store.Section<EditorUiSettings>().Scheme.Set("light");
		store.Section<EditorUiSettings>().Accent.Set("#0f8a7e");
		store.Section<EditorUiSettings>().Density.Set("comfortable");
		store.Section<EditorUiSettings>().ReduceMotion = true;
		ProjectRegistry.TouchRecentProject(store, "/proj/a", "A", "0.1.0");
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let registry = loaded.Find<RecentProjectsSettings>();
		Test.Assert((registry != null) && (registry.Entries.Count == 1) && (registry.Entries[0].Name == "A"));
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert((ui != null) && (Math.Abs(ui.UiScale - 1.2f) < 1e-5f));
		Test.Assert(ui.Scheme == "light"); // the look's inputs (appended 2026-10-27)
		Test.Assert(ui.Accent == "#0f8a7e");
		Test.Assert(ui.Density == "comfortable");
		Test.Assert(ui.ReduceMotion);
	}

	/// The font section the editor kept before its fonts became its sheet's (the type is gone):
	/// its paths, under its old identity and version.
	private class LegacyFontSection : ISerializable
	{
		public const String cTypeName = "Sedulous.Editor.Core.EditorFontSettings";
		public String FontPath = new .() ~ delete _;
		public String MonoFontPath = new .() ~ delete _;

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, TypeIdOf(cTypeName), 1);
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "fontPath", FontPath);
			Sedulous.Core.Serialization.Serialize(ar, "monoFontPath", MonoFontPath);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	/// A store still holding the font section loads: the section no type reads is kept aside (and
	/// written back, so an older build keeps its paths), and the sections after it read as ever.
	[Test]
	public static void AStoreStillHoldingTheFontSectionLoadsTheSectionsAfterIt()
	{
		EditorSerializables.RegisterAll();
		Test.Assert(GlobalSerializableRegistry.Create(TypeIdOf(LegacyFontSection.cTypeName)) == null, "no type reads it now");
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let fonts = scope LegacyFontSection();
			fonts.FontPath.Set("/fonts/ui.ttf");
			let ui = scope EditorUiSettings();
			ui.UiScale = 1.25f;
			ui.Scheme.Set("light");
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			uint32 count = 2;
			archive.Key("sections");
			archive.BeginArray(ref count);
			// The font section first, so a load that stopped at it would lose the UI's.
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(LegacyFontSection.cTypeName);
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			fonts.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(typeof(EditorUiSettings).GetFullName(.. scope .()));
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			(ui as ISerializable).Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}

		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 1, "kept aside, not refused");
		Test.Assert(loaded.SectionCount == 1);
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert(ui != null, "the section after it read");
		Test.Assert(Math.Abs(ui.UiScale - 1.25f) < 1e-5f);
		Test.Assert(ui.Scheme == "light");

		// Saved again, the kept section goes back out with its paths.
		let again = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(loaded.Save(again, factory) case .Ok);
		let text = scope String((char8*)again.Bytes.Ptr, again.Bytes.Length);
		Test.Assert(text.Contains(LegacyFontSection.cTypeName) && text.Contains("/fonts/ui.ttf"));
		again.Seek(0, .Begin);
		let reloaded = scope Settings();
		Test.Assert(reloaded.Load(again, factory) case .Ok);
		Test.Assert((reloaded.UnknownSectionCount == 1) && (reloaded.Find<EditorUiSettings>() != null));
	}

	/// The UI section as the editor saved it before the look's inputs: the scale and axis views
	/// only, under the section's identity and version.
	private class LegacyUiSection : ISerializable
	{
		public float UiScale = 1.0f;
		public bool AutoOrthographic = true;

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, EditorUiSettings.TypeId, EditorUiSettings.DataVersion);
			ar.BeginObject();
			SerializeValue(ar, "uiScale", ref UiScale);
			SerializeValue(ar, "autoOrthographic", ref AutoOrthographic);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	/// A settings file from before the look's inputs reads through the store: what it has comes
	/// back, the inputs it lacks are their defaults, and saved again it carries them.
	[Test]
	public static void AUiSectionSavedBeforeTheLooksInputsReadsWithThemAtTheirDefaults()
	{
		EditorSerializables.RegisterAll();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let legacy = scope LegacyUiSection();
			legacy.UiScale = 1.5f;
			legacy.AutoOrthographic = false;
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			Test.Assert(archive.IsSelfDescribing, "a self describing file has no format version to write");
			uint32 count = 1;
			archive.Key("sections");
			archive.BeginArray(ref count);
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(typeof(EditorUiSettings).GetFullName(.. scope .()));
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			legacy.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		Test.Assert(!text.Contains("scheme") && !text.Contains("accent"), "written without the inputs");

		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert(ui != null, "read, not refused");
		Test.Assert(Math.Abs(ui.UiScale - 1.5f) < 1e-5f);
		Test.Assert(!ui.AutoOrthographic);
		Test.Assert(ui.Scheme == "dark");
		Test.Assert(ui.Accent == "#2f6fdf");
		Test.Assert(ui.Density == "compact");
		Test.Assert(!ui.ReduceMotion);

		// Saved again, the inputs are in it and read back.
		ui.Scheme.Set("light");
		let again = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(loaded.Save(again, factory) case .Ok);
		again.Seek(0, .Begin);
		let reloaded = scope Settings();
		Test.Assert(reloaded.Load(again, factory) case .Ok);
		let back = reloaded.Find<EditorUiSettings>();
		Test.Assert((back != null) && (back.Scheme == "light") && (back.Accent == "#2f6fdf") && !back.AutoOrthographic);
	}

	/// The Game tab's preview resolutions: the common sizes seed once, a user's removal stays
	/// removed, and the list round trips through the store.
	[Test]
	public static void ThePreviewResolutionsSeedOnceAndRoundTrip()
	{
		EditorSerializables.RegisterAll();
		Test.Assert(GamePreviewSettings.From(null) == null, "no store, nothing");
		let store = scope Settings();
		let previews = GamePreviewSettings.From(store);
		Test.Assert(previews.Seeded && (previews.Presets.Count == 6));
		Test.Assert((previews.Presets[3].Name == "Steam Deck") && (previews.Presets[3].Width == 1280) && (previews.Presets[3].Height == 800));

		ClearAndDeleteItems!(previews.Presets);
		previews.Presets.Add(new .("Handheld", 960, 544));
		Test.Assert(GamePreviewSettings.From(store).Presets.Count == 1, "not seeded again");

		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let back = GamePreviewSettings.From(loaded);
		Test.Assert((back.Presets.Count == 1) && (back.Presets[0].Name == "Handheld") && (back.Presets[0].Width == 960) && (back.Presets[0].Height == 544));
	}
}
