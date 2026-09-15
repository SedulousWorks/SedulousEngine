using System;
using System.IO;
using Sedulous.Core.IO;

namespace Samples.VGSandbox;

/// Finds the repository's data next to wherever this was run from.
///
/// Raptor bakes the paths in at compile time from the source root. A Beef workspace has no
/// equivalent, so the directory is WALKED UP from the working directory instead: the sample
/// runs from the workspace root, from its own project directory, or from the build output,
/// and the data sits at the repository root in all three cases.
static class SandboxContent
{
	public const String cFontFile = "Assets/fonts/roboto/Roboto-Regular.ttf";

	/// The absolute path of a repository relative file, or false when this checkout has no
	/// data. False rather than an assertion, because the sample still draws everything that
	/// does not need it.
	public static bool FindFile(StringView relative, String outPath) =>
		Find(relative, outPath, false);

	public static bool FindDirectory(StringView relative, String outPath) =>
		Find(relative, outPath, true);

	private static bool Find(StringView relative, String outPath, bool directory)
	{
		let current = scope String();
		GetCurrentDirectory(current);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(current, relative, candidate);
			if (directory ? Directory.Exists(candidate) : File.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(current, parent);
			if (parent.IsEmpty || (parent == current))
				break;
			current.Set(parent);
		}
		return false;
	}
}
