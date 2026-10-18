using System;

namespace sheenbidi_Beef;

/*
 * SheenBidi - the Unicode bidirectional algorithm.
 *
 * Source: https://github.com/Tehreer/SheenBidi
 * Version: 3.0.0
 * License: Apache-2.0 (sheenbidi/LICENSE). The project ships no NOTICE file.
 *
 * A C API, bound directly. This declares only what the engine's bidi resolver calls: an
 * algorithm over a codepoint sequence, a paragraph from it, and the paragraph's resolved
 * levels. Nothing above the engine's own bidi interface sees these types.
 */

[CRepr] struct SBAlgorithm;
[CRepr] struct SBParagraph;

typealias SBUInteger = uint;
/// An embedding level: even reads left to right, odd right to left.
typealias SBLevel = uint8;
typealias SBStringEncoding = uint32;

[CRepr]
struct SBCodepointSequence
{
	public SBStringEncoding stringEncoding;
	/// BORROWED for the algorithm's lifetime.
	public void* stringBuffer;
	/// In code units of the encoding.
	public SBUInteger stringLength;
}

static
{
	public const SBStringEncoding SBStringEncodingUTF8 = 0;
	public const SBStringEncoding SBStringEncodingUTF16 = 1;
	public const SBStringEncoding SBStringEncodingUTF32 = 2;

	public const SBLevel SBLevelInvalid = 0xFF;
	public const SBLevel SBLevelMax = 125;
	/// The base level is 0 (left to right) when the paragraph has no strong character.
	public const SBLevel SBLevelDefaultLTR = 0xFE;
	/// The base level is 1 (right to left) when the paragraph has no strong character.
	public const SBLevel SBLevelDefaultRTL = 0xFD;

	[CLink]
	public static extern SBAlgorithm* SBAlgorithmCreate(SBCodepointSequence* codepointSequence);
	[CLink]
	public static extern void SBAlgorithmRelease(SBAlgorithm* algorithm);
	/// The paragraph from `paragraphOffset`, up to `suggestedLength` code units or its end.
	[CLink]
	public static extern SBParagraph* SBAlgorithmCreateParagraph(SBAlgorithm* algorithm,
		SBUInteger paragraphOffset, SBUInteger suggestedLength, SBLevel baseLevel);

	[CLink]
	public static extern SBUInteger SBParagraphGetLength(SBParagraph* paragraph);
	[CLink]
	public static extern SBLevel SBParagraphGetBaseLevel(SBParagraph* paragraph);
	/// One level per code unit of the paragraph. BORROWED from the paragraph.
	[CLink]
	public static extern SBLevel* SBParagraphGetLevelsPtr(SBParagraph* paragraph);
	[CLink]
	public static extern void SBParagraphRelease(SBParagraph* paragraph);
}
