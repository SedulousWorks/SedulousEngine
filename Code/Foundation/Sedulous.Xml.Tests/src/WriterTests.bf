using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class WriterTests
{
	private static void Write(XmlElement element, String output, bool compact = false)
	{
		ToXml(element, output, compact);
	}

	[Test]
	public static void SimpleElement()
	{
		let element = scope XmlElement("root");
		Test.Assert(Write(element, .. scope String()) == "<root/>", "no children writes self closing");
	}

	[Test]
	public static void ElementWithContent()
	{
		let element = scope XmlElement("name");
		element.SetTextContent("value");
		// One text child stays on the line with its tags: breaking it would add whitespace
		// to the content that reading it back would have to decide about.
		Test.Assert(Write(element, .. scope String()) == "<name>value</name>");
	}

	[Test]
	public static void Attributes()
	{
		let element = scope XmlElement("e");
		element.SetAttribute("a", "1");
		element.SetAttribute("b", "2");
		Test.Assert(Write(element, .. scope String()) == "<e a=\"1\" b=\"2\"/>");
	}

	[Test]
	public static void TextEscaping()
	{
		let element = scope XmlElement("e");
		element.SetTextContent("a < b & c > d");
		// A quote is data inside text, so it is left alone.
		element.AppendChild(new XmlText(" \"quoted\""));
		Test.Assert(Write(element, .. scope String(), true) == "<e>a &lt; b &amp; c &gt; d \"quoted\"</e>");
	}

	[Test]
	public static void AttributeEscaping()
	{
		let element = scope XmlElement("e");
		element.SetAttribute("a", "x < y & \"z\" 'w'");
		Test.Assert(Write(element, .. scope String()) == "<e a=\"x &lt; y &amp; &quot;z&quot; &apos;w&apos;\"/>");

		// Whitespace becomes character references, because attribute values are normalised
		// on the way back in and a tab would otherwise come back as a space.
		let ws = scope XmlElement("e");
		ws.SetAttribute("a", "x\ty\nz\r");
		Test.Assert(Write(ws, .. scope String()) == "<e a=\"x&#x9;y&#xA;z&#xD;\"/>");
	}

	[Test]
	public static void CompactModeIsOneLine()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a>1</a><b>2</b></root>") == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		settings.OmitDeclaration = true;

		let output = scope String();
		document.WriteTo(output, settings);
		Test.Assert(output == "<root><a>1</a><b>2</b></root>");
		Test.Assert(!output.Contains('\n'));
	}

	[Test]
	public static void Indentation()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a>1</a></root>") == .Ok);

		let output = scope String();
		document.WriteTo(output);
		Test.Assert(output == "<root>\n\t<a>1</a>\n</root>", scope $"got '{output}'");
	}

	[Test]
	public static void CustomIndentString()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a>1</a></root>") == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.IndentString = "  ";
		let output = scope String();
		document.WriteTo(output, settings);
		Test.Assert(output == "<root>\n  <a>1</a>\n</root>", scope $"got '{output}'");

		// Indent off puts everything at the margin but keeps the line breaks.
		settings.Indent = false;
		let flat = scope String();
		document.WriteTo(flat, settings);
		Test.Assert(flat == "<root>\n<a>1</a>\n</root>", scope $"got '{flat}'");
	}

	[Test]
	public static void CDataCommentAndInstruction()
	{
		let element = scope XmlElement("root");
		element.AppendChild(new XmlCData("<raw>"));
		let output = scope String();
		Write(element, output, true);
		Test.Assert(output == "<root><![CDATA[<raw>]]></root>");

		let withComment = scope XmlElement("root");
		withComment.AppendChild(new XmlComment(" note "));
		withComment.AppendChild(new XmlProcessingInstruction("pi", "data"));
		let commented = scope String();
		Write(withComment, commented, true);
		Test.Assert(commented == "<root><!-- note --><?pi data?></root>");
	}

	[Test]
	public static void DeclarationIsWrittenOnceAndCanBeOmitted()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<?xml version=\"1.0\" encoding=\"utf-8\"?><root/>") == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;

		let withDeclaration = scope String();
		document.WriteTo(withDeclaration, settings);
		Test.Assert(withDeclaration == "<?xml version=\"1.0\" encoding=\"utf-8\"?><root/>");

		settings.OmitDeclaration = true;
		let without = scope String();
		document.WriteTo(without, settings);
		Test.Assert(without == "<root/>");
	}

	/// Parse, write, parse again: the second document has to say the same thing as the
	/// first, which is the property that makes the writer usable for storage.
	[Test]
	public static void RoundTrip()
	{
		let source = "<?xml version=\"1.0\" encoding=\"utf-8\"?><config version=\"2\"><item name=\"a\">1</item><item name=\"b\">2</item><raw><![CDATA[x < y]]></raw></config>";

		let first = scope XmlDocument();
		Test.Assert(first.Parse(source) == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		let written = scope String();
		first.WriteTo(written, settings);
		Test.Assert(written == source, scope $"got '{written}'");

		let second = scope XmlDocument();
		Test.Assert(second.Parse(written) == .Ok);
		let rewritten = scope String();
		second.WriteTo(rewritten, settings);
		Test.Assert(rewritten == written, "and it is stable across a second pass");
	}

	/// Escaped text has to survive the round trip as the ORIGINAL characters, not as the
	/// escapes: a document written twice must not grow &amp;amp;.
	[Test]
	public static void EscapingIsStableAcrossARoundTrip()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<e a=\"x &amp; y\">p &lt; q</e>") == .Ok);
		Test.Assert(document.RootElement.GetAttribute("a") == "x & y");
		Test.Assert(document.RootElement.GetInnerText(.. scope String()) == "p < q");

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		settings.OmitDeclaration = true;
		let written = scope String();
		document.WriteTo(written, settings);
		Test.Assert(written == "<e a=\"x &amp; y\">p &lt; q</e>", scope $"got '{written}'");

		let again = scope XmlDocument();
		Test.Assert(again.Parse(written) == .Ok);
		Test.Assert(again.RootElement.GetInnerText(.. scope String()) == "p < q", "not double escaped");
	}

	[Test]
	public static void EscapeHelpers()
	{
		Test.Assert(EscapeText("a & b < c > d", .. scope String()) == "a &amp; b &lt; c &gt; d");
		Test.Assert(EscapeText("plain", .. scope String()) == "plain");
		Test.Assert(EscapeAttributeValue("\"'&<>", .. scope String()) == "&quot;&apos;&amp;&lt;&gt;");
	}

	[Test]
	public static void MixedContent()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<p>before<b>bold</b>after</p>") == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		settings.OmitDeclaration = true;
		let output = scope String();
		document.WriteTo(output, settings);
		Test.Assert(output == "<p>before<b>bold</b>after</p>", scope $"got '{output}'");
	}

	[Test]
	public static void NestedElementsCompact()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<a><b><c/></b></a>") == .Ok);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		settings.OmitDeclaration = true;
		let output = scope String();
		document.WriteTo(output, settings);
		Test.Assert(output == "<a><b><c/></b></a>");
	}

	/// GetOuterXml on a node writes that node and its subtree, without a declaration.
	[Test]
	public static void OuterXmlOfANode()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><child a=\"1\">t</child></root>") == .Ok);

		let child = document.RootElement.FirstChildElement;
		Test.Assert(child.GetOuterXml(.. scope String()) == "<child a=\"1\">t</child>");
	}
}
