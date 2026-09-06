using System;

namespace Sedulous.Xml;

/// XML escaping, shared by node serialisation and the writer.
///
/// It lives on its own so neither of those has to depend on the other.
static
{
	/// Escapes element text content: the three characters that would otherwise start
	/// markup. A quote is data inside text, so it is left alone.
	public static void EscapeText(StringView text, String output)
	{
		for (let c in text)
		{
			switch (c)
			{
			case '&': output.Append("&amp;");
			case '<': output.Append("&lt;");
			case '>': output.Append("&gt;");
			default: output.Append(c);
			}
		}
	}

	/// Escapes an attribute value.
	///
	/// Both quote forms go, since the writer may use either delimiter, and the three
	/// whitespace characters become character references: an attribute value is subject to
	/// normalisation on the way back in, which would otherwise turn a tab or a newline
	/// into a space and lose it.
	public static void EscapeAttributeValue(StringView value, String output)
	{
		for (let c in value)
		{
			switch (c)
			{
			case '&': output.Append("&amp;");
			case '<': output.Append("&lt;");
			case '>': output.Append("&gt;");
			case '"': output.Append("&quot;");
			case '\'': output.Append("&apos;");
			case '\r': output.Append("&#xD;");
			case '\n': output.Append("&#xA;");
			case '\t': output.Append("&#x9;");
			default: output.Append(c);
			}
		}
	}
}
