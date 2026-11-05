using System;
using Sedulous.Editor.Main;

namespace Sedulous.Tools.Editor;

/// The stock editor executable. The startup is EditorMain's, in a library, so a project's own
/// build runs the same editor with its packages linked in.
class Program
{
	public static int Main(String[] args) => EditorMain.Run(args);
}
