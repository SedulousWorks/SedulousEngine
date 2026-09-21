using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.VFS.Pak;

/// Read and enumerate over a .pak archive: the shipping counterpart to the disk backend.
///
/// Immutable at runtime, so it implements neither IWritableFileSystem nor
/// IWatchableFileSystem. It does not implement IStatFileSystem either, and that is
/// deliberate rather than an omission: content that cannot change has no modification time
/// worth asking for, and a consumer that needs an identity for it hashes the bytes.
class PakFileSystem : IFileSystem, IEnumerableFileSystem
{
	private struct Entry
	{
		public String Locator;
		public uint64 Offset;
		public uint64 StoredSize;
		public uint64 OriginalSize;
		public uint16 Compression;
	}

	private String mPath = new .() ~ delete _;
	private List<Entry> mEntries = new .() ~ delete _;
	/// Locator to index. Scanning the entry list for every lookup is fine for a handful of
	/// files and quadratic for an archive that ships a whole game.
	private Dictionary<String, int> mByLocator = new .() ~ delete _;
	private bool mIsValid;

	public this(StringView pakPath)
	{
		mPath.Set(pakPath);
		Load();
	}

	public ~this()
	{
		for (let entry in mEntries)
			delete entry.Locator;
	}

	/// True once the archive has opened and parsed. A false here is the whole error
	/// report: everything else answers as an empty archive would.
	public bool IsValid => mIsValid;
	public int EntryCount => mEntries.Count;

	// ---- IFileSystem ----

	/// Reads an entry into memory and hands back a stream over it, which THE CALLER OWNS.
	///
	/// The archive is reopened per call rather than kept open, so two readers never
	/// contend for one seek position.
	public IStream Open(StringView locator, FileMode mode)
	{
		if (!mIsValid || (mode != .Read))
			return null;

		if (!mByLocator.TryGetValue(scope String(locator), let index))
			return null;

		let entry = mEntries[index];
		if (entry.Compression != cCompressionNone)
			return null;

		let file = scope FileStream(mPath, .Read);
		if (!file.IsValid)
			return null;
		if (file.Seek((int64)entry.Offset, .Begin) < 0)
			return null;

		let stream = new MemoryStream();
		if (entry.StoredSize > 0)
		{
			let bytes = scope List<uint8>();
			let raw = bytes.GrowUninitialized((int)entry.StoredSize);
			if (file.Read(.(raw, (int)entry.StoredSize)) != (int)entry.StoredSize)
			{
				delete stream;
				return null;
			}
			stream.Write(.(raw, (int)entry.StoredSize));
		}
		stream.Seek(0, .Begin);
		return stream;
	}

	public bool Exists(StringView locator)
	{
		return mIsValid && mByLocator.ContainsKey(scope String(locator));
	}

	// ---- IEnumerableFileSystem ----

	/// Synthesises directories from the locators, since an archive stores a flat list and
	/// has no directory entries of its own.
	public Result<void, ErrorCode> Enumerate(StringView folder, List<DirEntry> outEntries)
	{
		if (!mIsValid)
			return .Err(.NotFound);

		for (let entry in mEntries)
		{
			if (!RelativeUnder(entry.Locator, folder, let relative))
				continue;

			// A separator in the remainder means this locator is under a subdirectory
			// rather than directly in the folder.
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

	private void Load()
	{
		let file = scope FileStream(mPath, .Read);
		if (!file.IsValid)
			return;

		let fileSize = file.Size();
		if (fileSize < cPakHeaderSize)
			return;

		let reader = scope BinaryReader(file);
		uint32 magic = 0;
		uint32 version = 0;
		uint64 entryCount = 0;
		uint64 tocOffset = 0;
		uint64 tocSize = 0;
		reader.Read(out magic);
		reader.Read(out version);
		reader.Read(out entryCount);
		reader.Read(out tocOffset);
		reader.Read(out tocSize);
		if (!reader.IsOk || (magic != cPakMagic) || (version != cPakVersion))
			return;

		// The header is the least trustworthy part of a corrupt file, and everything below
		// is sized from it, so tocOffset and entryCount are checked before either is trusted.
		if ((tocOffset < (uint64)cPakHeaderSize) || (tocOffset > (uint64)fileSize))
			return;
		if (tocSize > (uint64)fileSize - tocOffset)
			return;
		// The smallest an entry can be: a zero length locator and its fixed fields.
		const uint64 cMinEntrySize = 2 + 8 + 8 + 8 + 2;
		if (entryCount > (tocSize / cMinEntrySize))
			return;

		if (file.Seek((int64)tocOffset, .Begin) < 0)
			return;

		for (uint64 i < entryCount)
		{
			uint16 locatorLength = 0;
			if (!reader.Read(out locatorLength))
				return;

			let locator = new String();
			if (locatorLength > 0)
			{
				let raw = locator.PrepareBuffer((int)locatorLength);
				if (!reader.ReadBytes(.((uint8*)raw, (int)locatorLength)))
				{
					delete locator;
					return;
				}
			}

			Entry entry = default;
			entry.Locator = locator;
			reader.Read(out entry.Offset);
			reader.Read(out entry.StoredSize);
			reader.Read(out entry.OriginalSize);
			reader.Read(out entry.Compression);
			if (!reader.IsOk)
			{
				delete locator;
				return;
			}

			// An entry that points outside the file is corrupt, and following it would
			// read whatever happened to be at that offset.
			if ((entry.Offset > (uint64)fileSize) || (entry.StoredSize > (uint64)fileSize - entry.Offset))
			{
				delete locator;
				return;
			}

			mByLocator[locator] = mEntries.Count;
			mEntries.Add(entry);
		}
		mIsValid = true;
	}

	/// Is a locator under a folder? The remainder comes back in outRelative.
	private static bool RelativeUnder(StringView locator, StringView folder, out StringView outRelative)
	{
		outRelative = default;

		if (folder.IsEmpty)
		{
			outRelative = locator;
			return true;
		}
		if (locator.Length <= folder.Length + 1)
			return false;
		if (StringView(locator, 0, folder.Length) != folder)
			return false;
		if (locator[folder.Length] != '/')
			return false;

		outRelative = StringView(locator, folder.Length + 1);
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
