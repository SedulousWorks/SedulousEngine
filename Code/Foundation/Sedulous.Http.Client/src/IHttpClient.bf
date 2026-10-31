using System;

namespace Sedulous.Http.Client;

/// The game-facing HTTP client: requests go out, their responses come back by callback on the
/// caller's thread when it pumps. The native backend (NativeHttpClient) runs each request on a
/// worker thread, since a name lookup blocks, speaking HTTP/1.1 over a PlainStream for http:// and
/// a TlsStream for https://.
///
/// What it does: GET, POST and any method; bodies by Content-Length, chunked, or until close;
/// redirects within a limit (an https request is never followed to http); a timeout over the
/// whole request; cancel; a cap on the response's size. What it does not, by design for now:
/// keep-alive or HTTP/2 (each request its own connection), cookies, proxies, IPv6 (the socket
/// layer's).
///
/// Threading: Send, Cancel and Pump from one thread (the game's); callbacks run inside Pump.
interface IHttpClient
{
	/// Sends `request`, taking OWNERSHIP of it and of `done`, which hears its response (or why it
	/// failed) inside a later Pump. The response is the client's, valid for the call.
	uint64 Send(HttpClientRequest request, delegate void(HttpClientResponse response) done);
	/// Its callback is never called; a request under way is dropped.
	void Cancel(uint64 id);
	/// Delivers the responses that have arrived, on this thread.
	void Pump();
	/// Requests sent and not yet delivered or cancelled.
	int Pending { get; }
}
