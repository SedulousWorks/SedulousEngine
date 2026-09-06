using System;

namespace Sedulous.Core.IO;

/// Read, write and seek over a sequence of bytes.
///
/// Read and Write report the count actually transferred, which may fall short at the end
/// of the stream or on error, rather than each returning a Result. The callers that care
/// about a short transfer are BinaryReader and BinaryWriter, and they accumulate it into
/// one sticky flag rather than testing every call.
///
/// An abstract class rather than an interface, as in Raptor, because of the typed
/// conveniences below. A Beef extension on an interface only resolves when the static type
/// IS the interface, so as an interface these would be unreachable through a FileStream or
/// a MemoryStream held as itself, which is how streams are usually held.
abstract class IStream
{
	/// False once the stream is unusable: a file that failed to open, or one closed since.
	public abstract bool IsValid { get; }

	public abstract int Read(Span<uint8> destination);
	public abstract int Write(Span<uint8> source);

	/// The new absolute position, or -1 if the target was out of range.
	public abstract int64 Seek(int64 offset, SeekOrigin origin);
	public abstract int64 Tell();
	public abstract int64 Size();

	/// Writes one value as stored. False on a short write.
	///
	/// The struct constraint stands in for Raptor's is_trivially_copyable static_assert:
	/// it is the strongest thing Beef can say here, and it keeps a class reference from
	/// being written out as the pointer it is.
	public bool WriteValue<T>(T value) where T : struct
	{
		// A local copy, because the address of a parameter is the address of something
		// immutable.
		var value;
		return Write(.((uint8*)&value, sizeof(T))) == sizeof(T);
	}

	/// Reads one value as stored. False on a short read, leaving the value unspecified.
	public bool ReadValue<T>(out T value) where T : struct
	{
		value = ?;
		return Read(.((uint8*)&value, sizeof(T))) == sizeof(T);
	}
}
