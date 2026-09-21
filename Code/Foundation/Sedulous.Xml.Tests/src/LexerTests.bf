using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class LexerTests
{
	[Test]
	public static void WhitespaceLength()
	{
		Test.Assert(XmlLexer.GetWhitespaceLength("   abc") == 3);
		Test.Assert(XmlLexer.GetWhitespaceLength(" \t\r\nabc") == 4);
		Test.Assert(XmlLexer.GetWhitespaceLength("abc") == 0);
		Test.Assert(XmlLexer.GetWhitespaceLength("") == 0);
		Test.Assert(XmlLexer.GetWhitespaceLength("   ") == 3, "all whitespace");
	}

	/// XML whitespace is exactly four characters, which is not the same as a general
	/// is-space test: a vertical tab or a form feed is not whitespace here.
	[Test]
	public static void IsWhitespace()
	{
		Test.Assert(XmlLexer.IsWhitespace(' '));
		Test.Assert(XmlLexer.IsWhitespace('\t'));
		Test.Assert(XmlLexer.IsWhitespace('\r'));
		Test.Assert(XmlLexer.IsWhitespace('\n'));
		Test.Assert(!XmlLexer.IsWhitespace('a'));
		Test.Assert(!XmlLexer.IsWhitespace('\v'));
		Test.Assert(!XmlLexer.IsWhitespace('\f'));
		Test.Assert(!XmlLexer.IsWhitespace((char8)0));
	}

	/// The predicates stand in for 256-byte tables, so they have to agree with the rule over
	/// every byte value, including the non-ASCII ones a UTF-8 name is made of.
	[Test]
	public static void NameCharacterClassesCoverEveryByte()
	{
		for (int value < 256)
		{
			let c = (char8)value;
			let isLetter = ((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z'));
			let isDigit = (c >= '0') && (c <= '9');
			let isHighByte = value >= 0x80;

			let expectedStart = isLetter || (c == ':') || (c == '_') || isHighByte;
			let expectedChar = expectedStart || isDigit || (c == '-') || (c == '.');

			Test.Assert(XmlLexer.IsNameStartChar(c) == expectedStart, scope $"start char 0x{value:X}");
			Test.Assert(XmlLexer.IsNameChar(c) == expectedChar, scope $"name char 0x{value:X}");
		}
	}

	[Test]
	public static void ReadName()
	{
		int length = 0;
		Test.Assert(XmlLexer.ReadName("element>", out length) == .Ok);
		Test.Assert(length == 7);

		Test.Assert(XmlLexer.ReadName("ns:local ", out length) == .Ok);
		Test.Assert(length == 8, "a colon is a name character");

		Test.Assert(XmlLexer.ReadName("a1-2.3_x=", out length) == .Ok);
		Test.Assert(length == 8);

		Test.Assert(XmlLexer.ReadName("_under", out length) == .Ok);
		Test.Assert(length == 6);
	}

	[Test]
	public static void ReadNameRejectsWhatCannotStartOne()
	{
		int length = 0;
		Test.Assert(XmlLexer.ReadName("", out length) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName("1abc", out length) == .NameEmpty, "a digit cannot start a name");
		Test.Assert(XmlLexer.ReadName("-abc", out length) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName(".abc", out length) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName(" abc", out length) == .NameEmpty);
		Test.Assert(length == 0, "nothing was consumed");
	}

	[Test]
	public static void ReadNameWithOutput()
	{
		let name = scope String("stale");
		int length = 0;
		Test.Assert(XmlLexer.ReadName("tag attr=\"x\"", out length, name) == .Ok);
		Test.Assert(name == "tag");
		Test.Assert(length == 3);

		// A failure leaves the output alone rather than half written.
		Test.Assert(XmlLexer.ReadName("1bad", out length, name) == .NameEmpty);
	}

	[Test]
	public static void ReadAttributeValueTakesEitherQuote()
	{
		let value = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("\"hello\" rest", out length, value) == .Ok);
		Test.Assert(value == "hello");
		Test.Assert(length == 7, "both quotes are consumed");

		Test.Assert(XmlLexer.ReadAttributeValue("'world'", out length, value) == .Ok);
		Test.Assert(value == "world");

		// The other quote is ordinary data inside a value.
		Test.Assert(XmlLexer.ReadAttributeValue("\"it's\"", out length, value) == .Ok);
		Test.Assert(value == "it's");

		Test.Assert(XmlLexer.ReadAttributeValue("\"\"", out length, value) == .Ok);
		Test.Assert(value == "");
	}

	[Test]
	public static void ReadAttributeValueDecodesReferences()
	{
		let value = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("\"a &amp; b\"", out length, value) == .Ok);
		Test.Assert(value == "a & b");

		Test.Assert(XmlLexer.ReadAttributeValue("\"&lt;tag&gt;\"", out length, value) == .Ok);
		Test.Assert(value == "<tag>");

		Test.Assert(XmlLexer.ReadAttributeValue("\"&quot;q&quot; &apos;a&apos;\"", out length, value) == .Ok);
		Test.Assert(value == "\"q\" 'a'");

		Test.Assert(XmlLexer.ReadAttributeValue("\"&#65;&#x42;\"", out length, value) == .Ok);
		Test.Assert(value == "AB", "decimal and hexadecimal");
	}

	[Test]
	public static void ReadAttributeValueErrors()
	{
		let value = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("", out length, value) == .AttributeMissingQuote);
		Test.Assert(XmlLexer.ReadAttributeValue("bare", out length, value) == .AttributeMissingQuote);
		Test.Assert(XmlLexer.ReadAttributeValue("\"unclosed", out length, value) == .AttributeMissingQuote);
		// A raw '<' would be markup, so it is never data.
		Test.Assert(XmlLexer.ReadAttributeValue("\"a < b\"", out length, value) == .AttributeValueInvalid);
	}

	[Test]
	public static void ReadTextContent()
	{
		let text = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadTextContent("hello<tag>", out length, text) == .Ok);
		Test.Assert(text == "hello");
		Test.Assert(length == 5, "the stop character is left for the caller");

		Test.Assert(XmlLexer.ReadTextContent("a &amp; b<", out length, text) == .Ok);
		Test.Assert(text == "a & b");

		Test.Assert(XmlLexer.ReadTextContent("no markup at all", out length, text) == .Ok);
		Test.Assert(text == "no markup at all");

		Test.Assert(XmlLexer.ReadTextContent("<immediate", out length, text) == .Ok);
		Test.Assert(text == "");
		Test.Assert(length == 0);
	}

	[Test]
	public static void ReadCDataContent()
	{
		let data = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadCDataContent("raw <b>markup</b>]]>after", out length, data) == .Ok);
		Test.Assert(data == "raw <b>markup</b>", "nothing inside is interpreted");
		Test.Assert(length == 20);

		Test.Assert(XmlLexer.ReadCDataContent("]]>", out length, data) == .Ok);
		Test.Assert(data == "");

		Test.Assert(XmlLexer.ReadCDataContent("never closed", out length, data) == .CDataUnclosed);
	}

	[Test]
	public static void ReadCommentContent()
	{
		let text = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadCommentContent(" a comment -->rest", out length, text) == .Ok);
		Test.Assert(text == " a comment ");

		Test.Assert(XmlLexer.ReadCommentContent("-->", out length, text) == .Ok);
		Test.Assert(text == "");

		Test.Assert(XmlLexer.ReadCommentContent("never closed", out length, text) == .CommentUnclosed);
		// XML forbids "--" inside a comment outright, so it is an error rather than data.
		Test.Assert(XmlLexer.ReadCommentContent("a -- b -->", out length, text) == .CommentIllegalSequence);
	}

	[Test]
	public static void ReadProcessingInstruction()
	{
		let target = scope String();
		let data = scope String();
		int length = 0;

		Test.Assert(XmlLexer.ReadProcessingInstruction("php echo 1; ?>rest", out length, target, data) == .Ok);
		Test.Assert(target == "php");
		Test.Assert(data == "echo 1; ");

		Test.Assert(XmlLexer.ReadProcessingInstruction("target?>", out length, target, data) == .Ok);
		Test.Assert(target == "target");
		Test.Assert(data == "", "a target with no data");

		Test.Assert(XmlLexer.ReadProcessingInstruction("unclosed data", out length, target, data) == .PIUnclosed);
		Test.Assert(XmlLexer.ReadProcessingInstruction("1bad?>", out length, target, data) == .PIInvalid);
	}

	[Test]
	public static void IsValidName()
	{
		Test.Assert(XmlLexer.IsValidName("element"));
		Test.Assert(XmlLexer.IsValidName("ns:local"));
		Test.Assert(XmlLexer.IsValidName("_x"));
		Test.Assert(XmlLexer.IsValidName("a1-2.3"));

		Test.Assert(!XmlLexer.IsValidName(""));
		Test.Assert(!XmlLexer.IsValidName("1abc"));
		Test.Assert(!XmlLexer.IsValidName("a b"));
		Test.Assert(!XmlLexer.IsValidName("a<b"));
	}

	[Test]
	public static void SplitQualifiedName()
	{
		let prefix = scope String();
		let localName = scope String();

		XmlLexer.SplitQualifiedName("ns:local", prefix, localName);
		Test.Assert(prefix == "ns");
		Test.Assert(localName == "local");

		// No colon means the whole thing is local and the prefix is empty, which is what
		// an unprefixed name means.
		XmlLexer.SplitQualifiedName("bare", prefix, localName);
		Test.Assert(prefix == "");
		Test.Assert(localName == "bare");

		// The FIRST colon splits.
		XmlLexer.SplitQualifiedName("a:b:c", prefix, localName);
		Test.Assert(prefix == "a");
		Test.Assert(localName == "b:c");

		XmlLexer.SplitQualifiedName("", prefix, localName);
		Test.Assert(prefix == "");
		Test.Assert(localName == "");
	}

	[Test]
	public static void ReferenceErrors()
	{
		let output = scope String();
		int length = 0;

		Test.Assert(XmlLexer.DecodeReference("&unknown;", out length, output) == .EntityUnknown);
		Test.Assert(XmlLexer.DecodeReference("&amp", out length, output) == .EntityMalformed, "no semicolon");
		// An EMPTY name reads as unknown rather than malformed: the loop that validates
		// each name character never runs, so nothing rejects the absence of one. This pins
		// what the lexer does rather than what it arguably should.
		Test.Assert(XmlLexer.DecodeReference("&;", out length, output) == .EntityUnknown);
		Test.Assert(XmlLexer.DecodeReference("nothing", out length, output) == .EntityMalformed);

		Test.Assert(XmlLexer.DecodeReference("&#xZZ;", out length, output) == .CharRefInvalid);
		Test.Assert(XmlLexer.DecodeReference("&#;", out length, output) == .CharRefInvalid);
		// Zero is not a character, and the range stops at 0x10FFFF.
		Test.Assert(XmlLexer.DecodeReference("&#0;", out length, output) == .CharRefOutOfRange);
		Test.Assert(XmlLexer.DecodeReference("&#x110000;", out length, output) == .CharRefOutOfRange);
	}

	/// The valid ranges have gaps, and a reference to something in one of them is an
	/// error rather than a character nobody can render.
	[Test]
	public static void CharacterReferencesRespectTheValidRanges()
	{
		let output = scope String();
		int length = 0;

		// The surrogate range is not a character.
		Test.Assert(XmlLexer.DecodeReference("&#xD800;", out length, output) == .CharRefOutOfRange);
		// Nor are the two noncharacters at the end of the plane.
		Test.Assert(XmlLexer.DecodeReference("&#xFFFE;", out length, output) == .CharRefOutOfRange);
		// Most control characters are excluded, but tab, newline and return are not.
		Test.Assert(XmlLexer.DecodeReference("&#x1;", out length, output) == .CharRefOutOfRange);
		Test.Assert(XmlLexer.DecodeReference("&#x9;", out length, output) == .Ok);

		Test.Assert(XmlLexer.IsValidXmlChar(0x09));
		Test.Assert(XmlLexer.IsValidXmlChar(0x20));
		Test.Assert(!XmlLexer.IsValidXmlChar(0x00));
		Test.Assert(!XmlLexer.IsValidXmlChar(0xD800));
		Test.Assert(XmlLexer.IsValidXmlChar(0x10FFFF));
		Test.Assert(!XmlLexer.IsValidXmlChar(0x110000));
	}

	/// A reference is encoded as UTF-8, so a codepoint above ASCII becomes several bytes.
	[Test]
	public static void CharacterReferencesEncodeAsUtf8()
	{
		let output = scope String();
		int length = 0;

		output.Clear();
		Test.Assert(XmlLexer.DecodeReference("&#xE9;", out length, output) == .Ok);
		Test.Assert(output.Length == 2, "two bytes for U+00E9");

		output.Clear();
		Test.Assert(XmlLexer.DecodeReference("&#x20AC;", out length, output) == .Ok);
		Test.Assert(output.Length == 3, "three bytes for the euro sign");

		output.Clear();
		Test.Assert(XmlLexer.DecodeReference("&#x1F600;", out length, output) == .Ok);
		Test.Assert(output.Length == 4, "four bytes above the BMP");
	}

	[Test]
	public static void HexDigitValue()
	{
		Test.Assert(XmlLexer.HexDigitValue('0') == 0);
		Test.Assert(XmlLexer.HexDigitValue('9') == 9);
		Test.Assert(XmlLexer.HexDigitValue('A') == 10);
		Test.Assert(XmlLexer.HexDigitValue('f') == 15);
		Test.Assert(XmlLexer.HexDigitValue('g') == -1);
		Test.Assert(XmlLexer.IsHexDigit('a') && !XmlLexer.IsHexDigit('g'));
	}
}
