using System;

namespace Sedulous.Core.IO;

/// Buffers reads and writes over another stream, to cut the number of small transfers.
///
/// It buffers in one direction at a time. Switching direction, or seeking, syncs the
/// buffer first: pending writes are flushed, and an unread prefetch is given back to the
/// underlying stream by seeking backwards over it.
///
/// The underlying stream is borrowed and must outlive this one.
class BufferedStream : IStream
{
	private enum Mode
	{
		None,
		Read,
		Write
	}

	private IStream mStream;
	private uint8[] mBuffer ~ delete _;
	/// Writing: bytes pending in the buffer. Reading: the cursor into it.
	private int mPos;
	/// Reading: how many bytes of the buffer are valid.
	private int mLen;
	private Mode mMode;

	public this(IStream stream, int bufferSize = 4096)
	{
		mStream = stream;
		mBuffer = new uint8[(bufferSize <= 0) ? 1 : bufferSize];
	}

	public ~this()
	{
		FlushWrites();
	}

	public override bool IsValid => mStream.IsValid;

	/// Pushes pending writes down to the underlying stream.
	public void Flush() => FlushWrites();

	public override int Write(Span<uint8> source)
	{
		if (mMode == .Read)
			SyncForSeek();
		mMode = .Write;

		var src = source.Ptr;
		var remaining = source.Length;
		while (remaining > 0)
		{
			let space = mBuffer.Count - mPos;
			let chunk = (remaining < space) ? remaining : space;
			Internal.MemCpy(&mBuffer[mPos], src, chunk);
			mPos += chunk;
			src += chunk;
			remaining -= chunk;
			if (mPos == mBuffer.Count)
				FlushBuffer();
		}
		return source.Length;
	}

	public override int Read(Span<uint8> destination)
	{
		if (mMode == .Write)
			FlushWrites();
		mMode = .Read;

		var produced = 0;
		while (produced < destination.Length)
		{
			if (mPos == mLen)
			{
				mLen = mStream.Read(.(&mBuffer[0], mBuffer.Count));
				mPos = 0;
				if (mLen == 0)
					break; // end of the underlying stream
			}
			let available = mLen - mPos;
			let want = destination.Length - produced;
			let chunk = (want < available) ? want : available;
			Internal.MemCpy(destination.Ptr + produced, &mBuffer[mPos], chunk);
			mPos += chunk;
			produced += chunk;
		}
		return produced;
	}

	public override int64 Seek(int64 offset, SeekOrigin origin)
	{
		SyncForSeek();
		return mStream.Seek(offset, origin);
	}

	public override int64 Tell()
	{
		let position = mStream.Tell();
		if (mMode == .Write)
			return position + mPos;
		if (mMode == .Read)
			return position - (mLen - mPos);
		return position;
	}

	/// Does not account for pending writes that would extend the underlying stream.
	public override int64 Size() => mStream.Size();

	/// Pushes the pending bytes down and empties the buffer, leaving the direction alone.
	/// Called when the buffer fills mid-write, where the write is still going.
	private void FlushBuffer()
	{
		if (mPos > 0)
			mStream.Write(.(&mBuffer[0], mPos));
		mPos = 0;
	}

	/// Ends the write, pushing anything pending down first.
	private void FlushWrites()
	{
		if (mMode == .Write)
			FlushBuffer();
		mPos = 0;
		mLen = 0;
		mMode = .None;
	}

	/// Leaves the underlying position where the caller of this stream believes it to be.
	private void SyncForSeek()
	{
		if (mMode == .Write)
		{
			FlushWrites();
		}
		else if (mMode == .Read)
		{
			// Hand back whatever was prefetched but never read.
			let unread = mLen - mPos;
			if (unread > 0)
				mStream.Seek(-unread, .Current);
		}
		mPos = 0;
		mLen = 0;
		mMode = .None;
	}
}
