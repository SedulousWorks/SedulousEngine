using System;
using Sedulous.Xml;

namespace Sedulous.Xml.Tests;

/// Namespaces are resolved by LOOKUP rather than stamped onto nodes at parse time: a
/// prefix is looked up when asked, walking outwards, so an inner declaration shadows an
/// outer one without either having to know.
class NamespaceTests
{
	[Test]
	public static void DefaultNamespace()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root xmlns=\"urn:default\"><child/></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("") == "urn:default");
		Test.Assert(root.FirstChildElement.ResolveNamespacePrefix("") == "urn:default", "inherited");
	}

	[Test]
	public static void PrefixedNamespace()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root xmlns:a=\"urn:a\" xmlns:b=\"urn:b\"><a:x/></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("a") == "urn:a");
		Test.Assert(root.ResolveNamespacePrefix("b") == "urn:b");
		Test.Assert(root.ResolveNamespacePrefix("c") == "", "nothing binds it");

		let child = root.FirstChildElement;
		Test.Assert(child.Prefix == "a");
		Test.Assert(child.LocalName == "x");
	}

	[Test]
	public static void Inheritance()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<a xmlns:p=\"urn:p\"><b><c/></b></a>") == .Ok);

		let c = document.RootElement.FirstChildElement.FirstChildElement;
		Test.Assert(c.TagName == "c");
		Test.Assert(c.ResolveNamespacePrefix("p") == "urn:p", "found several levels up");
	}

	/// An inner declaration shadows an outer one for its subtree, and only for its subtree.
	[Test]
	public static void Override()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<a xmlns:p=\"urn:outer\"><b xmlns:p=\"urn:inner\"><c/></b><d/></a>") == .Ok);

		let a = document.RootElement;
		let b = a.FirstChildElement;
		let c = b.FirstChildElement;
		let d = b.NextSiblingElement;

		Test.Assert(a.ResolveNamespacePrefix("p") == "urn:outer");
		Test.Assert(b.ResolveNamespacePrefix("p") == "urn:inner");
		Test.Assert(c.ResolveNamespacePrefix("p") == "urn:inner", "the inner one reaches its children");
		Test.Assert(d.ResolveNamespacePrefix("p") == "urn:outer", "and not its siblings");
	}

	/// Two prefixes are bound by the specification rather than declared, so they resolve
	/// even in a document that says nothing about them.
	[Test]
	public static void ReservedPrefixes()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root/>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("xml") == XmlNamespaces.Xml);
		Test.Assert(root.ResolveNamespacePrefix("xmlns") == XmlNamespaces.Xmlns);
	}

	[Test]
	public static void IsNamespaceDeclaration()
	{
		let plain = scope XmlAttribute("name", "value");
		Test.Assert(!plain.IsNamespaceDeclaration);
		Test.Assert(plain.DeclaredNamespaceUri == "");

		let defaultDeclaration = scope XmlAttribute("xmlns", "urn:d");
		Test.Assert(defaultDeclaration.IsNamespaceDeclaration);
		Test.Assert(defaultDeclaration.DeclaredPrefix == "", "the default binds no prefix");
		Test.Assert(defaultDeclaration.DeclaredNamespaceUri == "urn:d");

		let prefixed = scope XmlAttribute("xmlns:a", "urn:a");
		Test.Assert(prefixed.IsNamespaceDeclaration);
		Test.Assert(prefixed.DeclaredPrefix == "a");
		Test.Assert(prefixed.DeclaredNamespaceUri == "urn:a");
	}

	[Test]
	public static void HelperRules()
	{
		Test.Assert(XmlNamespaceHelper.IsReservedPrefix("xml"));
		Test.Assert(XmlNamespaceHelper.IsReservedPrefix("xmlns"));
		Test.Assert(!XmlNamespaceHelper.IsReservedPrefix("a"));

		// Each of the reserved names is bound to the other, and to nothing else.
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xml", XmlNamespaces.Xml) == .Ok);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xml", "urn:other") == .PrefixReserved);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("xmlns", "anything") == .PrefixReserved);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("p", XmlNamespaces.Xml) == .NamespaceInvalid);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("p", XmlNamespaces.Xmlns) == .NamespaceInvalid);
		Test.Assert(XmlNamespaceHelper.ValidateNamespaceDeclaration("p", "urn:p") == .Ok);

		// Any casing of "xml" is reserved.
		Test.Assert(XmlNamespaceHelper.StartsWithXml("xmlFoo"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("XML"));
		Test.Assert(XmlNamespaceHelper.StartsWithXml("XmL"));
		Test.Assert(!XmlNamespaceHelper.StartsWithXml("xm"));
		Test.Assert(!XmlNamespaceHelper.StartsWithXml("axml"));

		let prefix = scope String();
		let localName = scope String();
		XmlNamespaceHelper.SplitQualifiedName("a:b", prefix, localName);
		Test.Assert((prefix == "a") && (localName == "b"));
	}

	[Test]
	public static void Constants()
	{
		Test.Assert(XmlNamespaces.Xml == "http://www.w3.org/XML/1998/namespace");
		Test.Assert(XmlNamespaces.Xmlns == "http://www.w3.org/2000/xmlns/");
		Test.Assert(XmlNamespaces.XmlPrefix == "xml");
		Test.Assert(XmlNamespaces.XmlnsPrefix == "xmlns");
	}

	/// The reverse lookup: which prefix is bound to a URI.
	[Test]
	public static void ResolveNamespaceUri()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root xmlns:a=\"urn:a\"><child/></root>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespaceUri("urn:a") == "a");
		Test.Assert(root.ResolveNamespaceUri("urn:missing") == "");
		Test.Assert(root.FirstChildElement.ResolveNamespaceUri("urn:a") == "a", "walks up too");

		Test.Assert(root.ResolveNamespaceUri(XmlNamespaces.Xml) == "xml");
		Test.Assert(root.ResolveNamespaceUri(XmlNamespaces.Xmlns) == "xmlns");
	}

	[Test]
	public static void MultipleNamespacesOnOneElement()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root xmlns=\"urn:d\" xmlns:a=\"urn:a\" xmlns:b=\"urn:b\"/>") == .Ok);

		let root = document.RootElement;
		Test.Assert(root.ResolveNamespacePrefix("") == "urn:d");
		Test.Assert(root.ResolveNamespacePrefix("a") == "urn:a");
		Test.Assert(root.ResolveNamespacePrefix("b") == "urn:b");
		Test.Assert(root.AttributeCount == 3, "the declarations are attributes as well");
	}

	/// A tree built in code binds namespaces the same way a parsed one does.
	[Test]
	public static void ProgrammaticNamespace()
	{
		let root = scope XmlElement("root");
		root.DeclareNamespace("p", "urn:p");
		Test.Assert(root.ResolveNamespacePrefix("p") == "urn:p");

		// Redeclaring the same prefix replaces the binding.
		root.DeclareNamespace("p", "urn:other");
		Test.Assert(root.ResolveNamespacePrefix("p") == "urn:other");

		let child = new XmlElement("child");
		root.AppendChild(child);
		Test.Assert(child.ResolveNamespacePrefix("p") == "urn:other");
	}
}
