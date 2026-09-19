using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
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
}
