using System;

namespace Sedulous.Core.IO;

/// Typed binary input over a stream.
///
/// The mirror of BinaryWriter, with the same sticky ok flag: a short read sets it false
/// and it stays false, so a whole record can be read and tested once.
///
/// The stream is borrowed and must outlive the reader.
class BinaryReader
{
	private IStream mStream;
	private bool mOk = true;

	public this(IStream stream)
	{
		mStream = stream;
	}

	public bool IsOk => mOk;

	/// Raw bytes. Sticks to not-ok on a short read; once failed it reads nothing more and
	/// hands back zeros, so a count read after the failure is 0 and a loop over it ends.
	public bool ReadBytes(Span<uint8> data)
	{
		if (data.Length == 0)
			return mOk;
		if (!mOk)
		{
			Internal.MemSet(data.Ptr, 0, data.Length);
			return false;
		}
		if (mStream.Read(data) != data.Length)
			mOk = false;
		return mOk;
	}

	/// One value, as stored. Left unspecified if the read comes up short; zero when the
	/// reader had already failed.
	public bool Read<T>(out T value) where T : struct
	{
		value = ?;
		return ReadBytes(.((uint8*)&value, sizeof(T)));
	}

	/// A string written by WriteString. The output is cleared first, so a failed read
	/// leaves it empty rather than half filled.
	public bool ReadString(String outValue)
	{
		outValue.Clear();

		uint32 length = 0;
		if (!Read(out length))
			return false;
		if (length == 0)
			return mOk;

		// A count longer than what is left cannot be real. Sizing the buffer to it first
		// would be trusting a corrupt file about its own size, and a large enough garbage
		// count takes the process down before the short read is ever reported.
		if (!Holds(length))
		{
			mOk = false;
			return false;
		}

		// The length came off the stream, so it is only as trustworthy as the file. Read
		// it in one transfer against the buffer we actually sized, and let a short read
		// report itself, rather than trusting the count enough to loop on it.
		let buffer = outValue.PrepareBuffer((int)length);
		if (!ReadBytes(.((uint8*)buffer, (int)length)))
		{
			outValue.Clear();
			return false;
		}
		return mOk;
	}

	/// Whether `count` items of at least a byte each can still be in the stream. A count
	/// beyond the bytes left is a misread (a record written in another layout), not data:
	/// trusting it reserves gigabytes and reads past the end millions of times. A count up
	/// to cTrustedCount passes without asking the stream (a file stream's size and position
	/// are two system calls), since reading it out costs little before the end stops it.
	public bool Holds(uint64 count)
	{
		if (count <= cTrustedCount)
			return true;
		let size = mStream.Size();
		let at = mStream.Tell();
		return (size < 0) || (at < 0) || (count <= (uint64)((size > at) ? (size - at) : 0));
	}

	private const uint64 cTrustedCount = 4096;
}
