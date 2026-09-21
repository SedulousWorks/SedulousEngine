using System;
using Sedulous.Core.IO;

namespace Sedulous.VFS;

/// The minimum a filesystem has to do: hand back bytes for a logical path.
///
/// Capabilities beyond this are separate interfaces a backend implements only if it can,
/// so a caller writes
///
///     if (let writable = fs as IWritableFileSystem)
///
/// and there is no family of virtual AsEnumerable/AsWritable/AsStat queries to keep in
/// step, nor a rule that the capability interfaces must not derive from this one.
interface IFileSystem
{
	/// Opens a stream for a logical path, or null if it cannot be opened. THE CALLER OWNS
	/// the stream that comes back.
	IStream Open(StringView path, FileMode mode);

	bool Exists(StringView path);
}
