using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class LexerTests
{
	[Test]
	public static void TestWhitespaceLength()
	{
		Test.Assert(XmlLexer.GetWhitespaceLength("") == 0);
		Test.Assert(XmlLexer.GetWhitespaceLength("abc") == 0);
		Test.Assert(XmlLexer.GetWhitespaceLength(" abc") == 1);
		Test.Assert(XmlLexer.GetWhitespaceLength("  abc") == 2);
		Test.Assert(XmlLexer.GetWhitespaceLength("\t\nabc") == 2);
		Test.Assert(XmlLexer.GetWhitespaceLength(" \t\r\n abc") == 5);
		Test.Assert(XmlLexer.GetWhitespaceLength("   ") == 3);
	}

	[Test]
	public static void TestIsWhitespace()
	{
		Test.Assert(XmlLexer.IsWhitespace(' '));
		Test.Assert(XmlLexer.IsWhitespace('\t'));
		Test.Assert(XmlLexer.IsWhitespace('\r'));
		Test.Assert(XmlLexer.IsWhitespace('\n'));
		Test.Assert(!XmlLexer.IsWhitespace('a'));
		Test.Assert(!XmlLexer.IsWhitespace('0'));
	}

	[Test]
	public static void TestReadName()
	{
		int len = 0;

		Test.Assert(XmlLexer.ReadName("element", out len) == .Ok);
		Test.Assert(len == 7);

		Test.Assert(XmlLexer.ReadName("ns:element", out len) == .Ok);
		Test.Assert(len == 10);

		Test.Assert(XmlLexer.ReadName("_underscore", out len) == .Ok);
		Test.Assert(len == 11);

		Test.Assert(XmlLexer.ReadName("name123", out len) == .Ok);
		Test.Assert(len == 7);

		Test.Assert(XmlLexer.ReadName("name-with-dash", out len) == .Ok);
		Test.Assert(len == 14);

		Test.Assert(XmlLexer.ReadName("name.with.dot", out len) == .Ok);
		Test.Assert(len == 13);
	}

	[Test]
	public static void TestReadName_Invalid()
	{
		int len = 0;

		Test.Assert(XmlLexer.ReadName("", out len) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName("123invalid", out len) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName("-invalid", out len) == .NameEmpty);
		Test.Assert(XmlLexer.ReadName(".invalid", out len) == .NameEmpty);
	}

	[Test]
	public static void TestReadName_WithOutput()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadName("element>", out len, output) == .Ok);
		Test.Assert(output == "element");
		Test.Assert(len == 7);

		output.Clear();
		Test.Assert(XmlLexer.ReadName("ns:tag ", out len, output) == .Ok);
		Test.Assert(output == "ns:tag");
		Test.Assert(len == 6);
	}

	[Test]
	public static void TestReadAttributeValue_DoubleQuotes()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("\"hello\"", out len, output) == .Ok);
		Test.Assert(output == "hello");
		Test.Assert(len == 7);

		output.Clear();
		Test.Assert(XmlLexer.ReadAttributeValue("\"hello world\"", out len, output) == .Ok);
		Test.Assert(output == "hello world");
	}

	[Test]
	public static void TestReadAttributeValue_SingleQuotes()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("'hello'", out len, output) == .Ok);
		Test.Assert(output == "hello");
		Test.Assert(len == 7);
	}

	[Test]
	public static void TestReadAttributeValue_WithEntities()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("\"&amp;\"", out len, output) == .Ok);
		Test.Assert(output == "&");

		output.Clear();
		Test.Assert(XmlLexer.ReadAttributeValue("\"&lt;&gt;\"", out len, output) == .Ok);
		Test.Assert(output == "<>");

		output.Clear();
		Test.Assert(XmlLexer.ReadAttributeValue("\"&apos;&quot;\"", out len, output) == .Ok);
		Test.Assert(output == "'\"");
	}

	[Test]
	public static void TestReadAttributeValue_CharacterReferences()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadAttributeValue("\"&#65;\"", out len, output) == .Ok);
		Test.Assert(output == "A");

		output.Clear();
		Test.Assert(XmlLexer.ReadAttributeValue("\"&#x41;\"", out len, output) == .Ok);
		Test.Assert(output == "A");

		output.Clear();
		Test.Assert(XmlLexer.ReadAttributeValue("\"&#x3C;\"", out len, output) == .Ok);
		Test.Assert(output == "<");
	}

	[Test]
	public static void TestReadTextContent()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadTextContent("hello<", out len, output) == .Ok);
		Test.Assert(output == "hello");
		Test.Assert(len == 5);

		output.Clear();
		Test.Assert(XmlLexer.ReadTextContent("hello &amp; world<", out len, output) == .Ok);
		Test.Assert(output == "hello & world");
	}

	[Test]
	public static void TestReadCDataContent()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadCDataContent("content]]>", out len, output) == .Ok);
		Test.Assert(output == "content");
		Test.Assert(len == 10);

		output.Clear();
		Test.Assert(XmlLexer.ReadCDataContent("text with <special> chars]]>", out len, output) == .Ok);
		Test.Assert(output == "text with <special> chars");
	}

	[Test]
	public static void TestReadCDataContent_Unclosed()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadCDataContent("unclosed content", out len, output) == .CDataUnclosed);
	}

	[Test]
	public static void TestReadCommentContent()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadCommentContent("comment-->", out len, output) == .Ok);
		Test.Assert(output == "comment");
		Test.Assert(len == 10);

		output.Clear();
		Test.Assert(XmlLexer.ReadCommentContent(" this is a comment -->", out len, output) == .Ok);
		Test.Assert(output == " this is a comment ");
	}

	[Test]
	public static void TestReadCommentContent_IllegalSequence()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadCommentContent("illegal -- sequence-->", out len, output) == .CommentIllegalSequence);
	}

	[Test]
	public static void TestReadProcessingInstruction()
	{
		let target = scope String();
		let data = scope String();
		int len = 0;

		Test.Assert(XmlLexer.ReadProcessingInstruction("target?>", out len, target, data) == .Ok);
		Test.Assert(target == "target");
		Test.Assert(data.IsEmpty);

		target.Clear();
		data.Clear();
		Test.Assert(XmlLexer.ReadProcessingInstruction("target data?>", out len, target, data) == .Ok);
		Test.Assert(target == "target");
		Test.Assert(data == "data");

		target.Clear();
		data.Clear();
		Test.Assert(XmlLexer.ReadProcessingInstruction("php echo 'hello'; ?>", out len, target, data) == .Ok);
		Test.Assert(target == "php");
		Test.Assert(data == "echo 'hello'; ");
	}

	[Test]
	public static void TestIsValidName()
	{
		Test.Assert(XmlLexer.IsValidName("valid"));
		Test.Assert(XmlLexer.IsValidName("_valid"));
		Test.Assert(XmlLexer.IsValidName("valid123"));
		Test.Assert(XmlLexer.IsValidName("ns:name"));
		Test.Assert(XmlLexer.IsValidName("name-with-dash"));

		Test.Assert(!XmlLexer.IsValidName(""));
		Test.Assert(!XmlLexer.IsValidName("123invalid"));
		Test.Assert(!XmlLexer.IsValidName("-invalid"));
	}

	[Test]
	public static void TestSplitQualifiedName()
	{
		let prefix = scope String();
		let localName = scope String();

		XmlLexer.SplitQualifiedName("element", prefix, localName);
		Test.Assert(prefix.IsEmpty);
		Test.Assert(localName == "element");

		prefix.Clear();
		localName.Clear();
		XmlLexer.SplitQualifiedName("ns:element", prefix, localName);
		Test.Assert(prefix == "ns");
		Test.Assert(localName == "element");

		prefix.Clear();
		localName.Clear();
		XmlLexer.SplitQualifiedName("a:b:c", prefix, localName);
		Test.Assert(prefix == "a");
		Test.Assert(localName == "b:c");
	}

	[Test]
	public static void TestEntityReference_Unknown()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.DecodeReference("&unknown;", out len, output) == .EntityUnknown);
	}

	[Test]
	public static void TestCharacterReference_OutOfRange()
	{
		let output = scope String();
		int len = 0;

		Test.Assert(XmlLexer.DecodeReference("&#x110000;", out len, output) == .CharRefOutOfRange);
		Test.Assert(XmlLexer.DecodeReference("&#0;", out len, output) == .CharRefOutOfRange);
	}
}
