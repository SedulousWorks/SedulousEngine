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

namespace Sedulous.Editor.Core.Tests;

/// The project registry and the manager controller: recency ordering, removal, the store
/// round trip, the probe, the version relation, the manifest backup, the open gates, and
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
		Test.Assert(decision.PromptBody.Contains("99.0.0") && decision.PromptBody.Contains(EngineVersion.String));

		// An older stamp offers the backup.
		text.Replace("99.0.0", "0.0.1");
		Test.Assert(WriteFile(manifest, .((uint8*)text.Ptr, text.Length)) case .Ok);
		controller.DecideOpen(dir, decision);
		Test.Assert((decision.Gate == .PromptOlderBackup) && decision.PromptBody.Contains("0.0.1"));

		controller.NoteOpened(dir, "Gate Test", "0.1.0");
		Test.Assert(controller.Entries.Entries.Count == 1);
		Test.Assert(controller.Remove(dir));
		Test.Assert(controller.Entries.Entries.IsEmpty);
	}

	[Test]
	public static void EveryRegisteredSectionTypeIsInstantiable()
	{
		// A section the store cannot instantiate makes every later Load abort at it and
		// drop the sections after: the empty project list incident.
		EditorSerializables.RegisterAll();
		for (let type in scope Type[](typeof(EditorFontSettings), typeof(EditorUiSettings), typeof(EditorMcpSettings), typeof(RecentProjectsSettings), typeof(EditorExportSettings)))
		{
			let name = type.GetFullName(.. scope .());
			let made = GlobalSerializableRegistry.Create(TypeIdOf(name));
			Test.Assert(made != null, name);
			delete made;
		}
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
		store.Section<EditorFontSettings>().FontPath.Set("/fonts/ui.ttf");
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
		Test.Assert(loaded.Find<EditorFontSettings>().FontPath == "/fonts/ui.ttf");
	}
}
