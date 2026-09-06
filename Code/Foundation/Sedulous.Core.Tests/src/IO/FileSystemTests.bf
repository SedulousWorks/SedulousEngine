using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

class FileSystemTests
{
	private const String kScratch = "scratch_filesystem";

	[Test]
	public static void ReadFileWriteFileRoundTrip()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let path = PathJoin(kScratch, "payload.bin", .. scope String());

		uint8[5] payload = .(1, 2, 3, 4, 5);
		Test.Assert(WriteFile(path, .(&payload[0], 5)) case .Ok);
		Test.Assert(FileExists(path));

		let readBack = scope List<uint8>();
		Test.Assert(ReadFile(path, readBack) case .Ok);
		Test.Assert(readBack.Count == 5);
		for (int i < 5)
			Test.Assert(readBack[i] == payload[i]);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// An empty file is a file, not a failure, and reading one empties the output rather
	/// than leaving it alone.
	[Test]
	public static void AnEmptyFileRoundTrips()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let path = PathJoin(kScratch, "empty.bin", .. scope String());

		Test.Assert(WriteFile(path, Span<uint8>()) case .Ok);
		Test.Assert(FileExists(path));

		let readBack = scope List<uint8>()..Add(0xFF);
		Test.Assert(ReadFile(path, readBack) case .Ok);
		Test.Assert(readBack.Count == 0, "the output is replaced, not appended to");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void ReadingAMissingFileReportsNotFound()
	{
		let readBack = scope List<uint8>()..Add(0xFF);
		let result = ReadFile("no_such_file_anywhere.bin", readBack);

		if (result case .Err(let code))
			Test.Assert(code == .NotFound);
		else
			Test.Assert(false, "reading a missing file must fail");
		Test.Assert(readBack.Count == 0, "a failed read leaves nothing behind");
	}

	[Test]
	public static void WritingToAMissingDirectoryFails()
	{
		uint8[1] payload = .(1);
		Test.Assert(WriteFile("no_such_directory_at_all/x.bin", .(&payload[0], 1)) case .Err);
	}

	[Test]
	public static void DirectoryCreateExistsRemove()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(!DirectoryExists(kScratch));

		Test.Assert(CreateDirectory(kScratch));
		Test.Assert(DirectoryExists(kScratch));

		Test.Assert(RemoveDirectory(kScratch));
		Test.Assert(!DirectoryExists(kScratch));
	}

	/// The raw primitive is rmdir, which only removes an EMPTY directory and fails quietly
	/// otherwise. That quiet failure is how stale scratch directories accumulate, so the
	/// difference between the two is worth pinning.
	[Test]
	public static void RemoveDirectoryRecursiveDeletesAPopulatedTree()
	{
		RemoveDirectoryRecursive(kScratch);

		let sub = PathJoin(kScratch, "sub", .. scope String());
		let inner = PathJoin(sub, "inner", .. scope String());

		Test.Assert(CreateDirectory(kScratch));
		Test.Assert(CreateDirectory(sub));
		Test.Assert(CreateDirectory(inner));

		uint8[3] payload = .(1, 2, 3);
		let top = PathJoin(kScratch, "top.bin", .. scope String());
		let mid = PathJoin(sub, "mid.bin", .. scope String());
		let leaf = PathJoin(inner, "leaf.bin", .. scope String());
		Test.Assert(WriteFile(top, .(&payload[0], 3)) case .Ok);
		Test.Assert(WriteFile(mid, .(&payload[0], 3)) case .Ok);
		Test.Assert(WriteFile(leaf, .(&payload[0], 3)) case .Ok);

		// The raw primitive cannot touch a populated directory.
		Test.Assert(!RemoveDirectory(kScratch));
		Test.Assert(DirectoryExists(kScratch));

		// The recursive helper takes the whole tree, and is idempotent afterwards.
		Test.Assert(RemoveDirectoryRecursive(kScratch));
		Test.Assert(!DirectoryExists(kScratch));
		Test.Assert(RemoveDirectoryRecursive(kScratch), "a directory already gone counts as gone");
	}

	[Test]
	public static void DeleteFileRemovesAFile()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let path = PathJoin(kScratch, "doomed.bin", .. scope String());
		uint8[1] payload = .(9);
		Test.Assert(WriteFile(path, .(&payload[0], 1)) case .Ok);
		Test.Assert(FileExists(path));

		Test.Assert(DeleteFile(path));
		Test.Assert(!FileExists(path));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
}
