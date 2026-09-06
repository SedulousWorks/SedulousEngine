using System;

namespace Sedulous.Xml;

/// The scanning primitives the parser is built from.
///
/// Every one of these takes a view and reports how much it consumed, so the parser holds
/// the position and the lexer holds no state at all.
static class XmlLexer
{
	/// XML whitespace, which is these four characters and nothing else. Notably not the
	/// same set as a general "is space" test.
	public static bool IsWhitespace(char8 c) => (c == ' ') || (c == '\t') || (c == '\r') || (c == '\n');

	public static int GetWhitespaceLength(StringView text)
	{
		var index = 0;
		while ((index < text.Length) && IsWhitespace(text[index]))
			index++;
		return index;
	}

	/// What a name may START with: a letter, an underscore, or a colon, plus every byte
	/// above ASCII.
	///
	/// Raptor keeps 256-byte lookup tables for these. The predicate form says the rule
	/// rather than encoding it, and a test walks all 256 values to prove the two agree.
	/// Bytes above 0x7F are accepted wholesale because a UTF-8 lead or continuation byte
	/// belongs to a character this byte-wise scan does not decode, and the alternative is
	/// rejecting every non-ASCII name.
	public static bool IsNameStartChar(char8 c)
	{
		let b = (uint8)c;
		return (c == ':') || (c == '_')
			|| ((c >= 'A') && (c <= 'Z'))
			|| ((c >= 'a') && (c <= 'z'))
			|| (b >= 0x80);
	}

	/// What a name may CONTINUE with: the above, plus digits, hyphen and dot.
	public static bool IsNameChar(char8 c)
	{
		return IsNameStartChar(c) || ((c >= '0') && (c <= '9')) || (c == '-') || (c == '.');
	}

	public static bool IsHexDigit(char8 c)
	{
		return ((c >= '0') && (c <= '9')) || ((c >= 'A') && (c <= 'F')) || ((c >= 'a') && (c <= 'f'));
	}

	/// The value of a hex digit, or -1 when it is not one.
	public static int HexDigitValue(char8 c)
	{
		if ((c >= '0') && (c <= '9'))
			return (int)(c - '0');
		if ((c >= 'A') && (c <= 'F'))
			return (int)(c - 'A') + 10;
		if ((c >= 'a') && (c <= 'f'))
			return (int)(c - 'a') + 10;
		return -1;
	}

	/// XML 1.0's valid character ranges. The gaps are the surrogate range and the two
	/// noncharacters at the end of the BMP, which are not permitted even by reference.
	public static bool IsValidXmlChar(uint32 code)
	{
		return (code == 0x09) || (code == 0x0A) || (code == 0x0D)
			|| ((code >= 0x20) && (code <= 0xD7FF))
			|| ((code >= 0xE000) && (code <= 0xFFFD))
			|| ((code >= 0x10000) && (code <= 0x10FFFF));
	}

	public static bool IsValidName(StringView name)
	{
		if (name.IsEmpty)
			return false;
		if (!IsNameStartChar(name[0]))
			return false;
		for (int i = 1; i < name.Length; i++)
		{
			if (!IsNameChar(name[i]))
				return false;
		}
		return true;
	}

	/// Splits "prefix:local". With no colon the whole thing is the local name and the
	/// prefix is empty, which is what an unprefixed name means.
	public static void SplitQualifiedName(StringView qualifiedName, String prefix, String localName)
	{
		prefix.Clear();
		localName.Clear();

		let colon = qualifiedName.IndexOf(':');
		if (colon < 0)
		{
			localName.Append(qualifiedName);
			return;
		}
		prefix.Append(StringView(qualifiedName, 0, colon));
		localName.Append(StringView(qualifiedName, colon + 1));
	}

	// ---- readers ----

	/// Reads a name: one start character then any number of name characters.
	public static XmlResult ReadName(StringView text, out int length)
	{
		length = 0;
		if (text.IsEmpty || !IsNameStartChar(text[0]))
			return .NameEmpty;

		var index = 1;
		while ((index < text.Length) && IsNameChar(text[index]))
			index++;
		length = index;
		return .Ok;
	}

	public static XmlResult ReadName(StringView text, out int length, String output)
	{
		let result = ReadName(text, out length);
		if (result == .Ok)
		{
			output.Clear();
			output.Append(StringView(text, 0, length));
		}
		return result;
	}

	/// Reads a quoted attribute value, decoding references as it goes. The length covers
	/// both quotes; the output holds the decoded value.
	public static XmlResult ReadAttributeValue(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();
		if (text.IsEmpty)
			return .AttributeMissingQuote;

		let quote = text[0];
		if ((quote != '"') && (quote != '\''))
			return .AttributeMissingQuote;

		var index = 1;
		while (index < text.Length)
		{
			let c = text[index];
			if (c == quote)
			{
				length = index + 1;
				return .Ok;
			}
			// A raw '<' in an attribute value is always an error: it would be markup.
			if (c == '<')
				return .AttributeValueInvalid;

			if (c == '&')
			{
				let result = DecodeReference(Rest(text, index), let referenceLength, output);
				if (result != .Ok)
					return result;
				index += referenceLength;
				continue;
			}

			output.Append(c);
			index++;
		}
		return .AttributeMissingQuote;
	}

	/// Reads text content up to any of the stop characters, decoding references.
	public static XmlResult ReadTextContent(StringView text, out int length, String output, StringView stopChars = "<")
	{
		length = 0;
		output.Clear();

		var index = 0;
		while (index < text.Length)
		{
			let c = text[index];
			if (stopChars.Contains(c))
				break;

			if (c == '&')
			{
				let result = DecodeReference(Rest(text, index), let referenceLength, output);
				if (result != .Ok)
					return result;
				index += referenceLength;
				continue;
			}

			output.Append(c);
			index++;
		}
		length = index;
		return .Ok;
	}

	/// Decodes one reference, which the text must start with.
	public static XmlResult DecodeReference(StringView text, out int length, String output)
	{
		length = 0;
		if (text.IsEmpty || (text[0] != '&'))
			return .EntityMalformed;

		if ((text.Length > 2) && (text[1] == '#'))
			return DecodeCharacterReference(text, out length, output);
		return DecodeEntityReference(text, out length, output);
	}

	/// Reads a CDATA body, given the text AFTER the opening, consuming through "]]>".
	public static XmlResult ReadCDataContent(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		var index = 0;
		while (index < text.Length)
		{
			if ((index + 2 < text.Length) && (text[index] == ']') && (text[index + 1] == ']') && (text[index + 2] == '>'))
			{
				length = index + 3;
				return .Ok;
			}
			output.Append(text[index]);
			index++;
		}
		return .CDataUnclosed;
	}

	/// Reads a comment body, given the text AFTER the opening, consuming through "-->".
	///
	/// A "--" that is not the close is an error rather than content: XML forbids it inside
	/// a comment outright.
	public static XmlResult ReadCommentContent(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		var index = 0;
		while (index < text.Length)
		{
			if ((index + 2 < text.Length) && (text[index] == '-') && (text[index + 1] == '-'))
			{
				if (text[index + 2] == '>')
				{
					length = index + 3;
					return .Ok;
				}
				return .CommentIllegalSequence;
			}
			output.Append(text[index]);
			index++;
		}
		return .CommentUnclosed;
	}

	/// Reads a processing instruction, given the text AFTER the "<?", through "?>".
	public static XmlResult ReadProcessingInstruction(StringView text, out int length, String target, String data)
	{
		length = 0;
		target.Clear();
		data.Clear();

		if (ReadName(text, let nameLength, target) != .Ok)
			return .PIInvalid;

		var index = nameLength;
		while ((index < text.Length) && IsWhitespace(text[index]))
			index++;

		// A target with no data at all.
		if ((index + 1 < text.Length) && (text[index] == '?') && (text[index + 1] == '>'))
		{
			length = index + 2;
			return .Ok;
		}

		while (index < text.Length)
		{
			if ((index + 1 < text.Length) && (text[index] == '?') && (text[index + 1] == '>'))
			{
				length = index + 2;
				return .Ok;
			}
			data.Append(text[index]);
			index++;
		}
		return .PIUnclosed;
	}

	// ---- internals ----

	private static StringView Rest(StringView text, int index) => StringView(text, index);

	/// A numeric character reference, decimal or hexadecimal.
	///
	/// The overflow guard is on the accumulator rather than after it: a long enough run of
	/// digits would wrap around into a value that looks legitimate.
	private static XmlResult DecodeCharacterReference(StringView text, out int length, String output)
	{
		length = 0;
		if ((text.Length < 4) || (text[0] != '&') || (text[1] != '#'))
			return .CharRefInvalid;

		var index = 2;
		var isHex = false;
		if ((text[index] == 'x') || (text[index] == 'X'))
		{
			isHex = true;
			index++;
		}
		if (index >= text.Length)
			return .CharRefInvalid;

		uint32 codepoint = 0;
		var hasDigits = false;
		while (index < text.Length)
		{
			let c = text[index];
			if (c == ';')
			{
				if (!hasDigits)
					return .CharRefInvalid;
				if ((codepoint == 0) || (codepoint > 0x10FFFF))
					return .CharRefOutOfRange;
				if (!IsValidXmlChar(codepoint))
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
				if ((c < '0') || (c > '9'))
					return .CharRefInvalid;
				let digit = (uint32)(c - '0');
				if (codepoint > (0x10FFFF - digit) / 10)
					return .CharRefOutOfRange;
				codepoint = codepoint * 10 + digit;
			}

			hasDigits = true;
			index++;
		}
		return .CharRefInvalid;
	}

	/// A named reference. Only the five the specification predefines are known: anything
	/// else would need a document type declaration, which this parser does not read.
	private static XmlResult DecodeEntityReference(StringView text, out int length, String output)
	{
		length = 0;
		if (text.IsEmpty || (text[0] != '&'))
			return .EntityMalformed;

		var index = 1;
		let nameStart = index;
		while ((index < text.Length) && (text[index] != ';'))
		{
			let c = text[index];
			if (index == nameStart)
			{
				if (!IsNameStartChar(c))
					return .EntityMalformed;
			}
			else if (!IsNameChar(c))
			{
				return .EntityMalformed;
			}
			index++;
		}
		if ((index >= text.Length) || (text[index] != ';'))
			return .EntityMalformed;

		let name = StringView(text, nameStart, index - nameStart);
		length = index + 1;

		switch (name)
		{
		case "amp": output.Append('&');
		case "lt": output.Append('<');
		case "gt": output.Append('>');
		case "apos": output.Append('\'');
		case "quot": output.Append('"');
		default: return .EntityUnknown;
		}
		return .Ok;
	}
}
