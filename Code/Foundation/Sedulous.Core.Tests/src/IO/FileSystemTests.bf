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

	/// A whole-file write lands entire, a shorter file over a longer one included, and leaves
	/// no temporary behind; one that cannot happen fails and touches nothing.
	[Test]
	public static void WriteFileAtomicReplacesAFileWholeAndLeavesNoTemporaryBehind()
	{
		let scratch = "scratch_filesystem_atomic";
		RemoveDirectoryRecursive(scratch);
		Test.Assert(CreateDirectory(scratch));
		let path = PathJoin(scratch, "save.bin", .. scope String());

		// A new file, then a shorter one over it: the second write is the whole file, not a
		// prefix over the first's tail.
		uint8[5] first = .(1, 2, 3, 4, 5);
		uint8[2] second = .(9, 8);
		Test.Assert(WriteFileAtomic(path, .(&first[0], 5)) case .Ok);
		Test.Assert(WriteFileAtomic(path, .(&second[0], 2)) case .Ok);
		let readBack = scope List<uint8>();
		Test.Assert(ReadFile(path, readBack) case .Ok);
		Test.Assert((readBack.Count == 2) && (readBack[0] == 9) && (readBack[1] == 8));
		// No temporary is left beside it: the folder holds the file alone.
		int entries = 0;
		Test.Assert(ListDirectory(scratch, scope [&](name, isDirectory) => { entries++; }));
		Test.Assert(entries == 1);

		// A write that cannot happen (its directory does not exist) fails and makes nothing.
		let nowhere = PathJoin(scratch, "no_such_dir/save.bin", .. scope String());
		Test.Assert(WriteFileAtomic(nowhere, .(&first[0], 5)) case .Err);
		Test.Assert(!DirectoryExists(PathJoin(scratch, "no_such_dir", .. scope String())));

		Test.Assert(RemoveDirectoryRecursive(scratch));
	}

	/// A save over a file a reader holds open replaces it, and the reader keeps the file it
	/// opened. On Windows a rename refused to replace a file another handle had open, so every
	/// save over a file a reader held failed.
	[Test]
	public static void ASaveReplacesAFileAReaderHasOpen()
	{
		let scratch = "scratch_filesystem_reader";
		RemoveDirectoryRecursive(scratch);
		Test.Assert(CreateDirectory(scratch));
		let path = PathJoin(scratch, "save.bin", .. scope String());
		uint8[3] first = .(1, 2, 3);
		uint8[2] second = .(9, 8);
		Test.Assert(WriteFileAtomic(path, .(&first[0], 3)) case .Ok);
		{
			let reader = scope System.IO.FileStream();
			Test.Assert(reader.Open(path, .Read, .ReadWrite | .Delete) case .Ok);
			Test.Assert(WriteFileAtomic(path, .(&second[0], 2)) case .Ok);
			uint8[3] held = default;
			Test.Assert(reader.TryRead(.(&held[0], 3)) case .Ok(3));
			Test.Assert((held[0] == 1) && (held[2] == 3)); // the file it opened
		}
		let readBack = scope List<uint8>();
		Test.Assert(ReadFile(path, readBack) case .Ok);
		Test.Assert((readBack.Count == 2) && (readBack[0] == 9));
		Test.Assert(RemoveDirectoryRecursive(scratch));
	}

	/// An unreadable file is moved out of the way under a free name, its bytes kept.
	[Test]
	public static void AnUnreadableFileIsSetAsideUnderAFreeNameItsBytesKept()
	{
		let scratch = "scratch_filesystem_aside";
		RemoveDirectoryRecursive(scratch);
		Test.Assert(CreateDirectory(scratch));
		let path = PathJoin(scratch, "damaged.xml", .. scope String());
		uint8[1] bytes = .((uint8)'x');
		Test.Assert(WriteFile(path, .(&bytes[0], 1)) case .Ok);
		let first = scope String();
		Test.Assert(SetAsideUnreadable(path, first) case .Ok);
		Test.Assert(first == scope String(path)..Append(".unreadable"));
		Test.Assert(!FileExists(path));

		Test.Assert(WriteFile(path, .(&bytes[0], 1)) case .Ok);
		let second = scope String();
		Test.Assert(SetAsideUnreadable(path, second) case .Ok);
		Test.Assert(second == scope String(path)..Append(".unreadable-2"));
		Test.Assert(FileExists(first));
		let kept = scope List<uint8>();
		Test.Assert(ReadFile(second, kept) case .Ok);
		Test.Assert((kept.Count == 1) && (kept[0] == (uint8)'x'));

		Test.Assert(SetAsideUnreadable(PathJoin(scratch, "no_such_file.xml", .. scope String()), scope String()) case .Err);
		Test.Assert(RemoveDirectoryRecursive(scratch));
	}

	/// Two writers of one file never share a temporary, and a watcher skips it by its ending.
	[Test]
	public static void AWholeFileWritesTemporaryIsUniqueToTheWriteAndEndsInTmp()
	{
		let a = TemporaryPathFor("dir/save.bin", .. scope String());
		let b = TemporaryPathFor("dir/save.bin", .. scope String());
		Test.Assert(a != b);
		Test.Assert(a.StartsWith("dir/save.bin."));
		Test.Assert(a.EndsWith(".tmp"));
	}

#if BF_PLATFORM_LINUX
	/// A file's permission bits as `stat` prints them ("600"): its first line, as a run under a
	/// sanitizer's preload has the child report after it.
	private static void PermissionBits(StringView path, String outBits)
	{
		let result = scope ProcessResult();
		Sedulous.Core.Process.Run("/usr/bin/stat", scope StringView[]("-c", "%a", path), result);
		let output = StringView(result.Output);
		let lineEnd = output.IndexOf('\n');
		outBits.Append((lineEnd >= 0) ? output.Substring(0, lineEnd) : output);
		outBits.Trim();
	}

	/// A secret written owner-only is its owner's alone, over a file written shared.
	[Test]
	public static void ASecretWrittenOwnerOnlyIsItsOwnersAloneOverAFileThatWasNot()
	{
		let scratch = "scratch_filesystem_secret";
		RemoveDirectoryRecursive(scratch);
		Test.Assert(CreateDirectory(scratch));
		let path = PathJoin(scratch, "secret.txt", .. scope String());
		uint8[1] open = .((uint8)'o');
		uint8[1] secret = .((uint8)'s');
		Test.Assert(WriteFileAtomic(path, .(&open[0], 1)) case .Ok);
		Test.Assert(WriteFileAtomic(path, .(&secret[0], 1), .OwnerOnly) case .Ok);
		Test.Assert(PermissionBits(path, .. scope String()) == "600");
		let readBack = scope List<uint8>();
		Test.Assert(ReadFile(path, readBack) case .Ok);
		Test.Assert((readBack.Count == 1) && (readBack[0] == (uint8)'s'));
		Test.Assert(RemoveDirectoryRecursive(scratch));
	}
#endif

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
		Test.Assert(ListDirectory(kScratch, scope [&names, &directories] (name, isDirectory) =>
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

	/// A recursive delete removes a link, never what it points to: a folder outside the tree,
	/// reached through a link inside it and through a link as the root.
	[Test]
	public static void ARecursiveDeleteRemovesALinkNeverWhatItPointsTo()
	{
		RemoveDirectoryRecursive("scratch_rml_outside");
		RemoveDirectoryRecursive("scratch_rml_tree");
		RemoveDirectoryRecursive("scratch_rml_root");
		Test.Assert(CreateDirectory("scratch_rml_outside"));
		uint8[1] payload = .(7);
		Test.Assert(WriteFile("scratch_rml_outside/keep.bin", payload) case .Ok);
		Test.Assert(CreateDirectory("scratch_rml_tree"));
		let outside = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_rml_outside", .. scope .());
		if (!CreateSymbolicLink(outside, "scratch_rml_tree/inside", true) || !CreateSymbolicLink(outside, "scratch_rml_root", true))
		{
			// This platform refuses symbolic links here (Windows without developer mode).
			RemoveDirectoryRecursive("scratch_rml_tree");
			RemoveDirectoryRecursive("scratch_rml_outside");
			return;
		}
		Test.Assert(IsSymbolicLink("scratch_rml_root"));
		Test.Assert(!IsSymbolicLink("scratch_rml_outside"));

		Test.Assert(RemoveDirectoryRecursive("scratch_rml_tree"), "a link inside the tree");
		Test.Assert(!DirectoryExists("scratch_rml_tree"));
		Test.Assert(FileExists("scratch_rml_outside/keep.bin"));

		Test.Assert(RemoveDirectoryRecursive("scratch_rml_root"), "the root itself a link");
		Test.Assert(!IsSymbolicLink("scratch_rml_root"));
		Test.Assert(FileExists("scratch_rml_outside/keep.bin"));
		Test.Assert(RemoveDirectoryRecursive("scratch_rml_outside"));
	}
}
