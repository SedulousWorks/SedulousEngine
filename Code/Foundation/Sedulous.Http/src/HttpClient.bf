using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Net;

namespace Sedulous.Http;

/// A blocking one-shot HTTP client, for tests, local tooling and the acceptance loop.
///
/// NOT a game-facing fetch API: it blocks the calling thread, it speaks no TLS, and it is
/// aimed at localhost. The timeout is spent across the WHOLE exchange, so a peer that
/// dribbles bytes cannot hold the caller past its budget.
static class HttpClient
{
	private const int cReadChunk = 4096;

	/// Sends a request and reads the whole response.
	///
	/// The address may be a host name or a dotted quad. On failure the error is a human
	/// readable reason, owned by the caller.
	public static Result<HttpResponse, String> Fetch(StringView address, uint16 port,
		HttpRequest request, uint32 timeoutMilliseconds = 5000)
	{
		let socket = TcpSocket.Connect(address, port);
		defer delete socket;

		if (!socket.IsOpen)
			return .Err(new $"could not open a socket to {address}:{port}");

		// One budget for the whole exchange: connect, send and read all draw from it.
		var budget = (int)timeoutMilliseconds;

		if (WaitForConnect(socket, ref budget) case .Err(let reason))
			return .Err(new $"connect to {address}:{port} {reason}");

		if (SendRequest(socket, address, request, ref budget) case .Err(let sendError))
			return .Err(sendError);

		return ReadResponse(socket, ref budget);
	}

	private static Result<void, String> WaitForConnect(TcpSocket socket, ref int budget)
	{
		for (;;)
		{
			let status = socket.ConnectStatus;
			if (status > 0)
				return .Ok;
			if (status < 0)
				return .Err("failed");

			budget--;
			if (budget <= 0)
				return .Err("timed out");
			Thread.Sleep(1);
		}
	}

	private static Result<void, String> SendRequest(TcpSocket socket, StringView address,
		HttpRequest request, ref int budget)
	{
		let head = scope String();
		head.Append(request.Method.IsEmpty ? "GET" : StringView(request.Method));
		head.Append(' ');
		head.Append(request.Target.IsEmpty ? "/" : StringView(request.Target));
		head.Append(" HTTP/1.1\r\nHost: ");
		head.Append(address);
		head.Append("\r\n");
		for (let header in request.Headers)
			head.AppendF("{}: {}\r\n", header.Name, header.Value);
		head.AppendF("Content-Length: {}\r\n", request.Body.Count);
		// One request per connection, said explicitly so the server frames its reply the same
		// way and the read ends at the close.
		head.Append("Connection: close\r\n\r\n");

		let wire = scope List<uint8>();
		wire.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
		wire.AddRange(request.Body);

		var sent = 0;
		while (sent < wire.Count)
		{
			let n = socket.Send(.(wire.Ptr + sent, wire.Count - sent));
			if (n < 0)
				return .Err(new $"connection closed while sending the request");
			if (n == 0)
			{
				budget--;
				if (budget <= 0)
					return .Err(new $"request send timed out");
				Thread.Sleep(1);
				continue;
			}
			sent += (int)n;
		}
		return .Ok;
	}

	private static Result<HttpResponse, String> ReadResponse(TcpSocket socket, ref int budget)
	{
		let parser = scope HttpMessageParser(.Response);
		let buffer = scope uint8[cReadChunk];

		for (;;)
		{
			let n = socket.Receive(buffer);
			if (n > 0)
			{
				let state = parser.Push(.(&buffer[0], (int)n));
				if (state == .Complete)
					break;
				if (state == .Failed)
					return .Err(new $"malformed HTTP response");
				continue;
			}
			if (n == 0)
			{
				budget--;
				if (budget <= 0)
					return .Err(new $"response read timed out");
				Thread.Sleep(1);
				continue;
			}
			// The peer closed. That completes a close-delimited body and truncates anything
			// else.
			if (parser.OnPeerClosed() == .Complete)
				break;
			return .Err(new $"connection closed mid-response");
		}

		let response = new HttpResponse();
		response.Status = parser.Status;
		for (let header in parser.Headers)
			response.Headers.Add(new HttpHeader(header.Name, header.Value));
		response.Body.AddRange(parser.Body);
		return .Ok(response);
	}
}
