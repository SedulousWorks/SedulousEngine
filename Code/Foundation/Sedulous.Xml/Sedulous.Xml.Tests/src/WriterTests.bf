using System;
using Sedulous.Xml;
using static Sedulous.Xml.XmlWriterExtensions;

namespace Sedulous.Xml.Tests;

class WriterTests
{
	[Test]
	public static void TestWriteSimpleElement()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		doc.AppendChild(root);

		let output = scope String();
		doc.WriteTo(output);

		Test.Assert(output.Contains("<root/>"));
	}

	[Test]
	public static void TestWriteElementWithContent()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.AppendChild(doc.CreateTextNode("Hello"));
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("<root>Hello</root>"));
	}

	[Test]
	public static void TestWriteNestedElements()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		let child = doc.CreateElement("child");
		let grandchild = doc.CreateElement("grandchild");

		child.AppendChild(grandchild);
		root.AppendChild(child);
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		settings.CompactMode = true;
		doc.WriteTo(output, settings);

		Test.Assert(output == "<root><child><grandchild/></child></root>");
	}

	[Test]
	public static void TestWriteAttributes()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.SetAttribute("id", "123");
		root.SetAttribute("name", "test");
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("id=\"123\""));
		Test.Assert(output.Contains("name=\"test\""));
	}

	[Test]
	public static void TestWriteEscaping()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.AppendChild(doc.CreateTextNode("a < b & c > d"));
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("a &lt; b &amp; c &gt; d"));
	}

	[Test]
	public static void TestWriteAttributeEscaping()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.SetAttribute("value", "a\"b'c<d>e&f");
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("&quot;"));
		Test.Assert(output.Contains("&apos;"));
		Test.Assert(output.Contains("&lt;"));
		Test.Assert(output.Contains("&gt;"));
		Test.Assert(output.Contains("&amp;"));
	}

	[Test]
	public static void TestWriteCompactMode()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		let child = doc.CreateElement("child");
		root.AppendChild(child);
		doc.AppendChild(root);

		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		settings.CompactMode = true;

		let output = scope String();
		doc.WriteTo(output, settings);

		Test.Assert(!output.Contains("\n"));
		Test.Assert(!output.Contains("\t"));
		Test.Assert(output == "<root><child/></root>");
	}

	[Test]
	public static void TestWriteIndentation()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		let child = doc.CreateElement("child");
		root.AppendChild(child);
		doc.AppendChild(root);

		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		settings.Indent = true;
		settings.IndentString = "  ";

		let output = scope String();
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("\n"));
		Test.Assert(output.Contains("  <child/>"));
	}

	[Test]
	public static void TestWriteCData()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.AppendChild(doc.CreateCDataSection("<special> & content"));
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("<![CDATA[<special> & content]]>"));
	}

	[Test]
	public static void TestWriteComment()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.AppendChild(doc.CreateComment(" this is a comment "));
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("<!-- this is a comment -->"));
	}

	[Test]
	public static void TestWriteDeclaration()
	{
		let doc = scope XmlDocument();
		let decl = new XmlDeclaration("1.0", "utf-8", "");
		doc.AppendChild(decl);
		let root = doc.CreateElement("root");
		doc.AppendChild(root);

		let output = scope String();
		doc.WriteTo(output);

		Test.Assert(output.StartsWith("<?xml version=\"1.0\" encoding=\"utf-8\"?>"));
	}

	[Test]
	public static void TestWriteDeclaration_OmitDeclaration()
	{
		let doc = scope XmlDocument();
		let decl = new XmlDeclaration("1.0", "utf-8", "");
		doc.AppendChild(decl);
		let root = doc.CreateElement("root");
		doc.AppendChild(root);

		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;

		let output = scope String();
		doc.WriteTo(output, settings);

		Test.Assert(!output.Contains("<?xml"));
	}

	[Test]
	public static void TestWriteProcessingInstruction()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		root.AppendChild(doc.CreateProcessingInstruction("php", "echo 'hello';"));
		doc.AppendChild(root);

		let output = scope String();
		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("<?php echo 'hello';?>"));
	}

	[Test]
	public static void TestRoundTrip()
	{
		let originalXml = """
			<?xml version="1.0" encoding="utf-8"?>
			<catalog>
				<book id="1">
					<title>Test</title>
				</book>
			</catalog>
			""";

		let doc = scope XmlDocument();
		let result = doc.Parse(originalXml);
		Test.Assert(result == .Ok);

		let output = scope String();
		doc.WriteTo(output);

		// Parse the output again
		let doc2 = scope XmlDocument();
		let result2 = doc2.Parse(output);
		Test.Assert(result2 == .Ok);

		// Verify structure is preserved
		Test.Assert(doc2.RootElement.TagName == "catalog");
		let book = doc2.RootElement.GetFirstChildElement("book");
		Test.Assert(book != null);
		Test.Assert(book.GetAttribute("id") == "1");

		let title = book.GetFirstChildElement("title");
		Test.Assert(title != null);

		let titleText = scope String();
		title.GetTextContent(titleText);
		Test.Assert(titleText == "Test");
	}

	[Test]
	public static void TestElementToXml()
	{
		let elem = scope XmlElement("test");
		elem.SetAttribute("id", "1");
		elem.SetTextContent("content");

		let output = scope String();
		elem.ToXml(output, true);

		Test.Assert(output == "<test id=\"1\">content</test>");
	}

	[Test]
	public static void TestEscapeText()
	{
		let output = scope String();
		XmlWriter.EscapeText("a < b & c > d", output);
		Test.Assert(output == "a &lt; b &amp; c &gt; d");
	}

	[Test]
	public static void TestEscapeAttributeValue()
	{
		let output = scope String();
		XmlWriter.EscapeAttributeValue("a\"b'c\r\n\t", output);
		Test.Assert(output.Contains("&quot;"));
		Test.Assert(output.Contains("&apos;"));
		Test.Assert(output.Contains("&#xD;"));
		Test.Assert(output.Contains("&#xA;"));
		Test.Assert(output.Contains("&#x9;"));
	}

	[Test]
	public static void TestCustomIndentString()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("root");
		let child = doc.CreateElement("child");
		root.AppendChild(child);
		doc.AppendChild(root);

		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		settings.IndentString = "    "; // 4 spaces

		let output = scope String();
		doc.WriteTo(output, settings);

		Test.Assert(output.Contains("    <child/>"));
	}

	[Test]
	public static void TestWriteMixedContent()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("p");
		root.AppendChild(doc.CreateTextNode("Hello "));
		let bold = doc.CreateElement("b");
		bold.AppendChild(doc.CreateTextNode("World"));
		root.AppendChild(bold);
		root.AppendChild(doc.CreateTextNode("!"));
		doc.AppendChild(root);

		var settings = XmlWriteSettings.Default;
		settings.OmitDeclaration = true;
		settings.CompactMode = true;

		let output = scope String();
		doc.WriteTo(output, settings);

		Test.Assert(output == "<p>Hello <b>World</b>!</p>");
	}
}
