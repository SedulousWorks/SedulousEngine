using System;
using Sedulous.Core.IO;

namespace Sedulous.VFS;

/// The minimum a filesystem has to do: hand back bytes for a logical path.
///
/// Capabilities beyond this are separate interfaces a backend implements only if it can.
/// Raptor discovers them through virtual AsEnumerable/AsWritable/AsStat query methods,
/// because C++ has no real interfaces and Raptor builds with RTTI off, so there is nothing
/// to ask a pointer. Beef has both, so a caller writes
///
///     if (let writable = fs as IWritableFileSystem)
///
/// and the whole As family disappears, along with the rule that the capability interfaces
/// must not derive from this one to avoid a diamond.
interface IFileSystem
{
	/// Opens a stream for a logical path, or null if it cannot be opened. THE CALLER OWNS
	/// the stream that comes back.
	IStream Open(StringView path, FileMode mode);

	bool Exists(StringView path);
}
