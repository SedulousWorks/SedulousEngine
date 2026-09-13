using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// The copy into the project's sources tree that every file importer starts with.
class CopyIntoSourcesTests
{
	private const String cRoot = "scratch_importer_test_project";
	private const String cLoose = "scratch_importer_loose.bin";

	[Test]
	public static void TheBytesLandUnderSourcesAndARepeatIsQuiet()
	{
		let sourcesRoot = scope String();
		PathJoin(cRoot, "Sources", sourcesRoot);
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(sourcesRoot));
		defer RemoveDirectoryRecursive(cRoot);

		// PROJECT FREE: copying into sources needs a directory and nothing else, which is the
		// whole point of the pipeline being drivable headless.
		let payload = scope List<uint8>() { 9, 8, 7, 6 };
		Test.Assert(WriteFile(cLoose, payload) case .Ok);
		defer DeleteFile(cLoose);

		let context = scope ImportContext(sourcesRoot);
		let name = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, cLoose, name) case .Ok);
		Test.Assert(name == cLoose);

		let copied = scope String();
		PathJoin(sourcesRoot, name, copied);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(copied, bytes) case .Ok);
		Test.Assert(bytes.Count == 4);
		Test.Assert(bytes[0] == 9);

		// Importing the same file again reuses the copy rather than failing, and the identical
		// bytes mean nothing downstream re-cooks.
		let again = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, cLoose, again) case .Ok);

		// And a source that is not there is a clean failure rather than a crash.
		let missing = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, "scratch_importer_missing.bin", missing)
			case .Err);
	}

	[Test]
	public static void ChangedBytesOverwriteTheStaleCopy()
	{
		let sourcesRoot = scope String();
		PathJoin(cRoot, "Sources", sourcesRoot);
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(sourcesRoot));
		defer RemoveDirectoryRecursive(cRoot);

		let context = scope ImportContext(sourcesRoot);
		let first = scope List<uint8>() { 1, 2, 3 };
		Test.Assert(WriteFile(cLoose, first) case .Ok);
		defer DeleteFile(cLoose);

		let name = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, cLoose, name) case .Ok);

		// The user edits the file and re-imports. The copy MUST follow: the older skip if
		// present behaviour kept a stale source forever and cooked it.
		let second = scope List<uint8>() { 4, 5, 6, 7 };
		Test.Assert(WriteFile(cLoose, second) case .Ok);
		name.Clear();
		Test.Assert(ImportPaths.CopyIntoSources(context, cLoose, name) case .Ok);

		let copied = scope String();
		PathJoin(sourcesRoot, name, copied);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(copied, bytes) case .Ok);
		Test.Assert(bytes.Count == 4);
		Test.Assert(bytes[0] == 4);
	}
}
