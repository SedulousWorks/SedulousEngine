using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

class NamespaceTests
{
	[Test]
	public static void TestDefaultNamespace()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root xmlns=\"http://example.com\"/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement.HasAttribute("xmlns"));
		Test.Assert(doc.RootElement.GetAttribute("xmlns") == "http://example.com");

		// Default namespace declaration
		Test.Assert(doc.RootElement.ResolveNamespacePrefix("") == "http://example.com");
	}

	[Test]
	public static void TestPrefixedNamespace()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<ns:root xmlns:ns=\"http://example.com\"/>");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootElement.TagName == "ns:root");
		Test.Assert(doc.RootElement.Prefix == "ns");
		Test.Assert(doc.RootElement.LocalName == "root");

		// Prefixed namespace resolution
		Test.Assert(doc.RootElement.ResolveNamespacePrefix("ns") == "http://example.com");
	}

	[Test]
	public static void TestNamespaceInheritance()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("""
			<root xmlns:ns="http://example.com">
				<ns:child/>
			</root>
			""");

		Test.Assert(result == .Ok);

		let child = doc.RootElement.FirstChildElement;
		Test.Assert(child != null);
		Test.Assert(child.TagName == "ns:child");

		// Child should inherit namespace from parent
		Test.Assert(child.ResolveNamespacePrefix("ns") == "http://example.com");
	}

	[Test]
	public static void TestNamespaceOverride()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("""
			<root xmlns:ns="http://outer.com">
				<child xmlns:ns="http://inner.com">
					<ns:leaf/>
				</child>
			</root>
			""");

		Test.Assert(result == .Ok);

		let child = doc.RootElement.FirstChildElement;
		Test.Assert(child != null);

		// Child has overridden namespace
		Test.Assert(child.ResolveNamespacePrefix("ns") == "http://inner.com");

		// Root still has original namespace
		Test.Assert(doc.RootElement.ResolveNamespacePrefix("ns") == "http://outer.com");
	}

	[Test]
	public static void TestReservedPrefixes()
	{
		// "xml" prefix is always bound to the XML namespace
		let elem = scope XmlElement("test");
		Test.Assert(elem.ResolveNamespacePrefix("xml") == XmlNamespaces.Xml);
		Test.Assert(elem.ResolveNamespacePrefix("xmlns") == XmlNamespaces.Xmlns);
	}

	[Test]
	public static void TestAttributeNamespaces()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("<root xmlns:ns=\"http://example.com\" ns:attr=\"value\"/>");

		Test.Assert(result == .Ok);

		let attr = doc.RootElement.GetAttributeNode("ns:attr");
		Test.Assert(attr != null);
		Test.Assert(attr.Prefix == "ns");
		Test.Assert(attr.LocalName == "attr");
	}

	[Test]
	public static void TestIsNamespaceDeclaration()
	{
		let xmlnsAttr = scope XmlAttribute("xmlns", "http://default.com");
		Test.Assert(xmlnsAttr.IsNamespaceDeclaration);
		Test.Assert(xmlnsAttr.DeclaredPrefix.IsEmpty);
		Test.Assert(xmlnsAttr.DeclaredNamespaceUri == "http://default.com");

		let prefixedAttr = scope XmlAttribute("xmlns:ns", "http://ns.com");
		prefixedAttr.SetName("xmlns:ns");
		prefixedAttr.SetValue("http://ns.com");
		Test.Assert(prefixedAttr.IsNamespaceDeclaration);
		Test.Assert(prefixedAttr.DeclaredPrefix == "ns");
		Test.Assert(prefixedAttr.DeclaredNamespaceUri == "http://ns.com");

		let normalAttr = scope XmlAttribute("id", "123");
		Test.Assert(!normalAttr.IsNamespaceDeclaration);
	}

	[Test]
	public static void TestIsReservedPrefix()
	{
		Test.Assert(XmlNamespaceHelper.IsReservedPrefix("xml"));
		Test.Assert(XmlNamespaceHelper.IsReservedPrefix("xmlns"));
		Test.Assert(!XmlNamespaceHelper.IsReservedPrefix("myprefix"));
		Test.Assert(!XmlNamespaceHelper.IsReservedPrefix(""));
	}

	[Test]
	public static void TestValidateNamespaceDeclaration()
	{
		// Normal declarations are OK
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("ns", "http://example.com") == .Ok);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("", "http://default.com") == .Ok);

		// "xmlns" prefix cannot be declared
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xmlns", "http://example.com") == .PrefixReserved);

		// "xml" can only be bound to XML namespace
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xml", "http://other.com") == .PrefixReserved);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xml", XmlNamespaces.Xml) == .Ok);

		// XML namespace can only be bound to "xml" prefix
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("other", XmlNamespaces.Xml) == .NamespaceInvalid);

		// XMLNS namespace cannot be bound
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("ns", XmlNamespaces.Xmlns) == .NamespaceInvalid);
	}

	[Test]
	public static void TestSplitQualifiedName()
	{
		let prefix = scope String();
		let localName = scope String();

		XmlNamespaceHelper.SplitQualifiedName("element", prefix, localName);
		Test.Assert(prefix.IsEmpty);
		Test.Assert(localName == "element");

		prefix.Clear();
		localName.Clear();
		XmlNamespaceHelper.SplitQualifiedName("ns:element", prefix, localName);
		Test.Assert(prefix == "ns");
		Test.Assert(localName == "element");
	}

	[Test]
	public static void TestStartsWithXml()
	{
		Test.Assert(XmlNamespaceHelper.StartsWithXml("xml"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("XML"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("Xml"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("xmlfoo"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("XMLbar"));

		Test.Assert(!XmlNamespaceHelper.StartsWithXml("xm"));
		Test.Assert(!XmlNamespaceHelper.StartsWithXml("foo"));
		Test.Assert(!XmlNamespaceHelper.StartsWithXml(""));
	}

	[Test]
	public static void TestXmlNamespaceConstants()
	{
		Test.Assert(XmlNamespaces.Xml == "http://www.w3.org/XML/1998/namespace");
		Test.Assert(XmlNamespaces.Xmlns == "http://www.w3.org/2000/xmlns/");
		Test.Assert(XmlNamespaces.XmlPrefix == "xml");
		Test.Assert(XmlNamespaces.XmlnsPrefix == "xmlns");
	}

	[Test]
	public static void TestResolveNamespaceUri()
	{
		let elem = scope XmlElement("test");
		elem.DeclareNamespace("ns", "http://example.com");

		Test.Assert(elem.ResolveNamespaceUri("http://example.com") == "ns");
		Test.Assert(elem.ResolveNamespaceUri("http://other.com").IsEmpty);

		// Built-in namespaces
		Test.Assert(elem.ResolveNamespaceUri(XmlNamespaces.Xml) == "xml");
		Test.Assert(elem.ResolveNamespaceUri(XmlNamespaces.Xmlns) == "xmlns");
	}

	[Test]
	public static void TestMultipleNamespaces()
	{
		let doc = scope XmlDocument();
		let result = doc.Parse("""
			<root xmlns="http://default.com" xmlns:a="http://a.com" xmlns:b="http://b.com">
				<a:element/>
				<b:element/>
			</root>
			""");

		Test.Assert(result == .Ok);

		let root = doc.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("") == "http://default.com");
		Test.Assert(root.ResolveNamespacePrefix("a") == "http://a.com");
		Test.Assert(root.ResolveNamespacePrefix("b") == "http://b.com");
	}

	[Test]
	public static void TestProgrammaticNamespace()
	{
		let doc = scope XmlDocument();
		let root = doc.CreateElement("ns", "root", "http://example.com");
		root.SetAttribute("xmlns:ns", "http://example.com");
		doc.AppendChild(root);

		Test.Assert(root.TagName == "ns:root");
		Test.Assert(root.Prefix == "ns");
		Test.Assert(root.LocalName == "root");
		Test.Assert(root.NamespaceUri == "http://example.com");
	}
}
