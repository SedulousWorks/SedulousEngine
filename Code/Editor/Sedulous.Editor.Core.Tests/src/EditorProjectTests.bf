using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core.Tests;

/// A project scaffolds, opens, and refuses what it should.
static class EditorProjectTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	[Test]
	public static void CreateScaffoldsAndOpenReadsItBack()
	{
		let dir = Scratch("scratch_editor_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		Test.Assert(EditorProject.Create(dir, "Demo") case .Ok, "created");
		Test.Assert(EditorProject.Create(dir, "Demo") case .Err(.AlreadyExists), "a second create is refused");
		for (let sub in scope String[](ProjectLayout.ContentDir, ProjectLayout.SourcesDir, ProjectLayout.CookedDir, ProjectLayout.EditorDir, ProjectLayout.CacheDir))
			Test.Assert(DirectoryExists(PathJoin(dir, sub, .. scope .())), sub);

		let project = EditorProject.Open(dir);
		Test.Assert(project != null, "opened");
		defer delete project;
		Test.Assert(project.Name == "Demo");
		Test.Assert(project.Directory == dir);
		Test.Assert(project.Settings.EngineVersion == EngineVersion.String, "the manifest was stamped");
		Test.Assert((project.SourceDb != null) && (project.CookedDb != null));
		Test.Assert(project.SourceDb.Extension == ProjectLayout.SourceAssetExtension);
		Test.Assert(project.CookedDb.Extension == ProjectLayout.CookedAssetExtension);
		Test.Assert(project.SourcesRoot(.. scope .()).EndsWith(ProjectLayout.SourcesDir));
		Test.Assert(project.CacheRoot(.. scope .()).EndsWith(ProjectLayout.CacheDir));

		// A generated directory removed by a checkout comes back on open.
		RemoveDirectoryRecursive(PathJoin(dir, ProjectLayout.CookedDir, .. scope .()));
		let again = EditorProject.Open(dir);
		Test.Assert(again != null);
		defer delete again;
		Test.Assert(DirectoryExists(PathJoin(dir, ProjectLayout.CookedDir, .. scope .())));

		// Settings changed and saved read back.
		again.Settings.DefaultScene.Set("Scenes/Main");
		Test.Assert(again.SaveSettings() case .Ok);
		let third = EditorProject.Open(dir);
		defer delete third;
		Test.Assert((third != null) && (third.Settings.DefaultScene == "Scenes/Main"));
	}

	[Test]
	public static void OpenRefusesADirectoryWithNoManifest()
	{
		let dir = Scratch("scratch_editor_project_bare", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		Test.Assert(EditorProject.Open(dir) == null, "no manifest, no project");
		Test.Assert(!DirectoryExists(PathJoin(dir, ProjectLayout.ContentDir, .. scope .())), "and nothing scaffolded on the sly");
	}

	/// A logger that keeps what it was told, for asserting on what a failure said.
	private class CaptureLogger : ILogger
	{
		public LogLevel MinimumLogLevel { get; set; } = .Trace;
		public String Name { get; private set; } = new .("capture") ~ delete _;
		public int Errors = 0;
		public String Last = new .() ~ delete _;

		public void Log(LogLevel logLevel, StringView format, params Object[] args)
		{
			if (logLevel != .Error)
				return;
			Errors++;
			Last.Clear();
			Last.AppendF(format, params args);
		}
	}

	[Test]
	public static void AnUnreadableManifestLogsAnErrorAndAMissingOneStaysSilent()
	{
		let capture = new CaptureLogger();
		InitGlobalLogger(capture, true);
		defer ShutdownGlobalLogger();

		// Absent: the scaffold path, no noise.
		let missing = Scratch("scratch_editor_project_silent", .. scope .());
		Test.Assert(EditorProject.Open(missing) == null);
		Test.Assert(capture.Errors == 0);

		// Present but unparseable, a pre versioning format say: loud, since a shell only
		// shows a status line and the log line is the signal.
		let dir = Scratch("scratch_editor_project_corrupt", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(CreateDirectory(dir));
		let garbage = "<root><string name=\"name\">P</string></root>";
		Test.Assert(WriteFile(PathJoin(dir, ProjectLayout.ManifestFile, .. scope .()), .((uint8*)garbage.Ptr, garbage.Length)) case .Ok);
		Test.Assert(EditorProject.Open(dir) == null);
		Test.Assert(capture.Errors == 1);
		Test.Assert(capture.Last.Contains(ProjectLayout.ManifestFile));
	}

	[Test]
	public static void SettingsGuidsPersistThroughSaveSettings()
	{
		let dir = Scratch("scratch_editor_project_save", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);

		let sceneId = Guid.Parse("6ba7b810-9dad-11d1-80b4-00c04fd430c8").Get();
		let themeId = Guid.Parse("6ba7b811-9dad-11d1-80b4-00c04fd430c8").Get();
		let mapId = Guid.Parse("6ba7b812-9dad-11d1-80b4-00c04fd430c8").Get();
		let fontId = Guid.Parse("6ba7b813-9dad-11d1-80b4-00c04fd430c8").Get();
		let scriptId = Guid.Parse("6ba7b814-9dad-11d1-80b4-00c04fd430c8").Get();
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			Test.Assert(!project.Settings.StartupScriptId.IsSet);
			project.Settings.DefaultScene.Set("scenes/main");
			project.Settings.DefaultSceneId = sceneId;
			project.Settings.DefaultUiThemeId = themeId;
			project.Settings.DefaultInputMapId = mapId;
			project.Settings.DefaultUiFontId = fontId;
			project.Settings.StartupScriptId = scriptId;
			Test.Assert(project.SaveSettings() case .Ok);
		}
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			Test.Assert(project.Settings.DefaultScene == "scenes/main");
			// Every guid field comes back: a per field settings move that DROPS one is
			// silent data loss, which is what this guards.
			Test.Assert(project.Settings.DefaultSceneId == sceneId);
			Test.Assert(project.Settings.DefaultUiThemeId == themeId);
			Test.Assert(project.Settings.DefaultInputMapId == mapId);
			Test.Assert(project.Settings.DefaultUiFontId == fontId);
			Test.Assert(project.Settings.StartupScriptId == scriptId);
		}
	}

	[Test]
	public static void TheSourceDbIsXmlAndTheCookedDbIsBinaryAndBothRoundTrip()
	{
		TestSerializables.RegisterAll();
		let dir = Scratch("scratch_editor_project_dbs", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);

		let typeName = typeof(TestMaterial).GetFullName(.. scope .());
		Guid sourceId = .Empty;
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let source = project.SourceDb.RootGroup.CreateGroup("materials").CreateInstance("steel", typeName);
			Test.Assert(source != null);
			sourceId = source.Id;
			let material = scope TestMaterial();
			material.Shininess = 7;
			Test.Assert(source.WriteObject(material) case .Ok);
			let cooked = project.CookedDb.RootGroup.CreateGroup("materials").CreateInstance("steel", typeName);
			Test.Assert(cooked != null);
			Test.Assert(cooked.WriteObject(material) case .Ok);
		}
		// The envelope extensions follow the split: source readable XML, cooked binary.
		Test.Assert(FileExists(PathJoin(dir, scope $"{ProjectLayout.ContentDir}/materials/steel.{ProjectLayout.SourceAssetExtension}", .. scope .())));
		Test.Assert(FileExists(PathJoin(dir, scope $"{ProjectLayout.CookedDir}/materials/steel.{ProjectLayout.CookedAssetExtension}", .. scope .())));
		let text = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(dir, scope $"{ProjectLayout.ContentDir}/materials/steel.{ProjectLayout.SourceAssetExtension}", .. scope .()), text) case .Ok);
		Test.Assert(StringView((char8*)text.Ptr, text.Count).Contains("<"), "the source envelope is text");
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let loaded = project.SourceDb.ReadObject(sourceId);
			Test.Assert(loaded != null);
			defer delete loaded;
			Test.Assert(((TestMaterial)loaded).Shininess == 7);
		}
	}

	/// A manifest written under another data version is refused: Open fails rather than
	/// guessing a layout, and the project is re-saved by the build that wrote it.
	[Test]
	public static void AStaleVersionManifestIsRefused()
	{
		let dir = Scratch("scratch_editor_project_stale", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let path = PathJoin(dir, ProjectLayout.ManifestFile, .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		let marker = "<u32 name=\"version\">";
		let at = text.IndexOf(marker);
		Test.Assert(at >= 0, "the version envelope is in the manifest");
		let close = text.IndexOf('<', at + marker.Length);
		text.Remove(at + marker.Length, close - (at + marker.Length));
		text.Insert(at + marker.Length, "1");
		Test.Assert(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok);

		InitGlobalLogger(new CaptureLogger(), true);
		defer ShutdownGlobalLogger();
		Test.Assert(EditorProject.Open(dir) == null, "another version's layout is not guessed at");
	}
}
