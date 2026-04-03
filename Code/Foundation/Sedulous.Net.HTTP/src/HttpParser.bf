namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Net;

/// Incremental HTTP parser that can handle partial TCP data.
public class HttpParser
{
	enum State
	{
		case ReadingHeaders;
		case ReadingBody;
		case ReadingChunkedBody;
		case Complete;
	}

	private String mBuffer = new .() ~ delete _;
	private State mState = .ReadingHeaders;
	private int64 mContentLength = -1;
	private bool mChunked;
	private int mHeaderEndOffset;

	public void Reset()
	{
		mBuffer.Clear();
		mState = .ReadingHeaders;
		mContentLength = -1;
		mChunked = false;
		mHeaderEndOffset = 0;
	}

	/// Feed data to the parser.
	public void Feed(Span<uint8> data)
	{
		mBuffer.Append((char8*)data.Ptr, data.Length);
	}

	/// Feed string data to the parser.
	public void Feed(StringView data)
	{
		mBuffer.Append(data);
	}

	/// Try to parse a complete HTTP response from the buffer.
	/// Returns .Ok if complete, .Err if more data needed.
	public Result<HttpResponse> TryParseResponse()
	{
		if (mState == .ReadingHeaders)
		{
			let headerEnd = mBuffer.IndexOf("\r\n\r\n");
			if (headerEnd == -1)
				return .Err; // Need more data

			mHeaderEndOffset = headerEnd + 4;
			mState = .ReadingBody;
		}

		let response = new HttpResponse();
		let headerSection = StringView(mBuffer, 0, mHeaderEndOffset - 4);

		// Parse status line
		if (ParseStatusLine(headerSection, response) case .Err)
		{
			delete response;
			return .Err;
		}

		// Parse headers
		ParseHeaders(headerSection, response.Headers);

		// Determine body handling
		let transferEncoding = scope String();
		if (response.Headers.Get("Transfer-Encoding", transferEncoding) && transferEncoding.Contains("chunked"))
		{
			mChunked = true;
			mState = .ReadingChunkedBody;
		}
		else
		{
			mContentLength = response.Headers.ContentLength;
		}

		// Read body
		let bodyData = StringView(mBuffer, mHeaderEndOffset);
		if (mChunked)
		{
			if (ParseChunkedBody(bodyData, response.Body) case .Err)
			{
				delete response;
				return .Err; // Need more data
			}
		}
		else if (mContentLength > 0)
		{
			if (bodyData.Length < mContentLength)
			{
				delete response;
				return .Err; // Need more data
			}
			response.Body.AddRange(Span<uint8>((uint8*)bodyData.Ptr, (int)mContentLength));
		}

		mState = .Complete;
		return .Ok(response);
	}

	/// Try to parse a complete HTTP request from the buffer.
	public Result<HttpRequest> TryParseRequest()
	{
		if (mState == .ReadingHeaders)
		{
			let headerEnd = mBuffer.IndexOf("\r\n\r\n");
			if (headerEnd == -1)
				return .Err; // Need more data

			mHeaderEndOffset = headerEnd + 4;
			mState = .ReadingBody;
		}

		let request = new HttpRequest();
		let headerSection = StringView(mBuffer, 0, mHeaderEndOffset - 4);

		// Parse request line
		if (ParseRequestLine(headerSection, request) case .Err)
		{
			delete request;
			return .Err;
		}

		// Parse headers
		ParseHeaders(headerSection, request.Headers);

		// Read body
		mContentLength = request.Headers.ContentLength;
		let bodyData = StringView(mBuffer, mHeaderEndOffset);
		if (mContentLength > 0)
		{
			if (bodyData.Length < mContentLength)
			{
				delete request;
				return .Err; // Need more data
			}
			request.Body.AddRange(Span<uint8>((uint8*)bodyData.Ptr, (int)mContentLength));
		}

		mState = .Complete;
		return .Ok(request);
	}

	private static Result<void> ParseStatusLine(StringView headerSection, HttpResponse response)
	{
		let firstLineEnd = headerSection.IndexOf("\r\n");
		let firstLine = (firstLineEnd >= 0) ? StringView(headerSection, 0, firstLineEnd) : headerSection;

		// "HTTP/1.1 200 OK"
		let spaceIdx1 = firstLine.IndexOf(' ');
		if (spaceIdx1 < 0) return .Err;

		response.Version.Set(StringView(firstLine, 0, spaceIdx1));

		let rest1 = StringView(firstLine, spaceIdx1 + 1);
		let spaceIdx2 = rest1.IndexOf(' ');
		if (spaceIdx2 < 0) return .Err;

		let statusStr = StringView(rest1, 0, spaceIdx2);
		if (int32.Parse(statusStr) case .Ok(let code))
			response.StatusCode = (HttpStatusCode)code;
		else
			return .Err;

		response.ReasonPhrase.Set(StringView(rest1, spaceIdx2 + 1));
		return .Ok;
	}

	private static Result<void> ParseRequestLine(StringView headerSection, HttpRequest request)
	{
		let firstLineEnd = headerSection.IndexOf("\r\n");
		let firstLine = (firstLineEnd >= 0) ? StringView(headerSection, 0, firstLineEnd) : headerSection;

		// "GET /path HTTP/1.1"
		let spaceIdx1 = firstLine.IndexOf(' ');
		if (spaceIdx1 < 0) return .Err;

		let methodStr = StringView(firstLine, 0, spaceIdx1);
		if (HttpMethod.Parse(methodStr) case .Ok(let method))
			request.Method = method;
		else
			return .Err;

		let rest1 = StringView(firstLine, spaceIdx1 + 1);
		let spaceIdx2 = rest1.IndexOf(' ');
		if (spaceIdx2 < 0) return .Err;

		request.Path.Set(StringView(rest1, 0, spaceIdx2));
		request.Version.Set(StringView(rest1, spaceIdx2 + 1));
		return .Ok;
	}

	private static void ParseHeaders(StringView headerSection, HttpHeaders headers)
	{
		let firstLineEnd = headerSection.IndexOf("\r\n");
		if (firstLineEnd < 0) return;

		var remaining = StringView(headerSection, firstLineEnd + 2);
		while (remaining.Length > 0)
		{
			let lineEnd = remaining.IndexOf("\r\n");
			let line = (lineEnd >= 0) ? StringView(remaining, 0, lineEnd) : remaining;

			if (line.Length > 0)
			{
				let colonIdx = line.IndexOf(':');
				if (colonIdx > 0)
				{
					var name = StringView(line, 0, colonIdx);
					var value = StringView(line, colonIdx + 1);
					name.Trim();
					value.Trim();
					headers.Add(name, value);
				}
			}

			if (lineEnd < 0) break;
			remaining = StringView(remaining, lineEnd + 2);
		}
	}

	private static Result<void> ParseChunkedBody(StringView data, List<uint8> body)
	{
		var remaining = data;
		while (true)
		{
			let lineEnd = remaining.IndexOf("\r\n");
			if (lineEnd < 0)
				return .Err; // Need more data

			var sizeStr = StringView(remaining, 0, lineEnd);
			sizeStr.Trim();
			var chunkSize = int(0);

			// Parse hex chunk size
			for (int i = 0; i < sizeStr.Length; i++)
			{
				let c = sizeStr[i];
				if (c >= '0' && c <= '9')
					chunkSize = chunkSize * 16 + (int)(c - '0');
				else if (c >= 'a' && c <= 'f')
					chunkSize = chunkSize * 16 + 10 + (int)(c - 'a');
				else if (c >= 'A' && c <= 'F')
					chunkSize = chunkSize * 16 + 10 + (int)(c - 'A');
				else
					return .Err;
			}

			if (chunkSize == 0)
				return .Ok; // End of chunks

			remaining = StringView(remaining, lineEnd + 2);
			if (remaining.Length < chunkSize + 2) // +2 for trailing \r\n
				return .Err; // Need more data

			body.AddRange(Span<uint8>((uint8*)remaining.Ptr, chunkSize));
			remaining = StringView(remaining, chunkSize + 2);
		}
	}
}
