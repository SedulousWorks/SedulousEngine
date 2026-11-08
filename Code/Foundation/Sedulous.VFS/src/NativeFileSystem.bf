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

	/// Told, after the attempt, of each path a write through this mount touched: a file saved or
	/// deleted, a directory made or removed, both ends of a move. Whoever watches the folder for
	/// changes made elsewhere hears its own process's writes here, so they never come back to it as
	/// outside changes. Called on the thread that wrote. Owned.
	public delegate void(StringView path) OnWritten ~ delete _;

	private void Wrote(StringView path)
	{
		if (OnWritten != null)
			OnWritten(path);
	}

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

		bool written;
		{
			let stream = scope FileStream(full, .Write);
			written = stream.IsValid && ((data.Length == 0) || (stream.Write(data) == data.Length));
		}
		Wrote(path); // the stream closed: the file is as it will stay
		return written ? .Ok : .Err(.Internal);
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
		let deleted = DeleteFile(full);
		Wrote(path);
		return deleted ? .Ok : .Err(.Internal);
	}

	public Result<void, ErrorCode> Move(StringView from, StringView to)
	{
		let fullFrom = Resolve(from, .. scope String());
		let fullTo = Resolve(to, .. scope String());
		EnsureParentDirectories(fullTo);
		let moved = MoveFile(fullFrom, fullTo);
		Wrote(from);
		Wrote(to);
		return moved ? .Ok : .Err(.NotFound);
	}

	public Result<void, ErrorCode> DeleteDirectory(StringView path)
	{
		let full = Resolve(path, .. scope String());
		let removed = RemoveDirectory(full);
		Wrote(path);
		return removed ? .Ok : .Err(.NotFound);
	}

	public Result<void, ErrorCode> CreateDirectory(StringView path)
	{
		let full = Resolve(path, .. scope String());
		EnsureParentDirectories(full);
		let made = Sedulous.Core.IO.CreateDirectory(full);
		Wrote(path);
		return made ? .Ok : .Err(.Unknown);
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
