using System;
using System.Collections;
using Sedulous.Http;

namespace Sedulous.Http.Client;

class HttpClientRequest
{
	public String Method = new .("GET") ~ delete _;
	/// http://host[:port]/path?query or https://...
	public String Url = new .() ~ delete _;
	public List<HttpHeader> Headers = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> Body = new .() ~ delete _;
	/// Over the whole request, redirects included.
	public float TimeoutSeconds = 30.0f;
	/// Nought: a redirect comes back as it is.
	public int32 MaxRedirects = 5;
	/// A body past this fails the request.
	public int MaxResponseBytes = 16 * 1024 * 1024;

	public this() {}

	public this(StringView url)
	{
		Url.Set(url);
	}

	/// A GET of `url`. The caller owns it, until Send takes it.
	public static HttpClientRequest Get(StringView url) => new .(url);

	/// A POST of `body` as `contentType` to `url`. The caller owns it, until Send takes it.
	public static HttpClientRequest Post(StringView url, StringView contentType, StringView body)
	{
		let request = new HttpClientRequest(url);
		request.Method.Set("POST");
		request.Headers.Add(new .("Content-Type", contentType));
		request.Body.AddRange(Span<uint8>((uint8*)body.Ptr, body.Length));
		return request;
	}
}

class HttpClientResponse
{
	/// Nought when no response arrived (Error says why).
	public int32 Status = 0;
	public List<HttpHeader> Headers = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> Body = new .() ~ delete _;
	/// Why the request failed, said for a person; empty when a response came.
	public String Error = new .() ~ delete _;
	/// The URL that answered (after redirects).
	public String Url = new .() ~ delete _;

	public bool Ok => Error.IsEmpty;
	public StringView Header(StringView name) => HttpHeader.Find(Headers, name);
	public StringView BodyText => .((char8*)Body.Ptr, Body.Count);
}
