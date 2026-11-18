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
		let source = from.ToScopedNativeWChar!();
		let target = to.ToScopedNativeWChar!();
		// MoveFileEx refuses to replace a file another handle has open, even one opened with
		// FILE_SHARE_DELETE, so a save over a file a reader held failed. A rename with POSIX
		// semantics (Windows 10 1809 and later, NTFS) replaces it, and the reader keeps the file
		// it opened. Where that is not supported (an older system, a FAT volume), MoveFileEx.
		int length = 0;
		while (target[length] != 0)
			length++;
		let size = (int)Math.Max(sizeof(FileRenameInfo), offsetof(FileRenameInfo, FileName) + (length + 1) * sizeof(char16));
		// In words, so the record is aligned for its handle.
		let info = (FileRenameInfo*)scope uint64[(size + 7) / 8]*;
		let handle = CreateFileW(source, cDelete | cSynchronize, cShareReadWriteDelete, null, cOpenExisting, cFileAttributeNormal, null);
		if (handle != (void*)-1)
		{
			info.Flags = cRenameReplaceIfExists | cRenamePosixSemantics;
			info.RootDirectory = null;
			info.FileNameLength = (uint32)(length * sizeof(char16)); // no terminator
			Internal.MemCpy(&info.FileName, target, (length + 1) * sizeof(char16));
			let renamed = SetFileInformationByHandle(handle, cFileRenameInfoEx, info, (uint32)(offsetof(FileRenameInfo, FileName) + length * sizeof(char16)));
			CloseHandle(handle);
			if (renamed != 0)
				return true;
		}
		return MoveFileExW(source, target, cMoveFileReplaceExisting) != 0;
#else
		return System.IO.File.Move(from, to) case .Ok;
#endif
	}

#if BF_PLATFORM_WINDOWS
	private const uint32 cMoveFileReplaceExisting = 0x1;
	private const uint32 cDelete = 0x00010000;
	private const uint32 cSynchronize = 0x00100000;
	private const uint32 cShareReadWriteDelete = 0x7;
	private const uint32 cOpenExisting = 3;
	private const uint32 cFileAttributeNormal = 0x80;
	private const uint32 cRenameReplaceIfExists = 0x1;
	private const uint32 cRenamePosixSemantics = 0x2;
	/// FILE_INFO_BY_HANDLE_CLASS's FileRenameInfoEx.
	private const int32 cFileRenameInfoEx = 22;
	private const uint32 cFileFlagBackupSemantics = 0x02000000;
	private const uint32 cFileNameNormalized = 0x0;

	/// FILE_RENAME_INFO, its name running on past the record.
	[CRepr]
	private struct FileRenameInfo
	{
		public uint32 Flags;
		public void* RootDirectory;
		public uint32 FileNameLength;
		public char16 FileName;
	}

	[CLink, CallingConvention(.Stdcall)]
	private static extern void* CreateFileW(char16* name, uint32 access, uint32 share, void* security, uint32 disposition, uint32 flags, void* templateFile);
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 SetFileInformationByHandle(void* file, int32 infoClass, void* info, uint32 size);
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 CloseHandle(void* handle);
	[CLink, CallingConvention(.Stdcall)]
	private static extern uint32 GetFinalPathNameByHandleW(void* file, char16* path, uint32 count, uint32 flags);

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
	///
	/// A link is removed, never walked: walking it would delete what it points to, which may lie
	/// outside the tree being removed. (The platform's listing reports a link to a directory as a
	/// directory, so a link inside the tree would be walked too.)
	public static bool RemoveDirectoryRecursive(StringView path)
	{
		if (IsSymbolicLink(path))
			return DeleteFile(path) || RemoveDirectory(path); // a directory link on Windows goes by RemoveDirectory
		if (!System.IO.Directory.Exists(path))
			return true;
		let files = scope List<String>();
		let folders = scope List<String>();
		defer { ClearAndDeleteItems!(files); ClearAndDeleteItems!(folders); }
		ListDirectory(path, scope [&](name, isDirectory) =>
			{
				let child = PathJoin(path, name, .. new String());
				((isDirectory && !IsSymbolicLink(child)) ? folders : files).Add(child);
			});
		bool removed = true;
		for (let folder in folders)
			removed &= RemoveDirectoryRecursive(folder);
		for (let file in files)
		{
			if (IsSymbolicLink(file))
			{
				removed &= DeleteFile(file) || RemoveDirectory(file);
				continue;
			}
			// A read-only file is deleted too, as the platform's tree delete does.
			System.IO.File.SetAttributes(file, .Archive).IgnoreError();
			removed &= DeleteFile(file);
		}
		RemoveDirectory(path);
		return removed && !System.IO.Directory.Exists(path);
	}

	/// Whether `path` itself is a symbolic link (on Windows, any reparse point: a symlink or a
	/// junction), not what it points to.
	public static bool IsSymbolicLink(StringView path)
	{
#if BF_PLATFORM_WINDOWS
		let attributes = GetFileAttributesW(path.ToScopedNativeWChar!());
		return (attributes != cInvalidFileAttributes) && ((attributes & cFileAttributeReparsePoint) != 0);
#else
		// readlink answers for a link alone (anything else is EINVAL).
		char8[1] target = ?;
		return readlink(path.ToScopeCStr!(), &target, 1) >= 0;
#endif
	}

	/// Makes `link` point to `target`; `directory` when the target is one (Windows needs to know).
	/// False when the platform refuses (Windows without developer mode or the privilege).
	public static bool CreateSymbolicLink(StringView target, StringView link, bool directory)
	{
#if BF_PLATFORM_WINDOWS
		var flags = cSymbolicLinkAllowUnprivilegedCreate;
		if (directory)
			flags |= cSymbolicLinkDirectory;
		return CreateSymbolicLinkW(link.ToScopedNativeWChar!(), target.ToScopedNativeWChar!(), flags) != 0;
#else
		return symlink(target.ToScopeCStr!(), link.ToScopeCStr!()) == 0;
#endif
	}

	/// `path` with every symbolic link followed, absolute, into `outPath`; false (and nothing
	/// added) when it does not exist. How the folder of a command found on PATH is learned when
	/// PATH holds a link to it (a snap's tools).
	public static bool PathResolveLinks(StringView path, String outPath)
	{
#if BF_PLATFORM_WINDOWS
		// Opened for no access (backup semantics, so a folder opens too): enough to ask the final
		// path of what the links lead to.
		let handle = CreateFileW(path.ToScopedNativeWChar!(), 0, cShareReadWriteDelete, null, cOpenExisting, cFileFlagBackupSemantics, null);
		if (handle == (void*)-1)
			return false;
		char16[4096] buffer = ?;
		let length = GetFinalPathNameByHandleW(handle, &buffer[0], (uint32)buffer.Count, cFileNameNormalized);
		CloseHandle(handle);
		if ((length == 0) || (length >= (uint32)buffer.Count))
			return false;
		buffer[length] = 0;
		// "\\?\C:\..." for a drive path: the prefix goes ("\\?\UNC\..." stays as it is).
		var start = 0;
		if ((length > 5) && (buffer[0] == '\\') && (buffer[1] == '\\') && (buffer[2] == '?') && (buffer[3] == '\\') && (buffer[5] == ':'))
			start = 4;
		UTF16.Decode(&buffer[start], outPath);
		return true;
#else
		char8[4096] buffer = ?; // PATH_MAX on Linux
		if (realpath(path.ToScopeCStr!(), &buffer[0]) == null)
			return false;
		outPath.Append(&buffer[0]);
		return true;
#endif
	}

#if BF_PLATFORM_WINDOWS
	private const uint32 cInvalidFileAttributes = 0xFFFFFFFF;
	private const uint32 cFileAttributeReparsePoint = 0x400;
	private const uint32 cSymbolicLinkDirectory = 0x1;
	private const uint32 cSymbolicLinkAllowUnprivilegedCreate = 0x2;

	[CLink, CallingConvention(.Stdcall)]
	private static extern uint32 GetFileAttributesW(char16* path);
	[CLink, CallingConvention(.Stdcall)]
	private static extern uint8 CreateSymbolicLinkW(char16* link, char16* target, uint32 flags);
#else
	[CLink]
	private static extern int readlink(char8* path, char8* buffer, uint size);
	[CLink]
	private static extern int32 symlink(char8* target, char8* link);
	[CLink]
	private static extern char8* realpath(char8* path, char8* resolved);
#endif
}
