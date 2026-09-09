using System;
using System.Collections;

namespace Sedulous.Http;

/// One header field. Owns its name and value.
class HttpHeader
{
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
