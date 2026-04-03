using System;
using System.IO;
using System.Collections;
using System.Threading;

namespace Sedulous.Resources.Tests;

class FileWatcherTests
{
	private static void WriteTempFile(StringView path, StringView content)
	{
		File.WriteAllText(path, content);
	}

	[Test]
	public static void TestFileWatcherTrackUntrack()
	{
		let watcher = scope FileWatcher();

		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("filewatcher_test_track.txt");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		WriteTempFile(tempPath, "hello");

		watcher.Track(tempPath);
		Test.Assert(watcher.IsTracked(tempPath));

		watcher.Untrack(tempPath);
		Test.Assert(!watcher.IsTracked(tempPath));
	}

	[Test]
	public static void TestFileWatcherDetectsChange()
	{
		let watcher = scope FileWatcher(0.0); // No poll delay

		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("filewatcher_test_change.txt");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		WriteTempFile(tempPath, "original");
		watcher.Track(tempPath);

		// First poll — no changes expected (just tracked)
		let changes1 = scope List<String>();
		watcher.Poll(changes1);
		for (let s in changes1)
			delete s;

		// Wait and modify
		Thread.Sleep(50);
		WriteTempFile(tempPath, "modified");

		let changes2 = scope List<String>();
		let detected = watcher.Poll(changes2);
		defer { for (let s in changes2) delete s; }

		Test.Assert(detected);
		Test.Assert(changes2.Count == 1);
		Test.Assert(changes2[0] == tempPath);
	}

	[Test]
	public static void TestFileWatcherNoFalsePositives()
	{
		let watcher = scope FileWatcher(0.0); // No poll delay

		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("filewatcher_test_nochange.txt");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		WriteTempFile(tempPath, "stable");
		watcher.Track(tempPath);

		// First poll to establish baseline
		let changes1 = scope List<String>();
		watcher.Poll(changes1);
		for (let s in changes1)
			delete s;

		// Second poll without modification
		let changes2 = scope List<String>();
		let detected = watcher.Poll(changes2);
		defer { for (let s in changes2) delete s; }

		Test.Assert(!detected);
		Test.Assert(changes2.Count == 0);
	}

	[Test]
	public static void TestFileWatcherPollInterval()
	{
		let watcher = scope FileWatcher(10.0); // Very long interval

		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("filewatcher_test_interval.txt");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		WriteTempFile(tempPath, "test");
		watcher.Track(tempPath);

		// First poll should go through (timer started in ctor)
		let changes1 = scope List<String>();
		watcher.Poll(changes1);
		for (let s in changes1)
			delete s;

		// Second poll should be blocked by interval
		WriteTempFile(tempPath, "changed");

		let changes2 = scope List<String>();
		let detected = watcher.Poll(changes2);
		defer { for (let s in changes2) delete s; }

		Test.Assert(!detected);
		Test.Assert(changes2.Count == 0);
	}
}
