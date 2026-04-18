namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Test drag source that records callbacks.
class TestDragSource : ColorView, IDragSource
{
	public String DragFormat;
	public bool DragStarted;
	public bool DragCompleted;
	public DragDropEffects CompletedEffect;
	public bool CompletedCancelled;
	public bool ReturnNullData;

	public this(StringView format = "test/item")
	{
		DragFormat = new String(format);
	}

	public ~this()
	{
		delete DragFormat;
	}

	public DragData CreateDragData()
	{
		if (ReturnNullData) return null;
		return new DragData(DragFormat);
	}

	public View CreateDragVisual(DragData data) => null;

	public void OnDragStarted(DragData data) { DragStarted = true; }

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
	{
		DragCompleted = true;
		CompletedEffect = effect;
		CompletedCancelled = cancelled;
	}
}

/// Test drop target that records callbacks.
class TestDropTarget : ColorView, IDropTarget
{
	public DragDropEffects AcceptEffect = .Move;
	public String AcceptFormat ~ delete _;
	public bool Entered;
	public bool Left;
	public bool Dropped;
	public int OverCount;

	public this(StringView acceptFormat = "test/item")
	{
		AcceptFormat = new String(acceptFormat);
	}

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		if (data.Format == AcceptFormat)
			return AcceptEffect;
		return .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY) { Entered = true; }
	public void OnDragOver(DragData data, float localX, float localY) { OverCount++; }
	public void OnDragLeave(DragData data) { Left = true; }

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		Dropped = true;
		return AcceptEffect;
	}
}

class DragDropTests
{
	// === State machine ===

	[Test]
	public static void BeginPotential_SetsState()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		let result = ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);
		Test.Assert(result);
		Test.Assert(ctx.DragDropManager.State == .Potential);
	}

	[Test]
	public static void Threshold_ActivatesDrag()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);

		// Move less than threshold — still potential.
		ctx.DragDropManager.UpdateDrag(52, 52);
		Test.Assert(ctx.DragDropManager.State == .Potential);

		// Move past threshold (4px).
		ctx.DragDropManager.UpdateDrag(56, 56);
		Test.Assert(ctx.DragDropManager.State == .Active);
		Test.Assert(source.DragStarted);
	}

	[Test]
	public static void MouseUp_BeforeThreshold_CancelsSilently()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);

		// Mouse up before threshold — cancels silently, no callbacks.
		let consumed = ctx.DragDropManager.EndDrag(51, 51);
		Test.Assert(!consumed); // Not consumed — normal mouseup should continue.
		Test.Assert(ctx.DragDropManager.State == .Idle);
		Test.Assert(!source.DragStarted);
		Test.Assert(!source.DragCompleted);
	}

	[Test]
	public static void NullDragData_CancelsDrag()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.ReturnNullData = true;
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);
		ctx.DragDropManager.UpdateDrag(60, 60); // Past threshold.

		// CreateDragData returned null — drag cancelled.
		Test.Assert(ctx.DragDropManager.State == .Idle);
		Test.Assert(!source.DragStarted);
	}

	[Test]
	public static void Drop_OnTarget_FiresOnDrop()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 50;
		source.PreferredHeight = 50;

		let target = new TestDropTarget();
		target.PreferredWidth = 100;
		target.PreferredHeight = 100;

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);
		layout.AddView(source, new LinearLayout.LayoutParams() { Width = 50, Height = 50 });
		layout.AddView(target, new LinearLayout.LayoutParams() { Width = 100, Height = 100 });
		ctx.UpdateRootView(root);

		// Start drag from source.
		ctx.DragDropManager.BeginPotentialDrag(source, source, 25, 25, .Left);
		ctx.DragDropManager.UpdateDrag(35, 25); // Past threshold.
		Test.Assert(ctx.DragDropManager.IsDragging);

		// Move over target.
		ctx.DragDropManager.UpdateDrag(100, 50);
		Test.Assert(target.Entered);

		// Drop.
		ctx.DragDropManager.EndDrag(100, 50);
		Test.Assert(target.Dropped);
		Test.Assert(source.DragCompleted);
		Test.Assert(source.CompletedEffect == .Move);
		Test.Assert(!source.CompletedCancelled);
	}

	[Test]
	public static void Drop_OnNonTarget_Cancels()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);
		ctx.DragDropManager.UpdateDrag(60, 60); // Activate.

		// Drop on empty area (no IDropTarget).
		ctx.DragDropManager.EndDrag(200, 200);
		Test.Assert(source.DragCompleted);
		Test.Assert(source.CompletedCancelled);
		Test.Assert(source.CompletedEffect == .None);
	}

	[Test]
	public static void CancelDrag_FiresCompletedWithCancelled()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);
		ctx.DragDropManager.UpdateDrag(60, 60); // Activate.

		ctx.DragDropManager.CancelDrag();
		Test.Assert(source.DragCompleted);
		Test.Assert(source.CompletedCancelled);
		Test.Assert(ctx.DragDropManager.State == .Idle);
	}

	[Test]
	public static void SourceDeleted_CancelsDrag()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 100;
		source.PreferredHeight = 100;
		root.AddView(source);
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Left);
		ctx.DragDropManager.UpdateDrag(60, 60); // Activate.

		// Delete source mid-drag.
		root.RemoveView(source, true);
		Test.Assert(ctx.DragDropManager.State == .Idle);
	}

	[Test]
	public static void DropTarget_EnterLeave_Fires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource();
		source.PreferredWidth = 50;
		source.PreferredHeight = 300;

		let target1 = new TestDropTarget();
		target1.PreferredWidth = 100;
		target1.PreferredHeight = 300;

		let target2 = new TestDropTarget();
		target2.PreferredWidth = 100;
		target2.PreferredHeight = 300;

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);
		layout.AddView(source, new LinearLayout.LayoutParams() { Width = 50, Height = 300 });
		layout.AddView(target1, new LinearLayout.LayoutParams() { Width = 100, Height = 300 });
		layout.AddView(target2, new LinearLayout.LayoutParams() { Width = 100, Height = 300 });
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 25, 25, .Left);
		ctx.DragDropManager.UpdateDrag(35, 25); // Activate.

		// Move over target1.
		ctx.DragDropManager.UpdateDrag(100, 50);
		Test.Assert(target1.Entered);
		Test.Assert(!target1.Left);

		// Move over target2.
		ctx.DragDropManager.UpdateDrag(200, 50);
		Test.Assert(target1.Left);
		Test.Assert(target2.Entered);

		// Cancel.
		ctx.DragDropManager.CancelDrag();
	}

	[Test]
	public static void WrongFormat_RejectsDrops()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let source = new TestDragSource("type/a");
		source.PreferredWidth = 50;
		source.PreferredHeight = 50;

		let target = new TestDropTarget("type/b"); // Different format.
		target.PreferredWidth = 100;
		target.PreferredHeight = 100;

		let layout = new LinearLayout();
		layout.Orientation = .Horizontal;
		root.AddView(layout);
		layout.AddView(source, new LinearLayout.LayoutParams() { Width = 50, Height = 50 });
		layout.AddView(target, new LinearLayout.LayoutParams() { Width = 100, Height = 100 });
		ctx.UpdateRootView(root);

		ctx.DragDropManager.BeginPotentialDrag(source, source, 25, 25, .Left);
		ctx.DragDropManager.UpdateDrag(35, 25); // Activate.

		// Move over target (wrong format -> CanAcceptDrop returns None).
		ctx.DragDropManager.UpdateDrag(100, 25);
		Test.Assert(ctx.DragDropManager.CurrentEffect == .None);

		// Drop — should cancel since effect is None.
		ctx.DragDropManager.EndDrag(100, 25);
		Test.Assert(!target.Dropped);
		Test.Assert(source.CompletedCancelled);
	}

	[Test]
	public static void RightClick_DoesNotStartDrag()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let source = new TestDragSource();
		root.AddView(source);

		let result = ctx.DragDropManager.BeginPotentialDrag(source, source, 50, 50, .Right);
		Test.Assert(!result);
		Test.Assert(ctx.DragDropManager.State == .Idle);
	}
}
