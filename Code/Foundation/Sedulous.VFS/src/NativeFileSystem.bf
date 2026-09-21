using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.VFS;

/// Backs logical paths with a real directory prefix.
///
/// Reads, enumerates, writes, stats and watches, so it implements every capability: one
/// class and a list of interfaces.
class NativeFileSystem : IFileSystem, IEnumerableFileSystem, IWritableFileSystem, IStatFileSystem, IWatchableFileSystem
{
	private String mRoot = new .() ~ delete _;
	/// Lazy: most mounts are never watched, and a change source carries a file snapshot.
	private NativeChangeSource mChangeSource ~ delete _;

	public this(StringView root)
	{
		mRoot.Set(root);
	}

	public StringView Root => mRoot;

	private void Resolve(StringView path, String outFull) => PathJoin(mRoot, path, outFull);

	// ---- IFileSystem ----

	public IStream Open(StringView path, FileMode mode)
	{
		let full = Resolve(path, .. scope String());
		let stream = new FileStream(full, mode);
		if (!stream.IsValid)
		{
			delete stream;
			return null;
		}
		return stream;
	}

	public bool Exists(StringView path)
	{
		let full = Resolve(path, .. scope String());
		return FileExists(full) || DirectoryExists(full);
	}

	// ---- IWatchableFileSystem ----

	public IChangeSource ChangeSource
	{
		get
		{
			if (mChangeSource == null)
				mChangeSource = new NativeChangeSource(this);
			return mChangeSource;
		}
	}

	// ---- IStatFileSystem ----

	public bool Stat(StringView path, out FileStatInfo info)
	{
		info = default;
		let full = Resolve(path, .. scope String());
		if (!FileStat(full, let size, let modified))
			return false;

		info.Size = size;
		info.ModifiedTicks = modified;
		return true;
	}

	// ---- IEnumerableFileSystem ----

	public Result<void, ErrorCode> Enumerate(StringView folder, List<DirEntry> outEntries)
	{
		let full = Resolve(folder, .. scope String());
		if (!ListDirectory(full, scope (name, isDirectory) => outEntries.Add(DirEntry(name, isDirectory))))
			return .Err(.NotFound);
		return .Ok;
	}

	// ---- IWritableFileSystem ----

	public Result<void, ErrorCode> Save(StringView path, Span<uint8> data)
	{
		let full = Resolve(path, .. scope String());
		EnsureParentDirectories(full);

		let stream = scope FileStream(full, .Write);
		if (!stream.IsValid)
			return .Err(.Internal);
		if ((data.Length > 0) && (stream.Write(data) != data.Length))
			return .Err(.Internal);
		return .Ok;
	}

	public Result<void, ErrorCode> Delete(StringView path)
	{
		let full = Resolve(path, .. scope String());
		// Checked rather than inferred from the platform call: unlink reports success for
		// a file that was never there on some targets and failure on others, and a mount
		// should answer the same question the same way everywhere. A caller that wants
		// this to be idempotent asks Exists first.
		if (!FileExists(full))
			return .Err(.NotFound);
		return DeleteFile(full) ? .Ok : .Err(.Internal);
	}

	public Result<void, ErrorCode> Move(StringView from, StringView to)
	{
		let fullFrom = Resolve(from, .. scope String());
		let fullTo = Resolve(to, .. scope String());
		EnsureParentDirectories(fullTo);
		return MoveFile(fullFrom, fullTo) ? .Ok : .Err(.NotFound);
	}

	public Result<void, ErrorCode> DeleteDirectory(StringView path)
	{
		let full = Resolve(path, .. scope String());
		return RemoveDirectory(full) ? .Ok : .Err(.NotFound);
	}

	public Result<void, ErrorCode> CreateDirectory(StringView path)
	{
		let full = Resolve(path, .. scope String());
		EnsureParentDirectories(full);
		return Sedulous.Core.IO.CreateDirectory(full) ? .Ok : .Err(.Unknown);
	}

	/// Creates every ancestor directory of a full path. The last component is the file
	/// itself and is left to the caller, which is why this walks separators rather than
	/// taking the parent: an intermediate directory may be missing too.
	private static void EnsureParentDirectories(StringView full)
	{
		for (int i = 1; i < full.Length; i++)
		{
			if (PathIsSeparator(full[i]))
				Sedulous.Core.IO.CreateDirectory(.(full, 0, i));
		}
	}
}
