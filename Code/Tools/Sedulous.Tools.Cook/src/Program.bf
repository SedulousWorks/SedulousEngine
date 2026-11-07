using System;
using Sedulous.Editor.CookMain;

namespace Sedulous.Tools.Cook;

/// The stock command line cooker. The startup is CookMain's, in a library, so a project's own
/// build (`<Game>Tools cook`) cooks the same way with its packages linked in.
class Program
{
	public static int Main(String[] args) => CookMain.Run(args);
}
