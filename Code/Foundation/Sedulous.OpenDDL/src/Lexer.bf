using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Low-level lexer/tokenization utilities for parsing OpenDDL text.
/// </summary>
static class Lexer
{
	/// <summary>
	/// Character classification for identifier parsing.
	/// 0 = invalid, 1 = valid start char (letter or underscore), 2 = valid continuation (letter, digit, underscore)
	/// </summary>
	private static readonly uint8[256] sIdentifierCharState = .(
		// 0x00-0x0F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x10-0x1F
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x20-0x2F: space ! " # $ % & ' ( ) * + , - . /
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		// 0x30-0x3F: 0-9 : ; < = > ?
		2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0,
		// 0x40-0x4F: @ A-O
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x50-0x5F: P-Z [ \ ] ^ _
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
		// 0x60-0x6F: ` a-o
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		// 0x70-0x7F: p-z { | } ~
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
		// 0x80-0xFF: extended ASCII
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	);

	/// <summary>
	/// Base64 decoding table. 255 = invalid, 64 = padding (=), other = 6-bit value.
	/// </summary>
	private static readonly uint8[256] sBase64DecodeTable = .(
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255, // 0x00-0x0F
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255, // 0x10-0x1F
		255,255,255,255,255,255,255,255,255,255,255, 62,255,255,255, 63, // 0x20-0x2F: +=/
		 52, 53, 54, 55, 56, 57, 58, 59, 60, 61,255,255,255, 64,255,255, // 0x30-0x3F: 0-9, =
		255,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, // 0x40-0x4F: A-O
		 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,255,255,255,255,255, // 0x50-0x5F: P-Z
		255, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, // 0x60-0x6F: a-o
		 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,255,255,255,255,255, // 0x70-0x7F: p-z
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
		255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
	);

	/// <summary>
	/// Returns the number of whitespace characters at the beginning of a text string.
	/// Whitespace includes ASCII characters 1-32 and C++ style comments.
	/// </summary>
	public static int GetWhitespaceLength(StringView text)
	{
		int index = 0;
		int length = text.Length;

		while (index < length)
		{
			let c = text[index];

			// Standard whitespace (ASCII 1-32)
			if ((uint8)c >= 1 && (uint8)c <= 32)
			{
				index++;
				continue;
			}

			// Check for comments
			if (c == '/')
			{
				if (index + 1 < length)
				{
					let next = text[index + 1];

					// Single-line comment: //
					if (next == '/')
					{
						index += 2;
						while (index < length && text[index] != '\n')
							index++;
						if (index < length)
							index++; // Skip the newline
						continue;
					}

					// Block comment: /* */
					if (next == '*')
					{
						index += 2;
						while (index + 1 < length)
						{
							if (text[index] == '*' && text[index + 1] == '/')
							{
								index += 2;
								break;
							}
							index++;
						}
						continue;
					}
				}
			}

			// Not whitespace
			break;
		}

		return index;
	}

	/// <summary>
	/// Reads an identifier from a text string.
	/// An identifier is composed of [A-Za-z_][A-Za-z0-9_]*.
	/// </summary>
	/// <param name="text">The text to read from.</param>
	/// <param name="length">Receives the length of the identifier.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static DataResult ReadIdentifier(StringView text, out int length)
	{
		length = 0;

		if (text.IsEmpty)
			return .IdentifierEmpty;

		let firstChar = (uint8)text[0];
		if (sIdentifierCharState[firstChar] != 1)
		{
			// Identifier must start with a letter or underscore
			// Digits and other characters mean no valid identifier here
			return .IdentifierEmpty;
		}

		int index = 1;
		while (index < text.Length)
		{
			let c = (uint8)text[index];
			if (sIdentifierCharState[c] == 0)
				break;
			index++;
		}

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads an identifier and copies it to the output string.
	/// </summary>
	public static DataResult ReadIdentifier(StringView text, out int length, String identifier)
	{
		let result = ReadIdentifier(text, out length);
		if (result == .Ok)
		{
			identifier.Clear();
			identifier.Append(text.Substring(0, length));
		}
		return result;
	}

	/// <summary>
	/// Reads a data type identifier from text.
	/// </summary>
	public static DataResult ReadDataType(StringView text, out int length, out DataType value)
	{
		length = 0;
		value = default;

		let result = ReadIdentifier(text, out length);
		if (result != .Ok)
			return result;

		let identifier = text.Substring(0, length);
		if (let dt = DataType.FromIdentifier(identifier))
		{
			value = dt;
			return .Ok;
		}

		length = 0;
		return .TypeInvalid;
	}

	/// <summary>
	/// Reads a boolean literal (true, false, 0, or 1).
	/// </summary>
	public static DataResult ReadBoolLiteral(StringView text, out int length, out bool value)
	{
		length = 0;
		value = false;

		if (text.IsEmpty)
			return .BoolInvalid;

		// Check for 0 or 1
		if (text[0] == '0')
		{
			// Make sure it's not part of 0x, 0o, 0b
			if (text.Length > 1)
			{
				let next = text[1];
				if (next == 'x' || next == 'X' || next == 'o' || next == 'O' || next == 'b' || next == 'B')
					return .BoolInvalid;
				if (sIdentifierCharState[(uint8)next] != 0)
					return .BoolInvalid;
			}
			length = 1;
			value = false;
			return .Ok;
		}

		if (text[0] == '1')
		{
			if (text.Length > 1 && sIdentifierCharState[(uint8)text[1]] != 0)
				return .BoolInvalid;
			length = 1;
			value = true;
			return .Ok;
		}

		// Check for true/false
		int idLen = 0;
		let result = ReadIdentifier(text, out idLen);
		if (result != .Ok)
			return .BoolInvalid;

		let identifier = text.Substring(0, idLen);
		if (identifier == "true")
		{
			length = idLen;
			value = true;
			return .Ok;
		}
		if (identifier == "false")
		{
			length = idLen;
			value = false;
			return .Ok;
		}

		return .BoolInvalid;
	}

	/// <summary>
	/// Parses a sign character (+ or -) and advances past it.
	/// </summary>
	/// <param name="text">The text to parse (may be modified to skip the sign).</param>
	/// <returns>True if negative, false otherwise.</returns>
	public static bool ParseSign(ref StringView text)
	{
		if (text.IsEmpty)
			return false;

		if (text[0] == '+')
		{
			text = text.Substring(1);
			return false;
		}

		if (text[0] == '-')
		{
			text = text.Substring(1);
			return true;
		}

		return false;
	}

	/// <summary>
	/// Converts a hex digit character to its numeric value.
	/// </summary>
	private static int HexDigitValue(char8 c)
	{
		if (c >= '0' && c <= '9') return c - '0';
		if (c >= 'A' && c <= 'F') return c - 'A' + 10;
		if (c >= 'a' && c <= 'f') return c - 'a' + 10;
		return -1;
	}

	/// <summary>
	/// Checks if a character is a hex digit.
	/// </summary>
	private static bool IsHexDigit(char8 c)
	{
		return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f');
	}

	/// <summary>
	/// Checks if a character is an octal digit.
	/// </summary>
	private static bool IsOctalDigit(char8 c)
	{
		return c >= '0' && c <= '7';
	}

	/// <summary>
	/// Checks if a character is a binary digit.
	/// </summary>
	private static bool IsBinaryDigit(char8 c)
	{
		return c == '0' || c == '1';
	}

	/// <summary>
	/// Reads a signed integer literal with optional leading + or - sign.
	/// </summary>
	public static DataResult ReadSignedIntegerLiteral(StringView text, out int length, out uint64 value, out bool isNegative)
	{
		length = 0;
		value = 0;
		isNegative = false;

		if (text.IsEmpty)
			return .SyntaxError;

		var startIndex = 0;

		// Check for sign
		if (text[0] == '-')
		{
			isNegative = true;
			startIndex = 1;
		}
		else if (text[0] == '+')
		{
			startIndex = 1;
		}

		if (startIndex >= text.Length)
			return .SyntaxError;

		// Read the unsigned part
		int unsignedLen;
		let result = ReadIntegerLiteral(text.Substring(startIndex), out unsignedLen, out value);
		if (result != .Ok)
			return result;

		length = startIndex + unsignedLen;
		return .Ok;
	}

	/// <summary>
	/// Reads an unsigned integer literal (decimal, hex, octal, binary, or char).
	/// </summary>
	public static DataResult ReadIntegerLiteral(StringView text, out int length, out uint64 value)
	{
		length = 0;
		value = 0;

		if (text.IsEmpty)
			return .SyntaxError;

		var index = 0;

		// Check for character literal
		if (text[0] == '\'')
			return ReadCharLiteral(text, out length, out value);

		// Check for hex (0x), octal (0o), or binary (0b)
		if (text[0] == '0' && text.Length > 1)
		{
			let prefix = text[1];

			if (prefix == 'x' || prefix == 'X')
				return ReadHexLiteral(text, out length, out value);

			if (prefix == 'o' || prefix == 'O')
				return ReadOctalLiteral(text, out length, out value);

			if (prefix == 'b' || prefix == 'B')
				return ReadBinaryLiteral(text, out length, out value);
		}

		// Decimal literal
		if (text[0] < '0' || text[0] > '9')
			return .SyntaxError;

		while (index < text.Length)
		{
			let c = text[index];

			if (c >= '0' && c <= '9')
			{
				let digit = (uint64)(c - '0');
				// Check for overflow
				if (value > (uint64.MaxValue - digit) / 10)
					return .IntegerOverflow;
				value = value * 10 + digit;
				index++;
			}
			else if (c == '_')
			{
				// Underscore separator - must be between digits
				if (index + 1 >= text.Length || text[index + 1] < '0' || text[index + 1] > '9')
					break;
				index++;
			}
			else
			{
				break;
			}
		}

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads a hexadecimal literal (0x prefix).
	/// </summary>
	private static DataResult ReadHexLiteral(StringView text, out int length, out uint64 value)
	{
		length = 0;
		value = 0;

		if (text.Length < 3 || text[0] != '0' || (text[1] != 'x' && text[1] != 'X'))
			return .SyntaxError;

		var index = 2;
		var hasDigits = false;

		while (index < text.Length)
		{
			let c = text[index];

			if (IsHexDigit(c))
			{
				let digit = (uint64)HexDigitValue(c);
				// Check for overflow
				if (value > (uint64.MaxValue - digit) / 16)
					return .IntegerOverflow;
				value = value * 16 + digit;
				hasDigits = true;
				index++;
			}
			else if (c == '_')
			{
				// Underscore separator - must be between digits
				if (index + 1 >= text.Length || !IsHexDigit(text[index + 1]))
					break;
				index++;
			}
			else
			{
				break;
			}
		}

		if (!hasDigits)
			return .SyntaxError;

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads an octal literal (0o prefix).
	/// </summary>
	private static DataResult ReadOctalLiteral(StringView text, out int length, out uint64 value)
	{
		length = 0;
		value = 0;

		if (text.Length < 3 || text[0] != '0' || (text[1] != 'o' && text[1] != 'O'))
			return .SyntaxError;

		var index = 2;
		var hasDigits = false;

		while (index < text.Length)
		{
			let c = text[index];

			if (IsOctalDigit(c))
			{
				let digit = (uint64)(c - '0');
				// Check for overflow
				if (value > (uint64.MaxValue - digit) / 8)
					return .IntegerOverflow;
				value = value * 8 + digit;
				hasDigits = true;
				index++;
			}
			else if (c == '_')
			{
				// Underscore separator - must be between digits
				if (index + 1 >= text.Length || !IsOctalDigit(text[index + 1]))
					break;
				index++;
			}
			else
			{
				break;
			}
		}

		if (!hasDigits)
			return .SyntaxError;

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads a binary literal (0b prefix).
	/// </summary>
	private static DataResult ReadBinaryLiteral(StringView text, out int length, out uint64 value)
	{
		length = 0;
		value = 0;

		if (text.Length < 3 || text[0] != '0' || (text[1] != 'b' && text[1] != 'B'))
			return .SyntaxError;

		var index = 2;
		var hasDigits = false;

		while (index < text.Length)
		{
			let c = text[index];

			if (IsBinaryDigit(c))
			{
				let digit = (uint64)(c - '0');
				// Check for overflow
				if (value > (uint64.MaxValue - digit) / 2)
					return .IntegerOverflow;
				value = value * 2 + digit;
				hasDigits = true;
				index++;
			}
			else if (c == '_')
			{
				// Underscore separator - must be between digits
				if (index + 1 >= text.Length || !IsBinaryDigit(text[index + 1]))
					break;
				index++;
			}
			else
			{
				break;
			}
		}

		if (!hasDigits)
			return .SyntaxError;

		length = index;
		return .Ok;
	}

	/// <summary>
	/// Reads a character literal ('A', '\n', '\x41', etc.).
	/// </summary>
	private static DataResult ReadCharLiteral(StringView text, out int length, out uint64 value)
	{
		length = 0;
		value = 0;

		if (text.Length < 2 || text[0] != '\'')
			return .SyntaxError;

		var index = 1;
		var byteCount = 0;

		while (index < text.Length && text[index] != '\'')
		{
			if (byteCount >= 8)
				return .IntegerOverflow;

			uint8 byteValue = 0;
			let c = text[index];

			if (c == 0)
				return .CharEndOfFile;

			if (c == '\\')
			{
				// Escape sequence
				if (index + 1 >= text.Length)
					return .CharEndOfFile;

				let escape = text[index + 1];
				index += 2;

				switch (escape)
				{
				case '"': byteValue = 0x22;
				case '\'': byteValue = 0x27;
				case '?': byteValue = 0x3F;
				case '\\': byteValue = 0x5C;
				case 'a': byteValue = 0x07;
				case 'b': byteValue = 0x08;
				case 'f': byteValue = 0x0C;
				case 'n': byteValue = 0x0A;
				case 'r': byteValue = 0x0D;
				case 't': byteValue = 0x09;
				case 'v': byteValue = 0x0B;
				case 'x':
					// \xhh - two hex digits
					if (index + 1 >= text.Length)
						return .CharIllegalEscape;
					let h1 = HexDigitValue(text[index]);
					let h2 = HexDigitValue(text[index + 1]);
					if (h1 < 0 || h2 < 0)
						return .CharIllegalEscape;
					byteValue = (uint8)(h1 * 16 + h2);
					index += 2;
				default:
					return .CharIllegalEscape;
				}
			}
			else if ((uint8)c < 0x20 || c == '\'' || c == '\\' || (uint8)c > 0x7E)
			{
				// Invalid character (control chars, single quote, backslash, or non-ASCII)
				return .CharIllegalChar;
			}
			else
			{
				byteValue = (uint8)c;
				index++;
			}

			// Add byte to value (right-most character is least significant byte)
			value = (value << 8) | byteValue;
			byteCount++;
		}

		if (index >= text.Length || text[index] != '\'')
			return .CharEndOfFile;

		if (byteCount == 0)
			return .CharIllegalChar; // Empty character literal

		length = index + 1; // Include closing quote
		return .Ok;
	}

	/// <summary>
	/// Reads a signed integer literal.
	/// </summary>
	public static DataResult ReadSignedIntegerLiteral(StringView text, out int length, out int64 value)
	{
		length = 0;
		value = 0;

		var remaining = text;
		let negative = ParseSign(ref remaining);
		let signLength = text.Length - remaining.Length;

		let result = ReadIntegerLiteral(remaining, var literalLength, var unsignedValue);
		if (result != .Ok)
			return result;

		length = signLength + literalLength;

		if (negative)
		{
			if (unsignedValue > (uint64)int64.MaxValue + 1)
				return .IntegerOverflow;
			value = -(int64)unsignedValue;
		}
		else
		{
			if (unsignedValue > (uint64)int64.MaxValue)
				return .IntegerOverflow;
			value = (int64)unsignedValue;
		}

		return .Ok;
	}

	/// <summary>
	/// Reads a floating-point literal.
	/// </summary>
	public static DataResult ReadFloatLiteral(StringView text, out int length, out double value)
	{
		length = 0;
		value = 0.0;

		if (text.IsEmpty)
			return .FloatInvalid;

		var remaining = text;
		let negative = ParseSign(ref remaining);
		let signLength = text.Length - remaining.Length;

		if (remaining.IsEmpty)
			return .FloatInvalid;

		// Check for hex, octal, or binary (bit pattern representation)
		if (remaining[0] == '0' && remaining.Length > 1)
		{
			let prefix = remaining[1];
			if (prefix == 'x' || prefix == 'X' || prefix == 'o' || prefix == 'O' || prefix == 'b' || prefix == 'B')
			{
				let result = ReadIntegerLiteral(remaining, var litLen, var bits);
				if (result != .Ok)
					return result;

				length = signLength + litLen;
				// Interpret bits as double
				value = *((double*)&bits);
				if (negative)
					value = -value;
				return .Ok;
			}
		}

		// Decimal floating-point
		var index = 0;
		var hasIntPart = false;
		var hasFracPart = false;
		var hasExpPart = false;

		// Integer part
		while (index < remaining.Length)
		{
			let c = remaining[index];
			if (c >= '0' && c <= '9')
			{
				hasIntPart = true;
				index++;
			}
			else if (c == '_' && hasIntPart && index + 1 < remaining.Length &&
					 remaining[index + 1] >= '0' && remaining[index + 1] <= '9')
			{
				index++;
			}
			else
			{
				break;
			}
		}

		// Fractional part
		if (index < remaining.Length && remaining[index] == '.')
		{
			index++;

			while (index < remaining.Length)
			{
				let c = remaining[index];
				if (c >= '0' && c <= '9')
				{
					hasFracPart = true;
					index++;
				}
				else if (c == '_' && hasFracPart && index + 1 < remaining.Length &&
						 remaining[index + 1] >= '0' && remaining[index + 1] <= '9')
				{
					index++;
				}
				else
				{
					break;
				}
			}
		}

		if (!hasIntPart && !hasFracPart)
			return .FloatInvalid;

		// Exponent part
		if (index < remaining.Length && (remaining[index] == 'e' || remaining[index] == 'E'))
		{
			index++;

			if (index < remaining.Length && (remaining[index] == '+' || remaining[index] == '-'))
				index++;

			if (index >= remaining.Length || remaining[index] < '0' || remaining[index] > '9')
				return .FloatInvalid;

			while (index < remaining.Length)
			{
				let c = remaining[index];
				if (c >= '0' && c <= '9')
				{
					hasExpPart = true;
					index++;
				}
				else if (c == '_' && hasExpPart && index + 1 < remaining.Length &&
						 remaining[index + 1] >= '0' && remaining[index + 1] <= '9')
				{
					index++;
				}
				else
				{
					break;
				}
			}
		}

		length = signLength + index;

		// Build string without underscores for parsing
		let numStr = scope String();
		if (negative)
			numStr.Append('-');
		for (var i = 0; i < index; i++)
		{
			let c = remaining[i];
			if (c != '_')
				numStr.Append(c);
		}

		if (double.Parse(numStr) case .Ok(let parsed))
		{
			value = parsed;
			return .Ok;
		}

		return .FloatInvalid;
	}

	/// <summary>
	/// Reads a string literal (double-quoted with escape sequences).
	/// Handles adjacent string concatenation.
	/// </summary>
	public static DataResult ReadStringLiteral(StringView text, out int length, String output)
	{
		length = 0;
		output.Clear();

		if (text.IsEmpty || text[0] != '"')
			return .StringInvalid;

		var totalLength = 0;

		// Handle adjacent strings (concatenation)
		while (totalLength < text.Length && text[totalLength] == '"')
		{
			var index = totalLength + 1;

			while (index < text.Length)
			{
				let c = text[index];

				if (c == '"')
				{
					index++;
					break;
				}

				if (c == 0)
					return .StringEndOfFile;

				if (c == '\\')
				{
					// Escape sequence
					if (index + 1 >= text.Length)
						return .StringEndOfFile;

					let escape = text[index + 1];
					index += 2;

					switch (escape)
					{
					case '"': output.Append('"');
					case '\'': output.Append('\'');
					case '?': output.Append('?');
					case '\\': output.Append('\\');
					case 'a': output.Append('\a');
					case 'b': output.Append('\b');
					case 'f': output.Append('\f');
					case 'n': output.Append('\n');
					case 'r': output.Append('\r');
					case 't': output.Append('\t');
					case 'v': output.Append('\v');
					case 'x':
						// \xhh - two hex digits
						if (index + 1 >= text.Length)
							return .StringIllegalEscape;
						let h1 = HexDigitValue(text[index]);
						let h2 = HexDigitValue(text[index + 1]);
						if (h1 < 0 || h2 < 0)
							return .StringIllegalEscape;
						output.Append((char8)(h1 * 16 + h2));
						index += 2;
					case 'u':
						// \uhhhh - four hex digits (Unicode BMP)
						if (index + 3 >= text.Length)
							return .StringIllegalEscape;
						uint32 codepoint = 0;
						for (var i = 0; i < 4; i++)
						{
							let h = HexDigitValue(text[index + i]);
							if (h < 0)
								return .StringIllegalEscape;
							codepoint = codepoint * 16 + (uint32)h;
						}
						if (codepoint == 0)
							return .StringIllegalEscape;
						output.Append((char32)codepoint);
						index += 4;
					case 'U':
						// \Uhhhhhh - six hex digits (full Unicode)
						if (index + 5 >= text.Length)
							return .StringIllegalEscape;
						uint32 codepoint = 0;
						for (var i = 0; i < 6; i++)
						{
							let h = HexDigitValue(text[index + i]);
							if (h < 0)
								return .StringIllegalEscape;
							codepoint = codepoint * 16 + (uint32)h;
						}
						if (codepoint == 0 || codepoint > 0x10FFFF)
							return .StringIllegalEscape;
						output.Append((char32)codepoint);
						index += 6;
					default:
						return .StringIllegalEscape;
					}
				}
				else if ((uint8)c < 0x20)
				{
					// Control characters not allowed (except via escape)
					return .StringIllegalChar;
				}
				else
				{
					// Regular character (including UTF-8 sequences)
					output.Append(c);
					index++;
				}
			}

			totalLength = index;

			// Skip whitespace between adjacent strings
			let ws = GetWhitespaceLength(text.Substring(totalLength));
			if (ws > 0 && totalLength + ws < text.Length && text[totalLength + ws] == '"')
			{
				totalLength += ws;
			}
		}

		length = totalLength;
		return .Ok;
	}

	/// <summary>
	/// Reads base64-encoded data.
	/// </summary>
	public static DataResult ReadBase64Data(StringView text, out int length, List<uint8> output)
	{
		length = 0;
		output.Clear();

		var index = 0;
		var buffer = scope uint8[4];
		var bufferCount = 0;
		var paddingCount = 0;

		while (index < text.Length)
		{
			let c = text[index];

			// Skip whitespace within base64 data
			if ((uint8)c >= 1 && (uint8)c <= 32)
			{
				index++;
				continue;
			}

			let value = sBase64DecodeTable[(uint8)c];

			if (value == 255)
			{
				// Not a valid base64 character - end of data
				break;
			}

			if (value == 64)
			{
				// Padding character '='
				paddingCount++;
				index++;

				if (paddingCount > 2)
					return .Base64Invalid;

				continue;
			}

			if (paddingCount > 0)
			{
				// Data after padding is invalid
				return .Base64Invalid;
			}

			buffer[bufferCount++] = (uint8)value;
			index++;

			if (bufferCount == 4)
			{
				// Decode 4 characters to 3 bytes
				output.Add((buffer[0] << 2) | (buffer[1] >> 4));
				output.Add((buffer[1] << 4) | (buffer[2] >> 2));
				output.Add((buffer[2] << 6) | buffer[3]);
				bufferCount = 0;
			}
		}

		// Handle remaining data
		if (bufferCount > 0)
		{
			if (bufferCount == 1)
				return .Base64Invalid; // Invalid: need at least 2 chars

			if (bufferCount >= 2)
			{
				output.Add((buffer[0] << 2) | (buffer[1] >> 4));
			}

			if (bufferCount >= 3)
			{
				output.Add((buffer[1] << 4) | (buffer[2] >> 2));
			}
		}

		length = index;
		return .Ok;
	}
}
