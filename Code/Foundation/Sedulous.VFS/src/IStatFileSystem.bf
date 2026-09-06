using System;

namespace Sedulous.VFS;

/// Capability: cheap metadata for one entry, without opening it.
///
/// A backend whose content cannot change, such as an archive, simply does not implement
/// this, and a consumer falls back to hashing the bytes.
interface IStatFileSystem
{
	/// False when the path is not a regular file on this mount.
	bool Stat(StringView path, out FileStatInfo info);
}
