using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.VFS.Tests;

/// The stat-sweep change source: what hot reload polls.
class ChangeSourceTests
{
	private const String kScratch = "scratch_vfs_watch";

	private static void Save(NativeFileSystem fs, StringView path, int size)
	{
		let payload = scope uint8[size];
		Test.Assert(fs.Save(path, .(payload.Ptr, size)) case .Ok);
	}

	private static bool Contains(List<String> changed, StringView path)
	{
		for (let entry in changed)
		{
			if (entry == path)
				return true;
		}
		return false;
	}

	[Test]
	public static void DetectsAddsEditsAndRemovals()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let fs = scope NativeFileSystem(kScratch);

		Save(fs, "a.bin", 4);
		Save(fs, "sub/b.bin", 4);

		let watcher = fs.ChangeSource;
		watcher.Track("");

		// Tracking baselines what is already there, so nothing is a change yet.
		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		Test.Assert(!watcher.Poll(changed), "pre-existing files are not changes");
		Test.Assert(changed.Count == 0);

		// An add, anywhere in the tree.
		Save(fs, "sub/c.bin", 4);
		Test.Assert(watcher.Poll(changed));
		Test.Assert(Contains(changed, "sub/c.bin"), scope $"saw {changed.Count} changes");
		ClearAndDeleteItems!(changed);

		// An edit, seen through the size.
		Save(fs, "a.bin", 16);
		Test.Assert(watcher.Poll(changed));
		Test.Assert(Contains(changed, "a.bin"));
		ClearAndDeleteItems!(changed);

		// A removal.
		Test.Assert(fs.Delete("sub/b.bin") case .Ok);
		Test.Assert(watcher.Poll(changed));
		Test.Assert(Contains(changed, "sub/b.bin"));
		ClearAndDeleteItems!(changed);

		// And nothing when nothing moved.
		Test.Assert(!watcher.Poll(changed));
		Test.Assert(changed.Count == 0);

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Tracking a subdirectory watches only that subtree, so an editor can watch one
	/// content group without sweeping the whole mount.
	[Test]
	public static void TrackingIsScopedToItsSubtree()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let fs = scope NativeFileSystem(kScratch);

		Save(fs, "watched/a.bin", 4);
		Save(fs, "ignored/b.bin", 4);

		let watcher = fs.ChangeSource;
		watcher.Track("watched");

		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		Test.Assert(!watcher.Poll(changed));

		Save(fs, "ignored/c.bin", 4);
		Test.Assert(!watcher.Poll(changed), "outside the tracked subtree");

		Save(fs, "watched/d.bin", 4);
		Test.Assert(watcher.Poll(changed));
		Test.Assert(Contains(changed, "watched/d.bin"));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Untracking has to forget the snapshot too, or a later change under a directory
	/// nobody is watching would still be reported.
	[Test]
	public static void UntrackingStopsReporting()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let fs = scope NativeFileSystem(kScratch);
		Save(fs, "a.bin", 4);

		let watcher = fs.ChangeSource;
		watcher.Track("");
		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		Test.Assert(!watcher.Poll(changed));

		watcher.Untrack("");
		Save(fs, "b.bin", 4);
		Test.Assert(!watcher.Poll(changed));
		Test.Assert(changed.Count == 0);

		// Tracking again re-baselines, so what happened while nobody watched is not news.
		watcher.Track("");
		Test.Assert(!watcher.Poll(changed));

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// Tracking the same locator twice must not double the sweep or re-baseline it.
	[Test]
	public static void TrackingIsIdempotent()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let fs = scope NativeFileSystem(kScratch);
		Save(fs, "a.bin", 4);

		let watcher = fs.ChangeSource;
		watcher.Track("");
		watcher.Track("");

		Save(fs, "b.bin", 4);
		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		Test.Assert(watcher.Poll(changed));
		Test.Assert(changed.Count == 1, scope $"reported {changed.Count} times");

		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}

	/// The change source is the mount's own, so asking twice gives the same one rather
	/// than a fresh snapshot that has forgotten everything.
	[Test]
	public static void TheChangeSourceIsStable()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(fs.ChangeSource == fs.ChangeSource);
		Test.Assert(RemoveDirectoryRecursive(kScratch));
	}
}
