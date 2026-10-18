using System;
using sheenbidi_Beef;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Bidi;

/// The Unicode bidirectional algorithm behind IBidiResolver: SheenBidi resolves a paragraph's
/// levels from UTF-32, one level per character as clusters count them, making and releasing its
/// objects per call so one resolver serves every shaper and thread. No SheenBidi type crosses
/// this interface.
class SheenBidiResolver : IBidiResolver
{
	public override void Resolve(Span<uint32> codepoints, TextDirection baseDirection, BidiLevels outLevels)
	{
		outLevels.Levels.Clear();
		outLevels.ParagraphLevel = (baseDirection == .RightToLeft) ? 1 : 0;
		if (codepoints.IsEmpty)
			return;

		var sequence = SBCodepointSequence();
		sequence.stringEncoding = SBStringEncodingUTF32;
		sequence.stringBuffer = codepoints.Ptr;
		sequence.stringLength = (SBUInteger)codepoints.Length;
		let algorithm = SBAlgorithmCreate(&sequence);
		if (algorithm == null)
			return;
		defer SBAlgorithmRelease(algorithm);

		SBLevel baseLevel;
		switch (baseDirection)
		{
		case .LeftToRight: baseLevel = 0;
		case .RightToLeft: baseLevel = 1;
		case .Auto: baseLevel = SBLevelDefaultLTR;
		}
		let paragraph = SBAlgorithmCreateParagraph(algorithm, 0, (SBUInteger)codepoints.Length, baseLevel);
		if (paragraph == null)
			return;
		defer SBParagraphRelease(paragraph);

		outLevels.ParagraphLevel = SBParagraphGetBaseLevel(paragraph);
		let length = (int)SBParagraphGetLength(paragraph);
		let levels = SBParagraphGetLevelsPtr(paragraph);
		for (int i < codepoints.Length)
			outLevels.Levels.Add((i < length) ? levels[i] : outLevels.ParagraphLevel);
	}
}

/// Installs the SheenBidi resolver behind BidiResolverFactory.
static class BidiAlgorithm
{
	private static SheenBidiResolver sResolver = new .() ~ delete _;

	/// Installs the resolver (idempotent): lines shaped after this reorder by their levels.
	public static void Install() => BidiResolverFactory.Install(sResolver);

	/// Removes it: a line is one run in its request's direction again.
	public static void Uninstall() => BidiResolverFactory.Remove(sResolver);

	public static bool IsInstalled => BidiResolverFactory.Resolver === sResolver;

	/// The resolver itself (one per process, stateless), for a caller that resolves levels.
	public static IBidiResolver Resolver => sResolver;
}
