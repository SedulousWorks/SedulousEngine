using System;
using Sedulous.Core;
using Sedulous.Runtime;

namespace Sedulous.Editor.Project;

/// The game's package over an open project: the directory forms with the project's directory and
/// settings, so the editor and its tools pass the project they hold.
extension GamePackage
{
	/// The game's package of `project` into `outInfo` (Find over its directory and settings).
	public static bool Find(EditorProject project, GamePackageInfo outInfo) => Find(project.Directory, project.Settings, outInfo);

	/// Add Native Code into `project` (Scaffold over its directory and settings): its settings gain
	/// the package's entry and its manifest is saved.
	public static Result<void, ErrorCode> Scaffold(EditorProject project, Span<PluginPartKind> parts)
		=> Scaffold(project.Directory, project.Settings, parts);
}
