namespace Sedulous.Net.HTTP;

using System;
using System.Collections;

/// Represents an HTTP request.
public class HttpRequest
{
	public HttpMethod Method;
	public String Path = new .() ~ delete _;
	public String Version = new .("HTTP/1.1") ~ delete _;
	public HttpHeaders Headers = new .() ~ delete _;
	public List<uint8> Body = new .() ~ delete _;

	public this()
	{
	}

	public this(HttpMethod method, StringView path)
	{
		Method = method;
		Path.Set(path);
	}

	/// Set a header.
	public Self SetHeader(StringView name, StringView value)
	{
		Headers.Set(name, value);
		return this;
	}

	/// Set the request body from raw bytes.
	public Self SetBody(Span<uint8> data)
	{
		Body.Clear();
		Body.AddRange(data);
		Headers.ContentLength = data.Length;
		return this;
	}

	/// Set a string body.
	public Self SetBody(StringView text)
	{
		return SetBody(Span<uint8>((uint8*)text.Ptr, text.Length));
	}

	/// Set a JSON body with appropriate content type.
	public Self SetJsonBody(StringView json)
	{
		Headers.SetContentType("application/json");
		return SetBody(json);
	}

	/// Write the request in HTTP wire format.
	public void WriteTo(String buffer)
	{
		Method.ToString(buffer);
		buffer.Append(' ');
		buffer.Append(Path);
		buffer.Append(' ');
		buffer.Append(Version);
		buffer.Append("\r\n");
		Headers.WriteTo(buffer);
		buffer.Append("\r\n");
		if (Body.Count > 0)
			buffer.Append((char8*)Body.Ptr, Body.Count);
	}
}
