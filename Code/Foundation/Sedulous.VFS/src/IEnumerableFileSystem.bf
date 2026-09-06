using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VFS;

/// Capability: list what is in a directory.
interface IEnumerableFileSystem
{
	/// Appends the immediate children of folder, where an empty folder means the mount
	/// root. The entries own their names, so the caller disposes them.
	Result<void, ErrorCode> Enumerate(StringView folder, List<DirEntry> outEntries);
}
