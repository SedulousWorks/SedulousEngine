using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Zip;

namespace Sedulous.VFS.Zip;

/// A read-only VFS backend over the files under one folder of a zip archive (an Android APK's
/// assets/Game/, say).
///
/// A stored entry is read in place, as a region of the archive file (FileRegionStream), so a
/// large stored file (a game's Content.pak) is never copied whole; a deflated one is inflated
/// into memory on Open. StoredRegion names where a stored entry lies, so another backend can read
/// it in place too (a PakFileSystem over the pak inside the APK). Separate from Sedulous.VFS so
/// the zip reader, and its zlib, stay out of it.
class ZipFileSystem : IFileSystem, IEnumerableFileSystem
{
	private class Entry
	{
		/// Its path below the folder.
		public String Path = new .() ~ delete _;
		/// Where its data starts in the archive.
		public uint64 DataOffset;
		/// Its bytes once extracted.
		public uint64 Size;
		/// 0 stored, 8 deflate.
		public uint16 Method;
		/// BORROWED: the archive's entry, which lives as long as the archive.
		public ZipEntry Source;
	}

	private String mPath = new .() ~ delete _;
	private String mError = new .() ~ delete _;
	/// The reader's stream (inflating), kept open for the archive's life.
	private FileStream mArchiveFile ~ delete _;
	private ZipArchive mArchive = new .() ~ delete _;
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// Path to index, keyed by views of the entries' own paths. A scan per lookup is quadratic for
	/// an archive holding a whole game.
	private Dictionary<StringView, int> mByPath = new .() ~ delete _;
	/// The archive's reader is one stream, so one inflate at a time.
	private Monitor mReadLock = new .() ~ delete _;
	private bool mIsValid;

	/// The files of the zip at `zipPath` under `folder` (a prefix such as "assets/Game"; empty for
	/// the whole archive), each named by its path below it.
	public this(StringView zipPath, StringView folder)
	{
		mPath.Set(zipPath);
		mArchiveFile = new FileStream(zipPath, .Read);
		Load(folder);
	}

	/// True when the archive opened and its directory read.
	public bool IsValid => mIsValid;
	/// Why it did not, said for a person.
	public StringView Error => mError;
	public int EntryCount => mEntries.Count;
	public StringView ArchivePath => mPath;

	/// Where a stored (uncompressed) file lies in the archive file, to read in place. False for a
	/// file it does not hold or one that is compressed.
	public bool StoredRegion(StringView path, out uint64 outOffset, out uint64 outSize)
	{
		outOffset = 0;
		outSize = 0;
		let entry = Find(path);
		if ((entry == null) || (entry.Method != 0))
			return false;
		outOffset = entry.DataOffset;
		outSize = entry.Size;
		return true;
	}

	// ---- IFileSystem ----

	/// A stream over a file, which THE CALLER OWNS: a region of the archive for a stored file,
	/// its inflated bytes for a deflated one. Null for a file it does not hold, or any mode but
	/// Read.
	public IStream Open(StringView path, FileMode mode)
	{
		let entry = (mIsValid && (mode == .Read)) ? Find(path) : null;
		if (entry == null)
			return null;
		if (entry.Method == 0)
		{
			// In place: its own handle on the archive, so readers on other threads never share a
			// position.
			let region = new FileRegionStream(mPath, entry.DataOffset, entry.Size);
			if (!region.IsValid)
			{
				delete region;
				return null;
			}
			return region;
		}
		let bytes = scope List<uint8>();
		let error = scope String();
		using (mReadLock.Enter())
		{
			if (!mArchive.Read(entry.Source, bytes, error))
				return null;
		}
		let stream = new MemoryStream();
		if (!bytes.IsEmpty)
			stream.Write(bytes);
		stream.Seek(0, .Begin);
		return stream;
	}

	/// A file it holds, or a folder with a file below it.
	public bool Exists(StringView path)
	{
		if (!mIsValid)
			return false;
		if (Find(path) != null)
			return true;
		for (let entry in mEntries)
		{
			if (RelativeUnder(entry.Path, path, ?))
				return true;
		}
		return false;
	}

	// ---- IEnumerableFileSystem ----

	/// Synthesises folders from the paths, as a zip need not list its folders.
	public Result<void, ErrorCode> Enumerate(StringView folder, List<DirEntry> outEntries)
	{
		if (!mIsValid)
			return .Err(.NotFound);

		for (let entry in mEntries)
		{
			if (!RelativeUnder(entry.Path, folder, let relative))
				continue;

			let slash = relative.IndexOf('/');
			if (slash < 0)
			{
				outEntries.Add(DirEntry(relative, false));
				continue;
			}

			let directory = StringView(relative, 0, slash);
			if (!ContainsDirectory(outEntries, directory))
				outEntries.Add(DirEntry(directory, true));
		}
		return .Ok;
	}

	// ---- internals ----

	private void Load(StringView folder)
	{
		if (!mArchiveFile.IsValid)
		{
			mError.Set(scope $"cannot open {mPath}");
			return;
		}
		if (!mArchive.Open(mArchiveFile, mError))
			return;
		for (let zipEntry in mArchive.Entries)
		{
			if (zipEntry.Directory)
				continue;
			if (!RelativeUnder(zipEntry.Name, folder, let below))
				continue;
			if (!mArchive.DataOffset(zipEntry, let dataOffset, mError))
				return;
			let entry = new Entry();
			entry.Path.Set(below);
			entry.DataOffset = dataOffset;
			entry.Size = zipEntry.Size;
			entry.Method = zipEntry.Method;
			entry.Source = zipEntry;
			mByPath[entry.Path] = mEntries.Count;
			mEntries.Add(entry);
		}
		mIsValid = true;
	}

	private Entry Find(StringView path)
	{
		if (mByPath.TryGetValue(path, let index))
			return mEntries[index];
		return null;
	}

	/// Whether `path` lies below `folder` (empty: everything does), with the rest in
	/// `outRelative`.
	private static bool RelativeUnder(StringView path, StringView folder, out StringView outRelative)
	{
		outRelative = default;
		var under = folder;
		while (!under.IsEmpty && (under[under.Length - 1] == '/'))
			under = StringView(under, 0, under.Length - 1);
		if (under.IsEmpty)
		{
			outRelative = path;
			return !path.IsEmpty;
		}
		if ((path.Length <= under.Length + 1) || (StringView(path, 0, under.Length) != under) || (path[under.Length] != '/'))
			return false;
		outRelative = StringView(path, under.Length + 1);
		return true;
	}

	private static bool ContainsDirectory(List<DirEntry> entries, StringView name)
	{
		for (let entry in entries)
		{
			if (entry.IsDirectory && (entry.Name == name))
				return true;
		}
		return false;
	}
}
