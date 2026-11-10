using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Zip;

namespace Sedulous.Zip.Tests;

/// Zip archives made by the system's tools (Data/Tests/Zip, from make-fixtures.sh): Info-ZIP's zip
/// with deflated, stored and empty files and folders; one stored outright; Python's zipfile for a
/// name outside the folder, a damaged entry, a comment and Unix modes. Read, checked and extracted,
/// modes kept; also the CRC-32 against its known values and which entry names are safe.
class ZipTests
{
	private static void Fixture(StringView name, String outPath)
	{
		let root = FindDataRoot(.. scope String());
		PathJoin(root, scope $"Tests/Zip/{name}", outPath);
	}

	private static StringView Text(List<uint8> bytes) => .((char8*)bytes.Ptr, bytes.Count);
	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	private static ZipEntry Named(ZipArchive zip, StringView name)
	{
		for (let e in zip.Entries)
		{
			if (e.Name == name)
				return e;
		}
		return null;
	}

	private static void Scene(String outText)
	{
		for (int i = 1; i <= 200; i++)
			outText.AppendF("line {} of a scene that compresses well\n", i);
	}

	[Test]
	public static void Crc32OfKnownStrings()
	{
		Test.Assert(Crc32(Bytes("")) == 0);
		Test.Assert(Crc32(Bytes("123456789")) == 0xCBF43926);
		Test.Assert(Crc32(Bytes("The quick brown fox jumps over the lazy dog")) == 0x414FA339);
		// In two parts, as one.
		let first = Crc32(Bytes("1234"));
		Test.Assert(Crc32(Bytes("56789"), first) == 0xCBF43926);
	}

	[Test]
	public static void EntryNamesThatStayInTheirFolder()
	{
		Test.Assert(IsSafeEntryName("Game/Project.xml"));
		Test.Assert(IsSafeEntryName("Game/"));
		Test.Assert(IsSafeEntryName("a..b/c"));
		Test.Assert(!IsSafeEntryName(""));
		Test.Assert(!IsSafeEntryName("../outside.txt"));
		Test.Assert(!IsSafeEntryName("Game/../../x"));
		Test.Assert(!IsSafeEntryName("Game\\..\\..\\x"));
		Test.Assert(!IsSafeEntryName("/etc/passwd"));
		Test.Assert(!IsSafeEntryName("C:/Windows/x"));
		Test.Assert(!IsSafeEntryName(".."));
	}

	[Test]
	public static void AProjectZippedByZipReadsEachEntryInflatedOrStoredAndChecked()
	{
		let file = scope FileStream(Fixture("project.zip", .. scope .()), .Read);
		Test.Assert(file.IsValid);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		Test.Assert(zip.Entries.Count == 7);
		let scene = Named(zip, "Game/Scenes/Level1.scene");
		let noise = Named(zip, "Game/Audio/noise.bin");
		let empty = Named(zip, "Game/Empty.txt");
		let folder = Named(zip, "Game/Scenes/");
		Test.Assert((scene != null) && (noise != null) && (empty != null) && (folder != null));
		Test.Assert(scene.Method == 8);
		Test.Assert(noise.Method == 0);
		Test.Assert(folder.Directory);
		Test.Assert(zip.TotalSize == scene.Size + noise.Size + 23);

		let bytes = scope List<uint8>();
		Test.Assert(zip.Read(scene, bytes, error), error);
		Test.Assert(Text(bytes) == Scene(.. scope .()));
		Test.Assert(zip.Read(noise, bytes, error), error);
		Test.Assert(bytes.Count == 3000);
		Test.Assert(zip.Read(empty, bytes, error), error);
		Test.Assert(bytes.IsEmpty);
		Test.Assert(zip.Read(Named(zip, "Game/Project.xml"), bytes, error), error);
		Test.Assert(Text(bytes) == "<Project name=\"Game\"/>\n");
	}

	/// A stored entry's bytes lie in the archive where DataOffset says, past its local header.
	[Test]
	public static void AStoredEntrysDataLiesWhereItsOffsetSays()
	{
		let path = Fixture("project.zip", .. scope .());
		let file = scope FileStream(path, .Read);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		let noise = Named(zip, "Game/Audio/noise.bin");
		Test.Assert(noise.Method == 0);
		Test.Assert(zip.DataOffset(noise, let offset, error), error);
		Test.Assert(offset > noise.LocalHeader + 30);

		let extracted = scope List<uint8>();
		Test.Assert(zip.Read(noise, extracted, error), error);
		let inPlace = scope List<uint8>();
		inPlace.Count = 3000;
		Test.Assert(file.Seek((int64)offset, .Begin) == (int64)offset);
		Test.Assert(file.Read(.(inPlace.Ptr, 3000)) == 3000);
		Test.Assert(extracted.Count == 3000);
		for (int i < 3000)
			Test.Assert(inPlace[i] == extracted[i]);

		// No archive open: no offset.
		let closed = scope ZipArchive();
		Test.Assert(!closed.DataOffset(noise, let none, error));
		Test.Assert(none == 0);
		Test.Assert(error.Contains("local header", true), error);
	}

	[Test]
	public static void ExtractingWritesEveryFileUnderTheFolderAndReportsItsProgress()
	{
		let into = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_zip_extract", .. scope .());
		RemoveDirectoryRecursive(into);
		let file = scope FileStream(Fixture("project.zip", .. scope .()), .Read);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		uint64 last = 0;
		uint64 total = 0;
		int calls = 0;
		Test.Assert(zip.ExtractAll(into, error, scope [&](done, all) =>
			{
				Test.Assert(done >= last);
				last = done;
				total = all;
				calls++;
			}), error);
		Test.Assert(calls == 4); // the four files; folders say nothing
		Test.Assert(last == total);
		Test.Assert(total == zip.TotalSize);
		let scene = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(into, "Game/Scenes/Level1.scene", .. scope .()), scene) case .Ok);
		Test.Assert(Text(scene) == Scene(.. scope .()));
		Test.Assert(FileExists(PathJoin(into, "Game/Empty.txt", .. scope .())));
		Test.Assert(DirectoryExists(PathJoin(into, "Game/Audio", .. scope .())));

		// A stored archive (zip -0) extracts the same files.
		let stored = scope FileStream(Fixture("stored.zip", .. scope .()), .Read);
		let plain = scope ZipArchive();
		Test.Assert(plain.Open(stored, error), error);
		for (let e in plain.Entries)
			Test.Assert(e.Method == 0);
		let bytes = scope List<uint8>();
		Test.Assert(plain.Read(Named(plain, "Game/Scenes/Level1.scene"), bytes, error), error);
		Test.Assert(Text(bytes) == Scene(.. scope .()));
		RemoveDirectoryRecursive(into);
	}

	/// Python's zipfile keeps each file's Unix mode in its entry: an executable (0755) and a plain
	/// file (0644) from a Unix host, read as such, and the executable extracted runnable; an entry
	/// from a DOS host carries 0755 in its attributes too, which says nothing there, and extracts
	/// with a new file's default.
	[Test]
	public static void AnEntrysUnixModeIsKeptOnExtract()
	{
		let file = scope FileStream(Fixture("modes.zip", .. scope .()), .Read);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		Test.Assert(zip.Entries.Count == 3);
		let tool = Named(zip, "bin/tool");
		let readme = Named(zip, "readme.txt");
		let dos = Named(zip, "dos.txt");
		Test.Assert((tool != null) && (readme != null) && (dos != null));
		Test.Assert(tool.Mode == 0x1ED, "0755");
		Test.Assert(readme.Mode == 0x1A4, "0644");
		Test.Assert(dos.Mode == 0, "a DOS host's attributes hold no mode");

		let into = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_zip_modes", .. scope .());
		RemoveDirectoryRecursive(into);
		defer RemoveDirectoryRecursive(into);
		Test.Assert(zip.ExtractAll(into, error), error);
		let toolPath = PathJoin(into, "bin/tool", .. scope .());
		let readmePath = PathJoin(into, "readme.txt", .. scope .());
		let dosPath = PathJoin(into, "dos.txt", .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(toolPath, bytes) case .Ok);
		Test.Assert(Text(bytes) == "#!/bin/sh\necho tool\n");
		Test.Assert(ReadFile(readmePath, bytes..Clear()) case .Ok);
		Test.Assert(Text(bytes) == "read me\n");
		Test.Assert(ReadFile(dosPath, bytes..Clear()) case .Ok);
		Test.Assert(Text(bytes) == "from DOS\n");
#if BF_PLATFORM_LINUX || BF_PLATFORM_MACOS
		Test.Assert(access(toolPath.CStr(), cExecutable) == 0, "the executable runs");
		Test.Assert(access(readmePath.CStr(), cExecutable) != 0, "a plain file does not");
		Test.Assert(access(readmePath.CStr(), cReadable | cWritable) == 0, "and is its owner's to read and write");
		Test.Assert(access(dosPath.CStr(), cExecutable) != 0, "the DOS entry's 0755 was not taken");
#endif
	}

#if BF_PLATFORM_LINUX || BF_PLATFORM_MACOS
	private const int32 cExecutable = 1; // X_OK
	private const int32 cWritable = 2; // W_OK
	private const int32 cReadable = 4; // R_OK

	[CLink]
	private static extern int32 access(char8* path, int32 mode);
#endif

	[Test]
	public static void ANameOutsideTheFolderRefusesTheArchiveBeforeAnythingIsWritten()
	{
		let outer = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_zip_escape", .. scope .());
		let into = PathJoin(outer, "inner", .. scope .());
		RemoveDirectoryRecursive(outer);
		let file = scope FileStream(Fixture("escape.zip", .. scope .()), .Read);
		let zip = scope ZipArchive();
		let error = scope String();
		Test.Assert(zip.Open(file, error), error);
		Test.Assert(!zip.ExtractAll(into, error));
		Test.Assert(error.Contains("../outside.txt", true), error);
		Test.Assert(!DirectoryExists(into));
		Test.Assert(!FileExists(PathJoin(outer, "outside.txt", .. scope .())));
	}

	[Test]
	public static void ADamagedEntryACommentAndWhatIsNotAZip()
	{
		let error = scope String();
		{
			let file = scope FileStream(Fixture("damaged.zip", .. scope .()), .Read);
			let zip = scope ZipArchive();
			Test.Assert(zip.Open(file, error), error);
			let bytes = scope List<uint8>();
			Test.Assert(!zip.Read(zip.Entries[0], bytes, error));
			Test.Assert(error.Contains("damaged", true), error);
			Test.Assert(bytes.IsEmpty);
		}
		{
			// The end record found behind a 1000-byte comment.
			let file = scope FileStream(Fixture("commented.zip", .. scope .()), .Read);
			let zip = scope ZipArchive();
			Test.Assert(zip.Open(file, error), error);
			let bytes = scope List<uint8>();
			Test.Assert(zip.Read(zip.Entries[0], bytes, error), error);
			Test.Assert(Text(bytes) == "after a comment");
		}
		{
			let junk = scope MemoryStream();
			junk.Write(Bytes("this is a text file, long enough to look for an end record in it"));
			let zip = scope ZipArchive();
			Test.Assert(!zip.Open(junk, error));
			Test.Assert(error.Contains("not a zip", true), error);
		}
	}
}
