using System;
using System.IO;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.HarfBuzz.Tests;

/// The bundled fonts the shaper is tested over, found by walking up from the working
/// directory to the repository's Data/.
static class TestFonts
{
	public const String cRoboto = "Data/Assets/fonts/roboto/Roboto-Regular.ttf";
	public const String cDejaVuMono = "Data/Assets/fonts/dejavu/DejaVuSansMono.ttf";

	public static bool FindPath(StringView relative, String outPath)
	{
		let directory = scope String();
		GetCurrentDirectory(directory);
		for (int depth < 8)
		{
			let candidate = scope String();
			PathJoin(directory, relative, candidate);
			if (File.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}
			let parent = scope String();
			PathParent(directory, parent);
			if (parent.IsEmpty || (parent == directory))
				break;
			directory.Set(parent);
		}
		return false;
	}

	/// The font at `pixelHeight`, which the caller owns; null when the asset is not there.
	public static TrueTypeFont Load(StringView relative, float pixelHeight = 32.0f)
	{
		let path = scope String();
		if (!FindPath(relative, path))
			return null;
		let parser = scope TrueTypeFontParser();
		var options = FontLoadOptions.Default();
		options.PixelHeight = pixelHeight;
		if (parser.ParseFromFile(path, options) case .Ok(let font))
			return (TrueTypeFont)font;
		return null;
	}
}
