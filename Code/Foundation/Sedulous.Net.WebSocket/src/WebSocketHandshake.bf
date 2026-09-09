using System;
using System.Collections;
using Sedulous.Http;

namespace Sedulous.Net.WebSocket;

/// The upgrade handshake: validation, the accept value, and the two responses.
static class WebSocketHandshake
{
	/// Fixed by RFC 6455 and concatenated to the client's key VERBATIM, with no decoding.
	/// Its only job is to make the answer specific to this protocol.
	private const String cMagicGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

	/// The Sec-WebSocket-Accept value for a client's Sec-WebSocket-Key.
	public static void ComputeAccept(StringView clientKey, String outAccept)
	{
		let input = scope List<uint8>();
		input.AddRange(Span<uint8>((uint8*)clientKey.Ptr, clientKey.Length));
		input.AddRange(Span<uint8>((uint8*)cMagicGuid.Ptr, cMagicGuid.Length));

		let digest = scope uint8[Sha1.DigestBytes];
		Sha1.Compute(input, digest);
		Base64.Encode(digest, outAccept);
	}

	/// Whether a COMPLETE parsed request is a valid upgrade, filling outKey with the client's
	/// key.
	///
	/// Every condition is required by the RFC, and a request failing any of them is answered
	/// with a plain 400 rather than upgraded.
	public static bool Validate(HttpMessageParser request, String outKey)
	{
		if ((request.State != .Complete) || (request.Method != "GET"))
			return false;

		let upgrade = HttpHeader.Find(request.Headers, "Upgrade");
		let connection = HttpHeader.Find(request.Headers, "Connection");
		let version = HttpHeader.Find(request.Headers, "Sec-WebSocket-Version");
		let key = HttpHeader.Find(request.Headers, "Sec-WebSocket-Key");

		// Connection is a comma separated list, so the Upgrade token is searched for rather
		// than compared: a browser may well send "keep-alive, Upgrade".
		if (!ContainsTokenNoCase(upgrade, "websocket")
			|| !ContainsTokenNoCase(connection, "upgrade") || (version != "13") || key.IsEmpty)
			return false;

		outKey.Set(key);
		return true;
	}

	/// The 101 response that completes an upgrade.
	public static void BuildUpgradeResponse(StringView clientKey, List<uint8> outBytes)
	{
		let head = scope String();
		head.Append("HTTP/1.1 101 Switching Protocols\r\n");
		head.Append("Upgrade: websocket\r\n");
		head.Append("Connection: Upgrade\r\n");
		head.Append("Sec-WebSocket-Accept: ");
		ComputeAccept(clientKey, head);
		head.Append("\r\n\r\n");
		outBytes.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
	}

	/// The 400 for anything that is not a valid upgrade.
	public static void BuildRejectResponse(List<uint8> outBytes)
	{
		let head = scope String();
		head.Append("HTTP/1.1 400 Bad Request\r\n");
		head.Append("Connection: close\r\n");
		head.Append("Content-Length: 0\r\n\r\n");
		outBytes.AddRange(Span<uint8>((uint8*)head.Ptr, head.Length));
	}

	/// Whether a header value contains a token, comparing ASCII case insensitively.
	private static bool ContainsTokenNoCase(StringView haystack, StringView token)
	{
		if (token.IsEmpty || (haystack.Length < token.Length))
			return false;

		for (int i = 0; (i + token.Length) <= haystack.Length; i++)
		{
			var match = true;
			for (int j = 0; j < token.Length; j++)
			{
				if (Lower(haystack[i + j]) != Lower(token[j]))
				{
					match = false;
					break;
				}
			}
			if (match)
				return true;
		}
		return false;
	}

	private static char8 Lower(char8 c) =>
		((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c;
}
