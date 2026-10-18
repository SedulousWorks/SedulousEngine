using sheenbidi_Beef;
using System;

namespace sheenbidi_Beef_Test;

/// Exercises the binding end to end against the real library: "abc" then three Arabic letters
/// resolve to a left-to-right paragraph whose Arabic is at level 1.
class Program
{
	static int Run()
	{
		uint32[7] text = .((.)'a', (.)'b', (.)'c', (.)' ', 0x0627, 0x0628, 0x062C);
		var sequence = SBCodepointSequence();
		sequence.stringEncoding = SBStringEncodingUTF32;
		sequence.stringBuffer = &text[0];
		sequence.stringLength = 7;

		let algorithm = SBAlgorithmCreate(&sequence);
		defer SBAlgorithmRelease(algorithm);
		let paragraph = SBAlgorithmCreateParagraph(algorithm, 0, 7, SBLevelDefaultLTR);
		defer SBParagraphRelease(paragraph);

		let length = SBParagraphGetLength(paragraph);
		let baseLevel = SBParagraphGetBaseLevel(paragraph);
		let levels = SBParagraphGetLevelsPtr(paragraph);
		Console.Write("length {} base {} levels", length, baseLevel);
		for (int i < (int)length)
			Console.Write(" {}", levels[i]);
		Console.WriteLine();

		if ((length != 7) || (baseLevel != 0))
			return 1;
		for (int i < 4)
		{
			if (levels[i] != 0)
				return 1;
		}
		for (int i = 4; i < 7; i++)
		{
			if (levels[i] != 1)
				return 1;
		}

		// With no strong character, a default right-to-left paragraph is right to left.
		uint32[1] digits = .((.)'7');
		var neutral = SBCodepointSequence();
		neutral.stringEncoding = SBStringEncodingUTF32;
		neutral.stringBuffer = &digits[0];
		neutral.stringLength = 1;
		let other = SBAlgorithmCreate(&neutral);
		defer SBAlgorithmRelease(other);
		let rtl = SBAlgorithmCreateParagraph(other, 0, 1, SBLevelDefaultRTL);
		defer SBParagraphRelease(rtl);
		if (SBParagraphGetBaseLevel(rtl) != 1)
			return 1;
		return 0;
	}

	public static int Main()
	{
		let result = Run();
		Console.WriteLine(result == 0 ? "sheenbidi binding OK." : "sheenbidi binding FAILED.");
		return result;
	}
}
