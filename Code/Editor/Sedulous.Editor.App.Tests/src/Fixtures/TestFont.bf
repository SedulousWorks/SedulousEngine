using System;
using System.IO;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Editor.App.Tests;

/// Finds and loads the Roboto the cache tests bake, walking up from the working directory
/// to the repository's Data folder.
static class TestFont
{
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

	/// Null when the asset is not there, so a checkout without the data skips rather than
	/// reporting the editor broken.
	public static IFont Load()
	{
		let path = scope String();
		if (!FindPath(path))
			return null;
		let parser = scope TrueTypeFontParser();
		if (parser.ParseFromFile(path, FontLoadOptions.Default()) case .Ok(let font))
			return font;
		return null;
	}

	/// A small distance-field range keeps the bake quick.
	public static FontLoadOptions SmallDF()
	{
		var options = FontLoadOptions.DistanceField();
		options.PixelHeight = 32.0f;
		options.FirstCodepoint = 32;
		options.LastCodepoint = 96;
		options.AtlasWidth = 512;
		options.AtlasHeight = 512;
		return options;
	}
}
