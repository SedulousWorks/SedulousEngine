namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Net;

/// Simple HTTP/1.1 server.
/// Call Update() from your game loop to process pending connections without blocking.
public class HttpServer
{
	/// Delegate called when a WebSocket upgrade request is received.
	/// Return true to accept the upgrade, false to reject.
	public delegate bool WebSocketUpgradeHandler(TcpClient client, HttpRequest request);

	private TcpListener mListener = new .() ~ delete _;
	private List<HttpRoute> mRoutes = new .() ~ DeleteContainerAndItems!(_);
	private bool mRunning;
	public WebSocketUpgradeHandler OnWebSocketUpgrade ~ delete _;

	public bool IsRunning => mRunning;

	/// Register a route handler.
	public void Route(HttpMethod method, StringView path, HttpHandler handler)
	{
		mRoutes.Add(new HttpRoute(method, path, handler));
	}

	/// Convenience route methods.
	public void Get(StringView path, HttpHandler handler) => Route(.GET, path, handler);
	public void Post(StringView path, HttpHandler handler) => Route(.POST, path, handler);
	public void Put(StringView path, HttpHandler handler) => Route(.PUT, path, handler);
	public void Delete(StringView path, HttpHandler handler) => Route(.DELETE, path, handler);

	/// Start listening on the given port.
	public Result<void, NetError> Start(uint16 port)
	{
		if (mRunning)
			return .Err(.InvalidState);

		if (mListener.Start(port) case .Err(let err))
			return .Err(err);

		mRunning = true;
		return .Ok;
	}

	/// Start listening on a specific endpoint.
	public Result<void, NetError> Start(IPEndPoint endPoint)
	{
		if (mRunning)
			return .Err(.InvalidState);

		if (mListener.Start(endPoint) case .Err(let err))
			return .Err(err);

		mRunning = true;
		return .Ok;
	}

	/// Process one pending connection (non-blocking, game-loop friendly).
	/// Call this each frame or on a regular interval.
	public void Update()
	{
		if (!mRunning) return;

		switch (mListener.Accept())
		{
		case .Ok(let client):
			let takenOver = HandleClient(client);
			if (!takenOver)
				delete client;
		case .Err(.WouldBlock):
			// No pending connections - normal
		case .Err:
			// Ignore other errors
		}
	}

	/// Stop the server.
	public void Stop()
	{
		mListener.Stop();
		mRunning = false;
	}

	public uint16 Port => mListener.LocalEndPoint.Port;

	/// Returns true if the client was taken over (e.g. WebSocket upgrade) and should not be deleted.
	private bool HandleClient(TcpClient client)
	{
		// Read the request with timeout
		let parser = scope HttpParser();
		uint8[4096] recvBuf = default;
		int elapsed = 0;
		let timeoutMs = 5000;

		while (elapsed < timeoutMs)
		{
			switch (client.Recv(Span<uint8>(&recvBuf, 4096)))
			{
			case .Ok(let received):
				if (received == 0)
					return false; // Client disconnected
				parser.Feed(Span<uint8>(&recvBuf, received));

				switch (parser.TryParseRequest())
				{
				case .Ok(let request):
					// Check for WebSocket upgrade
					let upgradeHeader = scope String();
					if (request.Headers.Get("Upgrade", upgradeHeader) && StringView.Compare(upgradeHeader, "websocket", true) == 0)
					{
						if (OnWebSocketUpgrade != null && OnWebSocketUpgrade(client, request))
						{
							delete request;
							return true; // WebSocket handler takes over the connection
						}
					}

					ProcessRequest(client, request);
					delete request;
					return false;
				case .Err:
					continue; // Need more data
				}
			case .Err(.WouldBlock):
				System.Threading.Thread.Sleep(10);
				elapsed += 10;
			case .Err:
				return false; // Error reading
			}
		}
		return false;
	}

	private void ProcessRequest(TcpClient client, HttpRequest request)
	{
		let response = scope HttpResponse();
		response.Version.Set("HTTP/1.1");

		// Find matching route
		var handled = false;
		for (let route in mRoutes)
		{
			if (route.Matches(request.Method, request.Path))
			{
				response.StatusCode = .OK;
				response.ReasonPhrase.Set("OK");
				route.Handler(request, response);
				handled = true;
				break;
			}
		}

		if (!handled)
		{
			response.StatusCode = .NotFound;
			response.ReasonPhrase.Set("Not Found");
			response.SetBody("404 Not Found");
			response.Headers.SetContentType("text/plain");
		}

		// Ensure Content-Length is set
		if (response.Headers.ContentLength < 0 && response.Body.Count > 0)
			response.Headers.ContentLength = response.Body.Count;

		// Set Connection: close
		response.SetHeader("Connection", "close");

		// Send response
		let wireData = scope String();
		response.WriteTo(wireData);
		client.SendAll(Span<uint8>((uint8*)wireData.Ptr, wireData.Length));
	}
}
