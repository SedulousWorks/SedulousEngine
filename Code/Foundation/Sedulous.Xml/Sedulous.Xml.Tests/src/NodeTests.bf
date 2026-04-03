using System;
using System.Collections;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class NodeTests
{
	[Test]
	public static void TestElementCreation()
	{
		let elem = scope XmlElement("test");
		Test.Assert(elem.TagName == "test");
		Test.Assert(elem.LocalName == "test");
		Test.Assert(elem.Prefix.IsEmpty);
		Test.Assert(elem.NodeType == .Element);
	}

	[Test]
	public static void TestElementCreation_WithNamespace()
	{
		let elem = scope XmlElement("ns", "test", "http://example.com");
		Test.Assert(elem.TagName == "ns:test");
		Test.Assert(elem.LocalName == "test");
		Test.Assert(elem.Prefix == "ns");
		Test.Assert(elem.NamespaceUri == "http://example.com");
	}

	[Test]
	public static void TestAttributeManipulation()
	{
		let elem = scope XmlElement("test");

		// Add attributes
		elem.SetAttribute("id", "123");
		elem.SetAttribute("name", "value");

		Test.Assert(elem.AttributeCount == 2);
		Test.Assert(elem.HasAttribute("id"));
		Test.Assert(elem.HasAttribute("name"));
		Test.Assert(elem.GetAttribute("id") == "123");
		Test.Assert(elem.GetAttribute("name") == "value");

		// Update attribute
		elem.SetAttribute("id", "456");
		Test.Assert(elem.GetAttribute("id") == "456");
		Test.Assert(elem.AttributeCount == 2);

		// Remove attribute
		elem.RemoveAttribute("id");
		Test.Assert(!elem.HasAttribute("id"));
		Test.Assert(elem.AttributeCount == 1);

		// Get non-existent attribute
		Test.Assert(elem.GetAttribute("nonexistent").IsEmpty);
	}

	[Test]
	public static void TestChildManipulation()
	{
		let parent = scope XmlElement("parent");
		let child1 = new XmlElement("child1");
		let child2 = new XmlElement("child2");
		let child3 = new XmlElement("child3");

		// Append children
		parent.AppendChild(child1);
		parent.AppendChild(child2);

		Test.Assert(parent.ChildCount == 2);
		Test.Assert(parent.FirstChild == child1);
		Test.Assert(parent.LastChild == child2);
		Test.Assert(child1.NextSibling == child2);
		Test.Assert(child2.PrevSibling == child1);
		Test.Assert(child1.Parent == parent);

		// Prepend child
		parent.PrependChild(child3);
		Test.Assert(parent.FirstChild == child3);
		Test.Assert(child3.NextSibling == child1);

		// Insert before
		let child4 = new XmlElement("child4");
		parent.InsertBefore(child4, child2);
		Test.Assert(child1.NextSibling == child4);
		Test.Assert(child4.NextSibling == child2);

		// Remove child
		parent.RemoveChild(child4);
		delete child4;
		Test.Assert(child1.NextSibling == child2);
		Test.Assert(parent.ChildCount == 3);

		// Clear children
		parent.ClearChildren();
		Test.Assert(!parent.HasChildren);
		Test.Assert(parent.ChildCount == 0);
	}

	[Test]
	public static void TestTreeNavigation()
	{
		let root = scope XmlElement("root");
		let child1 = new XmlElement("child");
		let child2 = new XmlElement("child");
		let text = new XmlText("text");
		let child3 = new XmlElement("other");

		root.AppendChild(child1);
		root.AppendChild(text);
		root.AppendChild(child2);
		root.AppendChild(child3);

		// First/Last child element
		Test.Assert(root.FirstChildElement == child1);
		Test.Assert(root.LastChildElement == child3);

		// Next/Prev sibling element
		Test.Assert(child1.NextSiblingElement == child2);
		Test.Assert(child2.PrevSiblingElement == child1);
		Test.Assert(child2.NextSiblingElement == child3);

		// Get child by tag name
		let found = root.GetFirstChildElement("child");
		Test.Assert(found == child1);

		let foundOther = root.GetFirstChildElement("other");
		Test.Assert(foundOther == child3);

		let notFound = root.GetFirstChildElement("nonexistent");
		Test.Assert(notFound == null);
	}

	[Test]
	public static void TestChildEnumeration()
	{
		let parent = scope XmlElement("parent");
		parent.AppendChild(new XmlElement("child1"));
		parent.AppendChild(new XmlElement("child2"));
		parent.AppendChild(new XmlElement("child3"));

		var count = 0;
		for (let child in parent.Children)
		{
			Test.Assert(child.NodeType == .Element);
			count++;
		}
		Test.Assert(count == 3);
	}

	[Test]
	public static void TestGetChildElements()
	{
		let parent = scope XmlElement("parent");
		parent.AppendChild(new XmlElement("item"));
		parent.AppendChild(new XmlText("text"));
		parent.AppendChild(new XmlElement("item"));
		parent.AppendChild(new XmlElement("other"));

		let items = scope List<XmlElement>();
		parent.GetChildElements("item", items);
		Test.Assert(items.Count == 2);

		items.Clear();
		parent.GetChildElements("", items); // All elements
		Test.Assert(items.Count == 3);
	}

	[Test]
	public static void TestGetDescendantElements()
	{
		let root = scope XmlElement("root");
		let child1 = new XmlElement("item");
		let child2 = new XmlElement("container");
		let grandchild = new XmlElement("item");

		root.AppendChild(child1);
		root.AppendChild(child2);
		child2.AppendChild(grandchild);

		let items = scope List<XmlElement>();
		root.GetDescendantElements("item", items);
		Test.Assert(items.Count == 2);
		Test.Assert(items[0] == child1);
		Test.Assert(items[1] == grandchild);
	}

	[Test]
	public static void TestTextContent()
	{
		let elem = scope XmlElement("test");
		elem.SetTextContent("Hello World");

		Test.Assert(elem.HasChildren);
		Test.Assert(elem.ChildCount == 1);

		let text = scope String();
		elem.GetTextContent(text);
		Test.Assert(text == "Hello World");

		// Set text replaces existing content
		elem.SetTextContent("New Text");
		text.Clear();
		elem.GetTextContent(text);
		Test.Assert(text == "New Text");
		Test.Assert(elem.ChildCount == 1);
	}

	[Test]
	public static void TestTextNode()
	{
		let text = scope XmlText("Hello");
		Test.Assert(text.Text == "Hello");
		Test.Assert(!text.IsWhitespace);

		text.AppendText(" World");
		Test.Assert(text.Text == "Hello World");

		let wsText = scope XmlText("   \t\n");
		Test.Assert(wsText.IsWhitespace);
	}

	[Test]
	public static void TestCDataNode()
	{
		let cdata = scope XmlCData("<special> & content");
		Test.Assert(cdata.Data == "<special> & content");
		Test.Assert(cdata.NodeType == .CData);

		let xml = scope String();
		cdata.GetOuterXml(xml);
		Test.Assert(xml == "<![CDATA[<special> & content]]>");
	}

	[Test]
	public static void TestCommentNode()
	{
		let comment = scope XmlComment("This is a comment");
		Test.Assert(comment.Text == "This is a comment");
		Test.Assert(comment.NodeType == .Comment);

		let xml = scope String();
		comment.GetOuterXml(xml);
		Test.Assert(xml == "<!--This is a comment-->");

		// Comments don't contribute to inner text
		let innerText = scope String();
		comment.GetInnerText(innerText);
		Test.Assert(innerText.IsEmpty);
	}

	[Test]
	public static void TestDeclarationNode()
	{
		let decl = scope XmlDeclaration("1.0", "utf-8", "yes");
		Test.Assert(decl.Version == "1.0");
		Test.Assert(decl.Encoding == "utf-8");
		Test.Assert(decl.Standalone == "yes");
		Test.Assert(decl.NodeType == .Declaration);

		let xml = scope String();
		decl.GetOuterXml(xml);
		Test.Assert(xml == "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>");
	}

	[Test]
	public static void TestProcessingInstructionNode()
	{
		let pi = scope XmlProcessingInstruction("target", "data content");
		Test.Assert(pi.Target == "target");
		Test.Assert(pi.Data == "data content");
		Test.Assert(pi.NodeType == .ProcessingInstruction);

		let xml = scope String();
		pi.GetOuterXml(xml);
		Test.Assert(xml == "<?target data content?>");
	}

	[Test]
	public static void TestAttributeNode()
	{
		let attr = scope XmlAttribute("name", "value");
		Test.Assert(attr.Name == "name");
		Test.Assert(attr.Value == "value");
		Test.Assert(attr.LocalName == "name");
		Test.Assert(attr.Prefix.IsEmpty);
		Test.Assert(!attr.IsNamespaceDeclaration);

		let nsAttr = scope XmlAttribute("xmlns:ns", "http://example.com");
		nsAttr.SetName("xmlns:ns");
		nsAttr.SetValue("http://example.com");
		Test.Assert(nsAttr.IsNamespaceDeclaration);
		Test.Assert(nsAttr.DeclaredPrefix == "ns");
	}

	[Test]
	public static void TestOwnerDocument()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root><child/></root>");
		Test.Assert(result == .Ok);

		Test.Assert(doc.RootElement.OwnerDocument == doc);
		Test.Assert(doc.RootElement.FirstChild.OwnerDocument == doc);
	}

	[Test]
	public static void TestRemoveFromParent()
	{
		let parent = scope XmlElement("parent");
		let child = new XmlElement("child");
		parent.AppendChild(child);

		Test.Assert(child.Parent == parent);

		child.RemoveFromParent();
		Test.Assert(child.Parent == null);
		Test.Assert(!parent.HasChildren);

		delete child;
	}

	[Test]
	public static void TestInsertAfter()
	{
		let parent = scope XmlElement("parent");
		let child1 = new XmlElement("child1");
		let child2 = new XmlElement("child2");
		let child3 = new XmlElement("child3");

		parent.AppendChild(child1);
		parent.AppendChild(child3);

		parent.InsertAfter(child2, child1);

		Test.Assert(child1.NextSibling == child2);
		Test.Assert(child2.NextSibling == child3);
		Test.Assert(child2.PrevSibling == child1);
	}

	[Test]
	public static void TestNamespaceDeclaration()
	{
		let elem = scope XmlElement("root");
		elem.SetAttribute("xmlns", "http://default.example.com");
		elem.SetAttribute("xmlns:ns", "http://ns.example.com");

		// Check namespace resolution
		Test.Assert(elem.ResolveNamespacePrefix("") == "http://default.example.com");
		Test.Assert(elem.ResolveNamespacePrefix("ns") == "http://ns.example.com");
	}
}
