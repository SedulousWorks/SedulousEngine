using System;
using System.IO;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage;

namespace Sedulous.Fonts.Coverage.Baker.Tests;

/// Finds the Roboto the bake runs over, and reads its bytes.
///
/// The baker takes BYTES rather than a path, because a caller may be baking something it
/// pulled out of an archive. So these tests read the file themselves.
static class TestFontBytes
{
	/// Walks up from the working directory looking for the asset.
	///
	/// The tests run from the project directory, and the data sits at the repository root,
	/// but neither is guaranteed: the runner's working directory has moved before. Walking
	/// up is what makes the fixture findable from wherever it is run.
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

	/// Reads the fixture into `outBytes`, or returns false when the asset is not there.
	///
	/// False rather than a failed assertion, so a checkout without the data skips these
	/// rather than reporting the baker broken.
	public static bool Read(List<uint8> outBytes)
	{
		let path = scope String();
		if (!FindPath(path))
			return false;

		if (File.ReadAll(path, outBytes) case .Err)
			return false;
		return !outBytes.IsEmpty;
	}
}
