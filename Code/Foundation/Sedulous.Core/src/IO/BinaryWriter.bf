using System;

namespace Sedulous.Core.IO;

/// Typed binary output over a stream.
///
/// It carries a sticky ok flag rather than returning a Result per call: a short write sets
/// it false and it never recovers, so a caller can write a whole record and test once at
/// the end. Everything after a failure still runs, and still fails.
///
/// The stream is borrowed and must outlive the writer.
class BinaryWriter
{
	private IStream mStream;
	private bool mOk = true;

	public this(IStream stream)
	{
		mStream = stream;
	}

	public bool IsOk => mOk;

	/// Raw bytes. Sticks to not-ok on a short write.
	public bool WriteBytes(Span<uint8> data)
	{
		if (data.Length == 0)
			return mOk;
		if (mStream.Write(data) != data.Length)
			mOk = false;
		return mOk;
	}

	/// One value, as stored.
	public bool Write<T>(T value) where T : struct
	{
		var value;
		return WriteBytes(.((uint8*)&value, sizeof(T)));
	}

	/// A string, length prefixed with a uint32 count of UTF-8 bytes.
	public bool WriteString(StringView value)
	{
		let length = (uint32)value.Length;
		Write(length);
		if (length > 0)
			WriteBytes(.((uint8*)value.Ptr, (int)length));
		return mOk;
	}
}
