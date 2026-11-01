using System;
using System.Collections;

namespace Sedulous.Http;

/// An incremental HTTP/1.1 parser, for a request or a response.
///
/// Push bytes as they arrive; once Complete, the pieces are readable. A STRICT SUBSET: CRLF
/// framing, a capped head, and a caller-set body cap. A request's body is Content-Length only:
/// a chunked request fails rather than being half supported (the server's contract), because a
/// wrong body boundary is worse than a refusal. A response's body is Content-Length, chunked
/// (what real servers send, which the client reads), or read UNTIL THE PEER CLOSES, which is
/// what the connection-close model leaves as the only other framing. A response that carries no
/// body (204, 304, 1xx, or one to a HEAD: SetNoBody) is Complete at its head.
class HttpMessageParser
{
	/// The head cap. Sixteen kibibytes is far past any legitimate request line and header
	/// block, and bounds what an unauthenticated peer can make us buffer.
	private const int cMaxHeadBytes = 16 * 1024;

	private HttpMessageMode mMode;
	private int mMaxBody;
	private HttpParseState mState = .NeedMore;
	private bool mHeadParsed = false;
	private bool mBodyUntilClose = false;
	private int mBodyExpected = 0;
	private bool mNoBody = false;
	private bool mChunked = false;
	private bool mTooLarge = false;

	private enum Chunk : uint8
	{
		/// A chunk's size line next.
		Size,
		/// mChunkLeft bytes of data, then CRLF.
		Data,
		/// After the last (0) chunk: trailer lines to the blank one.
		Trailers,
	}
	private Chunk mChunk = .Size;
	private int mChunkLeft = 0;
	/// Encoded bytes not yet decoded.
	private List<uint8> mChunkRaw = new .() ~ delete _;

	/// Head accumulation. Emptied once the head is parsed; the body goes to mBody.
	private List<uint8> mBuffer = new .() ~ delete _;
	private String mMethod = new .() ~ delete _;
	private String mTarget = new .() ~ delete _;
	private int32 mStatus = 0;
	private List<HttpHeader> mHeaders = new .() ~ DeleteContainerAndItems!(_);
	private List<uint8> mBody = new .() ~ delete _;
	/// Body bytes TakeBody moved out.
	private int mBodyTaken = 0;

	public this(HttpMessageMode mode, int maxBodyBytes = 16 * 1024 * 1024)
	{
		mMode = mode;
		mMaxBody = maxBodyBytes;
	}

	public HttpParseState State => mState;
	/// Failed because the body is larger than the cap, not because it is malformed.
	public bool TooLarge => mTooLarge;

	/// Response mode: the request was a HEAD, so the response has headers alone.
	public void SetNoBody() => mNoBody = true;

	// Request mode.
	public StringView Method => mMethod;
	public StringView Target => mTarget;
	// Response mode.
	public int32 Status => mStatus;
	// Both.
	public List<HttpHeader> Headers => mHeaders;
	public List<uint8> Body => mBody;

	/// Response mode, to stream a body: moves the body decoded so far into `outBody` (replacing
	/// what it held), so the parser keeps none of it. Completion and the cap still count every
	/// byte, taken or not.
	public void TakeBody(List<uint8> outBody)
	{
		outBody.Clear();
		outBody.AddRange(mBody);
		mBodyTaken += mBody.Count;
		mBody.Clear();
	}

	/// Whether the head has been read (status and headers known).
	public bool HeadParsed => mHeadParsed;

	/// The body's length as its head gives it (Content-Length), or -1 when it does not (chunked,
	/// or read until the peer closes).
	public int64 BodyLength => (mHeadParsed && !mChunked && !mBodyUntilClose) ? (int64)mBodyExpected : -1;

	/// The body so far, taken or kept.
	private int BodySoFar => mBodyTaken + mBody.Count;

	/// Feeds bytes. The returned state is also what State reports afterwards.
	public HttpParseState Push(Span<uint8> bytes)
	{
		if (mState != .NeedMore)
			return mState;

		if (!mHeadParsed)
		{
			mBuffer.AddRange(bytes);
			if (mBuffer.Count > cMaxHeadBytes)
			{
				mState = .Failed;
				return mState;
			}

			let headEnd = FindHeadEnd();
			if (headEnd < 0)
				return mState;

			// Whatever followed the blank line is already body.
			let spill = scope List<uint8>();
			spill.AddRange(Span<uint8>(mBuffer.Ptr + headEnd, mBuffer.Count - headEnd));
			mBuffer.Count = headEnd;

			if (!ParseHead())
			{
				mState = .Failed;
				return mState;
			}
			mHeadParsed = true;
			mBuffer.Clear();
			if (mNoBody)
			{
				mState = .Complete;
				return mState;
			}
			(mChunked ? mChunkRaw : mBody).AddRange(Span<uint8>(spill.Ptr, spill.Count));
		}
		else
		{
			(mChunked ? mChunkRaw : mBody).AddRange(bytes);
		}

		if (mChunked)
			return DecodeChunks();

		if (BodySoFar > mMaxBody)
		{
			mTooLarge = true;
			mState = .Failed;
			return mState;
		}
		// Close delimited: there is no length to reach, so only the peer closing ends it.
		if (mBodyUntilClose)
			return mState;

		if (BodySoFar >= mBodyExpected)
		{
			// Drop any over-read. One request per connection means anything past the declared
			// length is not ours to interpret.
			mBody.Count = mBodyExpected - mBodyTaken;
			mState = .Complete;
		}
		return mState;
	}

	/// The peer closed. A close-delimited response body is now whole; anything else was cut
	/// off mid message.
	public HttpParseState OnPeerClosed()
	{
		if (mState != .NeedMore)
			return mState;

		mState = (mHeadParsed && mBodyUntilClose) ? .Complete : .Failed;
		return mState;
	}

	/// The offset just past the blank line ending the head, or minus one when it has not
	/// arrived yet.
	private int FindHeadEnd()
	{
		for (int i = 0; (i + 3) < mBuffer.Count; i++)
		{
			if ((mBuffer[i] == '\r') && (mBuffer[i + 1] == '\n') && (mBuffer[i + 2] == '\r')
				&& (mBuffer[i + 3] == '\n'))
				return i + 4;
		}
		return -1;
	}

	private bool ParseHead()
	{
		let head = StringView((char8*)mBuffer.Ptr, mBuffer.Count);
		var lineStart = 0;
		var firstLine = true;

		while (lineStart < head.Length)
		{
			var lineEnd = lineStart;
			while (((lineEnd + 1) < head.Length)
				&& !((head[lineEnd] == '\r') && (head[lineEnd + 1] == '\n')))
				lineEnd++;

			let line = head.Substring(lineStart, lineEnd - lineStart);
			lineStart = lineEnd + 2;

			// The blank line ends the head.
			if (line.IsEmpty)
				break;

			if (firstLine)
			{
				firstLine = false;
				if (!ParseFirstLine(line))
					return false;
				continue;
			}

			if (!ParseHeaderLine(line))
				return false;
		}

		return ParseBodyFraming();
	}

	/// Request: METHOD SP TARGET SP HTTP/1.x. Response: HTTP/1.x SP STATUS SP REASON.
	private bool ParseFirstLine(StringView line)
	{
		var firstSpace = 0;
		while ((firstSpace < line.Length) && (line[firstSpace] != ' '))
			firstSpace++;
		var secondSpace = firstSpace + 1;
		while ((secondSpace < line.Length) && (line[secondSpace] != ' '))
			secondSpace++;

		// Both separators must be PRESENT and have something after them. "complete garbage"
		// clears a `secondSpace > Length` check, because the scan stops exactly at the end,
		// and the version read below then runs one past it. A response may omit the reason
		// phrase ("HTTP/1.1 204"): only the request form needs the third part.
		if ((firstSpace >= line.Length) || ((mMode == .Request) && (secondSpace >= line.Length)))
			return false;

		if (mMode == .Request)
		{
			let version = line.Substring(secondSpace + 1);
			// HTTP/1.x only. A 0.9 or 2 request is not something this subset can answer.
			if (!version.StartsWith("HTTP/1."))
				return false;

			mMethod.Set(line.Substring(0, firstSpace));
			mTarget.Set(line.Substring(firstSpace + 1, secondSpace - firstSpace - 1));
			return !mMethod.IsEmpty && !mTarget.IsEmpty;
		}

		if (!line.StartsWith("HTTP/1."))
			return false;
		if (!ParseUnsigned(line.Substring(firstSpace + 1, secondSpace - firstSpace - 1),
			let status) || (status > 999))
			return false;
		mStatus = (int32)status;
		return true;
	}

	private bool ParseHeaderLine(StringView line)
	{
		var colon = 0;
		while ((colon < line.Length) && (line[colon] != ':'))
			colon++;
		// An empty name, or no colon at all, is not a header.
		if ((colon == 0) || (colon >= line.Length))
			return false;

		let value = line.Substring(colon + 1)..Trim();
		mHeaders.Add(new HttpHeader(line.Substring(0, colon), value));
		return true;
	}

	private bool ParseBodyFraming()
	{
		// A response with no body: complete at its head (Push sees mNoBody).
		if ((mMode == .Response) && (mNoBody || (mStatus == 204) || (mStatus == 304) || ((mStatus >= 100) && (mStatus < 200))))
		{
			mNoBody = true;
			return true;
		}

		// Chunked: a response's, which servers send. A chunked REQUEST stays outside the
		// server's subset, as does any other transfer coding: guessing at one would mean
		// guessing where the message ends.
		let transfer = HttpHeader.Find(mHeaders, "Transfer-Encoding");
		if (!transfer.IsEmpty)
		{
			if ((mMode != .Response) || !transfer.Contains("chunked", true))
				return false;
			mChunked = true;
			return true;
		}

		let contentLength = HttpHeader.Find(mHeaders, "Content-Length");
		if (!contentLength.IsEmpty)
		{
			if (!ParseUnsigned(contentLength, let expected))
				return false;
			if (expected > (uint64)mMaxBody)
			{
				mTooLarge = true;
				return false;
			}
			mBodyExpected = (int)expected;
			return true;
		}

		// No length on a response means read until close. A request without one has no body.
		if (mMode == .Response)
			mBodyUntilClose = true;
		return true;
	}

	/// The chunked bytes so far into mBody: hex sizes (an extension after ';' ignored), each
	/// chunk's data and CRLF, then the trailers to the blank line, which are dropped.
	private HttpParseState DecodeChunks()
	{
		int at = 0;
		while (mState == .NeedMore)
		{
			if (mChunk == .Size)
			{
				if (!NextLine(ref at, let sizeLine))
					break;
				int size = 0;
				int digits = 0;
				for (let c in sizeLine)
				{
					if (c == ';')
						break;
					int v;
					if ((c >= '0') && (c <= '9'))
						v = (int)c - (int)'0';
					else if ((c >= 'a') && (c <= 'f'))
						v = (int)c - (int)'a' + 10;
					else if ((c >= 'A') && (c <= 'F'))
						v = (int)c - (int)'A' + 10;
					else if ((c == ' ') || (c == '\t'))
						continue;
					else
					{
						mState = .Failed;
						return mState;
					}
					// A size no body here reaches.
					if (++digits > 15)
					{
						mState = .Failed;
						return mState;
					}
					size = size * 16 + v;
				}
				if (digits == 0)
				{
					mState = .Failed;
					return mState;
				}
				if (size == 0)
				{
					mChunk = .Trailers;
					continue;
				}
				if (BodySoFar + size > mMaxBody)
				{
					mTooLarge = true;
					mState = .Failed;
					return mState;
				}
				mChunk = .Data;
				mChunkLeft = size;
			}
			else if (mChunk == .Data)
			{
				// The chunk and its CRLF not all here yet.
				if (mChunkRaw.Count - at < mChunkLeft + 2)
					break;
				mBody.AddRange(Span<uint8>(mChunkRaw.Ptr + at, mChunkLeft));
				at += mChunkLeft;
				if ((mChunkRaw[at] != '\r') || (mChunkRaw[at + 1] != '\n'))
				{
					mState = .Failed;
					return mState;
				}
				at += 2;
				mChunk = .Size;
			}
			else
			{
				if (!NextLine(ref at, let trailer))
					break;
				if (trailer.IsEmpty)
					mState = .Complete;
			}
		}
		// Keep what is not decoded yet.
		if (at > 0)
			mChunkRaw.RemoveRange(0, at);
		if (mChunkRaw.Count > cMaxHeadBytes + mMaxBody)
			mState = .Failed;
		return mState;
	}

	/// The CRLF-ended line of mChunkRaw starting at `at`, moving past it; false when it has not
	/// all arrived.
	private bool NextLine(ref int at, out StringView outLine)
	{
		outLine = default;
		for (int i = at; (i + 1) < mChunkRaw.Count; i++)
		{
			if ((mChunkRaw[i] == '\r') && (mChunkRaw[i + 1] == '\n'))
			{
				outLine = .((char8*)mChunkRaw.Ptr + at, i - at);
				at = i + 2;
				return true;
			}
		}
		return false;
	}

	/// Digits only. False on empty, on anything else, and on a value that would overflow,
	/// because a Content-Length is attacker supplied.
	private static bool ParseUnsigned(StringView text, out uint64 outValue)
	{
		outValue = 0;
		if (text.IsEmpty)
			return false;

		uint64 value = 0;
		for (let c in text)
		{
			if ((c < '0') || (c > '9'))
				return false;
			if (value > ((uint64.MaxValue - 9) / 10))
				return false;
			value = value * 10 + (uint64)(c - '0');
		}
		outValue = value;
		return true;
	}
}
