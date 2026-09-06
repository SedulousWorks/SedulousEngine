using System;

namespace Sedulous.Xml;

/// The namespaces and prefixes the specification fixes.
///
/// These are bound without being declared and cannot be rebound, which is why namespace
/// resolution falls back to them after searching the tree and finding nothing.
static class XmlNamespaces
{
	public const String Xml = "http://www.w3.org/XML/1998/namespace";
	public const String Xmlns = "http://www.w3.org/2000/xmlns/";
	public const String XmlPrefix = "xml";
	public const String XmlnsPrefix = "xmlns";
}
