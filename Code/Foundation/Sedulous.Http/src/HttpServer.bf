using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;

namespace Sedulous.Http;

/// The pump model HTTP server.
///
/// Each Pump accepts what is pending, reads, and for every COMPLETE request calls the handler
/// and writes the response with Connection: close. Two exceptions to answer and close: an
/// event stream response writes the stream headers and hands the connection over, and a
/// handler that answers NOT YET (null) keeps the request pending on its connection and is
/// asked again with the same request on every Pump until it answers - a handler that must
/// let its host make progress, an MCP tool waiting on a background cook say. A peer that
/// leaves while waiting is dropped. Malformed input gets a 400 and a close; no handler gets a
/// 404.
///
/// SINGLE THREADED: Start, Pump and Stop from ONE thread. Pump it from a dedicated thread or
/// from a frame loop.
class HttpServer
{
	/// How many one millisecond waits a partial write will tolerate. See SseStream.
	private const int cSendPatience = 2000;
	private const int cReadChunk = 4096;

	/// One accepted connection and the parse in progress on it.
	private class Connection
	{
		public TcpSocket Socket ~ delete _;
		public HttpMessageParser Parser ~ delete _;
		/// The parsed request, valid while Pending.
		public HttpRequest Request ~ delete _;
		/// A complete request awaits its answer, not yet given.
		public bool Pending = false;

		public this(TcpSocket socket, int maxBodyBytes)
		{
			Socket = socket;
			Parser = new .(.Request, maxBodyBytes);
		}
	}

	/// The request handler: a one shot response, the EventStream marker, or NOT YET (null).
	/// Not yet keeps the request pending on its connection, and the handler sees it again on
	/// the next Pump. A handler that waits this way keeps its own progress state and its own
	/// timeout: a server that stops pumping and a handler that never answers look the same
	/// to the peer. THE SERVER OWNS a returned response.
	public typealias RequestHandler = delegate HttpResponse(HttpRequest request);
	public typealias StreamHandler = delegate void(HttpRequest request, SseStream stream);

	private HttpServerConfig mConfig = .();
	private TcpListener mListener ~ delete _;
	private List<Connection> mConnections = new .() ~ DeleteContainerAndItems!(_);
	/// The server's own references. Released when a stream's peer goes or the server stops.
	private List<SseStream> mStreams = new .() ~ ReleaseStreams(_);
	private RequestHandler mHandler ~ delete _;
	private StreamHandler mStreamHandler ~ delete _;

	public ~this()
	{
		Stop();
	}

	private static void ReleaseStreams(List<SseStream> streams)
	{
		for (let stream in streams)
			stream.ReleaseRef();
		delete streams;
	}

	public bool Start(HttpServerConfig config)
	{
		Stop();
		mConfig = config;

		mListener = new .(config.Port);
		if (!mListener.IsOpen)
		{
			delete mListener;
			mListener = null;
			return false;
		}
		return true;
	}

	public void Stop()
	{
		ClearAndDeleteItems!(mConnections);

		// Closed AND released: the consumer's reference stays valid and its writes turn into
		// no-ops, which is what lets a consumer outlive the server without checking.
		for (let stream in mStreams)
		{
			stream.Close();
			stream.ReleaseRef();
		}
		mStreams.Clear();

		delete mListener;
		mListener = null;
	}

	public bool IsRunning => mListener != null;
	public uint16 BoundPort => (mListener != null) ? mListener.BoundPort : 0;

	/// The request handler, for one-shot responses and for the event stream marker. Ownership
	/// transfers; setting a second one deletes the first.
	public void SetHandler(RequestHandler handler)
	{
		delete mHandler;
		mHandler = handler;
	}

	/// Called when a handler answered with the event stream marker. The consumer takes its own
	/// reference by calling AddRef, and writes for as long as it likes.
	public void SetStreamHandler(StreamHandler handler)
	{
		delete mStreamHandler;
		mStreamHandler = handler;
	}

	/// One pump: accept, read, dispatch, write. Returns how many requests were ANSWERED, so a
	/// caller can sleep briefly on nought rather than spinning. A request answered not yet
	/// counts when it is finally answered, not on the pumps it waits.
	public int Pump()
	{
		if (mListener == null)
			return 0;

		AcceptPending();
		let completed = ServiceConnections();
		SweepStreams();
		return completed;
	}

	/// Requests whose handler answered not yet and that are still waiting. A host whose loop
	/// sleeps when idle must keep pumping while this is non zero.
	public int PendingRequestCount
	{
		get
		{
			var pending = 0;
			for (let connection in mConnections)
			{
				if (connection.Pending)
					pending++;
			}
			return pending;
		}
	}

	private void AcceptPending()
	{
		for (;;)
		{
			let accepted = mListener.Accept();
			if (accepted == null)
				break;

			// Past the cap the socket is simply dropped, which closes it: a refusal the peer
			// sees immediately rather than a queue that grows without bound.
			if (mConnections.Count >= mConfig.MaxConnections)
			{
				delete accepted;
				continue;
			}
			mConnections.Add(new Connection(accepted, mConfig.MaxBodyBytes));
		}
	}

	private int ServiceConnections()
	{
		var completed = 0;
		let buffer = scope uint8[cReadChunk];

		for (int i = 0; i < mConnections.Count;)
		{
			let connection = mConnections[i];
			var done = false;

			if (connection.Pending)
			{
				// A request answered not yet. The peer has nothing more to say on a one shot
				// connection, so the read only probes whether it is still there; then the
				// handler is asked again.
				if (connection.Socket.Receive(buffer) < 0)
				{
					done = true; // the peer left while waiting, so there is nobody to answer
				}
				else if (Dispatch(connection))
				{
					completed++;
					done = true;
				}
			}
			else for (;;)
			{
				let n = connection.Socket.Receive(buffer);
				if (n > 0)
				{
					let state = connection.Parser.Push(.(&buffer[0], (int)n));
					if (state == .Complete)
					{
						TakeRequest(connection);
						if (Dispatch(connection))
						{
							completed++;
							done = true;
						}
						break;
					}
					if (state == .Failed)
					{
						let response = HttpResponse.Text(400, "text/plain",
							"malformed HTTP request");
						defer delete response;
						WriteResponse(connection.Socket, response);
						done = true;
						break;
					}
					continue;
				}
				// Would block: keep the connection and try again next pump.
				if (n == 0)
					break;
				// The peer closed before finishing a request.
				done = true;
				break;
			}

			if (done)
			{
				delete connection;
				mConnections.RemoveAt(i);
			}
			else
			{
				i++;
			}
		}
		return completed;
	}

	/// Drops streams whose peer has gone. POLLED rather than inferred from the last write,
	/// for the reason SseStream.PollLive explains.
	private void SweepStreams()
	{
		for (int i = 0; i < mStreams.Count;)
		{
			if (!mStreams[i].PollLive())
			{
				mStreams[i].ReleaseRef();
				mStreams.RemoveAt(i);
			}
			else
			{
				i++;
			}
		}
	}

	/// Moves the parser's complete request onto the connection, where it stays while the
	/// handler answers not yet.
	private static void TakeRequest(Connection connection)
	{
		let request = new HttpRequest();
		request.Method.Set(connection.Parser.Method);
		request.Target.Set(connection.Parser.Target);
		for (let header in connection.Parser.Headers)
			request.Headers.Add(new HttpHeader(header.Name, header.Value));
		request.Body.AddRange(Span<uint8>(connection.Parser.Body.Ptr, connection.Parser.Body.Count));
		delete connection.Request;
		connection.Request = request;
		connection.Pending = true;
	}

	/// Hands the connection's pending request to the handler. True when it was answered, or
	/// handed to a stream, and the connection is finished with; false when the handler
	/// answered not yet and the request stays pending.
	private bool Dispatch(Connection connection)
	{
		let request = connection.Request;
		let response = (mHandler != null)
			? mHandler(request)
			: HttpResponse.Text(404, "text/plain", "no handler registered");
		if (response == null)
			return false; // not yet: the handler sees the same request next Pump
		defer delete response;
		connection.Pending = false;

		if (!response.EventStream)
		{
			WriteResponse(connection.Socket, response);
			return true;
		}

		let head = scope String();
		head.Append("HTTP/1.1 200 OK\r\n");
		head.Append("Content-Type: text/event-stream\r\n");
		head.Append("Cache-Control: no-store\r\n");
		head.Append("Connection: close\r\n\r\n");

		let sent = connection.Socket.Send(.((uint8*)head.Ptr, head.Length));
		if (sent != (int64)head.Length)
			return true;

		// The connection is handed to the stream, so the Connection must not delete it.
		let stream = new SseStream(connection.Socket);
		connection.[Friend]Socket = null;
		mStreams.Add(stream);

		if (mStreamHandler != null)
		{
			// The handler takes its own reference if it keeps the stream.
			mStreamHandler(request, stream);
		}
		return true;
	}

	/// Writes the status line, the handler's headers, the framing headers and the body.
	private static void WriteResponse(TcpSocket socket, HttpResponse response)
	{
		let head = scope String();
		head.AppendF("HTTP/1.1 {} {}\r\n", response.Status, HttpStatus.Text(response.Status));
		for (let header in response.Headers)
			head.AppendF("{}: {}\r\n", header.Name, header.Value);
		// Written HERE and not by the handler: the length has to match the body actually
		// sent, and this is the only place that knows both.
		head.AppendF("Content-Length: {}\r\n", response.Body.Count);
		head.Append("Connection: close\r\n\r\n");

		let wire = scope List<uint8>();
		wire.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
		wire.AddRange(Span<uint8>(response.Body.Ptr, response.Body.Count));

		var sent = 0;
		var patience = cSendPatience;
		while (sent < wire.Count)
		{
			let n = socket.Send(.(wire.Ptr + sent, wire.Count - sent));
			if (n < 0)
				return;
			if (n == 0)
			{
				patience--;
				if (patience <= 0)
					return;
				Thread.Sleep(1);
				continue;
			}
			sent += (int)n;
		}
	}
}
