using System;

namespace Sedulous.Core.IO;

/// An IStream over a file.
///
/// Raptor talks to its own System file primitives; this wraps corlib's FileStream, which
/// is the same BeefPlatform calls one layer down. What Core owns is the contract above it:
/// four file modes, transferred counts rather than Results, and a seek that answers with
/// the new absolute position.
class FileStream : IStream
{
	private System.IO.FileStream mFile = new .() ~ delete _;
	private bool mIsValid;

	public this(StringView path, FileMode mode)
	{
		System.IO.FileMode fileMode;
		System.IO.FileAccess access;
		switch (mode)
		{
		case .Read:
			fileMode = .Open;
			access = .Read;
		case .Write:
			fileMode = .Create;
			access = .Write;
		case .ReadWrite:
			fileMode = .OpenOrCreate;
			access = .ReadWrite;
		case .Append:
			fileMode = .Append;
			access = .Write;
		}

		// Shares EVERYTHING, which is what matches the POSIX semantics the rest of the engine
		// is written against: there an open reader never stops a file being rewritten,
		// replaced or unlinked. The default of no sharing makes Windows alone refuse a second
		// open, so two voices of one streamed clip, or regenerating an asset while its own
		// payload stream is open, fail there and pass on Linux.
		//
		// This is not a lock and never was one: it only ever blocked other openers, and only
		// while a handle happened to be alive. Code needing exclusive access must take a real
		// lock.
		mIsValid = mFile.Open(path, fileMode, access, .Read | .Write | .Delete) case .Ok;
	}

	public override bool IsValid => mIsValid;

	public override int Read(Span<uint8> destination)
	{
		if (!mIsValid)
			return 0;
		if (mFile.TryRead(destination) case .Ok(let read))
			return read;
		return 0;
	}

	public override int Write(Span<uint8> source)
	{
		if (!mIsValid)
			return 0;
		if (mFile.TryWrite(source) case .Ok(let written))
			return written;
		return 0;
	}

	public override int64 Seek(int64 offset, SeekOrigin origin)
	{
		if (!mIsValid)
			return -1;

		System.IO.Stream.SeekKind kind;
		switch (origin)
		{
		case .Begin: kind = .Absolute;
		case .Current: kind = .Relative;
		case .End: kind = .FromEnd;
		}

		if (mFile.Seek(offset, kind) case .Err)
			return -1;
		return mFile.Position;
	}

	public override int64 Tell() => mIsValid ? mFile.Position : -1;
	public override int64 Size() => mIsValid ? mFile.Length : -1;

	/// Pushes anything the platform is holding out to the file.
	public void Flush()
	{
		if (mIsValid)
			mFile.Flush().IgnoreError();
	}

	/// Closes the file. The stream is invalid afterwards.
	public void Close()
	{
		if (mIsValid)
		{
			mFile.Close().IgnoreError();
			mIsValid = false;
		}
	}
}
