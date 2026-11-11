using System;

namespace Sedulous.Engine.Project;

/// A project's fixed directory layout, and the layout an export stages.
///
/// Shared by the runtime and the editor, so the two cannot disagree about where anything
/// lives. The editor's own project type builds on this; mounts, databases and per user
/// state stay editor side.
static class ProjectLayout
{
	public const String ManifestFile = "Project.xml";
	public const String ContentDir = "Content";
	public const String SourcesDir = "Sources";
	public const String CookedDir = "Cooked";
	public const String EditorDir = "Editor";
	public const String CacheDir = ".cache";
	/// Where the editor's exports go.
	public const String DistDir = "Dist";

	/// Under CodeDir: BeefBuild's output, and the entries the build generates.
	public const String CodeBuildDir = "build";
	public const String CodeGeneratedDir = ".generated";
	/// What builds and the Beef IDE write in CodeDir: BeefBuild's output, the generated entries and
	/// the IDE's recovery folder.
	public const String[3] CodeOutputDirs = .(CodeBuildDir, CodeGeneratedDir, "recovery");

	/// Whether a project's folder `name` (project-relative) is one the editor, a cook, an export or a
	/// build writes (Cooked and each target's Cooked-<target>, Editor, .cache, Dist, and CodeDir's
	/// CodeOutputDirs): generated, never a file of the project's own to pick.
	public static bool IsOutputFolder(StringView name)
	{
		if ((name == CookedDir) || name.StartsWith("Cooked-") || (name == EditorDir) || (name == CacheDir) || (name == DistDir))
			return true;
		if (!name.StartsWith(CodeDir) || (name.Length <= CodeDir.Length) || (name[CodeDir.Length] != '/'))
			return false;
		let inCode = name.Substring(CodeDir.Length + 1);
		for (let dir in CodeOutputDirs)
		{
			if (inCode == dir)
				return true;
		}
		return false;
	}
	/// The project's reusable packages: Plugins/<Name>/, each a Plugin.xml and its parts,
	/// <Name>.<Kind>/. The game's own package lives in CodeDir.
	public const String PluginsDir = "Plugins";
	/// The project's Beef workspace: its BeefSpace.toml (the user's, kept up to date by the
	/// editor), the game's own package (its Plugin.xml, the Engine part <Game>/ and any
	/// <Game>.<Kind>/ part), and what builds write (the generated entries, BeefConfig.toml and
	/// BeefBuild's output), which stays out of version control.
	public const String CodeDir = "Code";

	/// Readable and diffable envelopes, against the binary ones a cook produces. Without
	/// the dot, as a ContentDatabase takes them: it adds its own, and a dotted one here had
	/// the player scanning for `..xasset`.
	public const String SourceAssetExtension = "xasset";
	public const String CookedAssetExtension = "rasset";

	// ---- distribution ----------------------------------------------------------------------

	/// What the export stages. The player detects a distribution by the pak.
	public const String DistContentPak = "Content.pak";
	public const String DistManifestFile = "player.xml";

	// ---- a project's packages --------------------------------------------------------------

	/// A plugin id from a package's name ("NativeSample" gives "nativesample"): lower case,
	/// anything but letters, digits and underscores an underscore, prefixed with "game_" when
	/// it does not start with a letter, so it is always a valid id.
	public static void PluginIdFromName(StringView name, String outId)
	{
		outId.Clear();
		for (let c in name.RawChars)
		{
			let lower = c.ToLower;
			let ok = ((lower >= 'a') && (lower <= 'z')) || ((lower >= '0') && (lower <= '9')) || (lower == '_');
			outId.Append(ok ? lower : '_');
		}
		if (outId.IsEmpty || !((outId[0] >= 'a') && (outId[0] <= 'z')))
			outId.Insert(0, "game_");
	}

	// ---- a game's save ---------------------------------------------------------------------

	/// A game's save file, `<project>.save.xml`: the player keeps it in the user data directory
	/// and a Game tab in the project's Editor/ folder, the same name in both, so a save copied
	/// between them is found.
	public static void SaveFileName(StringView projectName, String outName)
	{
		outName.Set(projectName.IsEmpty ? "project" : projectName);
		outName.Append(".save.xml");
	}
}
