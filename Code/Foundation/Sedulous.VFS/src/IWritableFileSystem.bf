using System;
using Sedulous.Core;

namespace Sedulous.VFS;

/// Capability: change what is on the mount.
///
/// Save and Delete are the whole contract; the rest have defaults that report
/// NotSupported, since an archive or a read-only backend can honestly do neither.
interface IWritableFileSystem
{
	Result<void, ErrorCode> Save(StringView path, Span<uint8> data);
	Result<void, ErrorCode> Delete(StringView path);

	/// Creates a directory and any missing ancestors, idempotently.
	///
	/// Writing a file makes its parents implicitly, so this exists for the one case that
	/// does not: persisting a directory that is still empty.
	Result<void, ErrorCode> CreateDirectory(StringView path)
	{
		return .Err(.NotSupported);
	}

	/// Renames a file or directory within the mount.
	Result<void, ErrorCode> Move(StringView from, StringView to)
	{
		return .Err(.NotSupported);
	}

	/// Removes an EMPTY directory. Emptying it first is the caller's business: deleting a
	/// tree is a policy decision, and policy does not belong under the mount.
	Result<void, ErrorCode> DeleteDirectory(StringView path)
	{
		return .Err(.NotSupported);
	}
}
