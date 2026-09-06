using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.VFS.Tests;

class NativeFileSystemTests
{
	private const String kScratch = "scratch_vfs_native";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	private static void Write(StringView path, StringView text)
	{
		let full = PathJoin(kScratch, path, .. scope String());
		Test.Assert(WriteFile(full, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	[Test]
	public static void ReadsThroughALogicalPath()
	{
		FreshScratch();
		Write("hello.txt", "hello vfs");

		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(fs.Exists("hello.txt"));
		Test.Assert(!fs.Exists("missing.txt"));

		let stream = fs.Open("hello.txt", .Read);
		Test.Assert(stream != null);
		defer delete stream;

		uint8[9] buffer = default;
		Test.Assert(stream.Read(.(&buffer[0], 9)) == 9);
		Test.Assert(StringView((char8*)&buffer[0], 9) == "hello vfs");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Opening something that is not there answers null rather than a stream that fails on
	/// first use, so a caller checks once.
	[Test]
	public static void OpeningAMissingFileAnswersNull()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(fs.Open("nope.txt", .Read) == null);
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Raptor asks for capabilities through virtual AsEnumerable/AsWritable/AsStat methods,
	/// because C++ has no real interfaces and it builds with RTTI off. Beef has both, so
	/// the whole As family is just `as`.
	[Test]
	public static void CapabilitiesAreOrdinaryInterfaces()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);
		IFileSystem asFileSystem = fs;

		Test.Assert((asFileSystem as IEnumerableFileSystem) != null);
		Test.Assert((asFileSystem as IWritableFileSystem) != null);
		Test.Assert((asFileSystem as IStatFileSystem) != null);
		Test.Assert((asFileSystem as IWatchableFileSystem) != null);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void WritableAndEnumerableRoundTrip()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		uint8[3] payload = .(1, 2, 3);
		// Parent directories are made on the way, so a nested save needs no setup.
		Test.Assert(fs.Save("nested/deep/file.bin", .(&payload[0], 3)) case .Ok);
		Test.Assert(fs.Exists("nested/deep/file.bin"));

		let entries = scope List<DirEntry>();
		defer { for (var entry in ref entries) entry.Dispose(); }
		Test.Assert(fs.Enumerate("nested/deep", entries) case .Ok);
		Test.Assert(entries.Count == 1);
		Test.Assert(entries[0].Name == "file.bin");
		Test.Assert(!entries[0].IsDirectory);

		// An empty folder means the mount root.
		let atRoot = scope List<DirEntry>();
		defer { for (var entry in ref atRoot) entry.Dispose(); }
		Test.Assert(fs.Enumerate("", atRoot) case .Ok);
		Test.Assert(atRoot.Count == 1);
		Test.Assert(atRoot[0].Name == "nested");
		Test.Assert(atRoot[0].IsDirectory);

		Test.Assert(fs.Delete("nested/deep/file.bin") case .Ok);
		Test.Assert(!fs.Exists("nested/deep/file.bin"));
		Test.Assert(fs.Delete("nested/deep/file.bin") case .Err(.NotFound));

		Test.Assert(fs.Enumerate("no/such/folder", scope List<DirEntry>()) case .Err(.NotFound));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Writing a file makes its parents implicitly, so this exists for the one case that
	/// does not: a directory that has to survive while it is still empty.
	[Test]
	public static void CreateDirectoryPersistsAnEmptyDirectory()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		Test.Assert(fs.CreateDirectory("groups/empty") case .Ok);
		Test.Assert(fs.Exists("groups/empty"));

		let entries = scope List<DirEntry>();
		defer { for (var entry in ref entries) entry.Dispose(); }
		Test.Assert(fs.Enumerate("groups", entries) case .Ok);
		Test.Assert(entries.Count == 1);
		Test.Assert(entries[0].Name == "empty");
		Test.Assert(entries[0].IsDirectory);

		// Idempotent, so a rescan does not have to check first.
		Test.Assert(fs.CreateDirectory("groups/empty") case .Ok);

		Test.Assert(fs.DeleteDirectory("groups/empty") case .Ok);
		Test.Assert(!fs.Exists("groups/empty"));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void MoveRenamesWithinTheMount()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		uint8[2] payload = .(9, 9);
		Test.Assert(fs.Save("a.bin", .(&payload[0], 2)) case .Ok);
		Test.Assert(fs.Move("a.bin", "moved/b.bin") case .Ok);

		Test.Assert(!fs.Exists("a.bin"));
		Test.Assert(fs.Exists("moved/b.bin"), "the destination's parents were made");
		Test.Assert(fs.Move("a.bin", "c.bin") case .Err(.NotFound));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void StatReportsSizeAndTime()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		uint8[5] payload = default;
		Test.Assert(fs.Save("stat.bin", .(&payload[0], 5)) case .Ok);

		FileStatInfo info = default;
		Test.Assert(fs.Stat("stat.bin", out info));
		Test.Assert(info.Size == 5);
		Test.Assert(info.ModifiedTicks > 0);

		// A directory is not a regular file, and neither is something absent.
		Test.Assert(!fs.Stat("", out info));
		Test.Assert(!fs.Stat("missing.bin", out info));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
}
