using System;

namespace Sedulous.Json;

/// A recursive descent parser for RFC 8259 JSON, UTF-8 in and a JsonValue out.
///
/// No exceptions and no partial results: a failure leaves a Null value with a message and the
/// byte offset. Recursion is BOUNDED, so hostile input cannot take the stack down.
static class JsonParser
{
	/// The nesting a document may reach. Deep enough for any real document and shallow enough
	/// that the recursion cannot exhaust a thread's stack.
	public const int MaxDepth = 256;

	private struct State
	{
		public StringView Text;
		public int Position;
		public String Error;
		public int ErrorPosition;

		public bool AtEnd => Position >= Text.Length;
		public char8 Peek => (Position < Text.Length) ? Text[Position] : '\0';

		/// Records the FIRST failure and keeps it, so the message describes the innermost
		/// problem rather than the outermost unwind. Always false, so a caller returns it.
		public bool Fail(StringView message, int at) mut
		{
			if (Error.IsEmpty)
			{
				Error.Set(message);
				ErrorPosition = at;
			}
			return false;
		}

		public void SkipWhitespace() mut
		{
			while (Position < Text.Length)
			{
				let c = Text[Position];
				if ((c == ' ') || (c == '\t') || (c == '\n') || (c == '\r'))
					Position++;
				else
					break;
			}
		}
	}

	/// Parses JSON text into outResult. On failure Ok is false, Value is Null, and Error and
	/// Position describe the first problem.
	public static void Parse(StringView text, JsonParseResult outResult)
	{
		outResult.Clear();

		var state = State();
		state.Text = text;
		state.Error = outResult.Error;

		JsonValue value = null;
		if (!ParseValue(ref state, out value, 0))
		{
			delete value;
			outResult.Position = state.ErrorPosition;
			return;
		}

		state.SkipWhitespace();
		if (!state.AtEnd)
		{
			// A second value after the first is not a document, and accepting it would let a
			// truncated read look like a whole one.
			delete value;
			outResult.Error.Set("trailing characters after JSON value");
			outResult.Position = state.Position;
			return;
		}

		delete outResult.Value;
		outResult.Value = value;
		outResult.Ok = true;
	}

	private static bool ParseValue(ref State state, out JsonValue outValue, int depth)
	{
		outValue = null;
		if (depth > MaxDepth)
			return state.Fail("maximum nesting depth exceeded", state.Position);

		state.SkipWhitespace();
		if (state.AtEnd)
			return state.Fail("unexpected end of input", state.Position);

		let c = state.Text[state.Position];
		switch (c)
		{
		case '{':
			return ParseObject(ref state, out outValue, depth);

		case '[':
			return ParseArray(ref state, out outValue, depth);

		case '"':
			state.Position++;
			let text = scope String();
			if (!ParseString(ref state, text))
				return false;
			outValue = JsonValue.MakeString(text);
			return true;

		case 't':
			if (Literal(ref state, "true"))
			{
				outValue = JsonValue.MakeBool(true);
				return true;
			}
			return state.Fail("invalid literal", state.Position);

		case 'f':
			if (Literal(ref state, "false"))
			{
				outValue = JsonValue.MakeBool(false);
				return true;
			}
			return state.Fail("invalid literal", state.Position);

		case 'n':
			if (Literal(ref state, "null"))
			{
				outValue = JsonValue.MakeNull();
				return true;
			}
			return state.Fail("invalid literal", state.Position);

		default:
			if ((c == '-') || ((c >= '0') && (c <= '9')))
				return ParseNumber(ref state, out outValue);
			return state.Fail("unexpected character", state.Position);
		}
	}

	private static bool ParseArray(ref State state, out JsonValue outValue, int depth)
	{
		state.Position++;
		let array = JsonValue.MakeArray();
		outValue = array;

		state.SkipWhitespace();
		if (state.Peek == ']')
		{
			state.Position++;
			return true;
		}

		for (;;)
		{
			JsonValue element = null;
			if (!ParseValue(ref state, out element, depth + 1))
			{
				delete element;
				return false;
			}
			array.Add(element);

			state.SkipWhitespace();
			let c = state.Peek;
			if (c == ',')
			{
				state.Position++;
				continue;
			}
			if (c == ']')
			{
				state.Position++;
				return true;
			}
			return state.Fail("expected ',' or ']' in array", state.Position);
		}
	}

	private static bool ParseObject(ref State state, out JsonValue outValue, int depth)
	{
		state.Position++;
		let object = JsonValue.MakeObject();
		outValue = object;

		state.SkipWhitespace();
		if (state.Peek == '}')
		{
			state.Position++;
			return true;
		}

		for (;;)
		{
			state.SkipWhitespace();
			if (state.Peek != '"')
				return state.Fail("expected string key in object", state.Position);
			state.Position++;

			let key = scope String();
			if (!ParseString(ref state, key))
				return false;

			state.SkipWhitespace();
			if (state.Peek != ':')
				return state.Fail("expected ':' after object key", state.Position);
			state.Position++;

			JsonValue value = null;
			if (!ParseValue(ref state, out value, depth + 1))
			{
				delete value;
				return false;
			}
			object.Set(key, value);

			state.SkipWhitespace();
			let c = state.Peek;
			if (c == ',')
			{
				state.Position++;
				continue;
			}
			if (c == '}')
			{
				state.Position++;
				return true;
			}
			return state.Fail("expected ',' or '}' in object", state.Position);
		}
	}

	/// The caller has already consumed the opening quote.
	private static bool ParseString(ref State state, String outText)
	{
		while (state.Position < state.Text.Length)
		{
			let c = state.Text[state.Position];
			state.Position++;

			if (c == '"')
				return true;

			if (c == '\\')
			{
				if (state.AtEnd)
					return state.Fail("unterminated escape in string", state.Position);
				let escape = state.Text[state.Position];
				state.Position++;

				switch (escape)
				{
				case '"': outText.Append('"');
				case '\\': outText.Append('\\');
				case '/': outText.Append('/');
				case 'b': outText.Append('\b');
				case 'f': outText.Append('\f');
				case 'n': outText.Append('\n');
				case 'r': outText.Append('\r');
				case 't': outText.Append('\t');
				case 'u':
					if (!ParseUnicodeEscape(ref state, outText))
						return false;
				default:
					return state.Fail("invalid escape character", state.Position - 1);
				}
			}
			else if (c < (char8)0x20)
			{
				return state.Fail("control character in string (must be escaped)",
					state.Position - 1);
			}
			else
			{
				// A UTF-8 continuation byte passes through as itself: the parser works in
				// bytes and the encoding is already what it should be.
				outText.Append(c);
			}
		}
		return state.Fail("unterminated string", state.Position);
	}

	/// The caller has consumed the backslash and the u.
	private static bool ParseUnicodeEscape(ref State state, String outText)
	{
		uint32 codepoint = 0;
		if (!ParseHex4(ref state, ref codepoint))
			return false;

		// A high surrogate carries only half a codepoint, so the low half must follow.
		if ((codepoint >= 0xD800) && (codepoint <= 0xDBFF))
		{
			if ((state.Position + 2 > state.Text.Length) || (state.Text[state.Position] != '\\')
				|| (state.Text[state.Position + 1] != 'u'))
				return state.Fail("unpaired high surrogate", state.Position);
			state.Position += 2;

			uint32 low = 0;
			if (!ParseHex4(ref state, ref low))
				return false;
			if ((low < 0xDC00) || (low > 0xDFFF))
				return state.Fail("invalid low surrogate", state.Position);

			codepoint = 0x10000 + ((codepoint - 0xD800) << 10) + (low - 0xDC00);
		}
		else if ((codepoint >= 0xDC00) && (codepoint <= 0xDFFF))
		{
			return state.Fail("unexpected low surrogate", state.Position);
		}

		outText.Append((char32)codepoint);
		return true;
	}

	private static bool ParseHex4(ref State state, ref uint32 outValue)
	{
		if (state.Position + 4 > state.Text.Length)
			return state.Fail("truncated \\u escape", state.Position);

		uint32 value = 0;
		for (int i = 0; i < 4; i++)
		{
			let c = state.Text[state.Position];
			state.Position++;
			value <<= 4;

			if ((c >= '0') && (c <= '9'))
				value |= (uint32)(c - '0');
			else if ((c >= 'a') && (c <= 'f'))
				value |= (uint32)(c - 'a') + 10;
			else if ((c >= 'A') && (c <= 'F'))
				value |= (uint32)(c - 'A') + 10;
			else
				return state.Fail("invalid hex digit in \\u escape", state.Position - 1);
		}

		outValue = value;
		return true;
	}

	private static bool ParseNumber(ref State state, out JsonValue outValue)
	{
		outValue = null;
		let start = state.Position;

		if (state.Peek == '-')
			state.Position++;

		// The integer part is one zero, or a run that does not begin with one. Raptor scans
		// digits loosely and lets the conversion decide, which accepts "01"; JSON does not,
		// and a leading zero is far more often a typo or a padded field than a number.
		let integerStart = state.Position;
		SkipDigits(ref state);
		let integerLength = state.Position - integerStart;
		if (integerLength == 0)
			return state.Fail("expected a digit in number", state.Position);
		if ((integerLength > 1) && (state.Text[integerStart] == '0'))
			return state.Fail("leading zero in number", integerStart);

		if ((state.Position < state.Text.Length) && (state.Text[state.Position] == '.'))
		{
			state.Position++;
			SkipDigits(ref state);
		}

		if ((state.Position < state.Text.Length)
			&& ((state.Text[state.Position] == 'e') || (state.Text[state.Position] == 'E')))
		{
			state.Position++;
			if ((state.Position < state.Text.Length)
				&& ((state.Text[state.Position] == '+') || (state.Text[state.Position] == '-')))
				state.Position++;
			SkipDigits(ref state);
		}

		let token = state.Text.Substring(start, state.Position - start);
		// The shape was scanned loosely above, so this is what actually rejects "-", "1e" and
		// the rest of the almost numbers.
		if (double.Parse(token) case .Ok(let parsed))
		{
			outValue = JsonValue.MakeNumber(parsed);
			return true;
		}
		return state.Fail("invalid number", start);
	}

	private static void SkipDigits(ref State state)
	{
		while ((state.Position < state.Text.Length) && (state.Text[state.Position] >= '0')
			&& (state.Text[state.Position] <= '9'))
			state.Position++;
	}

	/// Consumes a keyword when it is there. Leaves the position alone when it is not.
	private static bool Literal(ref State state, StringView word)
	{
		if (state.Position + word.Length > state.Text.Length)
			return false;
		for (int i = 0; i < word.Length; i++)
		{
			if (state.Text[state.Position + i] != word[i])
				return false;
		}
		state.Position += word.Length;
		return true;
	}
}
