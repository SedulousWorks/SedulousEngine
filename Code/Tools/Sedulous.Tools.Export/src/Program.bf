using System;
using Sedulous.Editor.ExportMain;

namespace Sedulous.Tools.Export;

/// The stock command line exporter. The startup is ExportMain's, in a library, so a project's
/// own build (`<Game>Tools export`) exports the same way with its packages linked in.
class Program
{
	public static int Main(String[] args) => ExportMain.Run(args);
}
