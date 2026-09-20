using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.GameUI;

/// The text file a UI asset links to under the project's sources, read whole and written
/// whole: the page edits that file, the asset only points at it.
static class LinkedSource
{
	/// Empty when there is no project or the file does not read.
	public static void Read(EditorContext context, StringView fileName, String outText)
	{
		outText.Clear();
		let sourcesRoot = scope String();
		if (context.Project != null)
			context.Project.SourcesRoot(sourcesRoot);
		let path = PathJoin(sourcesRoot, fileName, .. scope .());
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Ok)
			outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	public static Result<void, ErrorCode> Write(EditorContext context, StringView fileName, StringView text)
	{
		let sourcesRoot = scope String();
		if (context.Project != null)
			context.Project.SourcesRoot(sourcesRoot);
		let path = PathJoin(sourcesRoot, fileName, .. scope .());
		return WriteFile(path, .((uint8*)text.Ptr, text.Length));
	}
}
