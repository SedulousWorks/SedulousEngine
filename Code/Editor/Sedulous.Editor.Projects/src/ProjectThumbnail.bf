using System;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The picture the project manager shows a project by: its scene view, captured by the editor
/// (when the default scene opens without one, when it is saved, on Set as Project Thumbnail) or
/// an image the user chose, in the project's per machine editor folder (not under version
/// control). Here, not with the editor's project, so the manager finds it without the editor.
static class ProjectThumbnail
{
	/// The thumbnail's path for the project in `projectDirectory`, appended to `outPath`.
	public static void PathOf(StringView projectDirectory, String outPath)
	{
		let editorDir = PathJoin(projectDirectory, ProjectLayout.EditorDir, .. scope .());
		PathJoin(editorDir, "launcher-thumbnail.png", outPath);
	}
}
