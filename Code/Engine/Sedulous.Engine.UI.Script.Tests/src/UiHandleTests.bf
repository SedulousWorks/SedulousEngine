using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.Engine.UI.Script;

namespace Sedulous.Engine.UI.Script.Tests;

/// The handles: identity that outlives nothing it should not, typed finders that are loud
/// null on a miss or a type mismatch, deep first match, and a click callback that runs at
/// the queue's drain rather than in the dispatch.
static class UiHandleTests
{
	[Test]
	public static void AHandleReadsNullButValidOnceTheTreeDropsItsView()
	{
		let bed = scope UiScriptBed();
		let screen = UiScriptBed.Screen();
		bed.Stack.Push(screen);

		let label = bed.Ui.FindLabel("title");
		Test.Assert(label.IsValid && (label.Text == "Hello") && (label.Name == "title"));
		label.SetText("Changed");
		Test.Assert(label.Text == "Changed");
		Test.Assert(label.Visible && label.Enabled);
		label.SetVisible(false);
		label.SetEnabled(false);
		Test.Assert(!label.Visible && !label.Enabled);

		// A copy is the same handle.
		let copy = label;
		Test.Assert(copy.IsValid && (copy.Text == "Changed"));

		// The screen pops: its views leave the tree, and every handle into it goes null but
		// valid, reading empty and taking no writes.
		bed.Stack.Pop();
		Test.Assert(!label.IsValid && !copy.IsValid);
		Test.Assert((label.Text == "") && !label.Visible);
		label.SetText("nothing happens");
		Test.Assert(UiHandles.Count == 0, scope $"{UiHandles.Count} entries kept alive");
	}

	[Test]
	public static void TypedFindersAreLoudNullOnAMissOrAMismatch()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());

		Test.Assert(bed.Ui.FindButton("retry").IsValid);
		Test.Assert(!bed.Ui.FindButton("nope").IsValid, "a missing name");
		Test.Assert(!bed.Ui.FindLabel("retry").IsValid, "the wrong control type");
		Test.Assert(!bed.Ui.FindTextBox("health").IsValid);
		Test.Assert(bed.Ui.FindProgressBar("health").IsValid && (bed.Ui.FindProgressBar("health").Value == 0.5f));
		Test.Assert(bed.Ui.FindTextBox("name").IsValid && (bed.Ui.FindTextBox("name").Text == "Ada"));
		Test.Assert(bed.Ui.FindGroup("panel").IsValid);
		Test.Assert(!bed.Ui.FindGroup("title").IsValid, "a label is no group");
		// An untyped find answers any view.
		Test.Assert(bed.Ui.Find("title").IsValid && bed.Ui.Find("panel").IsValid && !bed.Ui.Find("x").IsValid);
		// And everything on a null handle is a safe nothing.
		let none = UiScreen();
		Test.Assert(!none.IsValid && (none.ChildCount == 0) && !none.FindLabel("title").IsValid && !none.ChildAt(0).IsValid);
	}

	[Test]
	public static void FindersSearchDeeplyFirstMatchAndScopeToTheirContainer()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());

		// Two labels named title: the screen's own first, the panel's when searched from it.
		Test.Assert(bed.Ui.FindLabel("title").Text == "Hello");
		let panel = bed.Ui.FindGroup("panel");
		Test.Assert(panel.FindLabel("title").Text == "Inner", "scoped to the group");
		Test.Assert(bed.Ui.FindLabel("deep").Text == "Deep", "found deep, through the panel");
		Test.Assert((panel.ChildCount == 2) && (panel.ChildAt(1).Name == "deep") && !panel.ChildAt(2).IsValid);

		let top = bed.Ui.Top;
		Test.Assert(top.IsValid && (top.Name == "screen") && (top.ChildCount == 5));
		Test.Assert(top.FindGroup("panel").IsValid && top.FindButton("retry").IsValid);
		Test.Assert(bed.Ui.Root.IsValid && bed.Ui.Root.FindScreen("screen").IsValid);
	}

	private class Counter : ScriptDelegate
	{
		public int Calls = 0;
		public override bool IsAlive => true;
		public override bool Invoke(Span<ScriptValue> args, ref ScriptValue result) { Calls++; return true; }
	}

	[Test]
	public static void AClickCallbackRunsAtTheDrainAndDiesWithItsButton()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());
		let button = bed.Ui.FindButton("retry");
		let counter = new Counter();
		button.OnClick(counter);

		// The click queues the callback: nothing runs inside the dispatch.
		button.Resolve().FireClick();
		Test.Assert(counter.Calls == 0, "not inline");
		bed.Context.BeginFrame(0.016f); // the drain
		Test.Assert(counter.Calls == 1);
		button.Resolve().FireClick();
		button.Resolve().FireClick();
		bed.Context.BeginFrame(0.016f);
		Test.Assert(counter.Calls == 3);

		// A null handler is a no-op that takes nothing.
		button.OnClick(null);
		// The screen pops: the button goes, and the delegate parked with it is freed by the
		// table's sweep, which the next resolve performs.
		bed.Stack.Pop();
		Test.Assert(!button.IsValid);
		Test.Assert(UiHandles.Count == 0);
	}

	[Test]
	public static void TheStackVerbsDriveTheScreenTier()
	{
		let bed = scope UiScriptBed();
		bed.Document = new () => UiScriptBed.Screen("doc");
		Test.Assert((bed.Ui.Count == 0) && !bed.Ui.Top.IsValid);
		Test.Assert(!bed.Ui.Push(Guid()).IsValid, "a nil document pushes nothing");

		let first = bed.Ui.Push(Guid.Create());
		Test.Assert(first.IsValid && (bed.Ui.Count == 1) && (bed.Ui.Top.Id == first.Id));
		Test.Assert(first.FindLabel("title").Text == "Hello", "the pushed screen is searchable at once");
		let second = bed.Ui.Push(Guid.Create());
		Test.Assert((bed.Ui.Count == 2) && (bed.Ui.Top.Id == second.Id));
		Test.Assert(bed.Ui.Back(), "back pops the top");
		Test.Assert((bed.Ui.Count == 1) && !second.IsValid && first.IsValid);
		Test.Assert(!bed.Ui.Back(), "but never the last");
		let replaced = bed.Ui.Replace(Guid.Create());
		Test.Assert((bed.Ui.Count == 1) && replaced.IsValid && !first.IsValid);
		bed.Ui.Pop();
		Test.Assert(bed.Ui.Count == 0);
		bed.Ui.Push(Guid.Create());
		bed.Ui.Push(Guid.Create());
		bed.Ui.Clear();
		Test.Assert((bed.Ui.Count == 0) && !bed.Ui.Top.IsValid);

		// A document that is not a screen is wrapped in one.
		delete bed.Document;
		bed.Document = new () => { let l = new Label(); l.Name.Set("lone"); return l; };
		let wrapped = bed.Ui.Push(Guid.Create());
		Test.Assert(wrapped.IsValid && wrapped.FindLabel("lone").IsValid && (bed.Ui.Count == 1));
	}
}
