using System;

namespace Sedulous.Xml;

/// The rules the specification fixes about prefixes and namespace declarations.
static class XmlNamespaceHelper
{
	public static void SplitQualifiedName(StringView qualifiedName, String prefix, String localName)
	{
		XmlLexer.SplitQualifiedName(qualifiedName, prefix, localName);
	}

	/// The two prefixes nobody may redefine.
	public static bool IsReservedPrefix(StringView prefix)
	{
		return (prefix == XmlNamespaces.XmlPrefix) || (prefix == XmlNamespaces.XmlnsPrefix);
	}

	/// Whether a declaration is one the specification permits.
	///
	/// The prefix and the URI are each reserved to the other: xml binds only to the XML
	/// namespace and that namespace binds only to xml, xmlns cannot be declared at all,
	/// and the XMLNS namespace binds to nothing.
	public static XmlResult ValidateNamespaceDeclaration(StringView prefix, StringView uri)
	{
		if ((prefix == XmlNamespaces.XmlPrefix) && (uri != XmlNamespaces.Xml))
			return .PrefixReserved;
		if (prefix == XmlNamespaces.XmlnsPrefix)
			return .PrefixReserved;
		if ((uri == XmlNamespaces.Xml) && (prefix != XmlNamespaces.XmlPrefix))
			return .NamespaceInvalid;
		if (uri == XmlNamespaces.Xmlns)
			return .NamespaceInvalid;
		return .Ok;
	}

	/// Names beginning with "xml" in any case are reserved by the specification, so a
	/// document should not invent one.
	public static bool StartsWithXml(StringView name)
	{
		if (name.Length < 3)
			return false;

		let c0 = name[0];
		let c1 = name[1];
		let c2 = name[2];
		return ((c0 == 'x') || (c0 == 'X'))
			&& ((c1 == 'm') || (c1 == 'M'))
			&& ((c2 == 'l') || (c2 == 'L'));
	}
}
