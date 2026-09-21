using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

/// Where a parse failed, not just that it did.
///
/// An error code alone makes a person hunt through the file, and a position that is
/// declared but never updated is worse than none: it always says line one.
class ParseErrorPositionTests
{
	private static void Fails(StringView text, int32 line, int32 column)
	{
		let document = scope XmlDocument();
		let result = document.Parse(text);
		Test.Assert(result != .Ok, "this input is supposed to fail");
		Test.Assert(document.ErrorLine == line,
			scope $"line: got {document.ErrorLine}, wanted {line}");
		Test.Assert(document.ErrorColumn == column,
			scope $"column: got {document.ErrorColumn}, wanted {column}");
	}

	[Test]
	public static void AGoodParseReportsTheStartOfTheFile()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root/>") == .Ok);
		Test.Assert(document.ErrorLine == 1 && document.ErrorColumn == 1);
	}

	[Test]
	public static void AFreshDocumentReportsTheStartOfTheFile()
	{
		let document = scope XmlDocument();
		Test.Assert(document.ErrorLine == 1 && document.ErrorColumn == 1);
	}

	/// The whole point: an error several lines in reports that line, not the first.
	[Test]
	public static void AFailureIsLocatedOnItsOwnLine()
	{
		// Line three: the name "b" was read, did not match "a", and the parser stopped on
		// the ">" that follows it.
		Fails("<root>\n  <a>\n  </b>\n</root>", 3, 6);
	}

	/// The column is where the parser STOPPED, which is just past what it rejected: a close
	/// tag's name has to be read before it can be compared.
	[Test]
	public static void TheColumnIsWhereTheParserStopped()
	{
		// "<root><a></b" is twelve bytes, so it stops on the ">" at column thirteen.
		Fails("<root><a></b></root>", 1, 13);
	}

	/// Both line endings, and the pair counted once, so the LINE is the same for all three
	/// even though the byte offsets differ.
	[Test]
	public static void EveryLineEndingConventionCountsTheSame()
	{
		Fails("<root>\n<a>\n</b>\n</root>", 3, 4);
		Fails("<root>\r\n<a>\r\n</b>\r\n</root>", 3, 4);
		Fails("<root>\r<a>\r</b>\r</root>", 3, 4);
	}

	/// A failure at the very end of the input reports the end rather than running past it.
	[Test]
	public static void AFailureAtTheEndReportsTheEnd()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>\n<a>") != .Ok, "an unclosed element");
		Test.Assert(document.ErrorLine == 2, scope $"got line {document.ErrorLine}");
	}

	/// Empty input fails at the start rather than at some computed offset into nothing.
	[Test]
	public static void EmptyInputFailsAtTheStart()
	{
		Fails("", 1, 1);
	}

	/// Parsing again resets it, so a document that failed once and then parsed something
	/// good does not keep reporting the old position.
	[Test]
	public static void APositionDoesNotSurviveTheNextParse()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>\n\n\n</b>") != .Ok);
		Test.Assert(document.ErrorLine > 1);

		Test.Assert(document.Parse("<root/>") == .Ok);
		Test.Assert(document.ErrorLine == 1 && document.ErrorColumn == 1);
	}

	/// The column counts CODE POINTS, so a multi byte character before the error advances it
	/// by one, not by its byte length.
	[Test]
	public static void TheColumnCountsCodePointsNotBytes()
	{
		let document = scope XmlDocument();

		// The same document twice, once with a two byte character and once with a one byte
		// character in its place. The reported column must be identical.
		Test.Assert(document.Parse("<r\u{E9}></x>") == .TagMismatch);
		Test.Assert(document.ErrorLine == 1);
		let afterMultibyte = document.ErrorColumn;

		Test.Assert(document.Parse("<re></x>") == .TagMismatch);
		Test.Assert(document.ErrorColumn == afterMultibyte,
			scope $"multibyte gave column {afterMultibyte}, single byte gave {document.ErrorColumn}");
	}
}
