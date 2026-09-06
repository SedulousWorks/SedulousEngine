using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.VFS.Pak;

namespace Sedulous.VFS.Pak.Tests;

class PakTests
{
	private const String kScratch = "scratch_pak";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	private static void PakPath(String outPath) => PathJoin(kScratch, "test.pak", outPath);

	private static void Add(PakBuilder builder, StringView locator, StringView text)
	{
		builder.Add(locator, .((uint8*)text.Ptr, text.Length));
	}

	private static void ReadAll(IStream stream, String outText)
	{
		outText.Clear();
		let size = (int)stream.Size();
		if (size == 0)
			return;
		let buffer = scope List<uint8>();
		let raw = buffer.GrowUninitialized(size);
		let read = stream.Read(.(raw, size));
		outText.Append(StringView((char8*)raw, read));
	}

	[Test]
	public static void BuildOpenReadEnumerate()
	{
		FreshScratch();
		let path = PakPath(.. scope String());

		{
			let builder = scope PakBuilder();
			Add(builder, "root.txt", "at the root");
			Add(builder, "Assets/a.txt", "asset a");
			Add(builder, "Assets/b.txt", "asset b");
			Add(builder, "Assets/Deep/c.txt", "asset c");
			Test.Assert(builder.Count == 4);
			Test.Assert(builder.Write(path) case .Ok);
		}
		Test.Assert(FileExists(path));

		let pak = scope PakFileSystem(path);
		Test.Assert(pak.IsValid);
		Test.Assert(pak.EntryCount == 4);

		Test.Assert(pak.Exists("Assets/a.txt"));
		Test.Assert(!pak.Exists("Assets/missing.txt"));

		let text = scope String();
		{
			let stream = pak.Open("Assets/a.txt", .Read);
			Test.Assert(stream != null);
			defer delete stream;
			ReadAll(stream, text);
		}
		Test.Assert(text == "asset a");

		{
			let stream = pak.Open("Assets/Deep/c.txt", .Read);
			Test.Assert(stream != null);
			defer delete stream;
			ReadAll(stream, text);
		}
		Test.Assert(text == "asset c");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// An archive stores a flat list of locators and has no directory entries, so the
	/// directories a caller sees are synthesised from the paths.
	[Test]
	public static void EnumerationSynthesisesDirectories()
	{
		FreshScratch();
		let path = PakPath(.. scope String());
		{
			let builder = scope PakBuilder();
			Add(builder, "root.txt", "x");
			Add(builder, "Assets/a.txt", "x");
			Add(builder, "Assets/b.txt", "x");
			Add(builder, "Assets/Deep/c.txt", "x");
			// A sibling whose name STARTS WITH "Assets". Without it, being under a folder
			// and merely starting with its name cannot be told apart, and a prefix match
			// passes every assertion below.
			Add(builder, "AssetsExtra/d.txt", "x");
			Test.Assert(builder.Write(path) case .Ok);
		}

		let pak = scope PakFileSystem(path);

		let atRoot = scope List<DirEntry>();
		defer { for (var entry in ref atRoot) entry.Dispose(); }
		Test.Assert(pak.Enumerate("", atRoot) case .Ok);
		Test.Assert(atRoot.Count == 3, scope $"saw {atRoot.Count}");

		var sawFile = false, sawDirectory = false;
		for (let entry in atRoot)
		{
			if ((entry.Name == "root.txt") && !entry.IsDirectory) sawFile = true;
			// One directory entry, not one per file inside it.
			if ((entry.Name == "Assets") && entry.IsDirectory) sawDirectory = true;
		}
		Test.Assert(sawFile && sawDirectory);

		let inAssets = scope List<DirEntry>();
		defer { for (var entry in ref inAssets) entry.Dispose(); }
		Test.Assert(pak.Enumerate("Assets", inAssets) case .Ok);
		Test.Assert(inAssets.Count == 3, "two files and the Deep directory, and nothing from AssetsExtra");
		for (let entry in inAssets)
			Test.Assert(entry.Name != "d.txt", "a sibling that merely shares the prefix is not under it");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Immutable at runtime, and honestly so: the capabilities it does not have are simply
	/// not implemented, rather than implemented to fail.
	[Test]
	public static void AnArchiveAdvertisesOnlyWhatItCanDo()
	{
		FreshScratch();
		let path = PakPath(.. scope String());
		{
			let builder = scope PakBuilder();
			Add(builder, "a.txt", "x");
			Test.Assert(builder.Write(path) case .Ok);
		}

		let pak = scope PakFileSystem(path);
		IFileSystem asFileSystem = pak;

		Test.Assert((asFileSystem as IEnumerableFileSystem) != null);
		Test.Assert((asFileSystem as IWritableFileSystem) == null);
		Test.Assert((asFileSystem as IWatchableFileSystem) == null);
		// Content that cannot change has no modification time worth asking for, so a
		// consumer that needs an identity for it hashes the bytes instead.
		Test.Assert((asFileSystem as IStatFileSystem) == null);

		// And opening for write is refused rather than silently opening for read.
		Test.Assert(pak.Open("a.txt", .Write) == null);
		Test.Assert(pak.Open("a.txt", .ReadWrite) == null);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void EmptyArchivesAndEmptyEntries()
	{
		FreshScratch();

		let emptyPak = PathJoin(kScratch, "empty.pak", .. scope String());
		{
			let builder = scope PakBuilder();
			Test.Assert(builder.Write(emptyPak) case .Ok);
		}
		let empty = scope PakFileSystem(emptyPak);
		Test.Assert(empty.IsValid, "an archive with no entries is still an archive");
		Test.Assert(empty.EntryCount == 0);
		Test.Assert(!empty.Exists("anything"));

		let entries = scope List<DirEntry>();
		defer { for (var entry in ref entries) entry.Dispose(); }
		Test.Assert(empty.Enumerate("", entries) case .Ok);
		Test.Assert(entries.Count == 0);

		// A zero byte entry is a file, not an absence.
		let withEmpty = PathJoin(kScratch, "withempty.pak", .. scope String());
		{
			let builder = scope PakBuilder();
			builder.Add("zero.bin", Span<uint8>());
			Add(builder, "one.txt", "x");
			Test.Assert(builder.Write(withEmpty) case .Ok);
		}
		let pak = scope PakFileSystem(withEmpty);
		Test.Assert(pak.IsValid);
		Test.Assert(pak.Exists("zero.bin"));
		let stream = pak.Open("zero.bin", .Read);
		Test.Assert(stream != null);
		Test.Assert(stream.Size() == 0);
		delete stream;

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void ANonPakFileIsRejected()
	{
		FreshScratch();

		let notAPak = PathJoin(kScratch, "notapak.bin", .. scope String());
		let text = "this is definitely not an archive, but it is long enough to be one";
		Test.Assert(WriteFile(notAPak, .((uint8*)text.Ptr, text.Length)) case .Ok);

		let pak = scope PakFileSystem(notAPak);
		Test.Assert(!pak.IsValid);
		Test.Assert(pak.EntryCount == 0);
		Test.Assert(!pak.Exists("anything"));
		Test.Assert(pak.Open("anything", .Read) == null);
		Test.Assert(pak.Enumerate("", scope List<DirEntry>()) case .Err(.NotFound));

		// A file that does not exist at all behaves the same way.
		let missing = scope PakFileSystem(PathJoin(kScratch, "no.pak", .. scope String()));
		Test.Assert(!missing.IsValid);

		// And so does one too short to hold a header.
		let stub = PathJoin(kScratch, "stub.pak", .. scope String());
		uint8[4] tiny = default;
		Test.Assert(WriteFile(stub, .(&tiny[0], 4)) case .Ok);
		Test.Assert(!(scope PakFileSystem(stub)).IsValid);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// A pak mounts behind the same interfaces as a directory, which is the whole point:
	/// shipping swaps the backend and nothing above the mount changes.
	[Test]
	public static void AnArchiveMountsLikeADirectory()
	{
		FreshScratch();
		let path = PakPath(.. scope String());
		{
			let builder = scope PakBuilder();
			Add(builder, "Assets/shipped.txt", "from the archive");
			Test.Assert(builder.Write(path) case .Ok);
		}

		let pak = scope PakFileSystem(path);
		let vfs = scope VirtualFileSystem();
		vfs.Mount("data", pak);

		Test.Assert(vfs.Exists("data://Assets/shipped.txt"));
		let text = scope String();
		let stream = vfs.Open("data://Assets/shipped.txt", .Read);
		Test.Assert(stream != null);
		ReadAll(stream, text);
		delete stream;
		Test.Assert(text == "from the archive");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Writes a header by hand, so a corrupt one can be built on purpose.
	private static void WriteHeader(StringView path, uint32 magic, uint32 version, uint64 entryCount,
		uint64 tocOffset, uint64 tocSize, int trailingBytes)
	{
		let stream = scope MemoryStream();
		let writer = scope BinaryWriter(stream);
		writer.Write(magic);
		writer.Write(version);
		writer.Write(entryCount);
		writer.Write(tocOffset);
		writer.Write(tocSize);
		for (int i < trailingBytes)
			writer.Write((uint8)0);
		Test.Assert(WriteFile(path, stream.Bytes) case .Ok);
	}

	/// The header is the least trustworthy part of a corrupt file, and everything below it
	/// is sized from it. Raptor seeks to tocOffset and loops entryCount times without
	/// asking whether either could be real, so a damaged byte becomes a wild seek or an
	/// allocation of whatever the count happened to be.
	[Test]
	public static void AnImpossibleHeaderIsRejectedRatherThanFollowed()
	{
		FreshScratch();
		let path = PathValid(.. scope String());

		// A count far larger than the table could hold.
		WriteHeader(path, cPakMagic, cPakVersion, 0xFFFFFFFF, 32, 16, 16);
		Test.Assert(!(scope PakFileSystem(path)).IsValid, "entry count cannot fit the table");

		// A table starting past the end of the file.
		WriteHeader(path, cPakMagic, cPakVersion, 1, 0xFFFFFFFF, 16, 16);
		Test.Assert(!(scope PakFileSystem(path)).IsValid, "table offset is past the end");

		// A table claiming to run past the end of the file.
		WriteHeader(path, cPakMagic, cPakVersion, 1, 32, 0xFFFFFFFF, 16);
		Test.Assert(!(scope PakFileSystem(path)).IsValid, "table runs past the end");

		// A table inside the header itself.
		WriteHeader(path, cPakMagic, cPakVersion, 1, 8, 16, 16);
		Test.Assert(!(scope PakFileSystem(path)).IsValid, "table overlaps the header");

		// A wrong version is refused even with the right magic, so a future format does
		// not get read as this one.
		WriteHeader(path, cPakMagic, cPakVersion + 1, 0, 32, 0, 16);
		Test.Assert(!(scope PakFileSystem(path)).IsValid);

		// And a plausible empty archive still loads, so the guards are not just refusing
		// everything.
		WriteHeader(path, cPakMagic, cPakVersion, 0, 32, 0, 0);
		Test.Assert((scope PakFileSystem(path)).IsValid);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	private static void PathValid(String outPath) => PathJoin(kScratch, "crafted.pak", outPath);
}
