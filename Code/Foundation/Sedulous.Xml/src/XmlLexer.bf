using System;
using System.Collections;

namespace Sedulous.Xml;

/// <summary>
/// Low-level lexer/tokenization utilities for parsing XML text.
/// </summary>
static class XmlLexer
{
	/// <summary>
	/// Character classification for XML name start characters.
	/// 0 = invalid, 1 = valid name start char (letter, underscore, colon)
	/// </summary>
	private static readonly uint8[256] sNameStartCharState = .(
		// 0x00-0x0F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x10-0x1F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x20-0x2F: space ! " # $ % & ' ( ) * + , - . /
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x30-0x3F: 0-9 : ; < = > ?
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, // colon at 0x3A is valid start
		// 0x40-0x4F: @ A-O
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x50-0x5F: P-Z [ \ ] ^ _
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
		// 0x60-0x6F: ` a-o
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x70-0x7F: p-z { | } ~
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
		// 0x80-0xFF: extended ASCII (valid for UTF-8 continuation)
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	);

	/// <summary>
	/// Character classification for XML name continuation characters.
	/// 0 = invalid, 1 = valid name char (letter, digit, underscore, colon, hyphen, dot)
	/// </summary>
	private static readonly uint8[256] sNameCharState = .(
		// 0x00-0x0F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x10-0x1F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x20-0x2F: space ! " # $ % & ' ( ) * + , - . /
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, // hyphen and dot are valid
		// 0x30-0x3F: 0-9 : ; < = > ?
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, // digits and colon are valid
		// 0x40-0x4F: @ A-O
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x50-0x5F: P-Z [ \ ] ^ _
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
		// 0x60-0x6F: ` a-o
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x70-0x7F: p-z { | } ~
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
		// 0x80-0xFF: extended ASCII (valid for UTF-8 continuation)
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	);

	/// <summary>
	/// Returns the number of whitespace characters at the beginning of a text string.
	/// XML whitespace is: space (0x20), tab (0x09), carriage return (0x0D), line feed (0x0A).
	/// </summary>
	public static int GetWhitespaceLength(StringView text)
	{
		int index = 0;
		int length = text.Length;

		while (index < length)
		{
			let c = text[index];
			if (c == ' ' || c == '\t' || c == '\r' || c == '\n')
				index++;
			else
				break;
		}

		return index;
	}

	/// <summary>
	/// Checks if a character is XML whitespace.
	/// </summary>
	public static bool IsWhitespace(char8 c)
	{
		return c == ' ' || c == '\t' || c == '\r' || c == '\n';
	}

	/// <summary>
	/// Checks if a character is a valid XML name start character.
	/// </summary>
	public static bool IsNameStartChar(char8 c)
	{
		return sNameStartCharState[(uint8)c] != 0;
	}

	/// <summary>
	/// Checks if a character is a valid XML name continuation character.
	/// </summary>
	public static bool IsNameChar(char8 c)
	{
		return sNameCharState[(uint8)c] != 0;
	}

	/// <summary>
	/// Checks if a character is a hex digit.
	/// </summary>
	public static bool IsHexDigit(char8 c)
	{
		return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
	}

	/// <summary>
	/// Converts a hex digit to its numeric value.
	/// </summary>
	public static int HexDigitValue(char8 c)
	{
		if (c >= '0' && c <= '9') return c - '0';
		if (c >= 'A' && c <= 'F') return c - 'A' + 10;
		if (c >= 'a' && c <= 'f') return c - 'a' + 10;
		return -1;
	}

	/// <summary>
	/// Reads an XML name from a text string.
	/// An XML name is: NameStartChar (NameChar)*
	/// </summary>
	/// <param name="text">The text to read from.</param>
	/// <param name="length">Receives the length of the name.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadName(StringView text, out int length)
	{
		length = 0;

		if (text.IsEmpty)
			return .NameEmpty;

		let firstChar = text[0];
		if (!IsNameStartChar(firstChar))
			return .NameEmpty;

		int index = 1;
		while (index < text.Length)
		{
			let c = text[index];
			if (!IsNameChar(c))
				break;
			index++;
		}

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads an XML name and copies it to the output string.
	/// </summary>
	public static XmlResult ReadName(StringView text, out int length, String output)
	{
		let result = ReadName(text, out length);
		if (result == .Ok)
		{
			output.Clear();
			output.Append(text.Substring(0, length));
		}
		return result;
	}

	/// <summary>
	/// Reads a quoted attribute value (handles both ' and ").
	/// Decodes entity references and character references.
	/// </summary>
	/// <param name="text">The text to read from (should start with quote).</param>
	/// <param name="length">Receives the total length consumed (including quotes).</param>
	/// <param name="output">Receives the decoded value.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadAttributeValue(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		if (text.IsEmpty)
			return .AttributeMissingQuote;

		let quote = text[0];
		if (quote != '"' && quote != '\'')
			return .AttributeMissingQuote;

		var index = 1;

		while (index < text.Length)
		{
			let c = text[index];

			if (c == quote)
			{
				// End of attribute value
				length = index + 1;
				return .Ok;
			}

			if (c == '<')
			{
				// < is not allowed in attribute values
				return .AttributeValueInvalid;
			}

			if (c == '&')
			{
				// Entity or character reference
				let remaining = text.Substring(index);
				let refResult = DecodeReference(remaining, var refLen, output);
				if (refResult != .Ok)
					return refResult;
				index += refLen;
			}
			else
			{
				output.Append(c);
				index++;
			}
		}

		// Unclosed attribute value
		return .AttributeMissingQuote;
	}

	/// <summary>
	/// Reads text content until a terminator is found.
	/// Decodes entity references and character references.
	/// </summary>
	/// <param name="text">The text to read from.</param>
	/// <param name="length">Receives the length consumed.</param>
	/// <param name="output">Receives the decoded text.</param>
	/// <param name="stopChars">Characters that stop parsing (typically "<").</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadTextContent(StringView text, out int length, String output, StringView stopChars = "<")
	{
		length = 0;
		output.Clear();

		var index = 0;

		while (index < text.Length)
		{
			let c = text[index];

			// Check for stop characters
			bool shouldStop = false;
			for (let sc in stopChars)
			{
				if (c == sc)
				{
					shouldStop = true;
					break;
				}
			}
			if (shouldStop)
				break;

			if (c == '&')
			{
				// Entity or character reference
				let remaining = text.Substring(index);
				let refResult = DecodeReference(remaining, var refLen, output);
				if (refResult != .Ok)
					return refResult;
				index += refLen;
			}
			else
			{
				output.Append(c);
				index++;
			}
		}

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Decodes an entity reference or character reference.
	/// </summary>
	/// <param name="text">The text starting with '&'.</param>
	/// <param name="length">Receives the length of the reference including '&' and ';'.</param>
	/// <param name="output">The string to append the decoded character(s) to.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult DecodeReference(StringView text, out int length, String output)
	{
		length = 0;

		if (text.IsEmpty || text[0] != '&')
			return .EntityMalformed;

		// Character reference: &#xNNN; or &#NNN;
		if (text.Length > 2 && text[1] == '#')
		{
			return DecodeCharacterReference(text, out length, output);
		}

		// Entity reference: &name;
		return DecodeEntityReference(text, out length, output);
	}

	/// <summary>
	/// Decodes a character reference (&#xNNN; or &#NNN;).
	/// </summary>
	private static XmlResult DecodeCharacterReference(StringView text, out int length, String output)
	{
		length = 0;

		if (text.Length < 4 || text[0] != '&' || text[1] != '#')
			return .CharRefInvalid;

		var index = 2;
		uint32 codepoint = 0;
		bool isHex = false;

		if (text[index] == 'x' || text[index] == 'X')
		{
			isHex = true;
			index++;
		}

		if (index >= text.Length)
			return .CharRefInvalid;

		var hasDigits = false;

		while (index < text.Length)
		{
			let c = text[index];

			if (c == ';')
			{
				if (!hasDigits)
					return .CharRefInvalid;

				// Validate codepoint
				if (codepoint == 0 || codepoint > 0x10FFFF)
					return .CharRefOutOfRange;

				// Check for invalid XML characters
				if (!IsValidXmlChar((char32)codepoint))
					return .CharRefOutOfRange;

				output.Append((char32)codepoint);
				length = index + 1;
				return .Ok;
			}

			if (isHex)
			{
				if (!IsHexDigit(c))
					return .CharRefInvalid;
				let digit = (uint32)HexDigitValue(c);
				if (codepoint > (0x10FFFF - digit) / 16)
					return .CharRefOutOfRange;
				codepoint = codepoint * 16 + digit;
			}
			else
			{
				if (c < '0' || c > '9')
					return .CharRefInvalid;
				let digit = (uint32)(c - '0');
				if (codepoint > (0x10FFFF - digit) / 10)
					return .CharRefOutOfRange;
				codepoint = codepoint * 10 + digit;
			}

			hasDigits = true;
			index++;
		}

		return .CharRefInvalid; // Missing semicolon
	}

	/// <summary>
	/// Decodes an entity reference (&name;).
	/// </summary>
	private static XmlResult DecodeEntityReference(StringView text, out int length, String output)
	{
		length = 0;

		if (text.IsEmpty || text[0] != '&')
			return .EntityMalformed;

		var index = 1;

		// Read entity name
		let nameStart = index;
		while (index < text.Length && text[index] != ';')
		{
			let c = text[index];
			if (index == nameStart)
			{
				if (!IsNameStartChar(c))
					return .EntityMalformed;
			}
			else
			{
				if (!IsNameChar(c))
					return .EntityMalformed;
			}
			index++;
		}

		if (index >= text.Length || text[index] != ';')
			return .EntityMalformed;

		let name = text.Substring(nameStart, index - nameStart);
		length = index + 1;

		// Built-in entities
		if (name == "amp")
		{
			output.Append('&');
			return .Ok;
		}
		if (name == "lt")
		{
			output.Append('<');
			return .Ok;
		}
		if (name == "gt")
		{
			output.Append('>');
			return .Ok;
		}
		if (name == "apos")
		{
			output.Append('\'');
			return .Ok;
		}
		if (name == "quot")
		{
			output.Append('"');
			return .Ok;
		}

		return .EntityUnknown;
	}

	/// <summary>
	/// Reads a CDATA section content (after "<![CDATA[").
	/// </summary>
	/// <param name="text">The text after the opening "<![CDATA[".</param>
	/// <param name="length">Receives the length of the content including "]]>".</param>
	/// <param name="output">Receives the CDATA content.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadCDataContent(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		var index = 0;

		while (index < text.Length)
		{
			// Check for closing sequence "]]>"
			if (index + 2 < text.Length &&
				text[index] == ']' &&
				text[index + 1] == ']' &&
				text[index + 2] == '>')
			{
				length = index + 3;
				return .Ok;
			}

			output.Append(text[index]);
			index++;
		}

		return .CDataUnclosed;
	}

	/// <summary>
	/// Reads a comment content (after "<!--").
	/// </summary>
	/// <param name="text">The text after the opening "<!--".</param>
	/// <param name="length">Receives the length of the content including "-->".</param>
	/// <param name="output">Receives the comment text.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadCommentContent(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		var index = 0;

		while (index < text.Length)
		{
			// Check for closing sequence "-->"
			if (index + 2 < text.Length &&
				text[index] == '-' &&
				text[index + 1] == '-')
			{
				if (text[index + 2] == '>')
				{
					length = index + 3;
					return .Ok;
				}
				else
				{
					// "--" not followed by ">" is illegal in comments
					return .CommentIllegalSequence;
				}
			}

			output.Append(text[index]);
			index++;
		}

		return .CommentUnclosed;
	}

	/// <summary>
	/// Reads a processing instruction (after "<?").
	/// </summary>
	/// <param name="text">The text after "<?", should start with target name.</param>
	/// <param name="length">Receives the length consumed including "?>".</param>
	/// <param name="target">Receives the PI target name.</param>
	/// <param name="data">Receives the PI data content.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static XmlResult ReadProcessingInstruction(StringView text, out int length, String target, String data)
	{
		length = 0;
		target.Clear();
		data.Clear();

		// Read target name
		let nameResult = ReadName(text, var nameLen, target);
		if (nameResult != .Ok)
			return .PIInvalid;

		var index = nameLen;

		// Skip whitespace
		while (index < text.Length && IsWhitespace(text[index]))
			index++;

		// Check for immediate close "?>"
		if (index + 1 < text.Length && text[index] == '?' && text[index + 1] == '>')
		{
			length = index + 2;
			return .Ok;
		}

		// Read data until "?>"
		while (index < text.Length)
		{
			if (index + 1 < text.Length && text[index] == '?' && text[index + 1] == '>')
			{
				length = index + 2;
				return .Ok;
			}

			data.Append(text[index]);
			index++;
		}

		return .PIUnclosed;
	}

	/// <summary>
	/// Checks if a codepoint is a valid XML character.
	/// </summary>
	public static bool IsValidXmlChar(char32 c)
	{
		let code = (uint32)c;
		// XML 1.0 valid characters:
		// #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
		return code == 0x09 ||
			   code == 0x0A ||
			   code == 0x0D ||
			   (code >= 0x20 && code <= 0xD7FF) ||
			   (code >= 0xE000 && code <= 0xFFFD) ||
			   (code >= 0x10000 && code <= 0x10FFFF);
	}

	/// <summary>
	/// Checks if a name is a valid XML name.
	/// </summary>
	public static bool IsValidName(StringView name)
	{
		if (name.IsEmpty)
			return false;

		if (!IsNameStartChar(name[0]))
			return false;

		for (var i = 1; i < name.Length; i++)
		{
			if (!IsNameChar(name[i]))
				return false;
		}

		return true;
	}

	/// <summary>
	/// Splits a qualified name into prefix and local name.
	/// </summary>
	/// <param name="qualifiedName">The name to split (e.g., "ns:element").</param>
	/// <param name="prefix">Receives the prefix (empty if none).</param>
	/// <param name="localName">Receives the local name.</param>
	public static void SplitQualifiedName(StringView qualifiedName, String prefix, String localName)
	{
		prefix.Clear();
		localName.Clear();

		let colonIndex = qualifiedName.IndexOf(':');
		if (colonIndex >= 0)
		{
			prefix.Append(qualifiedName.Substring(0, colonIndex));
			localName.Append(qualifiedName.Substring(colonIndex + 1));
		}
		else
		{
			localName.Append(qualifiedName);
		}
	}
}
