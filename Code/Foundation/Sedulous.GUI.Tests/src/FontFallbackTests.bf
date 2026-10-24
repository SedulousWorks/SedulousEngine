using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Font fallback: font-family takes a list; the first family the font service has is the font and
/// the rest are the faces a character it lacks falls back to. A piece's glyphs split into runs by
/// the face that drew them, each drawn and measured with that face. Over Roboto, which has no
/// Arabic, and DejaVu Sans Mono, which has.
class FontFallbackTests
{
	/// "ab " then Salaam (bytes 3 to 11).
	private const String cMixed = "ab \u{0633}\u{0644}\u{0627}\u{0645}";

	private static TrueTypeFontService Faces(TrueTypeFontService service)
	{
		TextFixtures.Load(service, "Roboto", TextFixtures.cRoboto);
		TextFixtures.Load(service, "DejaVu", TextFixtures.cDejaVuMono);
		return service;
	}

	private static TextLayoutStyle Style(TrueTypeFontService faces, StringView fallbacks, TextLayoutStyle outStyle)
	{
		outStyle.Font = faces.GetFont("Roboto", 16.0f);
		outStyle.Fonts = faces;
		outStyle.Family.Set("Roboto");
		outStyle.Selection.FallbackFamilies.Set(fallbacks);
		outStyle.Size = 16.0f;
		return outStyle;
	}

	private static TextLayout Lay(StringView text, TextLayoutStyle style, TextLayout outLayout) =>
		LayOutText(TextFixtures.OneRun(text, scope .()), style, outLayout);

	// The run drawing bytes [start, end), or null when glyphs of more than one run do.
	private static LaidOutGlyphs RunOf(TextLayout layout, int start, int end)
	{
		LaidOutGlyphs found = null;
		for (let run in layout.GlyphRuns)
		{
			for (int g = 0; g < run.Glyphs.Count; g++)
			{
				if ((run.GlyphStart[g] >= start) && (run.GlyphEnd[g] <= end))
				{
					if ((found != null) && (found !== run))
						return null;
					found = run;
				}
			}
		}
		return found;
	}

	private static bool AllDrawn(LaidOutGlyphs run)
	{
		for (let g in run.Glyphs)
			if (g.GlyphId == 0)
				return false;
		return !run.Glyphs.IsEmpty;
	}

	[Test]
	public static void WithoutAFallbackRobotoDrawsArabicAsMissingGlyphs()
	{
		let faces = Faces(scope .());
		let layout = Lay(cMixed, Style(faces, "", scope .()), scope .());
		let arabic = RunOf(layout, 3, 11);
		Test.Assert(arabic != null);
		Test.Assert(arabic.Font === faces.GetFont("Roboto", 16.0f));
		Test.Assert(!AllDrawn(arabic));
	}

	[Test]
	public static void WhatTheFontLacksComesFromTheFirstFallbackThatHasItInARunOfThatFace()
	{
		let faces = Faces(scope .());
		// A family the service lacks is passed over.
		let layout = Lay(cMixed, Style(faces, "Missing, 'DejaVu'", scope .()), scope .());
		let latin = RunOf(layout, 0, 2);
		let arabic = RunOf(layout, 3, 11);
		Test.Assert(latin != null);
		Test.Assert(arabic != null);
		Test.Assert(latin.Font === faces.GetFont("Roboto", 16.0f));
		Test.Assert(arabic.Font === faces.GetFont("DejaVu", 16.0f));
		Test.Assert(arabic !== latin);
		Test.Assert(AllDrawn(arabic));
		Test.Assert(AllDrawn(latin));
		for (let g in arabic.Glyphs)
			Test.Assert(g.Font == 1); // the request's second face
		// Its text and box are its glyphs'.
		Test.Assert(arabic.TextStart == 3);
		Test.Assert(arabic.TextEnd == 11);
	}

	[Test]
	public static void ALineMeasuresWhatItsFacesDrawAndIsAsTallAsTheTallest()
	{
		let faces = Faces(scope .());
		let layout = Lay(cMixed, Style(faces, "DejaVu", scope .()), scope .());
		Test.Assert(layout.Lines.Count == 1);
		float advances = 0.0f;
		for (let run in layout.GlyphRuns)
			for (let g in run.Glyphs)
				advances += g.Advance;
		Test.Assert(TextFixtures.Near(layout.Lines[0].Width, advances, 0.01f));
		let roboto = faces.GetFont("Roboto", 16.0f).Font.Metrics.Ascent;
		let dejavu = faces.GetFont("DejaVu", 16.0f).Font.Metrics.Ascent;
		Test.Assert(layout.Lines[0].Baseline >= Math.Max(roboto, dejavu) - 0.01f);
	}

	[Test]
	public static void LatinAloneKeepsOneRunInTheFontItsFallbacksUnused()
	{
		let faces = Faces(scope .());
		let layout = Lay("plain words", Style(faces, "DejaVu", scope .()), scope .());
		for (let run in layout.GlyphRuns)
			Test.Assert(run.Font === faces.GetFont("Roboto", 16.0f));
		Test.Assert(TextFixtures.Near(layout.Lines[0].Baseline, faces.GetFont("Roboto", 16.0f).Font.Metrics.Ascent));
	}
}
