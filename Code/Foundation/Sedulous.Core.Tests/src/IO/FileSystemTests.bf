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

	[Test]
	public static void ListDirectoryYieldsImmediateChildren()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));

		let sub = PathJoin(kScratch, "sub", .. scope String());
		Test.Assert(CreateDirectory(sub));

		uint8[2] payload = .(1, 2);
		Test.Assert(WriteFile(PathJoin(kScratch, "a.bin", .. scope String()), .(&payload[0], 2)) case .Ok);
		Test.Assert(WriteFile(PathJoin(kScratch, "b.bin", .. scope String()), .(&payload[0], 2)) case .Ok);
		// A grandchild, to prove enumeration does not recurse.
		Test.Assert(WriteFile(PathJoin(sub, "deep.bin", .. scope String()), .(&payload[0], 2)) case .Ok);

		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		var directories = 0;
		Test.Assert(ListDirectory(kScratch, scope [&] (name, isDirectory) =>
			{
				names.Add(new String(name));
				if (isDirectory)
					directories++;
			}));

		Test.Assert(names.Count == 3, scope $"saw {names.Count} entries");
		Test.Assert(directories == 1);

		var sawA = false, sawB = false, sawSub = false, sawDeep = false;
		for (let name in names)
		{
			if (name == "a.bin") sawA = true;
			if (name == "b.bin") sawB = true;
			if (name == "sub") sawSub = true;
			if (name == "deep.bin") sawDeep = true;
		}
		Test.Assert(sawA && sawB && sawSub);
		Test.Assert(!sawDeep, "enumeration is one level, not a walk");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void ListDirectoryOfAMissingDirectoryFails()
	{
		Test.Assert(!ListDirectory("no_such_directory_at_all", scope (name, isDirectory) => {}));
	}

	[Test]
	public static void FileStatReportsSizeAndTime()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let path = PathJoin(kScratch, "stat.bin", .. scope String());

		uint8[7] payload = default;
		Test.Assert(WriteFile(path, .(&payload[0], 7)) case .Ok);

		int64 size = 0;
		int64 modified = 0;
		Test.Assert(FileStat(path, out size, out modified));
		Test.Assert(size == 7);
		Test.Assert(modified > 0, "a real timestamp, not a zero placeholder");

		// A directory is not a regular file, and neither is something absent.
		int64 ignoredSize = 0;
		int64 ignoredTime = 0;
		Test.Assert(!FileStat(kScratch, out ignoredSize, out ignoredTime));
		Test.Assert(!FileStat(PathJoin(kScratch, "missing.bin", .. scope String()), out ignoredSize, out ignoredTime));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// The size has to follow the file, or a stat-sweep watcher would never see a rewrite.
	[Test]
	public static void FileStatFollowsARewrite()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let path = PathJoin(kScratch, "rewrite.bin", .. scope String());

		uint8[4] small = default;
		Test.Assert(WriteFile(path, .(&small[0], 4)) case .Ok);
		int64 first = 0;
		int64 time = 0;
		Test.Assert(FileStat(path, out first, out time));

		uint8[9] larger = default;
		Test.Assert(WriteFile(path, .(&larger[0], 9)) case .Ok);
		int64 second = 0;
		Test.Assert(FileStat(path, out second, out time));

		Test.Assert(first == 4);
		Test.Assert(second == 9);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	[Test]
	public static void MoveFileMovesIt()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let from = PathJoin(kScratch, "from.bin", .. scope String());
		let to = PathJoin(kScratch, "to.bin", .. scope String());

		uint8[3] payload = .(7, 8, 9);
		Test.Assert(WriteFile(from, .(&payload[0], 3)) case .Ok);
		Test.Assert(MoveFile(from, to));
		Test.Assert(!FileExists(from));
		Test.Assert(FileExists(to));

		let readBack = scope List<uint8>();
		Test.Assert(ReadFile(to, readBack) case .Ok);
		Test.Assert(readBack.Count == 3);
		Test.Assert(readBack[0] == 7);

		Test.Assert(!MoveFile(PathJoin(kScratch, "absent.bin", .. scope String()), to));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Discovery anchors at the executable, so it has to name a directory that exists.
	[Test]
	public static void TheExecutableAndWorkingDirectoriesResolve()
	{
		let exeDir = GetExecutableDirectory(.. scope String());
		Test.Assert(!exeDir.IsEmpty);
		Test.Assert(DirectoryExists(exeDir), scope $"executable directory '{exeDir}'");

		let cwd = GetCurrentDirectory(.. scope String());
		Test.Assert(!cwd.IsEmpty);
		Test.Assert(DirectoryExists(cwd), scope $"working directory '{cwd}'");
	}
}
