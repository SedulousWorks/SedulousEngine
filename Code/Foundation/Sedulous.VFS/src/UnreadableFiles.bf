using System;
using Sedulous.Core;

namespace Sedulous.VFS;

/// A file on a mount that could not be read, moved out of the way so what replaces it never
/// writes over it, as SetAsideUnreadable does on the disk.
static class UnreadableFiles
{
	/// Moves `path` to "<path>.unreadable", or "<path>.unreadable-2", -3 and on when that is
	/// taken; `outAside` is where it went. An error when it could not be moved (a mount that
	/// cannot write, or a failed move): then nothing may be written over it.
	public static Result<void, ErrorCode> SetAside(IFileSystem fs, StringView path, String outAside)
	{
		let writable = fs as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);
		outAside.Set(path);
		outAside.Append(".unreadable");
		for (int n = 2; fs.Exists(outAside); n++)
		{
			outAside.Set(path);
			outAside.AppendF(".unreadable-{}", n);
		}
		if (writable.Move(path, outAside) case .Err(let error))
		{
			outAside.Clear();
			return .Err(error);
		}
		return .Ok;
	}
}
