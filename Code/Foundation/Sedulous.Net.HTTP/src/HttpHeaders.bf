namespace Sedulous.Net.HTTP;

using System;
using System.Collections;

/// HTTP headers collection. Case-insensitive keys. Preserves order and allows duplicates.
public class HttpHeaders
{
	public struct Header : IDisposable
	{
		public String Name;
		public String Value;

		public void Dispose() mut
		{
			delete Name;
			delete Value;
		}
	}

	private List<Header> mHeaders = new .() ~ {
		for (var h in _) h.Dispose();
		delete _;
	};

	public int Count => mHeaders.Count;

	/// Set a header value. Replaces existing header with the same name.
	public void Set(StringView name, StringView value)
	{
		for (var h in ref mHeaders)
		{
			if (StringView.Compare(h.Name, name, true) == 0)
			{
				h.Value.Set(value);
				return;
			}
		}
		Header header;
		header.Name = new String(name);
		header.Value = new String(value);
		mHeaders.Add(header);
	}

	/// Add a header value. Allows duplicates (e.g. Set-Cookie).
	public void Add(StringView name, StringView value)
	{
		Header header;
		header.Name = new String(name);
		header.Value = new String(value);
		mHeaders.Add(header);
	}

	/// Get the first header value with the given name.
	public bool Get(StringView name, String outValue)
	{
		for (let h in mHeaders)
		{
			if (StringView.Compare(h.Name, name, true) == 0)
			{
				outValue.Set(h.Value);
				return true;
			}
		}
		return false;
	}

	/// Get all values for a header name.
	public void GetAll(StringView name, List<StringView> outValues)
	{
		for (let h in mHeaders)
		{
			if (StringView.Compare(h.Name, name, true) == 0)
				outValues.Add(h.Value);
		}
	}

	/// Check if a header exists.
	public bool Contains(StringView name)
	{
		for (let h in mHeaders)
		{
			if (StringView.Compare(h.Name, name, true) == 0)
				return true;
		}
		return false;
	}

	/// Remove all headers with the given name.
	public void Remove(StringView name)
	{
		for (int i = mHeaders.Count - 1; i >= 0; i--)
		{
			if (StringView.Compare(mHeaders[i].Name, name, true) == 0)
			{
				var h = mHeaders[i];
				h.Dispose();
				mHeaders.RemoveAt(i);
			}
		}
	}

	public void Clear()
	{
		for (var h in mHeaders) h.Dispose();
		mHeaders.Clear();
	}

	/// Convenience: Content-Length
	public int64 ContentLength
	{
		get
		{
			let val = scope String();
			if (Get("Content-Length", val))
			{
				if (int64.Parse(val) case .Ok(let len))
					return len;
			}
			return -1;
		}
		set
		{
			let val = scope String();
			value.ToString(val);
			Set("Content-Length", val);
		}
	}

	/// Convenience: Content-Type
	public void GetContentType(String outValue)
	{
		Get("Content-Type", outValue);
	}

	public void SetContentType(StringView value)
	{
		Set("Content-Type", value);
	}

	/// Write headers in HTTP wire format: "Name: Value\r\n" for each header.
	public void WriteTo(String buffer)
	{
		for (let h in mHeaders)
		{
			buffer.Append(h.Name);
			buffer.Append(": ");
			buffer.Append(h.Value);
			buffer.Append("\r\n");
		}
	}
}
