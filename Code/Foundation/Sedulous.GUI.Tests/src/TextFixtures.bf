using System;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.TrueType;
using Sedulous.VFS;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What the text tests share: the bundled fonts, loaded through a TrueType font service from the
/// data root, and doctest's Approx. The GUI's text is shaped by HarfBuzz here, as its hosts shape
/// it: every load installs it first (installing again changes nothing), so every font a test
/// loads takes it.
static class TextFixtures
{
	public const String cRoboto = "Assets/fonts/roboto/Roboto-Regular.ttf";
	public const String cRobotoBold = "Assets/fonts/roboto/Roboto-Bold.ttf";
	public const String cDejaVuMono = "Assets/fonts/dejavu/DejaVuSansMono.ttf";

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// Loads the font file at `relative` (from the data root) into `service` as `family`.
	public static void Load(TrueTypeFontService service, StringView family, StringView relative)
	{
		HarfBuzzShaping.Install();
		TrueTypeFonts.Initialize();
		let root = FindDataRoot(.. scope String());
		let path = DataPath(root, relative, .. scope String());
		Test.Assert(service.LoadFont(family, path) == .Success);
	}

	/// The plain text the glyphs on a line stand for, an ellipsis as "~", appended to `outText`.
	public static void Shown(TextLayout layout, StringView plain, int line, String outText)
	{
		for (let run in layout.GlyphRuns)
		{
			if (run.Line != line)
				continue;
			if (run.Run < 0)
			{
				outText.Append("~");
				continue;
			}
			for (int g = 0; g < run.Glyphs.Count; g++)
				outText.Append(plain.Substring(run.GlyphStart[g], run.GlyphEnd[g] - run.GlyphStart[g]));
		}
	}

	/// Shown, the runs taken in x order (an ellipsis may be added after the runs it sits between).
	/// The layout's runs are reordered.
	public static void ShownInOrder(TextLayout layout, StringView plain, int line, String outText)
	{
		for (int i = 0; i < layout.GlyphRuns.Count; i++)
			for (int j = i + 1; j < layout.GlyphRuns.Count; j++)
				if (layout.GlyphRuns[j].X < layout.GlyphRuns[i].X)
					Swap!(layout.GlyphRuns[i], layout.GlyphRuns[j]);
		Shown(layout, plain, line, outText);
	}

	/// A document of one run of `text`, built by hand (not through markup), in `outDocument`.
	public static TextDocument OneRun(StringView text, TextDocument outDocument)
	{
		outDocument.Clear();
		let run = new TextRun();
		run.Text.Set(text);
		outDocument.Runs.Add(run);
		return outDocument;
	}
}

/// A clipboard in memory.
class TestClipboard : IClipboard
{
	public String Text = new .() ~ delete _;

	public bool HasText => Text.Length != 0;
	public void GetText(String outText) { outText.Append(Text); }
	public void SetText(StringView text) { Text.Set(text); }
}
