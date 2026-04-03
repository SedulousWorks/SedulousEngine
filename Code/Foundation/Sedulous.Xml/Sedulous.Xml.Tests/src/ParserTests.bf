using System;
using System.Collections;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class ParserTests
{
	[Test]
	public static void TestParseEmptyElement()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root></root>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement != null);
		Test.Assert(doc.RootElement.TagName == "root");
		Test.Assert(!doc.RootElement.HasChildren);
	}

	[Test]
	public static void TestParseSelfClosingElement()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement != null);
		Test.Assert(doc.RootElement.TagName == "root");
		Test.Assert(!doc.RootElement.HasChildren);
	}

	[Test]
	public static void TestParseElementWithText()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root>Hello World</root>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement != null);
		Test.Assert(doc.RootElement.HasChildren);

		let text = scope String();
		doc.RootElement.GetTextContent(text);
		Test.Assert(text == "Hello World");
	}

	[Test]
	public static void TestParseElementWithAttributes()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root id=\"123\" name=\"test\"/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement != null);
		Test.Assert(doc.RootElement.AttributeCount == 2);
		Test.Assert(doc.RootElement.GetAttribute("id") == "123");
		Test.Assert(doc.RootElement.GetAttribute("name") == "test");
	}

	[Test]
	public static void TestParseNestedElements()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><child1/><child2><grandchild/></child2></root>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement != null);
		Test.Assert(doc.RootElement.ChildCount == 2);

		let child1 = doc.RootElement.GetFirstChildElement("child1");
		Test.Assert(child1 != null);

		let child2 = doc.RootElement.GetFirstChildElement("child2");
		Test.Assert(child2 != null);
		Test.Assert(child2.HasChildren);

		let grandchild = child2.GetFirstChildElement("grandchild");
		Test.Assert(grandchild != null);
	}

	[Test]
	public static void TestParseDeclaration()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<?xml version=\"1.0\"?><root/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.Declaration != null);
		Test.Assert(doc.Declaration.Version == "1.0");
	}

	[Test]
	public static void TestParseDeclaration_AllAttributes()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><root/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.Declaration != null);
		Test.Assert(doc.Declaration.Version == "1.0");
		Test.Assert(doc.Declaration.Encoding == "utf-8");
		Test.Assert(doc.Declaration.Standalone == "yes");
	}

	[Test]
	public static void TestParseCData()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><![CDATA[<special> & content]]></root>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement.HasChildren);

		let text = scope String();
		doc.RootElement.GetTextContent(text);
		Test.Assert(text == "<special> & content");
	}

	[Test]
	public static void TestParseComment()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><!-- this is a comment --></root>");

		Test.Assert(result == .Ok);

		var foundComment = false;
		for (let child in doc.RootElement.Children)
		{
			if (let comment = child as XmlComment)
			{
				Test.Assert(comment.Text == " this is a comment ");
				foundComment = true;
			}
		}
		Test.Assert(foundComment);
	}

	[Test]
	public static void TestParseComment_Ignored()
	{
		let doc = scope XmlDocument();
		var settings = XmlParseSettings.Default;
		settings.IgnoreComments = true;
		let result = doc.Parse("<root><!-- comment --></root>", settings);

		Test.Assert(result == .Ok);
		Test.Assert(!doc.RootElement.HasChildren);
	}

	[Test]
	public static void TestParseProcessingInstruction()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><?target data?></root>");

		Test.Assert(result == .Ok);

		var foundPI = false;
		for (let child in doc.RootElement.Children)
		{
			if (let pi = child as XmlProcessingInstruction)
			{
				Test.Assert(pi.Target == "target");
				Test.Assert(pi.Data == "data");
				foundPI = true;
			}
		}
		Test.Assert(foundPI);
	}

	[Test]
	public static void TestParseMixedContent()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root>text1<child/>text2</root>");

		Test.Assert(result == .Ok);

		var settings = XmlParseSettings.Default;
		settings.PreserveWhitespace = true;

		let doc2 = scope XmlDocument();
		let result2 = doc2.Parse("<root>text1<child/>text2</root>", settings);
		Test.Assert(result2 == .Ok);
		Test.Assert(doc2.RootElement.ChildCount == 3);
	}

	[Test]
	public static void TestParseBuiltinEntities()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root>&amp;&lt;&gt;&apos;&quot;</root>");

		Test.Assert(result == .Ok);

		let text = scope String();
		doc.RootElement.GetTextContent(text);
		Test.Assert(text == "&<>'\"");
	}

	[Test]
	public static void TestParseCharacterReferences()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root>&#65;&#x42;</root>");

		Test.Assert(result == .Ok);

		let text = scope String();
		doc.RootElement.GetTextContent(text);
		Test.Assert(text == "AB");
	}

	[Test]
	public static void TestParseDefaultNamespace()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root xmlns=\"http://example.com\"/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement.HasAttribute("xmlns"));
		Test.Assert(doc.RootElement.GetAttribute("xmlns") == "http://example.com");
	}

	[Test]
	public static void TestParsePrefixedNamespace()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<ns:root xmlns:ns=\"http://example.com\"/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement.TagName == "ns:root");
		Test.Assert(doc.RootElement.Prefix == "ns");
		Test.Assert(doc.RootElement.LocalName == "root");
	}

	[Test]
	public static void TestParseError_UnmatchedTag()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root></other>");

		Test.Assert(result == .TagMismatch);
	}

	[Test]
	public static void TestParseError_DuplicateAttribute()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root id=\"1\" id=\"2\"/>");

		Test.Assert(result == .AttributeDuplicate);
	}

	[Test]
	public static void TestParseError_UnclosedTag()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><child></root>");

		Test.Assert(result == .TagMismatch);
	}

	[Test]
	public static void TestParseError_MultipleRoots()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root1/><root2/>");

		Test.Assert(result == .MultipleRoots);
	}

	[Test]
	public static void TestParseError_NoRoot()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("");

		Test.Assert(result == .NoRootElement);

		let result2 = doc.Parse("<!-- comment only -->");
		Test.Assert(result2 == .NoRootElement);
	}

	[Test]
	public static void TestParseError_UnknownEntity()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root>&unknown;</root>");

		Test.Assert(result == .EntityUnknown);
	}

	[Test]
	public static void TestParseError_UnclosedCData()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><![CDATA[unclosed</root>");

		Test.Assert(result == .CDataUnclosed);
	}

	[Test]
	public static void TestParseError_UnclosedComment()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><!-- unclosed</root>");

		Test.Assert(result == .CommentUnclosed);
	}

	[Test]
	public static void TestParseWhitespace()
	{
		let doc = scope XmlDocument();
		var settings = XmlParseSettings.Default;
		settings.PreserveWhitespace = false;

		let result = doc.Parse("<root>  <child/>  </root>", settings);
		Test.Assert(result == .Ok);
		// Whitespace-only text nodes should be ignored
		Test.Assert(doc.RootElement.ChildCount == 1);

		settings.PreserveWhitespace = true;
		let doc2 = scope XmlDocument();
		let result2 = doc2.Parse("<root>  <child/>  </root>", settings);
		Test.Assert(result2 == .Ok);
		// Whitespace-only text nodes should be preserved
		Test.Assert(doc2.RootElement.ChildCount == 3);
	}

	[Test]
	public static void TestParseComplexDocument()
	{
		let xml = """
			<?xml version="1.0" encoding="utf-8"?>
			<!-- Root comment -->
			<catalog>
				<book id="1">
					<title>XML Guide</title>
					<author>John Doe</author>
					<price>29.99</price>
				</book>
				<book id="2">
					<title>Advanced XML</title>
					<author>Jane Smith</author>
					<price>39.99</price>
				</book>
			</catalog>
			""";

		let doc = scope XmlDocument();
		let result = doc.Parse(xml);

		Test.Assert(result == .Ok);
		Test.Assert(doc.Declaration != null);
		Test.Assert(doc.RootElement.TagName == "catalog");

		let books = scope List<XmlElement>();
		doc.GetElementsByTagName("book", books);
		Test.Assert(books.Count == 2);

		let firstBook = books[0];
		Test.Assert(firstBook.GetAttribute("id") == "1");

		let title = firstBook.GetFirstChildElement("title");
		Test.Assert(title != null);

		let titleText = scope String();
		title.GetTextContent(titleText);
		Test.Assert(titleText == "XML Guide");
	}
}
