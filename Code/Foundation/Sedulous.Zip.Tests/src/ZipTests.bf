using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Zip;

namespace Sedulous.Zip.Tests;

/// Zip archives made by the system's tools (Data/Tests/Zip, from make-fixtures.sh): Info-ZIP's zip
/// with deflated, stored and empty files and folders; one stored outright; Python's zipfile for a
/// name outside the folder, a damaged entry and a comment. Read, checked and extracted; also the
/// CRC-32 against its known values and which entry names are safe.
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
