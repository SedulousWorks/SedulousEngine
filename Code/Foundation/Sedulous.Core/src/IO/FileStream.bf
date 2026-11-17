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

	/// The most one read or write asks of the system: Linux moves at most about 2 GiB in a call, so
	/// a request for a file that size came back short, which callers read as failure.
	private const int cChunk = 1024 * 1024 * 1024;

	/// Reads until `destination` is full, the file ends or a read fails, in chunks: one call can
	/// come back short (a file past 2 GiB, a pipe), and a short read is not the end.
	public override int Read(Span<uint8> destination)
	{
		if (!mIsValid)
			return 0;
		int total = 0;
		while (total < destination.Length)
		{
			let wanted = Math.Min(destination.Length - total, cChunk);
			if (mFile.TryRead(.(destination.Ptr + total, wanted)) case .Ok(let read))
			{
				if (read <= 0)
					break;
				total += read;
			}
			else
				break;
		}
		return total;
	}

	/// Writes all of `source` unless a write fails, in chunks as Read reads.
	public override int Write(Span<uint8> source)
	{
		if (!mIsValid)
			return 0;
		int total = 0;
		while (total < source.Length)
		{
			let wanted = Math.Min(source.Length - total, cChunk);
			if (mFile.TryWrite(.(source.Ptr + total, wanted)) case .Ok(let written))
			{
				if (written <= 0)
					break;
				total += written;
			}
			else
				break;
		}
		return total;
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

	/// Pushes what was written out to the device itself (fsync; FlushFileBuffers on Windows),
	/// so a rename after it publishes a whole file even across a power loss. False when the
	/// stream is invalid or the platform refuses.
	public bool Sync()
	{
		if (!mIsValid)
			return false;
		if (mFile.Flush() case .Err)
			return false;
#if BF_PLATFORM_WINDOWS
		return FlushFileBuffers((void*)mFile.Handle) != 0;
#else
		return fsync((int32)mFile.Handle) == 0;
#endif
	}

	/// Makes the open file readable and writable by its owner alone (0600), for a secret such
	/// as a token. On Windows a file takes its folder's access list, and the user-data
	/// folders are the user's own, so there is nothing to change.
	public bool RestrictToOwner()
	{
		if (!mIsValid)
			return false;
#if BF_PLATFORM_WINDOWS
		return true;
#else
		return fchmod((int32)mFile.Handle, cOwnerReadWrite) == 0;
#endif
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
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 FlushFileBuffers(void* file);
#else
	private const int32 cLockExclusive = 2;
	private const int32 cLockNonBlocking = 4;
	private const int32 cLockUnlock = 8;

	private const uint32 cOwnerReadWrite = 0x180; // 0600

	[CLink]
	private static extern int32 flock(int32 fd, int32 operation);
	[CLink]
	private static extern int32 fsync(int32 fd);
	[CLink]
	private static extern int32 fchmod(int32 fd, uint32 mode);
#endif
}
