using System;
using System.Collections;

namespace Sedulous.Http;

/// A response to send, or one the client parsed.
class HttpResponse
{
	public int32 Status = 200;
	/// Content-Length and Connection are written by the server, not here.
	public List<HttpHeader> Headers = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> Body = new .() ~ delete _;
	/// The one exception to one request per connection: the headers go out and the connection
	/// STAYS OPEN for the consumer to write events through.
	public bool EventStream = false;

	public this() {}

	public StringView Header(StringView name) => HttpHeader.Find(Headers, name);

	public StringView BodyText => .((char8*)Body.Ptr, Body.Count);

	public void AddHeader(StringView name, StringView value) =>
		Headers.Add(new HttpHeader(name, value));

	public static HttpResponse Text(int32 status, StringView contentType, StringView text)
	{
		let response = new HttpResponse();
		response.Status = status;
		response.AddHeader("Content-Type", contentType);
		response.Body.AddRange(.((uint8*)text.Ptr, text.Length));
		return response;
	}

	public static HttpResponse Json(int32 status, StringView jsonText) =>
		Text(status, "application/json", jsonText);

	/// The marker that says "do not close this connection": the server writes the event
	/// stream headers and hands the socket to the stream handler.
	public static HttpResponse EventStreamResponse()
	{
		let response = new HttpResponse();
		response.Status = 200;
		response.EventStream = true;
		return response;
	}
}
