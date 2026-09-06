namespace Sedulous.VFS;

/// Capability: hand out a change source, for hot reload.
interface IWatchableFileSystem
{
	/// Owned by the filesystem, and valid for as long as it is.
	IChangeSource ChangeSource { get; }
}
