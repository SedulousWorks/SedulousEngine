using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Core.IO;

/// Who may read a file a whole-file write makes: whoever its folder lets (Shared), or its
/// owner alone (OwnerOnly, for a secret such as a token).
enum FileAccessRule : uint8
{
	Shared,
	OwnerOnly
}

/// Whole-file helpers and the directory queries, on one surface.
///
/// The whole-file helpers go through FileStream rather than corlib's File, so they
/// exercise the same stack everything else in Core does.
static
{
	/// Reads an entire file, replacing whatever outData held. On failure it is left empty
	/// rather than partly filled.
	public static Result<void, ErrorCode> ReadFile(StringView path, List<uint8> outData)
	{
		outData.Clear();

		let file = scope FileStream(path, .Read);
		if (!file.IsValid)
			return .Err(.NotFound);

		let size = file.Size();
		if (size < 0)
			return .Err(.Internal);
		if (size == 0)
			return .Ok;

		let buffer = outData.GrowUninitialized((int)size);
		if (file.Read(.(buffer, (int)size)) != (int)size)
		{
			outData.Clear();
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// Writes a buffer to a file, replacing its contents whole or not at all
	/// (WriteFileAtomic): never a file cut short by a crash or a full disk.
	public static Result<void, ErrorCode> WriteFile(StringView path, Span<uint8> data) => WriteFileAtomic(path, data);

	private static int32 sTemporaryWrites;

	/// The temporary a whole-file write goes to before it is moved over `path`:
	/// "<path>.<process>-<n>.tmp", unique to the process and to the write, so two writers of
	/// one file never share a temporary. The ".tmp" ending is what file watchers skip.
	public static void TemporaryPathFor(StringView path, String outPath)
	{
		let n = Interlocked.Increment(ref sTemporaryWrites);
		outPath.Append(path);
		outPath.AppendF(".{}-{}.tmp", System.Diagnostics.Process.CurrentId, n);
	}

	/// Writes a buffer to a file so that a reader, or the next run after a crash or a power
	/// loss, sees the old contents or the new ones, never a torn mix: the bytes go to a
	/// temporary beside the target (TemporaryPathFor), are flushed to the device, and the
	/// temporary is moved over the target (a rename on one volume replaces it atomically). A
	/// failed write leaves the target as it was and no temporary behind. OwnerOnly makes the
	/// temporary its owner's alone before the bytes go in.
	public static Result<void, ErrorCode> WriteFileAtomic(StringView path, Span<uint8> data, FileAccessRule access = .Shared)
	{
		let temporary = TemporaryPathFor(path, .. scope String());
		bool written;
		{
			// Closed at the end of this block, before the move: Windows does not replace a
			// file a handle of this process still holds open for writing.
			let file = scope FileStream(temporary, .Write);
			written = file.IsValid && ((access == .Shared) || file.RestrictToOwner())
				&& ((data.Length == 0) || (file.Write(data) == data.Length)) && file.Sync();
		}
		if (!written)
		{
			DeleteFile(temporary);
			return .Err(.Internal);
		}
		if (!MoveReplacing(temporary, path))
		{
			DeleteFile(temporary);
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// Moves a file that could not be read out of the way, so that what replaces it never
	/// writes over it and it can still be recovered by hand: to "<path>.unreadable", or
	/// "<path>.unreadable-2", -3 and on when that is taken. `outAside` is where it went; an
	/// error when it could not be moved, and then nothing may be written over it.
	public static Result<void, ErrorCode> SetAsideUnreadable(StringView path, String outAside)
	{
		outAside.Set(path);
		outAside.Append(".unreadable");
		for (int n = 2; FileExists(outAside); n++)
		{
			outAside.Set(path);
			outAside.AppendF(".unreadable-{}", n);
		}
		if (!MoveFile(path, outAside))
		{
			outAside.Clear();
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// A move that replaces an existing target. `File.Move` is POSIX `rename`, which does, on
	/// Linux; on Windows it is `MoveFileW`, which refuses an existing target.
	private static bool MoveReplacing(StringView from, StringView to)
	{
#if BF_PLATFORM_WINDOWS
		return MoveFileExW(from.ToScopedNativeWChar!(), to.ToScopedNativeWChar!(), cMoveFileReplaceExisting) != 0;
#else
		return System.IO.File.Move(from, to) case .Ok;
#endif
	}

#if BF_PLATFORM_WINDOWS
	private const uint32 cMoveFileReplaceExisting = 0x1;

	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 MoveFileExW(char16* existingName, char16* newName, uint32 flags);
#endif

	public static bool FileExists(StringView path) => System.IO.File.Exists(path);

	/// Calls onEntry for each immediate child of a directory, with the entry's NAME rather
	/// than its path. False when the directory cannot be opened.
	///
	/// A callback rather than a filled list: the name is only valid during the call, and
	/// Core has no business deciding who owns a copy of it.
	public static bool ListDirectory(StringView path, delegate void(StringView name, bool isDirectory) onEntry)
	{
		if (!System.IO.Directory.Exists(path))
			return false;

		let name = scope String();
		for (let entry in System.IO.Directory.Enumerate(path))
		{
			name.Clear();
			entry.GetFileName(name);
			// The platform yields the self and parent links; they are not children.
			if ((name == ".") || (name == ".."))
				continue;
			onEntry(name, entry.IsDirectory);
		}
		return true;
	}

	/// Size and last-write time of one regular file. False when the path is not one.
	///
	/// The time is in platform ticks rather than whole seconds. A stat sweep diffs these to
	/// find what changed, and a file edited twice within one second is exactly the case a
	/// second-granularity stamp cannot see.
	public static bool FileStat(StringView path, out int64 size, out int64 modifiedTicks)
	{
		size = 0;
		modifiedTicks = 0;

		if (!System.IO.File.Exists(path))
			return false;

		let parent = PathParent(path, .. scope String());
		let target = PathFilename(path, .. scope String());
		if (target.IsEmpty)
			return false;

		var found = false;
		let name = scope String();
		for (let entry in System.IO.Directory.Enumerate(parent.IsEmpty ? "." : parent))
		{
			name.Clear();
			entry.GetFileName(name);
			if (name != target)
				continue;
			if (entry.IsDirectory)
				return false;
			size = entry.GetFileSize();
			modifiedTicks = entry.GetLastWriteTimeUtc().Ticks;
			found = true;
			break;
		}
		return found;
	}

	public static bool MoveFile(StringView from, StringView to) => System.IO.File.Move(from, to) case .Ok;

	/// The directory holding this executable.
	///
	/// Discovery anchors here rather than at the working directory, which is unreliable:
	/// an application launched from a menu or a desktop entry inherits whatever directory
	/// the launcher happened to be in.
	public static void GetExecutableDirectory(String outPath)
	{
		let exePath = scope String();
		System.Environment.GetExecutableFilePath(exePath);
		outPath.Clear();
		PathParent(exePath, outPath);
	}

	public static void GetCurrentDirectory(String outPath)
	{
		outPath.Clear();
		System.IO.Directory.GetCurrentDirectory(outPath);
	}

	public static bool DeleteFile(StringView path) => System.IO.File.Delete(path) case .Ok;

	public static bool DirectoryExists(StringView path) => System.IO.Directory.Exists(path);

	public static bool CreateDirectory(StringView path) => System.IO.Directory.CreateDirectory(path) case .Ok;

	/// Empty directories only, which is all the platform primitive does. A populated one
	/// fails quietly, which is how stale test scratch directories accumulate.
	public static bool RemoveDirectory(StringView path) => System.IO.Directory.Delete(path) case .Ok;

	/// A directory and everything under it. A directory that is already absent counts as
	/// gone, so this is idempotent.
	public static bool RemoveDirectoryRecursive(StringView path)
	{
		if (!System.IO.Directory.Exists(path))
			return true;
		return System.IO.Directory.DelTree(path) case .Ok;
	}
}
