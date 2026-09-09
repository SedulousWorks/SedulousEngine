using System;

namespace Sedulous.Json;

/// Writes a value as UTF-8 JSON text: compact, or indented two spaces per level.
static class JsonWriter
{
	/// Appends the JSON text for a value.
	public static void Write(JsonValue value, String outText, bool pretty = false)
	{
		WriteValue(value, outText, pretty, 0);
	}

	private static void WriteValue(JsonValue value, String outText, bool pretty, int depth)
	{
		if (value == null)
		{
			outText.Append("null");
			return;
		}

		switch (value.Type)
		{
		case .Null:
			outText.Append("null");

		case .Bool:
			outText.Append(value.AsBool() ? "true" : "false");

		case .Number:
			WriteNumber(value.AsNumber(), outText);

		case .String:
			WriteEscaped(value.AsString(), outText);

		case .Array:
			let count = value.Count;
			if (count == 0)
			{
				outText.Append("[]");
				return;
			}
			outText.Append('[');
			for (int i = 0; i < count; i++)
			{
				if (i != 0)
					outText.Append(',');
				if (pretty)
					WriteIndent(outText, depth + 1);
				WriteValue(value.At(i), outText, pretty, depth + 1);
			}
			if (pretty)
				WriteIndent(outText, depth);
			outText.Append(']');

		case .Object:
			let keys = value.Keys;
			if (keys.Length == 0)
			{
				outText.Append("{}");
				return;
			}
			outText.Append('{');
			for (int i = 0; i < keys.Length; i++)
			{
				if (i != 0)
					outText.Append(',');
				if (pretty)
					WriteIndent(outText, depth + 1);
				WriteEscaped(keys[i], outText);
				outText.Append(pretty ? ": " : ":");
				WriteValue(value.Get(keys[i]), outText, pretty, depth + 1);
			}
			if (pretty)
				WriteIndent(outText, depth);
			outText.Append('}');
		}
	}

	private static void WriteIndent(String outText, int depth)
	{
		outText.Append('\n');
		for (int i = 0; i < depth; i++)
			outText.Append("  ");
	}

	/// A number JSON can hold. NaN and the infinities cannot be written at all, so they
	/// degrade to null and the output stays parseable.
	private static void WriteNumber(double value, String outText)
	{
		if (value.IsNaN || value.IsInfinity)
		{
			outText.Append("null");
			return;
		}

		// A whole number prints without a decimal point, which is what makes an integer field
		// round trip as it was written rather than gaining a ".0". Bounded, because outside
		// that range the conversion to an integer is not defined and every such double is a
		// whole number anyway.
		if ((value >= -1.0e15) && (value <= 1.0e15) && (value == (double)(int64)value))
		{
			outText.AppendF("{}", (int64)value);
			return;
		}
		outText.AppendF("{}", value);
	}

	/// The escapes RFC 8259 requires, and no more: valid UTF-8 passes through as its own
	/// bytes rather than being expanded into escapes.
	private static void WriteEscaped(StringView text, String outText)
	{
		const String cHexDigits = "0123456789abcdef";

		outText.Append('"');
		for (let c in text.RawChars)
		{
			switch (c)
			{
			case '"': outText.Append("\\\"");
			case '\\': outText.Append("\\\\");
			case '\b': outText.Append("\\b");
			case '\f': outText.Append("\\f");
			case '\n': outText.Append("\\n");
			case '\r': outText.Append("\\r");
			case '\t': outText.Append("\\t");
			default:
				if (c < (char8)0x20)
				{
					// Every other control character, which JSON forbids raw.
					outText.Append("\\u00");
					outText.Append(cHexDigits[((int)c >> 4) & 0xF]);
					outText.Append(cHexDigits[(int)c & 0xF]);
				}
				else
				{
					outText.Append(c);
				}
			}
		}
		outText.Append('"');
	}
}
