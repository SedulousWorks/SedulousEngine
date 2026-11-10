using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// A project's directories and manifest, made on disk without opening it: what a new project
/// starts as, for a host that has no content databases to mount (the project manager) as much
/// as for the editor, whose EditorProject.Create is this.
static class ProjectScaffold
{
	/// The fixed subdirectories every project has, the generated ones included.
	private static String[5] sDirectories = .(ProjectLayout.ContentDir, ProjectLayout.SourcesDir,
		ProjectLayout.CookedDir, ProjectLayout.EditorDir, ProjectLayout.CacheDir);

	/// Scaffolds a new project at `directory`, created when absent, its PARENT existing:
	/// the manifest and the fixed subdirectories. AlreadyExists when a manifest is there.
	public static Result<void, ErrorCode> Create(StringView directory, StringView name)
	{
		if (!DirectoryExists(directory) && !CreateDirectory(directory))
			return .Err(.NotFound);
		let root = scope NativeFileSystem(directory);
		if (root.Exists(ProjectLayout.ManifestFile))
			return .Err(.AlreadyExists);
		if (!EnsureDirectories(directory))
			return .Err(.Internal);
		let settings = scope ProjectSettings();
		settings.Name.Set(name);
		return ProjectManifest.Save(root, settings);
	}

	/// Makes the fixed subdirectories of the project at `directory` that are missing; false when
	/// one cannot be made. The generated ones (Cooked, Editor, .cache) are ignored by version
	/// control, so a fresh checkout lacks them.
	public static bool EnsureDirectories(StringView directory)
	{
		for (let dir in sDirectories)
		{
			let path = PathJoin(directory, dir, .. scope .());
			if (!DirectoryExists(path) && !CreateDirectory(path))
				return false;
		}
		return true;
	}
}
