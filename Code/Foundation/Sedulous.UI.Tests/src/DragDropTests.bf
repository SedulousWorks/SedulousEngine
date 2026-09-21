using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The drag state machine.
///
/// The state machine has real invariants beyond a context having a manager, so it gets
/// covered head on.
class DragDropTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 800, 600);
		root.Bounds = .(0, 0, 800, 600);
	}

	/// A draggable view that records what it was told, and can decline to produce data.
	private class DraggableView : TestView, IDragSource
	{
		public bool ProducesData = true;
		public bool Started = false;
		public bool Completed = false;
		public bool Cancelled = false;
		public DragDropEffects CompletedEffect = .None;

		public this(float width, float height) : base(width, height) {}

		public override IDragSource AsDragSource() => this;

		public DragData CreateDragData() => ProducesData ? new DragData("test/plain") : null;

		public View CreateDragVisual(DragData data) => null;

		public void OnDragStarted(DragData data) => Started = true;

		public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled)
		{
			Completed = true;
			CompletedEffect = effect;
			Cancelled = cancelled;
		}
	}

	/// A drop target that records the notifications it received, in order.
	private class DropView : TestView, IDropTarget
	{
		public DragDropEffects Accepts = .Move;
		public List<String> Log = new .() ~ DeleteContainerAndItems!(_);
		public bool Dropped = false;

		public this(float width, float height) : base(width, height) {}

		public override IDropTarget AsDropTarget() => this;

		public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY) => Accepts;

		public void OnDragEnter(DragData data, float localX, float localY) =>
			Log.Add(new String("enter"));
		public void OnDragOver(DragData data, float localX, float localY) =>
			Log.Add(new String("over"));
		public void OnDragLeave(DragData data) => Log.Add(new String("leave"));

		public DragDropEffects OnDrop(DragData data, float localX, float localY)
		{
			Dropped = true;
			Log.Add(new String("drop"));
			return Accepts;
		}
	}

	// ---- The threshold ------------------------------------------------------------------------

	/// A press on a drag source is POTENTIAL, not a drag. Until the pointer travels far enough
	/// the gesture is still a click, which is what keeps a draggable row clickable.
	[Test]
	public static void APressIsOnlyPotentialUntilTheThresholdIsPassed()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		root.AddView(source);

		Test.Assert(drag.BeginPotentialDrag(source, source, 100, 100, .Left));
		Test.Assert(drag.IsPotentialDrag);
		Test.Assert(!drag.IsDragging);

		// Inside the threshold: not consumed, and still only potential.
		Test.Assert(!drag.UpdateDrag(102, 100));
		Test.Assert(drag.IsPotentialDrag);
		Test.Assert(!source.Started, "the source has not been told yet");

		// Past it: the drag activates and consumes the move.
		Test.Assert(drag.UpdateDrag(120, 100));
		Test.Assert(drag.IsDragging);
		Test.Assert(source.Started);
	}

	/// A press that never travels ends as a CLICK: no notifications, nothing consumed.
	[Test]
	public static void APressThatNeverMovesEndsQuietly()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 100, 100, .Left);
		Test.Assert(!drag.EndDrag(100, 100), "the click was not consumed");

		Test.Assert(drag.State == .Idle);
		Test.Assert(!source.Started);
		Test.Assert(!source.Completed);
	}

	/// Only the LEFT button starts a drag: a right press is a different gesture.
	[Test]
	public static void OnlyTheLeftButtonBeginsADrag()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		root.AddView(source);

		Test.Assert(!drag.BeginPotentialDrag(source, source, 100, 100, .Right));
		Test.Assert(drag.State == .Idle);
	}

	/// A source that produces NO data cancels the drag as it activates, and the gesture goes
	/// back to idle rather than sitting half started.
	[Test]
	public static void ASourceThatDeclinesToProduceDataCancelsTheDrag()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.ProducesData = false;
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 100, 100, .Left);

		Test.Assert(!drag.UpdateDrag(200, 100), "activation failed, so nothing was consumed");
		Test.Assert(drag.State == .Idle);
		Test.Assert(!source.Started);
	}

	// ---- Targets ------------------------------------------------------------------------------

	/// Enter, over and leave arrive in that order, and moving WITHIN a target is `over` rather
	/// than another enter.
	[Test]
	public static void ATargetHearsEnterThenOverThenLeave()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		let target = new DropView(200, 200);
		target.Bounds = .(300, 300, 200, 200);
		root.AddView(target);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(350, 350); // past the threshold and onto the target
		Test.Assert(target.Log.Count == 1);
		Test.Assert(target.Log[0] == "enter");

		drag.UpdateDrag(360, 360); // still over it
		Test.Assert(target.Log.Count == 2);
		Test.Assert(target.Log[1] == "over");

		drag.UpdateDrag(50, 50); // off it again
		Test.Assert(target.Log[target.Log.Count - 1] == "leave");
	}

	/// Dropping on an accepting target reports the effect the TARGET performed, and the source
	/// is told it completed rather than was cancelled.
	[Test]
	public static void DroppingOnAnAcceptingTargetReportsItsEffect()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		let target = new DropView(200, 200);
		target.Accepts = .Copy;
		target.Bounds = .(300, 300, 200, 200);
		root.AddView(target);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(350, 350);
		Test.Assert(drag.EndDrag(350, 350));

		Test.Assert(target.Dropped);
		Test.Assert(source.Completed);
		Test.Assert(source.CompletedEffect == .Copy);
		Test.Assert(!source.Cancelled);
		Test.Assert(drag.State == .Idle);
	}

	/// Dropping where NOTHING accepts is a cancellation, not a silent success.
	[Test]
	public static void DroppingOnNothingCancels()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(400, 400);
		drag.EndDrag(400, 400);

		Test.Assert(source.Completed);
		Test.Assert(source.Cancelled);
		Test.Assert(source.CompletedEffect == .None);
	}

	/// A target that REFUSES the payload is still entered and left, but a drop on it performs
	/// nothing: refusing is about the effect, not about the notifications.
	[Test]
	public static void ARefusingTargetIsStillNotifiedButNothingDrops()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		let target = new DropView(200, 200);
		target.Accepts = .None;
		target.Bounds = .(300, 300, 200, 200);
		root.AddView(target);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(350, 350);
		Test.Assert(target.Log[0] == "enter", "still told");
		Test.Assert(drag.CurrentEffect == .None);

		drag.EndDrag(350, 350);
		Test.Assert(!target.Dropped);
		Test.Assert(source.Cancelled);
	}

	// ---- Cancelling and teardown ------------------------------------------------------------

	[Test]
	public static void CancellingEndsTheDragAndTellsTheSource()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(200, 200);
		Test.Assert(drag.IsDragging);

		drag.CancelDrag();

		Test.Assert(drag.State == .Idle);
		Test.Assert(source.Completed);
		Test.Assert(source.Cancelled);
	}

	/// The SOURCE leaving the tree mid drag cancels the whole gesture. The manager holds it as
	/// a raw pointer, so it has to hear about the removal before the view goes.
	[Test]
	public static void RemovingTheSourceMidDragCancelsIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		source.AddRef();
		defer source.ReleaseRef();
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(200, 200);
		Test.Assert(drag.IsDragging);

		root.RemoveView(source);

		Test.Assert(drag.State == .Idle);
		Test.Assert(source.Cancelled);
	}

	/// A drop TARGET leaving mid drag is told it was left, so its highlight comes off, and the
	/// drag carries on looking for another.
	[Test]
	public static void RemovingTheTargetMidDragLeavesItAndContinues()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		let target = new DropView(200, 200);
		target.Bounds = .(300, 300, 200, 200);
		target.AddRef();
		defer target.ReleaseRef();
		root.AddView(target);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(350, 350);
		Test.Assert(target.Log[0] == "enter");

		root.RemoveView(target);

		Test.Assert(target.Log[target.Log.Count - 1] == "leave");
		Test.Assert(drag.IsDragging, "the drag itself carries on");
		Test.Assert(drag.CurrentEffect == .None);
	}

	/// An active drag puts an adorner up through the popup layer, and takes it down again when
	/// the drag ends however it ends.
	[Test]
	public static void TheAdornerGoesUpWithTheDragAndDownWithIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		Test.Assert(root.PeekPopupLayer == null, "a potential drag shows nothing");

		drag.UpdateDrag(200, 200);
		Test.Assert(root.GetPopupLayer().PopupCount == 1, "the adorner");

		drag.CancelDrag();
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// The drag takes the MOUSE for its whole run, so leaving the source's bounds does not end
	/// it, and gives it back at the end.
	[Test]
	public static void TheDragCapturesTheMouseAndReleasesIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let drag = context.DragDrop;
		let focus = context.GetFocusManager();

		let source = new DraggableView(100, 50);
		source.Bounds = .(0, 0, 100, 50);
		root.AddView(source);

		drag.BeginPotentialDrag(source, source, 10, 10, .Left);
		drag.UpdateDrag(200, 200);

		Test.Assert(focus.HasCapture);
		Test.Assert(focus.CapturedView == source);

		drag.CancelDrag();
		Test.Assert(!focus.HasCapture);
	}
}
