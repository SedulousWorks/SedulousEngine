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
	/// MapFolder: the top-level name read from another folder (empty when nothing is mapped),
	/// and that folder on disk.
	private String mMappedName = new .() ~ delete _;
	private String mMappedRoot = new .() ~ delete _;
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

	/// Makes the top-level folder `name` of this mount another folder on disk, `folder`: a path
	/// whose first part is `name` resolves under `folder`, and listing the root shows `name` in
	/// place of any folder of that name under it (a project's Code/ beside its Sources/, read as
	/// one). One mapping; a second replaces the first.
	public void MapFolder(StringView name, StringView folder)
	{
		mMappedName.Set(name);
		mMappedRoot.Set(folder);
	}

	/// The file on disk that `path` (relative to the mount) names, into `outFull`.
	public void FullPath(StringView path, String outFull)
	{
		if (SourcePath.AfterFolder(path, mMappedName, let rest))
		{
			if (rest.IsEmpty)
				outFull.Set(mMappedRoot);
			else
				PathJoin(mMappedRoot, rest, outFull);
			return;
		}
		PathJoin(mRoot, path, outFull);
	}

	private void Resolve(StringView path, String outFull) => FullPath(path, outFull);

	/// Whether `folder` is the mount's root.
	private static bool IsTop(StringView folder) => folder.IsEmpty || (folder == ".");

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
		let before = outEntries.Count;
		if (!ListDirectory(full, scope (name, isDirectory) => outEntries.Add(DirEntry(name, isDirectory))))
			return .Err(.NotFound);
		if (!mMappedName.IsEmpty && IsTop(folder))
		{
			// The mapped folder stands in for any folder of its name under the root.
			for (int i = outEntries.Count - 1; i >= before; i--)
			{
				if (outEntries[i].Name == mMappedName)
				{
					outEntries[i].Dispose();
					outEntries.RemoveAt(i);
				}
			}
			if (DirectoryExists(mMappedRoot))
				outEntries.Add(DirEntry(mMappedName, true));
		}
		return .Ok;
	}

	// ---- IWritableFileSystem ----

	public Result<void, ErrorCode> Save(StringView path, Span<uint8> data)
	{
		let full = Resolve(path, .. scope String());
		EnsureParentDirectories(full);

		// Whole or not at all: a crash or a full disk mid-save leaves the old file, never a
		// truncated one.
		let written = WriteFileAtomic(full, data);
		Wrote(path); // the file is as it will stay
		return written;
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
