using System;

namespace Sedulous.Xml;

/// <summary>
/// Well-known XML namespace constants.
/// </summary>
static class XmlNamespaces
{
	/// <summary>
	/// The XML namespace URI (http://www.w3.org/XML/1998/namespace).
	/// </summary>
	public const String Xml = "http://www.w3.org/XML/1998/namespace";

	/// <summary>
	/// The XMLNS namespace URI (http://www.w3.org/2000/xmlns/).
	/// </summary>
	public const String Xmlns = "http://www.w3.org/2000/xmlns/";

	/// <summary>
	/// The XML namespace prefix.
	/// </summary>
	public const String XmlPrefix = "xml";

	/// <summary>
	/// The XMLNS namespace prefix.
	/// </summary>
	public const String XmlnsPrefix = "xmlns";
}

/// <summary>
/// Namespace handling utilities.
/// </summary>
static class XmlNamespaceHelper
{
	/// <summary>
	/// Splits a qualified name into prefix and local parts.
	/// </summary>
	public static void SplitQualifiedName(StringView qualifiedName, String prefix, String localName)
	{
		XmlLexer.SplitQualifiedName(qualifiedName, prefix, localName);
	}

	/// <summary>
	/// Checks if a prefix is reserved (xml, xmlns).
	/// </summary>
	public static bool IsReservedPrefix(StringView prefix)
	{
		return prefix == "xml" || prefix == "xmlns";
	}

	/// <summary>
	/// Validates a namespace declaration.
	/// </summary>
	/// <param name="prefix">The prefix being declared.</param>
	/// <param name="uri">The namespace URI.</param>
	/// <returns>Ok if valid, or an error code.</returns>
	public static XmlResult ValidateNamespaceDeclaration(StringView prefix, StringView uri)
	{
		// "xml" prefix can only be bound to the XML namespace
		if (prefix == "xml")
		{
			if (uri != XmlNamespaces.Xml)
				return .PrefixReserved;
		}

		// "xmlns" prefix cannot be declared
		if (prefix == "xmlns")
			return .PrefixReserved;

		// The XML namespace can only be bound to "xml" prefix
		if (uri == XmlNamespaces.Xml && prefix != "xml")
			return .NamespaceInvalid;

		// The XMLNS namespace cannot be bound to any prefix
		if (uri == XmlNamespaces.Xmlns)
			return .NamespaceInvalid;

		return .Ok;
	}

	/// <summary>
	/// Checks if a name starts with "xml" (case-insensitive).
	/// Names starting with "xml" are reserved.
	/// </summary>
	public static bool StartsWithXml(StringView name)
	{
		if (name.Length < 3)
			return false;

		let c0 = name[0];
		let c1 = name[1];
		let c2 = name[2];

		return (c0 == 'x' || c0 == 'X') &&
			   (c1 == 'm' || c1 == 'M') &&
			   (c2 == 'l' || c2 == 'L');
	}
}
