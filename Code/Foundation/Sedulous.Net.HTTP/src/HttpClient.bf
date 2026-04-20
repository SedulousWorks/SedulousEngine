namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Net;

/// Simple HTTP/1.1 client. Sends a request and returns a response.
/// Note: No TLS/SSL support - HTTP only.
public class HttpClient
{
	private int mTimeoutMs = 30000;

	public int TimeoutMs { get => mTimeoutMs; set { mTimeoutMs = value; } }

	/// Send an HTTP request to the specified host and port.
	public Result<HttpResponse, NetError> Send(StringView host, uint16 port, HttpRequest request)
	{
		// Set Host header if not present
		if (!request.Headers.Contains("Host"))
		{
			let hostHeader = scope String();
			hostHeader.Append(host);
			if (port != 80)
			{
				hostHeader.Append(':');
				port.ToString(hostHeader);
			}
			request.SetHeader("Host", hostHeader);
		}

		// Connect
		let client = scope TcpClient();
		if (client.Connect(host, port) case .Err(let err))
			return .Err(err);

		// Serialize request
		let wireData = scope String();
		request.WriteTo(wireData);

		// Send
		if (client.SendAll(Span<uint8>((uint8*)wireData.Ptr, wireData.Length)) case .Err(let sendErr))
		{
			client.Close();
			return .Err(sendErr);
		}

		// Receive response
		let parser = scope HttpParser();
		uint8[4096] recvBuf = default;
		int elapsed = 0;

		while (elapsed < mTimeoutMs)
		{
			switch (client.Recv(Span<uint8>(&recvBuf, 4096)))
			{
			case .Ok(let received):
				if (received == 0)
				{
					// Connection closed - try to parse what we have
					if (parser.TryParseResponse() case .Ok(let response))
					{
						client.Close();
						return .Ok(response);
					}
					client.Close();
					return .Err(.ConnectionClosed);
				}
				parser.Feed(Span<uint8>(&recvBuf, received));

				switch (parser.TryParseResponse())
				{
				case .Ok(let response):
					client.Close();
					return .Ok(response);
				case .Err:
					continue; // Need more data
				}
			case .Err(.WouldBlock):
				System.Threading.Thread.Sleep(10);
				elapsed += 10;
			case .Err(.ConnectionClosed):
				// Server closed after sending - try to parse buffered data
				if (parser.TryParseResponse() case .Ok(let response))
				{
					client.Close();
					return .Ok(response);
				}
				client.Close();
				return .Err(.ConnectionClosed);
			case .Err(let recvErr):
				client.Close();
				return .Err(recvErr);
			}
		}

		client.Close();
		return .Err(.TimedOut);
	}

	/// Convenience: GET request.
	public Result<HttpResponse, NetError> Get(StringView host, uint16 port, StringView path)
	{
		let request = scope HttpRequest(.GET, path);
		return Send(host, port, request);
	}

	/// Convenience: POST request with body.
	public Result<HttpResponse, NetError> Post(StringView host, uint16 port, StringView path, StringView body, StringView contentType = "application/octet-stream")
	{
		let request = scope HttpRequest(.POST, path);
		request.SetBody(body);
		request.Headers.SetContentType(contentType);
		return Send(host, port, request);
	}

	/// Convenience: PUT request with body.
	public Result<HttpResponse, NetError> Put(StringView host, uint16 port, StringView path, StringView body, StringView contentType = "application/octet-stream")
	{
		let request = scope HttpRequest(.PUT, path);
		request.SetBody(body);
		request.Headers.SetContentType(contentType);
		return Send(host, port, request);
	}

	/// Convenience: DELETE request.
	public Result<HttpResponse, NetError> Delete(StringView host, uint16 port, StringView path)
	{
		let request = scope HttpRequest(.DELETE, path);
		return Send(host, port, request);
	}

	/// Parse a URL into host, port, and path components.
	/// Only supports http:// URLs.
	public static Result<void> ParseUrl(StringView url, String outHost, out uint16 outPort, String outPath)
	{
		outPort = 80;

		var remaining = url;
		if (remaining.StartsWith("http://"))
			remaining = StringView(remaining, 7);
		else
			return .Err;

		// Find path separator
		let pathIdx = remaining.IndexOf('/');
		var hostPart = (pathIdx >= 0) ? StringView(remaining, 0, pathIdx) : remaining;

		if (pathIdx >= 0)
			outPath.Set(StringView(remaining, pathIdx));
		else
			outPath.Set("/");

		// Check for port
		let colonIdx = hostPart.IndexOf(':');
		if (colonIdx >= 0)
		{
			outHost.Set(StringView(hostPart, 0, colonIdx));
			let portStr = StringView(hostPart, colonIdx + 1);
			if (uint16.Parse(portStr) case .Ok(let p))
				outPort = p;
			else
				return .Err;
		}
		else
		{
			outHost.Set(hostPart);
		}

		return .Ok;
	}
}
