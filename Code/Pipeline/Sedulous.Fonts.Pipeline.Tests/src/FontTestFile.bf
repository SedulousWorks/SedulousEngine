using System;
using System.Collections;
using System.IO;
using Sedulous.Core.IO;

namespace Sedulous.Fonts.Pipeline.Tests;

/// Finding the typeface these cases bake.
///
/// A REAL face, because what a bake produces is glyph shapes and metrics, and a synthesised
/// one would only have whatever it was built with.
static class FontTestFile
{
	/// Walks up from the working directory looking for the asset.
	///
	/// The tests run from the project directory and the data sits at the repository root, but
	/// neither is guaranteed: the runner's working directory has moved before.
	public static bool FindPath(String outPath)
	{
		const String cRelative = "Data/Assets/fonts/roboto/Roboto-Regular.ttf";

		let directory = scope String();
		GetCurrentDirectory(directory);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(directory, cRelative, candidate);
			if (File.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(directory, parent);
			if (parent.IsEmpty || (parent == directory))
				break;
			directory.Set(parent);
		}
		return false;
	}

	/// Copies the face into a mount directory under the given name.
	///
	/// FALSE rather than a failed assertion when the data is not there, so a checkout without
	/// it skips these rather than reporting the font code broken.
	public static bool StageInto(StringView directory, StringView name)
	{
		let source = scope String();
		if (!FindPath(source))
			return false;

		let bytes = scope List<uint8>();
		if (ReadFile(source, bytes) case .Err)
			return false;

		let target = scope String();
		PathJoin(directory, name, target);
		return WriteFile(target, bytes) case .Ok;
	}
}
