namespace Sedulous.Net.HTTP;

using System;
using System.Collections;

/// Represents an HTTP response.
public class HttpResponse
{
	public HttpStatusCode StatusCode;
	public String ReasonPhrase = new .() ~ delete _;
	public String Version = new .("HTTP/1.1") ~ delete _;
	public HttpHeaders Headers = new .() ~ delete _;
	public List<uint8> Body = new .() ~ delete _;

	public this()
	{
	}

	public this(HttpStatusCode statusCode)
	{
		StatusCode = statusCode;
		statusCode.GetReasonPhrase(ReasonPhrase);
	}

	/// Set a header.
	public Self SetHeader(StringView name, StringView value)
	{
		Headers.Set(name, value);
		return this;
	}

	/// Set the response body from raw bytes.
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

	/// Get body as a string.
	public void GetBodyString(String outStr)
	{
		if (Body.Count > 0)
			outStr.Append((char8*)Body.Ptr, Body.Count);
	}

	/// Write the response in HTTP wire format.
	public void WriteTo(String buffer)
	{
		buffer.Append(Version);
		buffer.Append(' ');
		((int32)StatusCode).ToString(buffer);
		buffer.Append(' ');
		buffer.Append(ReasonPhrase);
		buffer.Append("\r\n");
		Headers.WriteTo(buffer);
		buffer.Append("\r\n");
		if (Body.Count > 0)
			buffer.Append((char8*)Body.Ptr, Body.Count);
	}
}
