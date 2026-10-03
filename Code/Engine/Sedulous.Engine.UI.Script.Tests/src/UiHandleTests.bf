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

	/// A minimap marker moves and turns without a relayout: the handle writes the view's post
	/// layout transform (translation in pixels, rotation in degrees stored as radians); a null
	/// handle takes nothing.
	[Test]
	public static void AViewIsTranslatedAndRotatedThroughItsTransform()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());
		let handle = bed.Ui.FindLabel("title");
		Test.Assert(handle.IsValid);
		Test.Assert((handle.Translation.X == 0.0f) && (handle.Rotation == 0.0f));

		handle.SetTranslation(40.0f, -12.5f);
		handle.SetRotation(90.0f);
		let view = handle.Resolve();
		Test.Assert((view.Transform.Translation.X == 40.0f) && (view.Transform.Translation.Y == -12.5f));
		Test.Assert(Math.Abs(view.Transform.Rotation - DegreesToRadians(90.0f)) < 0.0001f);
		Test.Assert(handle.Translation.Y == -12.5f);
		Test.Assert(Math.Abs(handle.Rotation - 90.0f) < 0.001f);

		// Every handle type has it: the bare view the generic finder returns moves the same way.
		let bare = bed.Ui.Find("title");
		Test.Assert(bare.IsValid);
		bare.SetTranslation(1.0f, 2.0f);
		Test.Assert(view.Transform.Translation.X == 1.0f);

		let missing = bed.Ui.FindLabel("nope");
		missing.SetTranslation(5.0f, 5.0f);
		missing.SetRotation(45.0f);
		Test.Assert((missing.Translation.X == 0.0f) && (missing.Rotation == 0.0f));
		bed.Stack.Pop();
	}

	/// An image handle: its source is the texture asset id it shows, SetSource swaps it, and a
	/// nil id clears it.
	[Test]
	public static void AnImageHandleNamesTheTextureItShows()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());
		let image = bed.Ui.FindImage("minimap");
		Test.Assert(image.IsValid && (image.Name == "minimap"));
		Test.Assert(image.Source.IsNil);
		let texture = Guid(0x11, 0x22, 0, 0, 0, 0, 0, 0, 0, 0, 0x33);
		image.SetSource(texture);
		Test.Assert(image.Source == texture);
		Test.Assert(image.Resolve().Source.Value == texture.ToString(.. scope .()));
		image.SetSource(.Empty);
		Test.Assert(image.Source.IsNil && image.Resolve().Source.Value.IsEmpty);
		// The wrong control type is a null but valid handle, as every finder's is.
		Test.Assert(!bed.Ui.FindImage("title").IsValid);
		bed.Stack.Pop();
	}

	/// Opacity at once, or faded on the UI's frame clock (which runs while the game is paused);
	/// a set stops a running fade; a null handle takes nothing.
	[Test]
	public static void AViewFadesOnTheFrameClockAndASetStopsTheFade()
	{
		let bed = scope UiScriptBed();
		bed.Stack.Push(UiScriptBed.Screen());
		for (int i < 30)
			bed.Context.BeginFrame(0.1f); // any push transition done

		let label = bed.Ui.FindLabel("title");
		Test.Assert(label.Opacity == 1.0f);
		label.SetOpacity(0.25f);
		Test.Assert(label.Opacity == 0.25f);
		label.SetOpacity(3.0f);
		Test.Assert(label.Opacity == 1.0f, "clamped");

		label.FadeTo(0.0f, 1.0f);
		Test.Assert(label.Opacity == 1.0f, "from where it was");
		bed.Context.BeginFrame(0.5f);
		Test.Assert((label.Opacity > 0.0f) && (label.Opacity < 1.0f), scope $"half way: {label.Opacity}");
		bed.Context.BeginFrame(0.6f);
		Test.Assert(label.Opacity == 0.0f);

		label.FadeTo(1.0f, 1.0f);
		bed.Context.BeginFrame(0.2f);
		label.SetOpacity(0.5f);
		bed.Context.BeginFrame(1.0f);
		Test.Assert(label.Opacity == 0.5f, "the set stopped the fade");

		// Zero seconds is a set; a group and a screen fade too.
		label.FadeTo(0.1f, 0.0f);
		Test.Assert(label.Opacity == 0.1f);
		let panel = bed.Ui.FindGroup("panel");
		panel.FadeTo(0.0f, 0.2f);
		bed.Context.BeginFrame(0.3f);
		Test.Assert(panel.Opacity == 0.0f);
		let missing = bed.Ui.FindLabel("nope");
		missing.SetOpacity(0.5f);
		missing.FadeTo(0.5f, 1.0f);
		Test.Assert(missing.Opacity == 0.0f);
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
		let volume = bed.Ui.FindSlider("volume");
		Test.Assert(volume.IsValid && (volume.Value == 0.5f) && (volume.Min == 0.0f) && (volume.Max == 1.0f));
		volume.SetValue(2.0f);
		Test.Assert(volume.Value == 1.0f, "clamped to the range");
		volume.SetRange(0.0f, 10.0f);
		volume.SetValue(7.0f);
		Test.Assert(volume.Value == 7.0f);
		Test.Assert(!bed.Ui.FindSlider("health").IsValid, "a progress bar is no slider");
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
		Test.Assert(top.IsValid && (top.Name == "screen") && (top.ChildCount == 7));
		Test.Assert(top.FindGroup("panel").IsValid && top.FindButton("retry").IsValid);
		Test.Assert(top.Find("health").IsValid && panel.Find("deep").IsValid && !panel.Find("retry").IsValid, "an untyped find, scoped as the typed ones");
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
