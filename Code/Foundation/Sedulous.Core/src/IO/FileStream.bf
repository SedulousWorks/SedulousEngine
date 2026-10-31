using System;

namespace Sedulous.Core.IO;

/// An IStream over a file.
///
/// Wraps corlib's FileStream, which is the BeefPlatform calls one layer down. What Core
/// owns is the contract above it: four file modes, transferred counts rather than Results,
/// and a seek that answers with the new absolute position.
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

	/// An exclusive lock on the open file, without waiting: true when taken, false when another
	/// handle holds it, in this process or another. It lasts until Unlock, the close, or the
	/// process's end (a crash included), so a lock is never left behind, as a lock file with a
	/// process id is when its holder crashes. Advisory: it stops other lockers, not readers or
	/// writers. For one-writer files (a tool's library).
	public bool TryLock()
	{
		if (!mIsValid)
			return false;
#if BF_PLATFORM_WINDOWS
		var range = LockRange();
		return LockFileEx((void*)mFile.Handle, cLockFileExclusiveLock | cLockFileFailImmediately, 0, 1, 0, &range) != 0;
#else
		// flock belongs to the open file description: a second open, in this process or
		// another, conflicts; the lock goes with the last descriptor of this one.
		return flock((int32)mFile.Handle, cLockExclusive | cLockNonBlocking) == 0;
#endif
	}

	/// Lets go of the lock TryLock took; nothing when there is none.
	public void Unlock()
	{
		if (!mIsValid)
			return;
#if BF_PLATFORM_WINDOWS
		var range = LockRange();
		UnlockFileEx((void*)mFile.Handle, 0, 1, 0, &range);
#else
		flock((int32)mFile.Handle, cLockUnlock);
#endif
	}

#if BF_PLATFORM_WINDOWS
	[CRepr]
	private struct Overlapped
	{
		public uint Internal;
		public uint InternalHigh;
		public uint32 Offset;
		public uint32 OffsetHigh;
		public void* Event;
	}

	private const uint32 cLockFileFailImmediately = 0x1;
	private const uint32 cLockFileExclusiveLock = 0x2;

	/// The byte the lock covers: far past any content, since a Win32 range lock is mandatory
	/// (it would stop other handles reading the bytes it covers), and locking past the end of a
	/// file is allowed.
	private static Overlapped LockRange()
	{
		Overlapped range = default;
		range.Offset = 0xFFFFFFFE;
		range.OffsetHigh = 0x7FFFFFFF;
		return range;
	}

	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 LockFileEx(void* file, uint32 flags, uint32 reserved, uint32 bytesLow, uint32 bytesHigh, Overlapped* overlapped);
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 UnlockFileEx(void* file, uint32 reserved, uint32 bytesLow, uint32 bytesHigh, Overlapped* overlapped);
#else
	private const int32 cLockExclusive = 2;
	private const int32 cLockNonBlocking = 4;
	private const int32 cLockUnlock = 8;

	[CLink]
	private static extern int32 flock(int32 fd, int32 operation);
#endif
}
