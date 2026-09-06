using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.IO;

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

	/// Writes a buffer to a file, replacing any existing contents.
	public static Result<void, ErrorCode> WriteFile(StringView path, Span<uint8> data)
	{
		let file = scope FileStream(path, .Write);
		if (!file.IsValid)
			return .Err(.Internal);
		if (data.Length == 0)
			return .Ok;
		if (file.Write(data) != data.Length)
			return .Err(.Internal);
		return .Ok;
	}

	public static bool FileExists(StringView path) => System.IO.File.Exists(path);

	/// Calls onEntry for each immediate child of a directory, with the entry's NAME rather
	/// than its path. False when the directory cannot be opened.
	///
	/// A callback rather than a filled list, as in Raptor: the name is only valid during
	/// the call, and Core has no business deciding who owns a copy of it.
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
	/// The time is in platform ticks rather than Raptor's whole seconds. A stat sweep
	/// diffs these to find what changed, and a file edited twice within one second is
	/// exactly the case a second-granularity stamp cannot see.
	public static bool FileStat(StringView path, out int64 size, out int64 modifiedTicks)
	{
		size = 0;
		modifiedTicks = 0;

		if (!System.IO.File.Exists(path))
			return false;

		let parent = PathParent(path);
		let target = PathFilename(path);
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
		outPath.Append(PathParent(exePath));
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
