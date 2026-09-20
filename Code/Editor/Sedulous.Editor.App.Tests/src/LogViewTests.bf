using System;
using Sedulous.Core.Logging;

namespace Sedulous.Editor.App.Tests;

/// Headless: entry accumulation with category-prefixed text, bucket filtering (Trace and
/// Debug fold, Error and Critical fold), the entry cap, and Clear.
static class LogViewTests
{
	[Test]
	public static void EntriesAccumulateWithCategoryPrefixedBucketedRows()
	{
		let view = new LogView();
		defer view.ReleaseRef();
		view.AddEntry(.Information, "Editor", "opened project");
		view.AddEntry(.Trace, "RHI", "trace detail");
		view.AddEntry(.Critical, "RHI", "device lost");

		Test.Assert(view.EntryCount == 3);
		Test.Assert(view.VisibleEntryCount == 3);
		Test.Assert(view.VisibleEntryText(0) == "[Editor] opened project");

		Test.Assert(LogBucket.Of(.Trace) == .Debug);
		Test.Assert(LogBucket.Of(.Debug) == .Debug);
		Test.Assert(LogBucket.Of(.Information) == .Info);
		Test.Assert(LogBucket.Of(.Warning) == .Warning);
		Test.Assert(LogBucket.Of(.Error) == .Error);
		Test.Assert(LogBucket.Of(.Critical) == .Error);
	}

	[Test]
	public static void BucketFiltersHideAndReshowEntries()
	{
		let view = new LogView();
		defer view.ReleaseRef();
		view.AddEntry(.Information, "A", "info");
		view.AddEntry(.Warning, "A", "warn");
		view.AddEntry(.Error, "A", "error");

		view.SetBucketVisible(.Warning, false);
		Test.Assert(view.EntryCount == 3);
		Test.Assert(view.VisibleEntryCount == 2);
		Test.Assert(view.VisibleEntryText(1) == "[A] error");

		// Entries added while filtered out stay hidden.
		view.AddEntry(.Warning, "A", "warn2");
		Test.Assert(view.VisibleEntryCount == 2);

		// They reappear, in order, when the bucket is reshown.
		view.SetBucketVisible(.Warning, true);
		Test.Assert(view.VisibleEntryCount == 4);
		Test.Assert(view.VisibleEntryText(1) == "[A] warn");
		Test.Assert(view.VisibleEntryText(3) == "[A] warn2");
	}

	[Test]
	public static void EntryCapTrimsOldestAndClearEmpties()
	{
		let view = new LogView();
		defer view.ReleaseRef();
		view.MaxEntries = 3;
		view.AddEntry(.Information, "A", "one");
		view.AddEntry(.Information, "A", "two");
		view.AddEntry(.Information, "A", "three");
		view.AddEntry(.Information, "A", "four");

		Test.Assert(view.EntryCount == 3);
		Test.Assert(view.VisibleEntryText(0) == "[A] two");
		Test.Assert(view.VisibleEntryText(2) == "[A] four");

		view.Clear();
		Test.Assert(view.EntryCount == 0);
		Test.Assert(view.VisibleEntryCount == 0);
	}
}
