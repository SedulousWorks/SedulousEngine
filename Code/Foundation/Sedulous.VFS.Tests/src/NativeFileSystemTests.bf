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

		// Scoped, so the file is CLOSED before the directory is removed. A deferred
		// delete would run at the end of the method instead, and Windows refuses to
		// remove a directory holding an open file where POSIX simply unlinks it.
		{
			let stream = fs.Open("hello.txt", .Read);
			Test.Assert(stream != null);
			defer delete stream;

			uint8[9] buffer = default;
			Test.Assert(stream.Read(.(&buffer[0], 9)) == 9);
			Test.Assert(StringView((char8*)&buffer[0], 9) == "hello vfs");
		}

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

	/// A capability is asked for with `as`, so a backend that implements one is found and one
	/// that does not answers null.
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

	/// Each write through the mount names the path it touched, after the fact: what lets a
	/// watcher of the folder tell its own process's writes from someone else's.
	[Test]
	public static void EveryWriteNamesThePathItTouched()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);
		let heard = scope List<String>();
		defer { ClearAndDeleteItems!(heard); }
		int sizeWhenHeard = -1;
		fs.OnWritten = new [&heard, &sizeWhenHeard, =fs] (path) =>
			{
				heard.Add(new String(path));
				// Told once the file is as it stays: a stat then sees the whole of it.
				if ((path == "a/one.txt") && fs.Stat(path, let info))
					sizeWhenHeard = (int)info.Size;
			};

		uint8[3] payload = .(1, 2, 3);
		Test.Assert(fs.Save("a/one.txt", .(&payload[0], 3)) case .Ok);
		Test.Assert(sizeWhenHeard == 3);
		Test.Assert(fs.Move("a/one.txt", "b/two.txt") case .Ok);
		Test.Assert(fs.Delete("b/two.txt") case .Ok);
		Test.Assert(fs.CreateDirectory("c") case .Ok);
		Test.Assert(fs.DeleteDirectory("c") case .Ok);
		StringView[?] expected = .("a/one.txt", "a/one.txt", "b/two.txt", "b/two.txt", "c", "c");
		Test.Assert(heard.Count == expected.Count);
		for (int i < expected.Count)
			Test.Assert(heard[i] == expected[i]);

		// A delete of nothing touches nothing, and says nothing.
		Test.Assert(fs.Delete("nope.txt") case .Err(.NotFound));
		Test.Assert(heard.Count == expected.Count);
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// A save replaces the file whole, so a reader that had it open keeps the bytes it opened.
	/// A save truncating in place would leave that reader the new bytes, or nothing at all (a
	/// crash between the truncate and the write leaves the file empty).
	[Test]
	public static void ASaveReplacesTheFileWholeAndAnOpenReaderKeepsTheOldBytes()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);
		uint8[4] before = .(1, 2, 3, 4);
		uint8[1] after = .(9);
		Test.Assert(fs.Save("a.bin", .(&before[0], 4)) case .Ok);

		{
			let reader = fs.Open("a.bin", .Read);
			Test.Assert(reader != null);
			defer delete reader;
			Test.Assert(fs.Save("a.bin", .(&after[0], 1)) case .Ok);
			uint8[4] held = default;
			Test.Assert(reader.Read(.(&held[0], 4)) == 4);
			Test.Assert(held[3] == 4);
		}

		let now = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(kScratch, "a.bin", .. scope String()), now) case .Ok);
		Test.Assert((now.Count == 1) && (now[0] == 9));
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// A mapped top-level folder: a project's Code/ read through its Sources/ mount. A path starting
	/// with the name resolves under the other folder; listing the root shows the mapped folder in
	/// place of a folder of the same name under the root; a watch sweeps into it.
	[Test]
	public static void AMappedTopLevelFolderIsReadFromAnotherFolderOnDisk()
	{
		const String root = "scratch_vfs_map";
		RemoveDirectoryRecursive(root);
		Test.Assert(CreateDirectory(root));
		let sources = PathJoin(root, "Sources", .. scope .());
		let code = PathJoin(root, "Code", .. scope .());
		let disk = scope NativeFileSystem(".");
		uint8[1] art = .(1);
		uint8[2] script = .(2, 3);
		uint8[1] hidden = .(9);
		Test.Assert(disk.Save("scratch_vfs_map/Sources/Models/a.bin", .(&art[0], 1)) case .Ok);
		Test.Assert(disk.Save("scratch_vfs_map/Code/Weapon.cs", .(&script[0], 2)) case .Ok);
		Test.Assert(disk.Save("scratch_vfs_map/Sources/Code/Old.cs", .(&hidden[0], 1)) case .Ok);

		let project = scope NativeFileSystem(sources);
		project.MapFolder("Code", code);
		Test.Assert(project.Exists("Models/a.bin"));
		Test.Assert(project.Exists("Code/Weapon.cs"));
		Test.Assert(!project.Exists("Code/Old.cs"), "the folder of that name under Sources/ is hidden");
		Test.Assert(project.FullPath("Code/Weapon.cs", .. scope .()) == PathJoin(code, "Weapon.cs", .. scope .()));
		Test.Assert(project.FullPath("Code", .. scope .()) == code);
		// A longer name is not it.
		Test.Assert(project.FullPath("Codex/x.cs", .. scope .()) == PathJoin(sources, "Codex/x.cs", .. scope .()));

		// Writes land in the mapped folder.
		Test.Assert(project.Save("Code/Enemies/Enemy.cs", .(&script[0], 2)) case .Ok);
		Test.Assert(disk.Exists("scratch_vfs_map/Code/Enemies/Enemy.cs"));

		// The root lists Code once, and it is the mapped one.
		{
			let top = scope List<DirEntry>();
			defer { for (var entry in ref top) entry.Dispose(); }
			Test.Assert(project.Enumerate("", top) case .Ok);
			int codes = 0;
			for (let entry in top)
			{
				if (entry.Name == "Code")
					codes++;
			}
			Test.Assert(codes == 1);
			let inCode = scope List<DirEntry>();
			defer { for (var entry in ref inCode) entry.Dispose(); }
			Test.Assert(project.Enumerate("Code", inCode) case .Ok);
			bool hasWeapon = false;
			bool hasOld = false;
			for (let entry in inCode)
			{
				hasWeapon = hasWeapon || (entry.Name == "Weapon.cs");
				hasOld = hasOld || (entry.Name == "Old.cs");
			}
			Test.Assert(hasWeapon && !hasOld);
		}

		// A watch of the root sees a file added under the mapped folder.
		let changes = project.ChangeSource;
		changes.Track("");
		Test.Assert(disk.Save("scratch_vfs_map/Code/New.cs", .(&script[0], 2)) case .Ok);
		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		changes.Poll(changed);
		bool sawNew = false;
		for (let path in changed)
			sawNew = sawNew || (path == "Code/New.cs");
		Test.Assert(sawNew);

		Test.Assert(RemoveDirectoryRecursive(root));
	}
}
