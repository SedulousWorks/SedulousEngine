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

	/// Readable and diffable envelopes, against the binary ones a cook produces. Without
	/// the dot, as a ContentDatabase takes them: it adds its own, and a dotted one here had
	/// the player scanning for `..xasset`.
	public const String SourceAssetExtension = "xasset";
	public const String CookedAssetExtension = "rasset";

	// ---- distribution ----------------------------------------------------------------------

	/// What the export stages. The player detects a distribution by the pak.
	public const String DistContentPak = "Content.pak";
	public const String DistManifestFile = "player.xml";
}
