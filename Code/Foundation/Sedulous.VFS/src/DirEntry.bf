using System;

namespace Sedulous.VFS;

/// One entry returned by enumeration.
///
/// Name is a single path component relative to the folder that was enumerated, not a full
/// path. It is owned by the entry, so a list of these is disposed rather than merely
/// cleared.
struct DirEntry : IDisposable
{
	public String Name;
	public bool IsDirectory;

	public this(StringView name, bool isDirectory)
	{
		Name = new String(name);
		IsDirectory = isDirectory;
	}

	public void Dispose() mut
	{
		delete Name;
		Name = null;
	}
}
