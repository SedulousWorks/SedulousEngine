using System;
using System.Collections;

namespace Sedulous.Http;

/// An incremental HTTP/1.1 parser, for a request or a response.
///
/// Push bytes as they arrive; once Complete, the pieces are readable. A STRICT SUBSET: CRLF
/// framing, Content-Length bodies only, a capped head, and a caller-set body cap. Chunked
/// transfer fails rather than being half supported, because a wrong body boundary is worse
/// than a refusal.
///
/// A response with no Content-Length is read UNTIL THE PEER CLOSES, which is what the
/// connection-close model leaves as the only framing.
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

	/// Head accumulation. Emptied once the head is parsed; the body goes to mBody.
	private List<uint8> mBuffer = new .() ~ delete _;
	private String mMethod = new .() ~ delete _;
	private String mTarget = new .() ~ delete _;
	private int32 mStatus = 0;
	private List<HttpHeader> mHeaders = new .() ~ DeleteContainerAndItems!(_);
	private List<uint8> mBody = new .() ~ delete _;

	public this(HttpMessageMode mode, int maxBodyBytes = 16 * 1024 * 1024)
	{
		mMode = mode;
		mMaxBody = maxBodyBytes;
	}

	public HttpParseState State => mState;

	// Request mode.
	public StringView Method => mMethod;
	public StringView Target => mTarget;
	// Response mode.
	public int32 Status => mStatus;
	// Both.
	public List<HttpHeader> Headers => mHeaders;
	public List<uint8> Body => mBody;

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
			mBody.AddRange(spill);
		}
		else
		{
			mBody.AddRange(bytes);
		}

		if (mBody.Count > mMaxBody)
		{
			mState = .Failed;
			return mState;
		}
		// Close delimited: there is no length to reach, so only the peer closing ends it.
		if (mBodyUntilClose)
			return mState;

		if (mBody.Count >= mBodyExpected)
		{
			// Drop any over-read. One request per connection means anything past the declared
			// length is not ours to interpret.
			mBody.Count = mBodyExpected;
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
		// and the version read below then runs one past it.
		if ((firstSpace >= line.Length) || (secondSpace >= line.Length))
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
		// Chunked is outside the subset in BOTH directions. Guessing at a chunked body would
		// mean guessing where the message ends.
		if (!HttpHeader.Find(mHeaders, "Transfer-Encoding").IsEmpty)
			return false;

		let contentLength = HttpHeader.Find(mHeaders, "Content-Length");
		if (!contentLength.IsEmpty)
		{
			if (!ParseUnsigned(contentLength, let expected) || (expected > (uint64)mMaxBody))
				return false;
			mBodyExpected = (int)expected;
			return true;
		}

		// No length on a response means read until close. A request without one has no body.
		if (mMode == .Response)
			mBodyUntilClose = true;
		return true;
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
