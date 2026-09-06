using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.VFS;

/// A stat-sweep change source over a filesystem that can enumerate and stat.
///
/// Track snapshots every regular file under a directory, recursively, and each Poll
/// re-walks the tracked trees and diffs size and modification time against the snapshot,
/// emitting whatever was added, changed or removed.
///
/// Deterministic and portable, with no inotify or ReadDirectoryChangesW plumbing behind
/// it. A sweep is O(files), so throttling the poll rate is the CALLER's job. A platform
/// event backend can replace the sweep behind the same Poll later.
class NativeChangeSource : IChangeSource
{
	private struct Entry
	{
		public int64 Size;
		public int64 ModifiedTicks;
		/// Cleared before each sweep; an entry still unmarked afterwards is gone.
		public bool Seen;
	}

	private IFileSystem mFileSystem;
	private List<String> mRoots = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<String, Entry> mSnapshot = new .() ~ DeleteDictionaryAndKeys!(_);

	public this(IFileSystem fileSystem)
	{
		mFileSystem = fileSystem;
	}

	public void Track(StringView locator)
	{
		for (let existing in mRoots)
		{
			if (existing == locator)
				return;
		}
		mRoots.Add(new String(locator));
		// Baseline WITHOUT emitting: files that were already there are not changes.
		Sweep(locator, null);
	}

	public void Untrack(StringView locator)
	{
		for (int i < mRoots.Count)
		{
			if (mRoots[i] == locator)
			{
				delete mRoots[i];
				mRoots.RemoveAt(i);
				break;
			}
		}
		RebuildSnapshot();
	}

	public bool Poll(List<String> outChanged)
	{
		let before = outChanged.Count;

		for (var pair in ref mSnapshot)
			pair.valueRef.Seen = false;

		for (let root in mRoots)
			Sweep(root, outChanged);

		// Whatever the walk did not reach is gone.
		let removed = scope List<String>();
		for (let pair in mSnapshot)
		{
			if (!pair.value.Seen)
				removed.Add(pair.key);
		}
		for (let path in removed)
		{
			outChanged.Add(new String(path));
			// The key is owned by the snapshot, so it goes with the entry.
			let key = mSnapshot.GetAndRemove(path).Get().key;
			delete key;
		}

		return outChanged.Count != before;
	}

	/// Walks a folder recursively, stats the regular files and diffs them against the
	/// snapshot. A null outChanged means baseline mode: record without emitting.
	private void Sweep(StringView folder, List<String> outChanged)
	{
		let enumerable = mFileSystem as IEnumerableFileSystem;
		let stat = mFileSystem as IStatFileSystem;
		if ((enumerable == null) || (stat == null))
			return;

		let entries = scope List<DirEntry>();
		defer
		{
			for (var entry in ref entries)
				entry.Dispose();
		}

		if (enumerable.Enumerate(folder, entries) case .Err)
			return;

		for (let entry in entries)
		{
			let child = scope String();
			if (folder.IsEmpty)
				child.Set(entry.Name);
			else
				PathJoin(folder, entry.Name, child);

			if (entry.IsDirectory)
			{
				Sweep(child, outChanged);
				continue;
			}

			FileStatInfo info = default;
			if (!stat.Stat(child, out info))
				continue;

			if (mSnapshot.TryGetValue(child, let existing))
			{
				let changed = (existing.Size != info.Size) || (existing.ModifiedTicks != info.ModifiedTicks);
				mSnapshot[child] = Entry() { Size = info.Size, ModifiedTicks = info.ModifiedTicks, Seen = true };
				if (changed && (outChanged != null))
					outChanged.Add(new String(child));
			}
			else
			{
				mSnapshot.Add(new String(child), Entry() { Size = info.Size, ModifiedTicks = info.ModifiedTicks, Seen = true });
				// New since the baseline, which is a change unless we ARE the baseline.
				if (outChanged != null)
					outChanged.Add(new String(child));
			}
		}
	}

	private void RebuildSnapshot()
	{
		for (let key in mSnapshot.Keys)
			delete key;
		mSnapshot.Clear();

		for (let root in mRoots)
			Sweep(root, null);
	}
}
