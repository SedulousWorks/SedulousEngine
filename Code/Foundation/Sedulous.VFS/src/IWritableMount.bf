using System;
using System.IO;

namespace Sedulous.VFS;

/// A mount that supports writes. Used by the editor for asset save / import flows.
///
/// Read-only mounts (paks, remote read-through caches, embedded resources) do not
/// implement this interface. Trying to write to them is a compile-time mismatch, not
/// a runtime `NotSupported`.
public interface IWritableMount : IMount
{
	/// Writes `data` to `locator`, creating it if missing and replacing it if present.
	/// Intermediate directories are created as needed. The stream is consumed but not
	/// owned by the mount - caller still deletes it.
	Result<void, MountError> Save(StringView locator, Stream data);

	/// Deletes the entry at `locator` (file or directory; directories are removed
	/// recursively). Returns `.Err(.NotFound)` if it doesn't exist.
	Result<void, MountError> Delete(StringView locator);

	/// Moves/renames the entry at `srcLocator` to `dstLocator` within this mount.
	/// Implementations should be atomic when the backing store allows it (a disk
	/// mount uses an OS rename on the same volume). Returns `.Err(.NotFound)` if
	/// the source is missing. Cross-mount moves are the caller's concern, not this.
	Result<void, MountError> Move(StringView srcLocator, StringView dstLocator);

	/// Creates the directory at `locator`, including intermediate directories.
	/// No-op (`.Ok`) if it already exists.
	Result<void, MountError> CreateDirectory(StringView locator);
}
