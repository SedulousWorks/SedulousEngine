using System;

namespace Sedulous.Core.IO;

/// A read-only IStream over part of a file: `size` bytes from `offset`.
///
/// Position 0 is the region's first byte, and reads stop at its end. A file stored inside
/// another (a pak stored in an Android APK, an entry stored in a zip) is read in place this
/// way, never copied out first. Each one holds its own handle on the file, so readers on
/// other threads never share a position.
class FileRegionStream : IStream
{
	private FileStream mFile ~ delete _;
	private uint64 mOffset;
	private uint64 mSize;
	private uint64 mPosition;

	public this(StringView path, uint64 offset, uint64 size)
	{
		mFile = new FileStream(path, .Read);
		mOffset = offset;
		mSize = size;
		if (!mFile.IsValid)
			return;
		// A region that lies past the file's end is no region: the stream is invalid.
		let fileSize = (uint64)mFile.Size();
		if ((size > fileSize) || (offset > fileSize - size) || (mFile.Seek((int64)offset, .Begin) != (int64)offset))
			mFile.Close();
	}

	public override bool IsValid => mFile.IsValid;

	public override int Read(Span<uint8> destination)
	{
		let left = mSize - mPosition;
		let wanted = ((uint64)destination.Length < left) ? destination.Length : (int)left;
		if ((wanted == 0) || !IsValid)
			return 0;
		let read = mFile.Read(.(destination.Ptr, wanted));
		if (read <= 0)
			return 0;
		mPosition += (uint64)read;
		return read;
	}

	/// Read-only: nothing is written.
	public override int Write(Span<uint8> source) => 0;

	public override int64 Seek(int64 offset, SeekOrigin origin)
	{
		var target = offset;
		if (origin == .Current)
			target += (int64)mPosition;
		else if (origin == .End)
			target += (int64)mSize;
		if ((target < 0) || (target > (int64)mSize) || !IsValid)
			return -1;
		if (mFile.Seek((int64)mOffset + target, .Begin) < 0)
			return -1;
		mPosition = (uint64)target;
		return target;
	}

	public override int64 Tell() => IsValid ? (int64)mPosition : -1;
	public override int64 Size() => IsValid ? (int64)mSize : -1;
}
