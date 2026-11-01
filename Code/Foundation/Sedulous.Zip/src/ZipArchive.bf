using System;
using System.Collections;
using Sedulous.Core.IO;
using stb_image;

namespace Sedulous.Zip;

/// One file or folder in an archive, as its central directory names it.
class ZipEntry
{
	/// Its path in the archive, with forward slashes ("Scenes/Level1.scene").
	public String Name = new .() ~ delete _;
	/// Its bytes once extracted.
	public uint64 Size = 0;
	/// Its bytes in the archive.
	public uint64 CompressedSize = 0;
	/// The CRC-32 of its extracted bytes.
	public uint32 Crc = 0;
	/// 0 stored, 8 deflate.
	public uint16 Method = 0;
	/// Where its local header starts.
	public uint64 LocalHeader = 0;
	/// A folder (its name ends with '/').
	public bool Directory = false;
}

static
{
	/// The CRC-32 table (IEEE 802.3, as zip uses).
	private static uint32[256] sCrcTable = MakeCrcTable();

	private static uint32[256] MakeCrcTable()
	{
		uint32[256] values = ?;
		for (uint32 i < 256)
		{
			var c = i;
			for (int k < 8)
				c = ((c & 1) != 0) ? ((uint32)0xEDB88320 ^ (c >> 1)) : (c >> 1);
			values[i] = c;
		}
		return values;
	}

	/// The CRC-32 (IEEE 802.3, as zip uses) of `bytes`, continuing from `crc`.
	public static uint32 Crc32(Span<uint8> bytes, uint32 crc = 0)
	{
		var c = ~crc;
		for (let b in bytes)
			c = sCrcTable[(c ^ b) & 0xFF] ^ (c >> 8);
		return ~c;
	}

	/// Whether an entry's name stays inside the folder it is extracted to: a relative path with no
	/// "..", no drive letter, and no empty name. Backslashes count as separators.
	public static bool IsSafeEntryName(StringView name)
	{
		if (name.IsEmpty || (name[0] == '/') || (name[0] == '\\'))
			return false;
		if ((name.Length >= 2) && (name[1] == ':'))
			return false; // a drive letter
		int start = 0;
		for (int i <= name.Length)
		{
			if ((i < name.Length) && (name[i] != '/') && (name[i] != '\\'))
				continue;
			if (StringView(name, start, i - start) == "..")
				return false;
			start = i + 1;
		}
		return true;
	}
}

/// A zip archive (PKWARE's APPNOTE format, as zip tools and GitHub release assets write it), read
/// for the sample downloads.
///
/// The central directory is read from the end of the stream; each entry is stored or deflated
/// (inflated by stb's zlib decoder, which Image.IO already links for PNG) and checked against its
/// CRC-32. Extracting writes every entry under a folder, refusing the whole archive before anything
/// is written when a name would land outside it. Not read: Zip64 (over 4 GB or 65535 entries),
/// encrypted entries, and compression methods other than stored and deflate.
class ZipArchive
{
	private const uint32 cEndOfDirectory = 0x06054b50;
	private const uint32 cDirectoryEntry = 0x02014b50;
	private const uint32 cLocalHeader = 0x04034b50;
	private const uint32 cZip64Locator = 0x07064b50;
	/// The end record without its comment.
	private const int cEndSize = 22;
	/// A directory entry without its name and extras.
	private const int cDirectoryEntrySize = 46;
	/// A local header without its name and extras.
	private const int cLocalHeaderSize = 30;

	/// BORROWED: the caller's, outliving the archive.
	private IStream mStream = null;
	private List<ZipEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	public List<ZipEntry> Entries => mEntries;

	/// The extracted bytes of all its files together.
	public uint64 TotalSize
	{
		get
		{
			uint64 total = 0;
			for (let e in mEntries)
				total += e.Directory ? 0 : e.Size;
			return total;
		}
	}

	private static uint16 U16(uint8* p) => (uint16)((uint16)p[0] | ((uint16)p[1] << 8));
	private static uint32 U32(uint8* p) => (uint32)p[0] | ((uint32)p[1] << 8) | ((uint32)p[2] << 16) | ((uint32)p[3] << 24);

	/// Reads `size` bytes at `at` into `outBytes`; false when the stream ends first.
	private static bool ReadAt(IStream stream, uint64 at, int size, List<uint8> outBytes)
	{
		outBytes.Count = size;
		if (stream.Seek((int64)at, .Begin) < 0)
			return false;
		return (size == 0) || (stream.Read(.(outBytes.Ptr, size)) == size);
	}

	/// Reads the central directory of the zip in `stream`, which must outlive the archive. False
	/// with `outError`, said for a person, when it is not a zip this reads.
	public bool Open(IStream stream, String outError)
	{
		mStream = stream;
		ClearAndDeleteItems!(mEntries);
		let length = stream.Size();
		if (length < cEndSize)
		{
			outError.Set("not a zip archive (too short)");
			return false;
		}
		// The end record is the last thing in the file, before a comment of up to 64 KB.
		let tail = (int)Math.Min(length, (int64)(cEndSize + 0xFFFF));
		let end = scope List<uint8>();
		if (!ReadAt(stream, (uint64)(length - tail), tail, end))
		{
			outError.Set("the archive could not be read");
			return false;
		}
		int at = tail - cEndSize + 1;
		bool found = false;
		while (at-- > 0)
		{
			if (U32(end.Ptr + at) == cEndOfDirectory)
			{
				found = true;
				break;
			}
		}
		if (!found)
		{
			outError.Set("not a zip archive (no end of central directory)");
			return false;
		}
		let record = end.Ptr + at;
		let count = U16(record + 10);
		let directorySize = U32(record + 12);
		let directoryAt = U32(record + 16);
		if (((at >= 20) && (U32(end.Ptr + at - 20) == cZip64Locator)) || (count == 0xFFFF) || (directoryAt == 0xFFFFFFFF))
		{
			outError.Set("a Zip64 archive (over 4 GB or 65535 entries) is not read");
			return false;
		}
		if ((uint64)directoryAt + directorySize > (uint64)length)
		{
			outError.Set("the archive is cut short (its directory runs past its end)");
			return false;
		}
		let directory = scope List<uint8>();
		if (!ReadAt(stream, directoryAt, (int)directorySize, directory))
		{
			outError.Set("the archive's directory could not be read");
			return false;
		}
		int p = 0;
		for (int i < count)
		{
			if ((p + cDirectoryEntrySize > directory.Count) || (U32(directory.Ptr + p) != cDirectoryEntry))
			{
				outError.Set("the archive's directory is damaged");
				return false;
			}
			let e = directory.Ptr + p;
			let flags = U16(e + 8);
			let nameLength = (int)U16(e + 28);
			let extraLength = (int)U16(e + 30);
			let commentLength = (int)U16(e + 32);
			if (p + cDirectoryEntrySize + nameLength + extraLength + commentLength > directory.Count)
			{
				outError.Set("the archive's directory is damaged");
				return false;
			}
			let entry = new ZipEntry();
			entry.Method = U16(e + 10);
			entry.Crc = U32(e + 16);
			entry.CompressedSize = U32(e + 20);
			entry.Size = U32(e + 24);
			entry.LocalHeader = U32(e + 42);
			entry.Name.Set(StringView((char8*)(e + cDirectoryEntrySize), nameLength));
			entry.Directory = entry.Name.EndsWith('/');
			if ((flags & 1) != 0)
			{
				outError.Set(scope $"{entry.Name} is encrypted, which is not read");
				delete entry;
				return false;
			}
			if ((entry.CompressedSize == 0xFFFFFFFF) || (entry.Size == 0xFFFFFFFF) || (entry.LocalHeader == 0xFFFFFFFF))
			{
				outError.Set("a Zip64 archive (over 4 GB or 65535 entries) is not read");
				delete entry;
				return false;
			}
			mEntries.Add(entry);
			p += cDirectoryEntrySize + nameLength + extraLength + commentLength;
		}
		return true;
	}

	/// An entry's bytes, inflated and checked against its CRC, replacing what `outBytes` held.
	/// False with `outError` when they cannot be read, do not inflate, or do not match.
	public bool Read(ZipEntry entry, List<uint8> outBytes, String outError)
	{
		outBytes.Clear();
		if (mStream == null)
		{
			outError.Set("no archive is open");
			return false;
		}
		if ((entry.Method != 0) && (entry.Method != 8))
		{
			outError.Set(scope $"{entry.Name} is compressed by method {entry.Method}, which is not read (only stored and deflate)");
			return false;
		}
		// The data follows the local header, whose name and extras may differ from the directory's.
		let header = scope List<uint8>();
		if (!ReadAt(mStream, entry.LocalHeader, cLocalHeaderSize, header) || (U32(header.Ptr) != cLocalHeader))
		{
			outError.Set(scope $"{entry.Name}: its local header is missing or damaged");
			return false;
		}
		let dataAt = entry.LocalHeader + cLocalHeaderSize + U16(header.Ptr + 26) + U16(header.Ptr + 28);
		if ((entry.CompressedSize > (uint64)int32.MaxValue) || (entry.Size > (uint64)int32.MaxValue))
		{
			outError.Set(scope $"{entry.Name} is over 2 GB, which is not read");
			return false;
		}
		let packed = scope List<uint8>();
		if (!ReadAt(mStream, dataAt, (int)entry.CompressedSize, packed))
		{
			outError.Set(scope $"{entry.Name}: the archive ends before its data does");
			return false;
		}
		if (entry.Method == 0)
		{
			if (entry.CompressedSize != entry.Size)
			{
				outError.Set(scope $"{entry.Name}: a stored entry whose sizes differ");
				return false;
			}
			outBytes.AddRange(packed);
		}
		else
		{
			outBytes.Count = (int)entry.Size;
			let got = (entry.Size == 0) ? 0
				: stbi_zlib_decode_noheader_buffer((char8*)outBytes.Ptr, (int32)entry.Size, (char8*)packed.Ptr, (int32)packed.Count);
			if (got != (int32)entry.Size)
			{
				outError.Set(scope $"{entry.Name} does not inflate (the archive is damaged)");
				outBytes.Clear();
				return false;
			}
		}
		if (Crc32(outBytes) != entry.Crc)
		{
			outError.Set(scope $"{entry.Name} does not match its checksum (the archive is damaged)");
			outBytes.Clear();
			return false;
		}
		return true;
	}

	/// Writes every entry under `directory` (made as needed), telling `progress` the bytes written
	/// of the total after each file. Every name is checked first: one that would land outside
	/// `directory` refuses the archive, and nothing is written. False with `outError` at the first
	/// failure (the files before it stay).
	public bool ExtractAll(StringView directory, String outError, delegate void(uint64 done, uint64 total) progress = null)
	{
		for (let entry in mEntries)
		{
			if (!IsSafeEntryName(entry.Name))
			{
				outError.Set(scope $"the archive names a file outside its folder ({entry.Name}): nothing was extracted");
				return false;
			}
		}
		if (!CreateDirectory(directory))
		{
			outError.Set(scope $"{directory} could not be made");
			return false;
		}
		let total = TotalSize;
		uint64 done = 0;
		let bytes = scope List<uint8>();
		for (let entry in mEntries)
		{
			let path = PathJoin(directory, entry.Name, .. scope String());
			if (entry.Directory)
			{
				if (!CreateDirectory(path))
				{
					outError.Set(scope $"{path} could not be made");
					return false;
				}
				continue;
			}
			if (!Read(entry, bytes, outError))
				return false;
			CreateDirectory(PathParent(path, .. scope String()));
			if (WriteFile(path, bytes) case .Err)
			{
				outError.Set(scope $"{path} could not be written");
				return false;
			}
			done += entry.Size;
			if (progress != null)
				progress(done, total);
		}
		return true;
	}
}
