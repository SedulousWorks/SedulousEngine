using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Look;
using Sedulous.Editor.ProjectManager;
using Sedulous.Editor.Projects.TestSupport;

namespace Sedulous.Editor.ProjectManager.Tests;

/// The project manager's program run headless over scratch files in place of the user's: the
/// recent list taken from the editor's store into projects.xml the first time and never again;
/// and the SDK it sits in registered (one listed already keeping how it was listed) and its own
/// executable recorded. How Open builds and launches a project's editor is OpenTests'.
class ProjectManagerProgramTests
{
	private class Bed
	{
		public String Root = new .() ~ delete _;
		public String Projects = new .() ~ delete _;
		public String EditorSettings = new .() ~ delete _;
		public String Sdks = new .() ~ delete _;

		public this(StringView leaf)
		{
			PathJoin(GetCurrentDirectory(.. scope .()), leaf, Root);
			RemoveDirectoryRecursive(Root);
			Test.Assert(CreateDirectory(Root));
			PathJoin(Root, "projects.xml", Projects);
			PathJoin(Root, "editor.settings.xml", EditorSettings);
			PathJoin(Root, "sdks.xml", Sdks);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(Root);
		}

		/// A config over the bed's files, with the data root `dataRoot` (empty: none). The caller's.
		public ProjectManagerConfig Config(StringView dataRoot = default)
		{
			let config = new ProjectManagerConfig();
			config.ProjectsPath.Set(Projects);
			config.EditorSettingsPath.Set(EditorSettings);
			config.SdksPath.Set(Sdks);
			PathJoin(Root, "theme", config.ThemeFolder);
			config.DataRoot.Set(dataRoot);
			return config;
		}

		/// The editor's store written with `store`'s sections.
		public void WriteEditorSettings(Settings store)
		{
			let buffer = scope MemoryStream();
			let factory = XmlSerializerFactory();
			defer delete factory;
			Test.Assert(store.Save(buffer, factory) case .Ok);
			Test.Assert(WriteFile(EditorSettings, buffer.Bytes) case .Ok);
		}
	}

	[Test]
	public static void TheRecentListIsTakenFromTheEditorsStoreOnceIntoItsOwnFile()
	{
		let bed = scope Bed("scratch_manager_program_migration");
		{
			let editor = scope Settings();
			ProjectRegistry.TouchRecentProject(editor, "/games/Harbour", "Harbour", "0.1.0");
			ProjectRegistry.TouchRecentProject(editor, "/games/Lighthouse", "Lighthouse", "0.1.0");
			let recent = editor.Section<RecentProjectsSettings>();
			recent.GridView = true;
			recent.LastLocation.Set("/games");
			recent.Entries[1].Favourite = true;
			editor.Section<EditorUiSettings>().Scheme.Set("light"); // a section of the editor's own, passed by
			bed.WriteEditorSettings(editor);
		}
		{
			let program = scope ProjectManagerProgram(bed.Config());
			program.Start();
			Test.Assert(program.Migrated);
			Test.Assert(FileExists(bed.Projects), "projects.xml written");
			let recent = program.Projects.Entries;
			Test.Assert(recent.Entries.Count == 2);
			Test.Assert((recent.Entries[0].Path == "/games/Lighthouse") && (recent.Entries[0].Name == "Lighthouse"));
			Test.Assert((recent.Entries[1].Path == "/games/Harbour") && recent.Entries[1].Favourite);
			Test.Assert(recent.GridView);
			Test.Assert(recent.LastLocation == "/games");
		}

		// The editor's store changes after: projects.xml is the list now, and is not taken again.
		{
			let editor = scope Settings();
			ProjectRegistry.TouchRecentProject(editor, "/games/Quarry", "Quarry", "0.1.0");
			bed.WriteEditorSettings(editor);
		}
		let again = scope ProjectManagerProgram(bed.Config());
		again.Start();
		Test.Assert(!again.Migrated);
		Test.Assert(again.Projects.Entries.Entries.Count == 2);
		Test.Assert(again.Projects.Entries.Find("/games/Quarry") == null);

		// With no editor store at all, the first start writes an empty list and takes nothing.
		Test.Assert(System.IO.File.Delete(bed.Projects) case .Ok);
		Test.Assert(System.IO.File.Delete(bed.EditorSettings) case .Ok);
		let fresh = scope ProjectManagerProgram(bed.Config());
		fresh.Start();
		Test.Assert(!fresh.Migrated);
		Test.Assert(fresh.Projects.Entries.Entries.IsEmpty);
		Test.Assert(FileExists(bed.Projects));
	}

	[Test]
	public static void ItRegistersTheSdkItSitsInKeepingHowItWasListedAndRecordsItsExecutable()
	{
		let bed = scope Bed("scratch_manager_program_sdk");
		let sdk = PathJoin(bed.Root, "sdk", .. scope .());
		// A packed SDK: its sdk.json says what it is (a checkout would need its version file).
		ProjectBuildBed.WriteSdk(sdk, "{\n  \"version\": \"0.1.0\",\n  \"label\": \"beta\",\n  \"display\": \"0.1.0-beta\",\n  \"buildNumber\": 1,\n  \"platform\": \"Linux64\",\n  \"beef\": \"nightly-2026-11-01\",\n  \"created\": \"2026-11-10T12:00:00Z\"\n}\n");
		let data = PathJoin(sdk, "Data", .. scope .());
		let exe = PathJoin(sdk, "ProjectManager/Sedulous.Tools.ProjectManager", .. scope .());
		let registry = scope SdkRegistry(bed.Sdks);

		{
			let config = bed.Config(data);
			config.ExecutablePath.Set(exe);
			let program = scope ProjectManagerProgram(config);
			program.Start();
			Test.Assert(program.Sdk == sdk);
		}
		let sdks = scope List<SdkInfo>();
		defer { ClearAndDeleteItems!(sdks); }
		let missing = scope List<String>();
		defer { ClearAndDeleteItems!(missing); }
		Test.Assert(registry.ReadSdks(sdks, missing));
		Test.Assert((sdks.Count == 1) && (sdks[0].Root == sdk) && missing.IsEmpty);
		Test.Assert(registry.ManagerPath(.. scope .()) == exe, "this executable recorded");

		// One the manager installed stays listed as installed when a manager in it starts.
		Test.Assert(registry.Register(sdk, true) case .Ok);
		{
			let program = scope ProjectManagerProgram(bed.Config(data));
			program.Start();
		}
		let store = scope Settings();
		Test.Assert(registry.Load(store) case .Ok);
		let listed = store.Section<SdkRegistrySettings>();
		Test.Assert(listed.Sdks.Count == 1);
		Test.Assert(listed.Sdks[0].Managed, "kept as it was listed");
		Test.Assert(listed.ManagerPath == exe, "no executable given: the last one recorded stays");

		// A data root whose parent is no SDK: nothing registered, and no SDK to open projects with.
		let elsewhere = PathJoin(bed.Root, "loose/Data", .. scope .());
		let loose = scope ProjectManagerProgram(bed.Config(elsewhere));
		loose.Start();
		Test.Assert(loose.Sdk.IsEmpty);
		ClearAndDeleteItems!(sdks);
		ClearAndDeleteItems!(missing);
		Test.Assert(registry.ReadSdks(sdks, missing) && (sdks.Count == 1));
	}
}
