using System;
using System.IO;
using System.Collections;
using System.Diagnostics;

namespace Sedulous.Resources;

/// Tracks file paths and their last-modified timestamps.
/// Polls on demand - no threading.
class FileWatcher
{
	struct WatchEntry : IDisposable
	{
		public String Path;
		public DateTime LastModified;

		public void Dispose() mut
		{
			delete Path;
			Path = null;
		}
	}

	private List<WatchEntry> mWatched = new .() ~ {
		for (var entry in _)
			entry.Dispose();
		delete _;
	};

	private double mPollIntervalSeconds = 1.0;
	private Stopwatch mTimeSinceLastPoll = new .() ~ delete _;

	/// Gets or sets the poll interval in seconds.
	public double PollIntervalSeconds
	{
		get => mPollIntervalSeconds;
		set => mPollIntervalSeconds = value;
	}

	public this(double pollIntervalSeconds = 1.0)
	{
		mPollIntervalSeconds = pollIntervalSeconds;
		mTimeSinceLastPoll.Start();
	}

	/// Starts tracking a file path.
	public void Track(StringView path)
	{
		// Don't double-track
		for (let entry in mWatched)
		{
			if (entry.Path == path)
				return;
		}

		DateTime lastModified = default;
		if (File.GetLastWriteTimeUtc(path) case .Ok(let time))
			lastModified = time;

		WatchEntry entry = .() { Path = new String(path), LastModified = lastModified };
		mWatched.Add(entry);
	}

	/// Stops tracking a file path.
	public void Untrack(StringView path)
	{
		for (int i = 0; i < mWatched.Count; i++)
		{
			if (mWatched[i].Path == path)
			{
				var entry = mWatched[i];
				entry.Dispose();
				mWatched.RemoveAtFast(i);
				return;
			}
		}
	}

	/// Returns true if a path is being tracked.
	public bool IsTracked(StringView path)
	{
		for (let entry in mWatched)
		{
			if (entry.Path == path)
				return true;
		}
		return false;
	}

	/// Removes all tracked paths.
	public void Clear()
	{
		for (var entry in mWatched)
			entry.Dispose();
		mWatched.Clear();
	}

	/// Returns true if interval elapsed and changes were found.
	/// Appends changed file paths to outChanged.
	public bool Poll(List<String> outChanged)
	{
		let elapsed = mTimeSinceLastPoll.Elapsed;
		if (elapsed.TotalSeconds < mPollIntervalSeconds)
			return false;

		mTimeSinceLastPoll.Restart();

		bool anyChanged = false;
		for (var entry in ref mWatched)
		{
			DateTime currentModified;
			if (File.GetLastWriteTimeUtc(entry.Path) case .Ok(let time))
				currentModified = time;
			else
				continue;

			if (currentModified != entry.LastModified)
			{
				entry.LastModified = currentModified;
				outChanged.Add(new String(entry.Path));
				anyChanged = true;
			}
		}

		return anyChanged;
	}
}
