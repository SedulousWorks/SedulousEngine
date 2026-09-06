using System;
using System.Collections;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class NodeTests
{
	[Test]
	public static void ElementCreation()
	{
		let element = scope XmlElement("div");
		Test.Assert(element.TagName == "div");
		Test.Assert(element.NodeType == .Element);
		Test.Assert(element.Prefix == "");
		Test.Assert(element.LocalName == "div");

		element.SetTagName("ns:span");
		Test.Assert(element.Prefix == "ns");
		Test.Assert(element.LocalName == "span");
	}

	[Test]
	public static void ElementCreationWithNamespace()
	{
		let element = scope XmlElement("a", "child", "urn:a");
		Test.Assert(element.TagName == "a:child", "the tag name is rebuilt from the parts");
		Test.Assert(element.Prefix == "a");
		Test.Assert(element.LocalName == "child");
		Test.Assert(element.NamespaceUri == "urn:a");

		// No prefix means no colon.
		let bare = scope XmlElement("", "child", "urn:a");
		Test.Assert(bare.TagName == "child");
	}

	[Test]
	public static void AttributeManipulation()
	{
		let element = scope XmlElement("e");
		element.SetAttribute("a", "1");
		element.SetAttribute("b", "2");
		Test.Assert(element.AttributeCount == 2);
		Test.Assert(element.GetAttribute("a") == "1");

		// Setting an existing name replaces rather than duplicating.
		element.SetAttribute("a", "9");
		Test.Assert(element.AttributeCount == 2);
		Test.Assert(element.GetAttribute("a") == "9");

		Test.Assert(element.GetAttribute("missing") == "", "an absent attribute reads as empty");
		Test.Assert(!element.HasAttribute("missing"));

		element.RemoveAttribute("a");
		Test.Assert(element.AttributeCount == 1);
		Test.Assert(!element.HasAttribute("a"));

		element.ClearAttributes();
		Test.Assert(element.AttributeCount == 0);
	}

	/// RemoveAttributeNode hands the node back alive; everything else deletes.
	[Test]
	public static void RemoveAttributeNodeDetachesWithoutDeleting()
	{
		let element = scope XmlElement("e");
		element.SetAttribute("a", "1");

		let node = element.GetAttributeNode("a");
		Test.Assert(node != null);
		Test.Assert(node.OwnerElement == element);

		element.RemoveAttributeNode(node);
		Test.Assert(element.AttributeCount == 0);
		Test.Assert(node.OwnerElement == null, "it no longer belongs to the element");
		Test.Assert(node.Value == "1", "and it is still alive");
		delete node;
	}

	[Test]
	public static void ChildManipulation()
	{
		let parent = scope XmlElement("parent");
		let a = new XmlElement("a");
		let b = new XmlElement("b");

		parent.AppendChild(a);
		parent.AppendChild(b);
		Test.Assert(parent.ChildCount == 2);
		Test.Assert(parent.FirstChild == a);
		Test.Assert(parent.LastChild == b);
		Test.Assert(a.Parent == parent);

		let c = new XmlElement("c");
		parent.PrependChild(c);
		Test.Assert(parent.FirstChild == c);
		Test.Assert(parent.ChildCount == 3);

		// Detaching does not delete, so the caller has to.
		parent.RemoveChild(c);
		Test.Assert(parent.ChildCount == 2);
		Test.Assert(c.Parent == null);
		delete c;

		parent.ClearChildren();
		Test.Assert(parent.ChildCount == 0);
		Test.Assert(!parent.HasChildren);
	}

	[Test]
	public static void InsertBeforeAndAfter()
	{
		let parent = scope XmlElement("parent");
		let a = new XmlElement("a");
		let c = new XmlElement("c");
		parent.AppendChild(a);
		parent.AppendChild(c);

		let b = new XmlElement("b");
		parent.InsertBefore(b, c);
		Test.Assert(parent.ChildCount == 3);
		Test.Assert(a.NextSibling == b);
		Test.Assert(b.NextSibling == c);
		Test.Assert(c.PrevSibling == b);

		let d = new XmlElement("d");
		parent.InsertAfter(d, c);
		Test.Assert(parent.LastChild == d);

		// A null reference appends or prepends, since there is nothing to sit beside.
		let first = new XmlElement("first");
		parent.InsertAfter(first, null);
		Test.Assert(parent.FirstChild == first);

		let last = new XmlElement("last");
		parent.InsertBefore(last, null);
		Test.Assert(parent.LastChild == last);
	}

	[Test]
	public static void TreeNavigation()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root>text<a/><b/>more</root>") == .Ok);

		let root = document.RootElement;
		// The element accessors skip text, which is what makes them useful.
		let a = root.FirstChildElement;
		Test.Assert((a != null) && (a.TagName == "a"));
		let b = a.NextSiblingElement;
		Test.Assert((b != null) && (b.TagName == "b"));
		Test.Assert(b.NextSiblingElement == null);
		Test.Assert(root.LastChildElement == b);
		Test.Assert(b.PrevSiblingElement == a);
		Test.Assert(a.PrevSiblingElement == null);

		Test.Assert(root.GetFirstChildElement("b") == b);
		Test.Assert(root.GetFirstChildElement("nope") == null);
	}

	[Test]
	public static void ChildEnumeration()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a/><b/><c/></root>") == .Ok);

		let names = scope String();
		for (let child in document.RootElement.Children)
		{
			if (let element = child as XmlElement)
				names.Append(element.TagName);
		}
		Test.Assert(names == "abc");
	}

	[Test]
	public static void GetChildElements()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a/><b/><a/><c><a/></c></root>") == .Ok);

		let matching = scope List<XmlElement>();
		document.RootElement.GetChildElements("a", matching);
		Test.Assert(matching.Count == 2, "direct children only, not the nested one");

		let all = scope List<XmlElement>();
		document.RootElement.GetChildElements("", all);
		Test.Assert(all.Count == 4, "an empty name matches every element");
	}

	[Test]
	public static void GetDescendantElements()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><a/><b><a/><c><a/></c></b></root>") == .Ok);

		let matching = scope List<XmlElement>();
		document.RootElement.GetDescendantElements("a", matching);
		Test.Assert(matching.Count == 3, "the whole subtree");

		let all = scope List<XmlElement>();
		document.RootElement.GetDescendantElements("", all);
		Test.Assert(all.Count == 5);
	}

	[Test]
	public static void TextContent()
	{
		let element = scope XmlElement("e");
		element.SetTextContent("hello");
		Test.Assert(element.ChildCount == 1);
		Test.Assert(element.GetTextContent(.. scope String()) == "hello");

		// Setting replaces everything that was there.
		element.SetTextContent("world");
		Test.Assert(element.ChildCount == 1);
		Test.Assert(element.GetTextContent(.. scope String()) == "world");

		// Empty means no child at all, not an empty one.
		element.SetTextContent("");
		Test.Assert(element.ChildCount == 0);
	}

	[Test]
	public static void TextNode()
	{
		let text = scope XmlText("hello");
		Test.Assert(text.NodeType == .Text);
		Test.Assert(text.Text == "hello");
		Test.Assert(!text.IsWhitespace);

		text.AppendText(" world");
		Test.Assert(text.Text == "hello world");

		let blank = scope XmlText("  \t\n ");
		Test.Assert(blank.IsWhitespace);

		let empty = scope XmlText("");
		Test.Assert(empty.IsWhitespace, "nothing but whitespace, vacuously");

		// The flag follows the text rather than being set once.
		blank.SetText("x");
		Test.Assert(!blank.IsWhitespace);
		blank.Clear();
		Test.Assert(blank.IsWhitespace);
	}

	[Test]
	public static void CDataNode()
	{
		let cdata = scope XmlCData("<raw> & stuff");
		Test.Assert(cdata.NodeType == .CData);
		Test.Assert(cdata.Data == "<raw> & stuff");
		Test.Assert(cdata.GetInnerText(.. scope String()) == "<raw> & stuff");
		// Written verbatim rather than escaped, which is the point of a CDATA section.
		Test.Assert(cdata.GetOuterXml(.. scope String()) == "<![CDATA[<raw> & stuff]]>");
	}

	[Test]
	public static void CommentNode()
	{
		let comment = scope XmlComment(" note ");
		Test.Assert(comment.NodeType == .Comment);
		Test.Assert(comment.Text == " note ");
		Test.Assert(comment.GetInnerText(.. scope String()) == "", "a comment is not content");
		Test.Assert(comment.GetOuterXml(.. scope String()) == "<!-- note -->");
	}

	[Test]
	public static void DeclarationNode()
	{
		let declaration = scope XmlDeclaration();
		Test.Assert(declaration.Version == "1.0", "the defaults");
		Test.Assert(declaration.Encoding == "utf-8");
		Test.Assert(declaration.Standalone == "");
		Test.Assert(declaration.GetOuterXml(.. scope String()) == "<?xml version=\"1.0\" encoding=\"utf-8\"?>");

		let full = scope XmlDeclaration("1.1", "utf-16", "yes");
		Test.Assert(full.GetOuterXml(.. scope String()) == "<?xml version=\"1.1\" encoding=\"utf-16\" standalone=\"yes\"?>");

		// An empty encoding is omitted rather than written as encoding="".
		let bare = scope XmlDeclaration("1.0", "", "");
		Test.Assert(bare.GetOuterXml(.. scope String()) == "<?xml version=\"1.0\"?>");
	}

	[Test]
	public static void ProcessingInstructionNode()
	{
		let instruction = scope XmlProcessingInstruction("target", "data here");
		Test.Assert(instruction.NodeType == .ProcessingInstruction);
		Test.Assert(instruction.Target == "target");
		Test.Assert(instruction.GetInnerText(.. scope String()) == "");
		Test.Assert(instruction.GetOuterXml(.. scope String()) == "<?target data here?>");

		let bare = scope XmlProcessingInstruction("target", "");
		Test.Assert(bare.GetOuterXml(.. scope String()) == "<?target?>", "no trailing space");
	}

	[Test]
	public static void AttributeNode()
	{
		let attribute = scope XmlAttribute("name", "value");
		Test.Assert(attribute.NodeType == .Attribute);
		Test.Assert(attribute.Name == "name");
		Test.Assert(attribute.Value == "value");
		Test.Assert(attribute.GetInnerText(.. scope String()) == "value");
		Test.Assert(attribute.GetOuterXml(.. scope String()) == "name=\"value\"");

		let qualified = scope XmlAttribute("ns", "local", "urn:x", "v");
		Test.Assert(qualified.Name == "ns:local");
		Test.Assert(qualified.NamespaceUri == "urn:x");

		// The value is escaped on the way out.
		let escaped = scope XmlAttribute("a", "x < y & \"z\"");
		Test.Assert(escaped.GetOuterXml(.. scope String()) == "a=\"x &lt; y &amp; &quot;z&quot;\"");
	}

	[Test]
	public static void OwnerDocument()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><child/></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.OwnerDocument == document);
		Test.Assert(root.FirstChildElement.OwnerDocument == document, "found by walking up");

		// A detached subtree belongs to no document.
		let orphan = scope XmlElement("orphan");
		Test.Assert(orphan.OwnerDocument == null);
	}

	[Test]
	public static void RemoveFromParent()
	{
		let parent = scope XmlElement("parent");
		let child = new XmlElement("child");
		parent.AppendChild(child);

		child.RemoveFromParent();
		Test.Assert(parent.ChildCount == 0);
		Test.Assert(child.Parent == null);
		delete child;

		// Harmless on something that has no parent.
		let orphan = scope XmlElement("orphan");
		orphan.RemoveFromParent();
	}

	/// Setting xmlns binds a namespace as well as storing an attribute.
	[Test]
	public static void NamespaceDeclarationThroughAnAttribute()
	{
		let element = scope XmlElement("root");
		element.SetAttribute("xmlns:a", "urn:a");

		Test.Assert(element.HasAttribute("xmlns:a"), "still an attribute");
		Test.Assert(element.ResolveNamespacePrefix("a") == "urn:a", "and a binding");

		element.SetAttribute("xmlns", "urn:default");
		Test.Assert(element.ResolveNamespacePrefix("") == "urn:default");
	}
}
