using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameInstance.Tests;

/// A run's save: the values a game keeps between runs, in a file the host names.
class RunSaveTests
{
	[Test]
	public static void ARunSaveWritesWhatChangedReadsItBackAndSurvivesABadFile()
	{
		let scratch = "scratch_run_save";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		// The directory is the save's to make: a first write creates it.
		let path = PathJoin(scratch, "run_save.xml", .. scope String());

		let save = scope RunSave();
		Test.Assert(!save.Flush(), "no file named: nowhere to write");
		save.Open(path); // absent: an empty save
		Test.Assert(save.IsOpen);
		Test.Assert(save.Values.Count == 0);
		Test.Assert(save.Flush(), "nothing changed: nothing to write, and that is fine");
		Test.Assert(!FileExists(path));

		save.Values.SetInt("best.level2", 4210);
		save.Values.SetFloat("time.level2", 41.5f);
		save.MarkChanged();
		Test.Assert(save.Flush());
		Test.Assert(!save.HasChanges);
		Test.Assert(FileExists(path));

		let reread = scope RunSave();
		reread.Open(path);
		Test.Assert(reread.Values.GetInt("best.level2", 0) == 4210);
		Test.Assert(reread.Values.GetFloat("time.level2", 0.0f) == 41.5f);

		// A file that is not a save: an empty save, and the file is left alone until the game
		// writes.
		let garbage = "not a save";
		Test.Assert(WriteFile(path, .((uint8*)garbage.Ptr, garbage.Length)) case .Ok);
		let damaged = scope RunSave();
		damaged.Open(path);
		Test.Assert(damaged.Values.Count == 0);
		Test.Assert(damaged.Flush());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok);
		Test.Assert(bytes.Count == garbage.Length);
	}
}
