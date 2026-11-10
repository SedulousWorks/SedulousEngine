using System;

namespace Sedulous.Tools.ProjectManager;

/// The project manager executable: its startup is ProjectManagerMain's.
class Program
{
	public static int Main(String[] args) => ProjectManagerMain.Run(args);
}
