using System;
using System.Collections;

namespace Sedulous.Http;

/// A parsed request, or one being built for the client.
class HttpRequest
{
	/// Verbatim and upper case, as the specification requires.
	public String Method = new .() ~ delete _;
	/// The origin form target, verbatim: "/mcp", "/events?since=5".
	public String Target = new .() ~ delete _;
	public List<HttpHeader> Headers = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> Body = new .() ~ delete _;

	public this() {}

	public this(StringView method, StringView target)
	{
		Method.Set(method);
		Target.Set(target);
	}

	public StringView Header(StringView name) => HttpHeader.Find(Headers, name);

	/// The body as text. BORROWED, and only meaningful for a textual content type.
	public StringView BodyText => .((char8*)Body.Ptr, Body.Count);

	public void AddHeader(StringView name, StringView value) =>
		Headers.Add(new HttpHeader(name, value));

	public void SetBodyText(StringView text)
	{
		Body.Clear();
		Body.AddRange(.((uint8*)text.Ptr, text.Length));
	}
}
