using System;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.App.Tests;

/// Headless: entry accumulation with category-prefixed text, bucket filtering (Trace and
/// Debug fold, Error and Critical fold), the entry cap, Clear, and copying a multi-row
/// selection.
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

	private class TestClipboard : IClipboard
	{
		public String Stored = new .() ~ delete _;

		public Result<void> GetText(String outText)
		{
			outText.Set(Stored);
			return .Ok;
		}

		public Result<void> SetText(StringView text)
		{
			Stored.Set(text);
			return .Ok;
		}

		public bool HasText => !Stored.IsEmpty;
	}

	private static void Press(ListView list, KeyCode key, KeyModifiers modifiers)
	{
		let e = scope KeyEventArgs();
		e.Set(key, modifiers, false);
		list.OnKeyDown(e);
		Test.Assert(e.Handled);
	}

	[Test]
	public static void SelectedRowsCopyOnePerLineInOrder()
	{
		let ui = scope UIContext();
		let clipboard = scope TestClipboard();
		ui.SetClipboard(clipboard);
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		ui.AddRootView(root);
		let view = new LogView();
		root.AddView(view);

		view.AddEntry(.Information, "A", "one");
		view.AddEntry(.Warning, "A", "two");
		view.AddEntry(.Error, "A", "three");

		// Several rows, picked out of order, copy oldest first.
		Test.Assert(view.List.Selection.Mode == .Multiple);
		view.List.Selection.Toggle(2);
		view.List.Selection.Toggle(0);
		Press(view.List, .C, .Ctrl);
		Test.Assert(clipboard.Stored == "[A] one\n[A] three");

		// Ctrl+A selects every row, and copies them all.
		Press(view.List, .A, .Ctrl);
		Test.Assert(view.SelectedCount == 3);
		Press(view.List, .C, .Ctrl);
		Test.Assert(clipboard.Stored == "[A] one\n[A] two\n[A] three");

		// The cap trims the oldest: the selection follows its rows, a trimmed one is gone.
		view.MaxEntries = 3;
		view.List.Selection.ClearSelection();
		view.List.Selection.Toggle(2); // "three"
		view.AddEntry(.Information, "A", "four");
		Test.Assert((view.SelectedCount == 1) && (view.SelectedText(.. scope .()) == "[A] three"));

		// A filter change re-numbers the rows, so the selection goes; nothing copies nothing.
		view.SetBucketVisible(.Warning, false);
		Test.Assert(view.SelectedCount == 0);
		clipboard.Stored.Set("kept");
		Press(view.List, .C, .Ctrl);
		Test.Assert(clipboard.Stored == "kept");
	}
}
