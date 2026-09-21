using System;
using System.IO;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.DistanceField.Baker.Tests;

/// Finds and loads the Roboto the tests parse.
///
/// A REAL typeface, because what is under test is the parsing of the name, glyph and
/// kerning tables, and a synthesised fixture would only have the shapes it was built with.
/// The cost is that the assertions are about RELATIONS between metrics rather than exact
/// numbers, since the numbers belong to this typeface.
static class TestFont
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

	/// The font at the default size, or null when the asset is not there.
	///
	/// Null rather than a failed assertion, so a checkout without the data skips these
	/// rather than reporting the baker broken.
	public static TrueTypeFont Load(float pixelHeight = 32.0f)
	{
		let path = scope String();
		if (!FindPath(path))
			return null;

		let parser = scope TrueTypeFontParser();
		var options = FontLoadOptions.Default();
		options.PixelHeight = pixelHeight;

		if (parser.ParseFromFile(path, options) case .Ok(let font))
			return (TrueTypeFont)font;
		return null;
	}
}
