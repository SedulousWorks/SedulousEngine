using System;
using System.Collections;

namespace Sedulous.Http;

/// One header field. Owns its name and value.
class HttpHeader
{
	/// Whether `name: value` may be written into a message head as one header: a name of token
	/// characters, and a value with no line break or NUL. A CR or LF in either would end the line
	/// and start a header (or a body) the caller never wrote.
	public static bool IsWritable(StringView name, StringView value)
	{
		if (name.IsEmpty)
			return false;
		for (let c in name.RawChars)
		{
			let b = (uint8)c;
			if ((b <= 0x20) || (b >= 0x7F))
				return false;
			switch (c)
			{
			case ':', '(', ')', '<', '>', '@', ',', ';', '\\', '"', '/', '[', ']', '?', '=', '{', '}':
				return false;
			default:
			}
		}
		for (let c in value.RawChars)
		{
			if ((c == '\r') || (c == '\n') || (c == '\0'))
				return false;
		}
		return true;
	}

	/// The first of `headers` that may not be written (IsWritable), or null when all may.
	public static HttpHeader FirstUnwritable(List<HttpHeader> headers)
	{
		for (let header in headers)
		{
			if (!IsWritable(header.Name, header.Value))
				return header;
		}
		return null;
	}

	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;

	public this() {}

	public this(StringView name, StringView value)
	{
		Name.Set(name);
		Value.Set(value);
	}

	/// A header's value, or an empty view when absent.
	///
	/// CASE INSENSITIVE over ASCII, because the field name is case insensitive per the
	/// specification and a peer is free to send "content-length".
	public static StringView Find(List<HttpHeader> headers, StringView name)
	{
		for (let header in headers)
		{
			if (AsciiEqualsIgnoreCase(header.Name, name))
				return header.Value;
		}
		return .();
	}

	/// ASCII only on purpose: a header field name is ASCII by definition, and a full Unicode
	/// fold would be both slower and wrong for a wire protocol.
	public static bool AsciiEqualsIgnoreCase(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;

		for (int i = 0; i < a.Length; i++)
		{
			var ca = a[i];
			var cb = b[i];
			if ((ca >= 'A') && (ca <= 'Z'))
				ca = (char8)(ca + ('a' - 'A'));
			if ((cb >= 'A') && (cb <= 'Z'))
				cb = (char8)(cb + ('a' - 'A'));
			if (ca != cb)
				return false;
		}
		return true;
	}
}
