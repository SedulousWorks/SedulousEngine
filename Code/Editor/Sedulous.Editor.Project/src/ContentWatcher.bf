using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.VFS;

namespace Sedulous.Editor.Project;

/// Watches a project's Content/ for records changed, added or deleted by something other than
/// the editor (a git pull, a text editor, another tool) and brings the source database in line.
///
/// A stat sweep: each Poll walks the folder and compares every file's size and modification time
/// with what it last took in. A path is acted on only once it has settled, the same on two looks
/// in a row, so a file still being written is never read half done; a path the database cannot
/// read yet (cut off, broken) is looked at again on later polls until it reads or changes. One
/// poll's settled paths go to one ContentDatabase.Refresh, so a record is reported once however
/// many of its files changed, and while other paths are still changing the settled ones wait for
/// them (up to cMaxHoldPolls polls), so a pull spread over several polls is one refresh.
///
/// The editor's own writes are not outside changes: the project keeps the paths written through
/// its Content/ mount (EditorProject.RecordContentWrites), and each poll first takes those paths
/// in as they are now, reporting nothing. Every write the editor makes into Content/ goes through
/// that mount: the source database's (a record written, a data stream, a rename, a move, a delete,
/// a group's folder) and the code that writes beside it.
///
/// A sweep is O(files), so the caller throttles it (EditorCookService polls about once a second
/// and when the window regains focus) and holds it off while a background reader has the
/// database, since a refresh changes its index. Main thread only.
class ContentWatcher
{
	/// How many polls settled paths wait for others still changing beside them before they go
	/// anyway: a file someone keeps writing must not hold the rest back for ever.
	public const int cMaxHoldPolls = 5;

	/// Where a record a poll removed lived, for a page still editing it to write it back.
	public class RemovedRecord
	{
		public Guid Id;
		/// The record the database dropped, FREED: a holder of it (the asset selection) compares
		/// it by identity and never reads it.
		public Instance Former;
		/// Its record path, "group/name", without the extension.
		public String Path = new .() ~ delete _;
		public String TypeName = new .() ~ delete _;
	}

	private struct Look
	{
		public bool Exists;
		public int64 Size;
		public int64 ModifiedTicks;

		public bool Same(Look other) => (Exists == other.Exists) && (Size == other.Size) && (ModifiedTicks == other.ModifiedTicks);
	}

	/// A path seen to differ from what was taken in, not acted on yet.
	private struct Pending
	{
		public Look Last;
		/// The same on the last two looks.
		public bool Settled;
		/// Polls it has waited, settled, for paths still changing beside it.
		public int Waited;
	}

	private EditorProject mProject;
	/// Every file under Content/ as it was last taken in, by mount relative path.
	private Dictionary<String, Look> mSnapshot = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, Pending> mPending = new .() ~ DeleteDictionaryAndKeys!(_);
	private List<RemovedRecord> mRemoved = new .() ~ DeleteContainerAndItems!(_);

	/// Takes in what Content/ holds now, reporting none of it, and has the project keep the
	/// editor's writes until it goes. The project is BORROWED and outlives it.
	public this(EditorProject project)
	{
		mProject = project;
		// Before the sweep: a worker's write landing during it is taken in at the first poll.
		mProject.RecordContentWrites(true);
		Sweep("", mSnapshot);
	}

	public ~this()
	{
		mProject.RecordContentWrites(false);
	}

	/// Where each record the last Poll removed lived, valid until the next Poll.
	public Span<RemovedRecord> RemovedRecords => mRemoved;

	/// Paths seen changing (or settled and waiting) that have not been acted on yet.
	public int PendingCount => mPending.Count;

	/// One look at Content/: what the editor wrote since is taken in without a word, then every
	/// path that changed and has settled goes to the source database in one refresh, its changes
	/// into `outChanges` (cleared first) and where each removed record lived into RemovedRecords.
	/// True when the refresh added, changed or removed a record.
	public bool Poll(ContentChanges outChanges)
	{
		outChanges.Clear();
		ClearAndDeleteItems!(mRemoved);
		TakeInWrites();

		let now = new Dictionary<String, Look>();
		defer { DeleteDictionaryAndKeys!(now); }
		Sweep("", now);
		for (let pair in now)
		{
			if (mSnapshot.TryGetValue(pair.key, let known) && known.Same(pair.value))
				Remove(mPending, pair.key); // back to what was taken in
			else
				Observe(pair.key, pair.value);
		}
		for (let pair in mSnapshot)
		{
			if (!now.ContainsKey(pair.key))
				Observe(pair.key, default); // gone
		}
		// A file that came and went again between looks: nothing to tell.
		let vanished = scope List<String>();
		defer { ClearAndDeleteItems!(vanished); }
		for (let pair in mPending)
		{
			if (!now.ContainsKey(pair.key) && !mSnapshot.ContainsKey(pair.key))
				vanished.Add(new String(pair.key));
		}
		for (let path in vanished)
			Remove(mPending, path);

		// The settled paths go together once nothing beside them is still changing, or once they
		// have waited long enough for it.
		let settled = scope List<String>();
		defer { ClearAndDeleteItems!(settled); }
		bool changing = false;
		int waited = 0;
		for (let pair in mPending)
		{
			if (!pair.value.Settled)
			{
				changing = true;
				continue;
			}
			settled.Add(new String(pair.key));
			waited = Math.Max(waited, pair.value.Waited);
		}
		if (settled.IsEmpty || (changing && (waited < cMaxHoldPolls)))
			return false;

		// Envelopes first: a data stream that changed with its envelope then names the record the
		// envelope's refresh left, not one it replaced.
		let db = mProject.SourceDb;
		let suffix = scope String(".");
		suffix.Append(db.Extension);
		settled.Sort(scope (a, b) => (a.EndsWith(suffix) == b.EndsWith(suffix)) ? 0 : (a.EndsWith(suffix) ? -1 : 1));

		// Where each record a changed envelope names lives, before the refresh can drop it.
		let places = scope List<RemovedRecord>();
		defer { ClearAndDeleteItems!(places); }
		let paths = scope List<StringView>();
		for (let path in settled)
		{
			paths.Add(path);
			if (!path.EndsWith(suffix))
				continue;
			let recordPath = StringView(path, 0, path.Length - suffix.Length);
			if (let instance = db.GetInstanceByPath(recordPath))
			{
				let place = new RemovedRecord();
				place.Id = instance.Id;
				place.Former = instance;
				place.Path.Set(recordPath);
				place.TypeName.Set(instance.TypeName);
				places.Add(place);
			}
		}
		db.Refresh(paths, outChanges);
		for (int i = 0; i < places.Count;)
		{
			if (outChanges.Removed.Contains(places[i].Id))
			{
				mRemoved.Add(places[i]);
				places.RemoveAt(i);
			}
			else
				i++;
		}

		// Taken in, but for a path the database could not read: it stays settled and is tried
		// again at the next poll.
		for (let path in settled)
		{
			if (outChanges.Unreadable.ContainsAlt((StringView)path))
				continue;
			let look = mPending[path].Last;
			if (look.Exists)
				Set(mSnapshot, path, look);
			else
				Remove(mSnapshot, path);
			Remove(mPending, path);
		}
		return !outChanges.Added.IsEmpty || !outChanges.Changed.IsEmpty || !outChanges.Removed.IsEmpty;
	}

	/// A path that differs from what was taken in, looked at once more: settled when it looks as
	/// it did last time, waiting again when not.
	private void Observe(StringView path, Look look)
	{
		if (mPending.TryGetRefAlt(path, ?, let pending))
		{
			if (pending.Last.Same(look))
			{
				if (pending.Settled)
					pending.Waited++;
				pending.Settled = true;
			}
			else
			{
				pending.Last = look;
				pending.Settled = false;
				pending.Waited = 0;
			}
			return;
		}
		Pending fresh = default;
		fresh.Last = look;
		Set(mPending, path, fresh);
	}

	/// The paths the editor wrote since the last poll, each taken in as it is now.
	private void TakeInWrites()
	{
		let written = scope List<String>();
		defer { ClearAndDeleteItems!(written); }
		mProject.TakeContentWrites(written);
		for (let path in written)
			TakeIn(path);
	}

	/// A path the editor wrote: a file's look now, or for a directory (a group made, renamed or
	/// moved) the files under it now, and nothing for one gone; whatever was known of it before
	/// goes, a change seen waiting there with it.
	private void TakeIn(StringView path)
	{
		if (path.IsEmpty)
			return; // the root: taking it in whole would swallow every outside change
		Remove(mPending, path);
		if (LookAt(path, let look))
		{
			Set(mSnapshot, path, look);
			return;
		}
		// A file deleted had its own entry; anything else may have files under it.
		if (Remove(mSnapshot, path))
			return;
		RemoveUnder(mSnapshot, path);
		RemoveUnder(mPending, path);
		if (mProject.ContentMount.Exists(path))
			Sweep(path, mSnapshot);
	}

	/// Every regular file under `folder`, recursively, into `into` with its look. Read from the
	/// directory listing itself, which carries each file's size and time: a stat per file looks
	/// its name up in its folder's listing again.
	private void Sweep(StringView folder, Dictionary<String, Look> into)
	{
		let root = mProject.ContentMount.Root;
		let full = scope String();
		if (folder.IsEmpty)
			full.Set(root);
		else
			PathJoin(root, folder, full);
		if (!System.IO.Directory.Exists(full))
			return;
		let name = scope String();
		for (let entry in System.IO.Directory.Enumerate(full))
		{
			name.Clear();
			entry.GetFileName(name);
			// The platform yields the self and parent links; they are not children.
			if ((name == ".") || (name == ".."))
				continue;
			let child = scope String();
			if (!folder.IsEmpty)
			{
				child.Append(folder);
				child.Append('/');
			}
			child.Append(name);
			if (entry.IsDirectory)
			{
				Sweep(child, into);
				continue;
			}
			Look look = default;
			look.Exists = true;
			look.Size = entry.GetFileSize();
			look.ModifiedTicks = entry.GetLastWriteTimeUtc().Ticks;
			Set(into, child, look);
		}
	}

	/// False when `path` is not a regular file on the mount.
	private bool LookAt(StringView path, out Look look)
	{
		look = default;
		if (!mProject.ContentMount.Stat(path, let info))
			return false;
		look.Exists = true;
		look.Size = info.Size;
		look.ModifiedTicks = info.ModifiedTicks;
		return true;
	}

	private static void Set<T>(Dictionary<String, T> map, StringView path, T value)
	{
		if (map.TryAddAlt(path, let keyPtr, let valuePtr))
			*keyPtr = new String(path);
		*valuePtr = value;
	}

	/// True when it was there.
	private static bool Remove<T>(Dictionary<String, T> map, StringView path)
	{
		if (map.GetAndRemoveAlt(path) case .Ok(let pair))
		{
			delete pair.key;
			return true;
		}
		return false;
	}

	/// Every entry under the folder `path`.
	private static void RemoveUnder<T>(Dictionary<String, T> map, StringView path)
	{
		let prefix = scope String(path);
		prefix.Append('/');
		let under = scope List<String>();
		for (let key in map.Keys)
		{
			if (key.StartsWith(prefix))
				under.Add(key);
		}
		for (let key in under)
		{
			map.Remove(key);
			delete key;
		}
	}
}
