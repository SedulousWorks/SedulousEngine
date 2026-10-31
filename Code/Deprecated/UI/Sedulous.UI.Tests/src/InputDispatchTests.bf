using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The three phase event dispatch: capture from the root down, target at the view, bubble back
/// up, and what an ancestor can do about it on the way through.
class InputDispatchTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static TestView Focusable(float width = 50, float height = 30)
	{
		let view = new TestView(width, height);
		view.IsFocusable = true;
		view.IsTabStop = true;
		return view;
	}

	/// Records which phases it was reached in, and can block during capture.
	private class PhaseTrackingView : TestView
	{
		public bool CaptureReceived = false;
		public bool TargetReceived = false;
		public bool BubbleReceived = false;
		public bool BlockInCapture = false;

		public this() : base(50, 30)
		{
			IsFocusable = true;
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Phase == .Target)
				TargetReceived = true;
			else if (e.Phase == .Bubble)
				BubbleReceived = true;
		}

		public override void OnMouseDownCapture(MouseEventArgs e)
		{
			CaptureReceived = true;
			if (BlockInCapture)
				e.Handled = true;
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Phase == .Target)
				TargetReceived = true;
			else if (e.Phase == .Bubble)
				BubbleReceived = true;
		}

		public override void OnKeyDownCapture(KeyEventArgs e)
		{
			CaptureReceived = true;
			if (BlockInCapture)
				e.Handled = true;
		}
	}

	/// The same, as a container.
	private class PhaseTrackingGroup : TestGroup
	{
		public bool CaptureReceived = false;
		public bool BubbleReceived = false;
		public bool BlockInCapture = false;

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Phase == .Bubble)
				BubbleReceived = true;
		}

		public override void OnMouseDownCapture(MouseEventArgs e)
		{
			CaptureReceived = true;
			if (BlockInCapture)
				e.Handled = true;
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Phase == .Bubble)
				BubbleReceived = true;
		}

		public override void OnKeyDownCapture(KeyEventArgs e)
		{
			CaptureReceived = true;
			if (BlockInCapture)
				e.Handled = true;
		}
	}

	/// Destroys itself from inside its own handler, which is what the pinning exists for.
	private class SelfRemovingView : TestView
	{
		public bool* HandlerRan = null;

		public this() : base(50, 30)
		{
			IsFocusable = true;
		}

		public override void OnMouseUp(MouseEventArgs e)
		{
			if (HandlerRan != null)
				*HandlerRan = true;
			e.Handled = true;

			if (let group = Parent as ViewGroup)
				group.RemoveView(this);
		}
	}

	// ---- Capture, target, bubble ----------------------------------------------------------------

	/// The parent sees the press BEFORE the child, and again on the way back up.
	[Test]
	public static void APressReachesTheParentFirstThenTheTargetThenTheParentAgain()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		parent.AddView(child);
		root.AddView(parent);
		UITest.LayoutPass(context, root);

		context.GetInputManager().ProcessMouseDown(.Left, 10, 10, 0);

		Test.Assert(parent.CaptureReceived, "capture, from the root down");
		Test.Assert(child.TargetReceived, "then the target");
		Test.Assert(parent.BubbleReceived, "then bubble, back up");
	}

	/// An ancestor handling during CAPTURE stops the event dead: the target never sees it, and
	/// nothing bubbles. That is what a modal or a drag handle relies on.
	[Test]
	public static void BlockingDuringCaptureStopsTheEventReachingTheTarget()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true;
		let child = new PhaseTrackingView();
		parent.AddView(child);
		root.AddView(parent);
		UITest.LayoutPass(context, root);

		context.GetInputManager().ProcessMouseDown(.Left, 10, 10, 0);

		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!child.CaptureReceived);
		Test.Assert(!parent.BubbleReceived);
	}

	/// Capture runs OUTERMOST first through however many levels, and bubble unwinds them.
	[Test]
	public static void CaptureRunsOutermostFirstThroughEveryLevel()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grandparent = new PhaseTrackingGroup();
		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		grandparent.AddView(parent);
		parent.AddView(child);
		root.AddView(grandparent);
		UITest.LayoutPass(context, root);

		context.GetInputManager().ProcessMouseDown(.Left, 10, 10, 0);

		Test.Assert(grandparent.CaptureReceived);
		Test.Assert(parent.CaptureReceived);
		Test.Assert(child.TargetReceived);
		Test.Assert(parent.BubbleReceived);
		Test.Assert(grandparent.BubbleReceived);
	}

	/// Blocking PART WAY down stops everything below it, and nothing above it bubbles either.
	[Test]
	public static void BlockingPartWayDownStopsEverythingBelowAndTheBubbleEntirely()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grandparent = new PhaseTrackingGroup();
		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true;
		let child = new PhaseTrackingView();
		grandparent.AddView(parent);
		parent.AddView(child);
		root.AddView(grandparent);
		UITest.LayoutPass(context, root);

		context.GetInputManager().ProcessMouseDown(.Left, 10, 10, 0);

		Test.Assert(grandparent.CaptureReceived, "it ran before the block");
		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!grandparent.BubbleReceived);
		Test.Assert(!parent.BubbleReceived);
	}

	[Test]
	public static void KeysDispatchThroughTheSamePhases()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		parent.AddView(child);
		root.AddView(parent);
		UITest.LayoutPass(context, root);
		context.GetFocusManager().SetFocus(child);

		context.GetInputManager().ProcessKeyDown(.A, .None, false);

		Test.Assert(parent.CaptureReceived);
		Test.Assert(child.TargetReceived);
		Test.Assert(parent.BubbleReceived);
	}

	[Test]
	public static void BlockingAKeyDuringCaptureStopsItToo()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true;
		let child = new PhaseTrackingView();
		parent.AddView(child);
		root.AddView(parent);
		UITest.LayoutPass(context, root);
		context.GetFocusManager().SetFocus(child);

		context.GetInputManager().ProcessKeyDown(.A, .None, false);

		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!parent.BubbleReceived);
	}

	/// A handler that destroys its OWN view mid dispatch must not leave the dispatcher reading
	/// freed memory: the phases after it read the target's bounds and parent.
	///
	/// A real crash once: a click handler destroyed the clicked button inline, and the mouse up
	/// dispatch dereferenced it immediately afterwards.
	[Test]
	public static void ATargetThatFreesItselfMidDispatchDoesNotFaultTheDispatcher()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new PhaseTrackingGroup();
		let child = new SelfRemovingView();
		var handlerRan = false;
		child.HandlerRan = &handlerRan;
		parent.AddView(child);
		root.AddView(parent);
		UITest.LayoutPass(context, root);

		// The parent's child list now holds the ONLY reference.
		let input = context.GetInputManager();
		input.ProcessMouseDown(.Left, 10, 10, 0);
		input.ProcessMouseUp(.Left, 10, 10);

		// Getting here at all is the assertion.
		Test.Assert(handlerRan);
		Test.Assert(parent.ChildCount == 0);
	}

	// ---- Return and Tab -------------------------------------------------------------------------

	/// A view that consumes Return in OnKeyDown is not ALSO activated.
	///
	/// Return is dispatched first and activation is the fallback, which is what lets a text
	/// control commit on Enter while a button keeps Enter to activate. Converting Return before
	/// dispatch would lock the text control out of ever seeing it.
	private class ReturnProbe : TestView
	{
		public bool ConsumeReturn = false;
		public int32 KeyDowns = 0;
		public int32 Activations = 0;

		public this() : base(50, 30)
		{
			IsFocusable = true;
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Key != .Return)
				return;

			KeyDowns++;
			e.Handled = ConsumeReturn;
		}

		public override void OnActivate()
		{
			Activations++;
		}
	}

	[Test]
	public static void ReturnIsDispatchedBeforeItActivates()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let probe = new ReturnProbe();
		root.AddView(probe);
		context.GetFocusManager().SetFocus(probe);
		let input = context.GetInputManager();

		// Unhandled: the view saw the key, and then activation fired.
		Test.Assert(input.ProcessKeyDown(.Return, .None, false));
		Test.Assert(probe.KeyDowns == 1);
		Test.Assert(probe.Activations == 1);

		// Handled: no activation at all.
		probe.ConsumeReturn = true;
		Test.Assert(input.ProcessKeyDown(.Return, .None, false));
		Test.Assert(probe.KeyDowns == 2);
		Test.Assert(probe.Activations == 1);
	}

	/// Tab normally drives traversal and never reaches a view. A view that EDITS tabs opts in,
	/// sees Tab first, and traversal stays the fallback when it leaves Tab unhandled.
	private class TabProbe : TestView
	{
		public bool ConsumeTab = false;
		public int32 TabDowns = 0;

		public this() : base(50, 30)
		{
			IsFocusable = true;
			IsTabStop = true;
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Key != .Tab)
				return;

			TabDowns++;
			e.Handled = ConsumeTab;
		}
	}

	[Test]
	public static void TabReachesOnlyTheViewsThatAskedForIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let editor = new TabProbe();
		let next = new TabProbe();
		root.AddView(editor);
		root.AddView(next);
		UITest.LayoutPass(context, root);

		let focus = context.GetFocusManager();
		let input = context.GetInputManager();
		focus.SetFocus(editor);

		// By default Tab never reaches the view; focus traverses.
		Test.Assert(input.ProcessKeyDown(.Tab, .None, false));
		Test.Assert(editor.TabDowns == 0);
		Test.Assert(focus.FocusedView == next);

		// Opted in AND handled: the view keeps both the key and the focus.
		focus.SetFocus(editor);
		editor.WantsTabKey = true;
		editor.ConsumeTab = true;
		Test.Assert(input.ProcessKeyDown(.Tab, .None, false));
		Test.Assert(editor.TabDowns == 1);
		Test.Assert(focus.FocusedView == editor);

		// Opted in but UNHANDLED: traversal is still the fallback.
		editor.ConsumeTab = false;
		Test.Assert(input.ProcessKeyDown(.Tab, .None, false));
		Test.Assert(editor.TabDowns == 2);
		Test.Assert(focus.FocusedView == next);
	}

	/// Cancel BUBBLES by default, so a dialog can answer for a control inside it that does not
	/// care about Escape.
	private class CancelTrackingGroup : TestGroup
	{
		public bool Cancelled = false;

		public override void OnCancel()
		{
			Cancelled = true;
			base.OnCancel();
		}
	}

	[Test]
	public static void CancelBubblesToTheParent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let parent = new CancelTrackingGroup();
		let child = Focusable();
		parent.AddView(child);
		root.AddView(parent);

		child.OnCancel();

		Test.Assert(parent.Cancelled);
	}
}
