using System;

namespace Sedulous.Xml;

/// How a document is formatted on the way out.
struct XmlWriteSettings
{
	public bool Indent = true;
	public StringView IndentString = "\t";
	public StringView NewLine = "\n";
	public bool OmitDeclaration = false;
	/// No indentation and no line breaks at all. Everything on one line, which is what a
	/// stored document wants and a document a person reads does not.
	public bool CompactMode = false;

	public static XmlWriteSettings Default => .();
}
