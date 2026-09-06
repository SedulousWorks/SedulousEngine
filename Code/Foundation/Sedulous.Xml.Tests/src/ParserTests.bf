using System;
using System.Collections;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class ParserTests
{
	[Test]
	public static void EmptyAndSelfClosingElements()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root/>") == .Ok);
		Test.Assert(document.RootElement != null);
		Test.Assert(document.RootElement.TagName == "root");
		Test.Assert(!document.RootElement.HasChildren);

		Test.Assert(document.Parse("<root></root>") == .Ok);
		Test.Assert(document.RootElement.TagName == "root");
		Test.Assert(!document.RootElement.HasChildren);

		Test.Assert(document.Parse("<root  />") == .Ok, "whitespace before the close");
	}

	[Test]
	public static void ElementWithText()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>hello</root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ChildCount == 1);
		Test.Assert(root.FirstChild.NodeType == .Text);
		Test.Assert(root.GetInnerText(.. scope String()) == "hello");
	}

	[Test]
	public static void ElementWithAttributes()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root a=\"1\" b='2' c=\"\"/>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.AttributeCount == 3);
		Test.Assert(root.GetAttribute("a") == "1");
		Test.Assert(root.GetAttribute("b") == "2", "either quote works");
		Test.Assert(root.GetAttribute("c") == "");
		Test.Assert(root.HasAttribute("a") && !root.HasAttribute("d"));

		Test.Assert(document.Parse("<root a = \"1\" />") == .Ok, "whitespace around the equals");
		Test.Assert(document.RootElement.GetAttribute("a") == "1");
	}

	[Test]
	public static void NestedElements()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<a><b><c>deep</c></b></a>") == .Ok);

		let a = document.RootElement;
		Test.Assert(a.TagName == "a");
		let b = a.FirstChildElement;
		Test.Assert((b != null) && (b.TagName == "b"));
		let c = b.FirstChildElement;
		Test.Assert((c != null) && (c.TagName == "c"));
		Test.Assert(c.GetInnerText(.. scope String()) == "deep");
		Test.Assert(a.GetInnerText(.. scope String()) == "deep", "inner text reaches the whole subtree");
	}

	[Test]
	public static void Declaration()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<?xml version=\"1.0\"?><root/>") == .Ok);
		Test.Assert(document.Declaration != null);
		Test.Assert(document.Declaration.Version == "1.0");

		Test.Assert(document.Parse("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?><root/>") == .Ok);
		Test.Assert(document.Declaration.Encoding == "utf-8");
		Test.Assert(document.Declaration.Standalone == "yes");

		// Version is required, and a declaration must come first.
		Test.Assert(document.Parse("<?xml encoding=\"utf-8\"?><root/>") == .DeclarationVersion);
		Test.Assert(document.Parse("<root/><?xml version=\"1.0\"?>") == .DeclarationPosition);
	}

	[Test]
	public static void CData()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><![CDATA[<b>not markup</b> & raw]]></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ChildCount == 1);
		Test.Assert(root.FirstChild.NodeType == .CData);
		Test.Assert(root.GetInnerText(.. scope String()) == "<b>not markup</b> & raw");

		Test.Assert(document.Parse("<root><![CDATA[unclosed</root>") == .CDataUnclosed);
	}

	[Test]
	public static void Comment()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><!-- a note --></root>") == .Ok);
		Test.Assert(document.RootElement.FirstChild.NodeType == .Comment);
		Test.Assert(((XmlComment)document.RootElement.FirstChild).Text == " a note ");
		Test.Assert(document.RootElement.GetInnerText(.. scope String()) == "", "a comment is not content");

		// Before and after the root, which is where a licence header lives.
		Test.Assert(document.Parse("<!-- before --><root/><!-- after -->") == .Ok);
		Test.Assert(document.Parse("<root><!-- a -- b --></root>") == .CommentIllegalSequence);
		Test.Assert(document.Parse("<root><!-- unclosed</root>") == .CommentUnclosed);
	}

	/// Ignoring comments still parses them, so a malformed one is an error either way.
	[Test]
	public static void IgnoredCommentsAreStillChecked()
	{
		let document = scope XmlDocument();
		var settings = XmlParseSettings.Default;
		settings.IgnoreComments = true;

		Test.Assert(document.Parse("<root><!-- a note --><x/></root>", settings) == .Ok);
		Test.Assert(document.RootElement.ChildCount == 1, "the comment was not attached");
		Test.Assert(document.Parse("<root><!-- a -- b --></root>", settings) == .CommentIllegalSequence);
	}

	[Test]
	public static void ProcessingInstruction()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><?target some data?></root>") == .Ok);

		let instruction = document.RootElement.FirstChild as XmlProcessingInstruction;
		Test.Assert(instruction != null);
		Test.Assert(instruction.Target == "target");
		Test.Assert(instruction.Data == "some data");

		var settings = XmlParseSettings.Default;
		settings.IgnoreProcessingInstructions = true;
		Test.Assert(document.Parse("<root><?target data?><x/></root>", settings) == .Ok);
		Test.Assert(document.RootElement.ChildCount == 1);
	}

	[Test]
	public static void MixedContentAndPreserveWhitespace()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>text<b>bold</b>more</root>") == .Ok);
		Test.Assert(document.RootElement.ChildCount == 3);
		Test.Assert(document.RootElement.GetInnerText(.. scope String()) == "textboldmore");

		// Formatting between elements is dropped by default.
		Test.Assert(document.Parse("<root>\n\t<a/>\n\t<b/>\n</root>") == .Ok);
		Test.Assert(document.RootElement.ChildCount == 2, "only the two elements");

		var settings = XmlParseSettings.Default;
		settings.PreserveWhitespace = true;
		Test.Assert(document.Parse("<root>\n\t<a/>\n</root>", settings) == .Ok);
		Test.Assert(document.RootElement.ChildCount == 3, "the whitespace either side is kept");
	}

	[Test]
	public static void EntitiesAndCharacterReferences()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>&lt;tag&gt; &amp; &quot;q&quot; &apos;a&apos;</root>") == .Ok);
		Test.Assert(document.RootElement.GetInnerText(.. scope String()) == "<tag> & \"q\" 'a'");

		Test.Assert(document.Parse("<root>&#65;&#x42;</root>") == .Ok);
		Test.Assert(document.RootElement.GetInnerText(.. scope String()) == "AB");

		Test.Assert(document.Parse("<root>&nope;</root>") == .EntityUnknown);
	}

	[Test]
	public static void Namespaces()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root xmlns:a=\"urn:a\"><a:child a:attr=\"v\"/></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("a") == "urn:a");

		let child = root.FirstChildElement;
		Test.Assert(child.TagName == "a:child");
		Test.Assert(child.Prefix == "a");
		Test.Assert(child.LocalName == "child");
		Test.Assert(child.ResolveNamespacePrefix("a") == "urn:a", "inherited from the parent");
	}

	[Test]
	public static void ErrorCases()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("") == .NoRootElement);
		Test.Assert(document.Parse("   ") == .NoRootElement);
		Test.Assert(document.Parse("not markup") == .NoRootElement);
		Test.Assert(document.Parse("</root>") == .TagUnexpectedClose);
		Test.Assert(document.Parse("<a></b>") == .TagMismatch);
		Test.Assert(document.Parse("<a>") == .UnexpectedEndOfFile);
		Test.Assert(document.Parse("<a/><b/>") == .MultipleRoots);
		Test.Assert(document.Parse("<a/>trailing") == .ContentAfterRoot);
		Test.Assert(document.Parse("<1bad/>") == .TagInvalid);
		Test.Assert(document.Parse("<a x/>") == .AttributeMissingEquals);
		Test.Assert(document.Parse("<a x=bare/>") == .AttributeMissingQuote);
		Test.Assert(document.Parse("<a x=\"1\" x=\"2\"/>") == .AttributeDuplicate);
	}

	/// Whitespace after the root is not content, so it is not an error either.
	[Test]
	public static void WhitespaceAroundTheRoot()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("  <root/>  ") == .Ok);
		Test.Assert(document.Parse("\n<root/>\n") == .Ok);
		Test.Assert(document.Parse("<root/>\n\t ") == .Ok);
	}

	/// Reparsing has to leave nothing of the previous document behind.
	[Test]
	public static void ReparsingReplacesEverything()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<?xml version=\"1.0\"?><first><a/><b/></first>") == .Ok);
		Test.Assert(document.RootElement.TagName == "first");
		Test.Assert(document.Declaration != null);

		Test.Assert(document.Parse("<second/>") == .Ok);
		Test.Assert(document.RootElement.TagName == "second");
		Test.Assert(document.Declaration == null, "the previous declaration is gone");
		Test.Assert(document.ChildCount == 1);

		// And after a FAILED parse the tree is empty rather than half built.
		Test.Assert(document.Parse("<a></b>") == .TagMismatch);
		Test.Assert(document.Parse("<third/>") == .Ok);
		Test.Assert(document.RootElement.TagName == "third");
	}

	[Test]
	public static void ComplexDocument()
	{
		let source = """
			<?xml version="1.0" encoding="utf-8"?>
			<!-- a config -->
			<config xmlns:app="urn:app" version="2">
				<app:setting name="width">1920</app:setting>
				<app:setting name="height">1080</app:setting>
				<paths>
					<path><![CDATA[C:\\data & more]]></path>
				</paths>
				<?build note?>
			</config>
			""";

		let document = scope XmlDocument();
		Test.Assert(document.Parse(source) == .Ok);

		let root = document.RootElement;
		Test.Assert(root.TagName == "config");
		Test.Assert(root.GetAttribute("version") == "2");
		Test.Assert(root.ResolveNamespacePrefix("app") == "urn:app");

		let settings = scope List<XmlElement>();
		root.GetChildElements("app:setting", settings);
		Test.Assert(settings.Count == 2);
		Test.Assert(settings[0].GetAttribute("name") == "width");
		Test.Assert(settings[0].GetInnerText(.. scope String()) == "1920");

		let all = scope List<XmlElement>();
		document.GetElementsByTagName("", all);
		Test.Assert(all.Count == 5, scope $"saw {all.Count} elements");
	}
}
