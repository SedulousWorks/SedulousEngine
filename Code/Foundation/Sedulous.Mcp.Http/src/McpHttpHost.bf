using System;
using System.Collections;
using Sedulous.Http;
using Sedulous.Mcp;

namespace Sedulous.Mcp.Http;

/// The MCP streamable HTTP binding: the SAME McpServer registry the stdio host serves, over
/// Sedulous.Http. Localhost plus a bearer token is the trust decision.
///
/// A satellite of Sedulous.Mcp, so the protocol core stays transport free.
///
/// The surface:
///   POST /mcp     one JSON-RPC message per request, the body being the line. The response is
///                 the 200 body; a notification, having no response, answers 202.
///   GET  /events  the Server-Sent Events channel for server initiated traffic. Broadcast
///                 sends to every listener; a `: connected` comment confirms the stream.
///   anything else 404. The wrong method on a known route is 405, and a missing or wrong
///                 token is 401 on BOTH routes.
///
/// Pump from ONE thread, the same one throughout. Handlers run synchronously inside it, so a
/// tool may touch that thread's state; Broadcast is safe from it too.
///
/// The McpServer must outlive the host.
class McpHttpHost
{
	private McpServer mServer;
	private HttpServer mHttp = new .() ~ delete _;
	private String mToken = new .() ~ delete _;
	/// The host's OWN references, taken with AddRef. The server holds its own and drops them
	/// on its own schedule, which is what lets these outlive a sweep on either side.
	private List<SseStream> mListeners = new .() ~ ReleaseListeners(_);

	public this(McpServer server)
	{
		mServer = server;
	}

	public ~this()
	{
		Stop();
	}

	private static void ReleaseListeners(List<SseStream> listeners)
	{
		for (let listener in listeners)
			listener.ReleaseRef();
		delete listeners;
	}

	public bool IsRunning => mHttp.IsRunning;
	public uint16 BoundPort => mHttp.BoundPort;
	public int ListenerCount => mListeners.Count;

	/// Binds and starts serving. False on an empty token, which is refused BEFORE the socket
	/// opens: a host that serves without a lock is worse than one that does not start.
	public bool Start(McpHttpConfig config)
	{
		if (config.Token.IsEmpty)
			return false;

		mToken.Set(config.Token);

		HttpServerConfig httpConfig = .();
		httpConfig.Port = config.Port;
		if (!mHttp.Start(httpConfig))
			return false;

		mHttp.SetHandler(new (request) => Handle(request));
		mHttp.SetStreamHandler(new (request, stream) =>
			{
				// Confirmed immediately: a client treats the first bytes as proof the stream
				// is live, and waits otherwise.
				stream.WriteComment("connected");
				stream.AddRef();
				mListeners.Add(stream);
			});
		return true;
	}

	public void Stop()
	{
		for (let listener in mListeners)
		{
			listener.Close();
			listener.ReleaseRef();
		}
		mListeners.Clear();
		mHttp.Stop();
	}

	/// One pump of the underlying server: accept, read, dispatch, write. Returns the requests
	/// completed this call, so a caller can sleep briefly on nought rather than spin.
	public int Pump()
	{
		let completed = mHttp.Pump();

		// Sweep listeners whose peer has gone. POLLED rather than inferred from the last
		// write, for the reason SseStream.PollLive gives.
		for (int i = 0; i < mListeners.Count;)
		{
			if (mListeners[i].PollLive())
			{
				i++;
				continue;
			}
			mListeners[i].ReleaseRef();
			mListeners.RemoveAt(i);
		}
		return completed;
	}

	/// Sends one event to every connected listener, returning how many received it. A stream
	/// whose write fails has lost its peer and is dropped.
	public int Broadcast(StringView eventName, StringView data)
	{
		var delivered = 0;
		for (int i = 0; i < mListeners.Count;)
		{
			if (mListeners[i].WriteEvent(eventName, data))
			{
				delivered++;
				i++;
				continue;
			}
			mListeners[i].ReleaseRef();
			mListeners.RemoveAt(i);
		}
		return delivered;
	}

	// ---- Handling ----------------------------------------------------------------------------

	private HttpResponse Handle(HttpRequest request)
	{
		// Checked FIRST, and on every route: an unauthorised caller learns nothing about what
		// the host serves.
		if (!Authorized(request))
			return HttpResponse.Json(401, "{\"error\":\"missing or invalid bearer token\"}");

		if (request.Target == "/mcp")
		{
			if (request.Method != "POST")
				return HttpResponse.Json(405,
					"{\"error\":\"POST one JSON-RPC message per request\"}");

			let line = scope String();
			switch (mServer.HandleLine(request.BodyText, line))
			{
			case .Notification:
				// Accepted, with nothing to say.
				let accepted = new HttpResponse();
				accepted.Status = 202;
				return accepted;
			case .NotFinished:
				// The tool asked to be re-entered: NOT YET, so the request waits on its
				// connection and comes back through here on the next Pump.
				return null;
			case .Answered:
			}
			return HttpResponse.Json(200, line);
		}

		if (request.Target == "/events")
		{
			if (request.Method != "GET")
				return HttpResponse.Json(405, "{\"error\":\"GET opens the event stream\"}");
			return HttpResponse.EventStreamResponse();
		}

		return HttpResponse.Json(404,
			"{\"error\":\"unknown endpoint - POST /mcp or GET /events\"}");
	}

	private bool Authorized(HttpRequest request)
	{
		let authorization = request.Header("Authorization");
		let prefix = "Bearer ";
		if (!authorization.StartsWith(prefix))
			return false;
		return authorization.Substring(prefix.Length) == mToken;
	}
}
