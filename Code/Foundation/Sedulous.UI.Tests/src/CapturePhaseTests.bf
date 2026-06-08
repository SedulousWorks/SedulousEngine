namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// View that records which phases it received events in.
class PhaseTrackingView : View
{
	public float DesiredWidth;
	public float DesiredHeight;
	public bool CaptureReceived;
	public bool TargetReceived;
	public bool BubbleReceived;
	public bool BlockInCapture;

	public this(float w = 50, float h = 30) { DesiredWidth = w; DesiredHeight = h; }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(DesiredWidth), constraints.ConstrainHeight(DesiredHeight));
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Phase == .Target) TargetReceived = true;
		else if (e.Phase == .Bubble) BubbleReceived = true;
	}

	public override void OnMouseDownCapture(MouseEventArgs e)
	{
		CaptureReceived = true;
		if (BlockInCapture) e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Phase == .Target) TargetReceived = true;
		else if (e.Phase == .Bubble) BubbleReceived = true;
	}

	public override void OnKeyDownCapture(KeyEventArgs e)
	{
		CaptureReceived = true;
		if (BlockInCapture) e.Handled = true;
	}

	public void ResetTracking()
	{
		CaptureReceived = false;
		TargetReceived = false;
		BubbleReceived = false;
	}
}

/// ViewGroup that tracks capture phase.
class PhaseTrackingGroup : ViewGroup
{
	public bool CaptureReceived;
	public bool BubbleReceived;
	public bool BlockInCapture;

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Phase == .Bubble) BubbleReceived = true;
	}

	public override void OnMouseDownCapture(MouseEventArgs e)
	{
		CaptureReceived = true;
		if (BlockInCapture) e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (e.Phase == .Bubble) BubbleReceived = true;
	}

	public override void OnKeyDownCapture(KeyEventArgs e)
	{
		CaptureReceived = true;
		if (BlockInCapture) e.Handled = true;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Layout(0, 0, width, height);
		}
	}

	public void ResetTracking()
	{
		CaptureReceived = false;
		BubbleReceived = false;
	}
}

class CapturePhaseTests
{
	[Test]
	public static void MouseDown_CapturePhase_ParentSeesFirst()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		parent.AddView(child);
		root.AddView(parent);
		TestSetup.Layout(ctx, root);

		// Simulate mouse down on child
		ctx.InputManager.ProcessMouseDown(.Left, 10, 10, 0);

		// Parent should have received capture, child should have received target
		Test.Assert(parent.CaptureReceived);
		Test.Assert(child.TargetReceived);
		// Parent should also have received bubble
		Test.Assert(parent.BubbleReceived);
	}

	[Test]
	public static void MouseDown_CaptureBlocks_TargetNotReached()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true; // Block during capture
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		parent.AddView(child);
		root.AddView(parent);
		TestSetup.Layout(ctx, root);

		ctx.InputManager.ProcessMouseDown(.Left, 10, 10, 0);

		// Parent blocked in capture — child should NOT receive target
		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!child.CaptureReceived);
		Test.Assert(!parent.BubbleReceived);
	}

	[Test]
	public static void MouseDown_PhaseFieldSet()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		root.AddView(child);
		TestSetup.Layout(ctx, root);

		ctx.InputManager.ProcessMouseDown(.Left, 10, 10, 0);

		// With no parent blocking, child receives target phase
		Test.Assert(child.TargetReceived);
	}

	[Test]
	public static void KeyDown_CapturePhase_Works()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		parent.AddView(child);
		root.AddView(parent);
		TestSetup.Layout(ctx, root);

		// Focus the child so key events go to it
		ctx.FocusManager.SetFocus(child);

		ctx.InputManager.ProcessKeyDown(.A, .None, false);

		Test.Assert(parent.CaptureReceived);
		Test.Assert(child.TargetReceived);
		Test.Assert(parent.BubbleReceived);
	}

	[Test]
	public static void KeyDown_CaptureBlocks()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true;
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		parent.AddView(child);
		root.AddView(parent);
		TestSetup.Layout(ctx, root);

		ctx.FocusManager.SetFocus(child);
		ctx.InputManager.ProcessKeyDown(.A, .None, false);

		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!parent.BubbleReceived);
	}

	[Test]
	public static void DeepHierarchy_CaptureOrder()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let grandparent = new PhaseTrackingGroup();
		let parent = new PhaseTrackingGroup();
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		grandparent.AddView(parent);
		parent.AddView(child);
		root.AddView(grandparent);
		TestSetup.Layout(ctx, root);

		ctx.InputManager.ProcessMouseDown(.Left, 10, 10, 0);

		// Both ancestors should receive capture
		Test.Assert(grandparent.CaptureReceived);
		Test.Assert(parent.CaptureReceived);
		Test.Assert(child.TargetReceived);
		// Both ancestors should receive bubble
		Test.Assert(parent.BubbleReceived);
		Test.Assert(grandparent.BubbleReceived);
	}

	[Test]
	public static void DeepHierarchy_MidCapture_Blocks()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let grandparent = new PhaseTrackingGroup();
		let parent = new PhaseTrackingGroup();
		parent.BlockInCapture = true; // Middle layer blocks
		let child = new PhaseTrackingView();
		child.IsFocusable = true;
		grandparent.AddView(parent);
		parent.AddView(child);
		root.AddView(grandparent);
		TestSetup.Layout(ctx, root);

		ctx.InputManager.ProcessMouseDown(.Left, 10, 10, 0);

		// Grandparent saw capture, parent blocked
		Test.Assert(grandparent.CaptureReceived);
		Test.Assert(parent.CaptureReceived);
		Test.Assert(!child.TargetReceived);
		Test.Assert(!child.CaptureReceived);
		Test.Assert(!grandparent.BubbleReceived);
		Test.Assert(!parent.BubbleReceived);
	}
}
