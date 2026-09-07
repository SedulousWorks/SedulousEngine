using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.DistanceField.Baker.Tests;

/// Bringing the distance-field baker up alongside the TrueType backend.
///
/// These two are meant to COEXIST: the distance-field side registers only a baker, and
/// relies on the TrueType parser to have produced the font. So the interesting property is
/// that both are registered at once and each request reaches the right one.
class DistanceFieldFontsTests
{
	private static void ClearRegistries()
	{
		DistanceFieldFonts.Shutdown();
		TrueTypeFonts.Shutdown();
		FontParserFactory.Shutdown();
		FontAtlasBakerFactory.Shutdown();
	}

	[Test]
	public static void InitializeRegistersOnlyABaker()
	{
		ClearRegistries();
		defer ClearRegistries();

		DistanceFieldFonts.Initialize();

		Test.Assert(FontAtlasBakerFactory.BakerCount == 1);
		Test.Assert(FontParserFactory.ParserCount == 0,
			"no parser: the TrueType backend is what reads the file");
		Test.Assert(DistanceFieldFonts.IsInitialized);

		// Idempotent, so a host bringing it up twice is not consulted twice.
		DistanceFieldFonts.Initialize();
		Test.Assert(FontAtlasBakerFactory.BakerCount == 1);

		DistanceFieldFonts.Shutdown();
		Test.Assert(FontAtlasBakerFactory.BakerCount == 0);
		Test.Assert(!DistanceFieldFonts.IsInitialized);
	}

	/// With both backends up, the atlas MODE is what picks the baker. This is the whole
	/// reason the two register side by side: the same .ttf bakes either way.
	[Test]
	public static void TheModeChoosesBetweenTheTwoBakers()
	{
		ClearRegistries();
		defer ClearRegistries();

		let font = TestFont.Load();
		Test.Assert(font != null);
		defer delete font;

		TrueTypeFonts.Initialize();
		DistanceFieldFonts.Initialize();
		Test.Assert(FontAtlasBakerFactory.BakerCount == 2);

		var coverage = FontLoadOptions.Default();
		coverage.AtlasMode = .Coverage;
		let coverageBaker = FontAtlasBakerFactory.GetBakerForFont(font, coverage);
		Test.Assert(coverageBaker != null);
		Test.Assert(!(coverageBaker is DistanceFieldFontAtlasBaker), "the raster baker took it");

		var distanceField = FontLoadOptions.DistanceField();
		let distanceFieldBaker = FontAtlasBakerFactory.GetBakerForFont(font, distanceField);
		Test.Assert(distanceFieldBaker != null);
		Test.Assert(distanceFieldBaker is DistanceFieldFontAtlasBaker, "and this one took the field");
	}

	/// Shutting one down leaves the other registered, which is what a host switching a
	/// single backend off depends on.
	[Test]
	public static void ShuttingOneDownLeavesTheOther()
	{
		ClearRegistries();
		defer ClearRegistries();

		TrueTypeFonts.Initialize();
		DistanceFieldFonts.Initialize();

		DistanceFieldFonts.Shutdown();

		Test.Assert(FontAtlasBakerFactory.BakerCount == 1, "the raster baker survived");
		Test.Assert(FontParserFactory.ParserCount == 1, "and so did the parser");
		Test.Assert(FontAtlasBakerFactory.GetBakerForExtension(".ttf") != null);
	}
}
