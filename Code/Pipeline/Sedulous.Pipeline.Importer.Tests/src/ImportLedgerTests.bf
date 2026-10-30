using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// The import ledger and the copy into the sources tree (the clash rule's file half): a second
/// file of the same name from another folder never overwrites the first's copy, it takes
/// "a.2.png"; the first file imported again (changed) overwrites its own copy; the same bytes
/// again are shared, untouched. Without a ledger, the caller's say decides.
class ImportLedgerTests
{
	private const String cRoot = "scratch_importer_ledger";

	private static void Write(StringView folder, StringView text, String outPath)
	{
		PathJoin(folder, "a.png", outPath);
		Test.Assert(WriteFile(outPath, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	private static void Read(StringView sources, StringView name, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(sources, name, .. scope .()), bytes) case .Ok);
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	[Test]
	public static void ACopyNeverOverwritesAnotherFilesAReimportOverwritesItsOwn()
	{
		RemoveDirectoryRecursive(cRoot);
		defer RemoveDirectoryRecursive(cRoot);
		let sources = PathJoin(cRoot, "Sources", .. scope .());
		let one = PathJoin(cRoot, "one", .. scope .());
		let two = PathJoin(cRoot, "two", .. scope .());
		for (let folder in scope StringView[](sources, one, two))
			Test.Assert(CreateDirectory(folder));
		let context = scope ImportContext(sources);
		ImportPaths.ImportLedgerPath(PathJoin(cRoot, ".cache", .. scope .()), context.LedgerPath);

		let first = scope String();
		Write(one, "first", first);
		let a = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, first, a, false) case .Ok);
		Test.Assert(a == "a.png");
		Test.Assert(ImportPaths.ImportOriginOf(context.LedgerPath, "a.png", .. scope .()) == first);

		// Another folder's a.png: beside it, the first's copy untouched.
		let second = scope String();
		Write(two, "second", second);
		let b = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, second, b, true) case .Ok); // even when the caller would allow it
		Test.Assert(b == "a.2.png");
		Test.Assert(Read(sources, "a.png", .. scope .()) == "first");
		Test.Assert(Read(sources, "a.2.png", .. scope .()) == "second");

		// The first, changed, imported again: its own copy overwritten.
		Write(one, "first, edited", scope .());
		let again = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, first, again, false) case .Ok);
		Test.Assert(again == "a.png");
		Test.Assert(Read(sources, "a.png", .. scope .()) == "first, edited");
		// The second again, unchanged: the same copy.
		let same = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, second, same, false) case .Ok);
		Test.Assert(same == "a.2.png");
		// Named without copying (a deferred write's), from the ledger alone.
		Test.Assert(ImportPaths.SourcesNameFor(context, second, .. scope .(), false) == "a.2.png");

		// No ledger: a copy there of unknown origin is overwritten only when the caller allows it.
		let bare = scope ImportContext(sources);
		let third = PathJoin(cRoot, "third.png", .. scope .());
		Test.Assert(WriteFile(third, scope List<uint8>() { (uint8)'x' }) case .Ok);
		Test.Assert(ImportPaths.CopyIntoSources(bare, third, scope .()) case .Ok); // third.png, new
		Test.Assert(WriteFile(third, scope List<uint8>() { (uint8)'y' }) case .Ok);
		let refused = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(bare, third, refused, false) case .Ok);
		Test.Assert(refused == "third.2.png");
		let allowed = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(bare, third, allowed, true) case .Ok);
		Test.Assert(allowed == "third.png");
	}

	[Test]
	public static void TheLedgerKeepsOneLinePerFileTheLastOrigin()
	{
		let root = "scratch_importer_ledger_lines";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let ledger = PathJoin(root, ".cache/imports.txt", .. scope .());
		Test.Assert(ImportPaths.ImportOriginOf(ledger, "a.png", .. scope .()).IsEmpty);
		Test.Assert(CreateDirectory(root));
		ImportPaths.RecordImportOrigin(ledger, "a.png", "/one/a.png");
		ImportPaths.RecordImportOrigin(ledger, "b.png", "/one/b.png");
		ImportPaths.RecordImportOrigin(ledger, "a.png", "/two/a.png");
		Test.Assert(ImportPaths.ImportOriginOf(ledger, "a.png", .. scope .()) == "/two/a.png");
		Test.Assert(ImportPaths.ImportOriginOf(ledger, "b.png", .. scope .()) == "/one/b.png");
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(ledger, bytes) case .Ok);
		int lines = 0;
		for (let c in bytes)
		{
			if (c == '\n')
				lines++;
		}
		Test.Assert(lines == 2);
		Test.Assert(ImportPaths.ImportOriginOf("", "a.png", .. scope .()).IsEmpty); // no ledger: says nothing
	}
}
