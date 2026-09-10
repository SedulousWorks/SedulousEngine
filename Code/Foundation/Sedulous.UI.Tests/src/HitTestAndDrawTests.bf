using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// Finding the view under a point, and the frame that lays a tree out and draws it.
class HitTestAndDrawTests
{
	/// A context with a root sized to a viewport, laid out and ready to be hit or drawn.
	private static void MakeTree(out UIContext context, out RootView root,
		float width = 200, float height = 100)
	{
		context = new UIContext();
		root = new RootView();
		root.ViewportSize = .(width, height);
		// Placed directly rather than through a layout pass: a hit test reads Bounds, and the
		// tests below place their children by hand for the same reason.
		root.Bounds = .(0, 0, width, height);
		context.AddRootView(root);
		context.SetActiveInputRoot(root);
	}

	/// A view of a fixed size at a fixed place. Layout is set directly rather than measured,
	/// so a test says exactly where a box is without arranging a whole tree to get it there.
	private static View Box(float x, float y, float width, float height)
	{
		let view = new View();
		view.Bounds = .(x, y, width, height);
		return view;
	}

	// ---- Leaves --------------------------------------------------------------------------

	[Test]
	public static void APointInsideALeafFindsIt()
	{
		let view = Box(0, 0, 50, 20);
		defer view.ReleaseRef();

		Test.Assert(view.HitTest(.(25, 10)) == view);
		Test.Assert(view.HitTest(.(0, 0)) == view, "the near edge is inside");
	}

	/// The far edge is EXCLUSIVE: a box at x with width w owns [x, x + w), so two boxes laid
	/// edge to edge never both claim the seam between them.
	[Test]
	public static void APointOutsideALeafMissesIt()
	{
		let view = Box(0, 0, 50, 20);
		defer view.ReleaseRef();

		Test.Assert(view.HitTest(.(50, 10)) == null);
		Test.Assert(view.HitTest(.(25, 20)) == null);
		Test.Assert(view.HitTest(.(-1, 10)) == null);
	}

	[Test]
	public static void AHiddenOrDisabledLeafIsNotHit()
	{
		let hidden = Box(0, 0, 50, 20);
		defer hidden.ReleaseRef();
		hidden.Visibility = .Hidden;
		Test.Assert(hidden.HitTest(.(25, 10)) == null);

		let disabled = Box(0, 0, 50, 20);
		defer disabled.ReleaseRef();
		disabled.IsInteractionEnabled = false;
		Test.Assert(disabled.HitTest(.(25, 10)) == null);

		let transparent = Box(0, 0, 50, 20);
		defer transparent.ReleaseRef();
		transparent.IsHitTestVisible = false;
		Test.Assert(transparent.HitTest(.(25, 10)) == null);
	}

	// ---- Groups --------------------------------------------------------------------------

	/// Front to back: where two children overlap, the one drawn LAST is the one found.
	[Test]
	public static void OverlappingChildrenAreHitFrontToBack()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let under = Box(0, 0, 100, 100);
		let over = Box(0, 0, 100, 100);
		root.AddView(under);
		root.AddView(over);

		Test.Assert(root.HitTest(.(50, 50)) == over);
	}

	/// A non zero z index reorders the hit test exactly as it reorders the draw, so what looks
	/// topmost is what answers the pointer.
	[Test]
	public static void ZIndexReordersTheHitTest()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let under = Box(0, 0, 100, 100);
		let over = Box(0, 0, 100, 100);
		root.AddView(under);
		root.AddView(over);

		// Lifting the FIRST child above the second makes it the one the pointer meets.
		var lifted = LayoutStyle();
		lifted.ZIndex = .(5, true);
		under.SetLayout(lifted);

		Test.Assert(root.HitTest(.(50, 50)) == under);
	}

	/// A group that is not itself hit testable passes the pointer through to whatever is
	/// behind it, while its CHILDREN stay findable. That is the difference between the
	/// per view IsHitTestVisible gate and the subtree wide interaction gate.
	[Test]
	public static void ANonHitTestableGroupPassesThroughButItsChildrenDoNot()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		group.Bounds = .(0, 0, 100, 100);
		group.IsHitTestVisible = false;
		root.AddView(group);

		let child = Box(10, 10, 20, 20);
		group.AddView(child);

		Test.Assert(root.HitTest(.(20, 20)) == child, "the child is still found");
		// The point misses the child but lands on the group, which declines it, so the root
		// answers instead.
		Test.Assert(root.HitTest(.(80, 80)) == root);
	}

	/// Disabling interaction takes the whole SUBTREE out, unlike IsHitTestVisible.
	[Test]
	public static void ADisabledGroupHidesItsChildrenFromTheHitTest()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		group.Bounds = .(0, 0, 100, 100);
		group.IsInteractionEnabled = false;
		root.AddView(group);

		let child = Box(10, 10, 20, 20);
		group.AddView(child);

		Test.Assert(root.HitTest(.(20, 20)) == root);
	}

	/// A child is hit where it is DRAWN, not where it was laid out: the draw path applies the
	/// render transform, so the hit test has to undo it.
	[Test]
	public static void ATranslatedChildIsHitAtItsDrawnPosition()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = Box(0, 0, 20, 20);
		child.Transform.Translation = .(50, 0);
		root.AddView(child);

		Test.Assert(root.HitTest(.(60, 10)) == child, "where it is drawn");
		Test.Assert(root.HitTest(.(10, 10)) == root, "not where it was laid out");
	}

	/// Scale is undone about the transform ORIGIN, which is a fraction of the child's own box.
	[Test]
	public static void AScaledChildIsHitOverItsScaledArea()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = Box(0, 0, 20, 20);
		// Doubled about the top left corner, so the drawn box covers forty by forty.
		child.Transform.Scale = .(2, 2);
		child.Transform.Origin = .(0, 0);
		root.AddView(child);

		Test.Assert(root.HitTest(.(30, 30)) == child);
		Test.Assert(root.HitTest(.(45, 30)) == root, "past the scaled edge");
	}

	/// A zero scale collapses the child to nothing. Dividing by it would send the point to
	/// infinity and report a miss by accident rather than by decision.
	[Test]
	public static void AZeroScaledChildIsNotHitByAccident()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = Box(0, 0, 20, 20);
		child.Transform.Scale = .(0, 0);
		root.AddView(child);

		// The inverse divide is SKIPPED rather than guarded after the fact, so the point keeps
		// its unscaled offset and the child answers over its layout box. Degenerate either
		// way, but deliberately so rather than by an accidental division to infinity.
		Test.Assert(root.HitTest(.(10, 10)) == child);
	}

	// ---- Effective visibility ------------------------------------------------------------

	[Test]
	public static void AVisibleViewUnderARootIsEffectivelyVisible()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = new View();
		root.AddView(child);

		Test.Assert(child.IsEffectivelyVisible());
	}

	[Test]
	public static void AHiddenAncestorHidesTheWholeSubtree()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);
		let child = new View();
		group.AddView(child);

		group.Visibility = .Hidden;

		Test.Assert(!child.IsEffectivelyVisible());
		Test.Assert(child.Visibility == .Visible, "the child itself never asked to be hidden");
	}

	/// A DETACHED subtree is not on screen however visible its own views are: the walk runs
	/// off the top without meeting a root.
	[Test]
	public static void ADetachedViewIsNotEffectivelyVisible()
	{
		let orphan = new ViewGroup();
		defer orphan.ReleaseRef();
		let child = new View();
		orphan.AddView(child);

		Test.Assert(!child.IsEffectivelyVisible());
		Test.Assert(!orphan.IsEffectivelyVisible());
	}

	// ---- Frame lifecycle -----------------------------------------------------------------

	/// Layout runs in LOGICAL units: the physical viewport divided by the DPI scale, so
	/// nothing between the root and the draw has to know the scale exists.
	[Test]
	public static void UpdateRootViewLaysOutInLogicalUnits()
	{
		MakeTree(let context, let root, 400, 200);
		defer { root.ReleaseRef(); delete context; }
		root.DpiScale = 2.0f;

		let child = new ViewGroup();
		root.AddView(child);

		context.UpdateRootView(root);

		Test.Assert(root.Bounds.Width == 200);
		Test.Assert(root.Bounds.Height == 100);
		Test.Assert(child.Bounds.Width == 200, "a child fills the root");
		Test.Assert(child.Bounds.Height == 100);
		Test.Assert(context.CurrentPhase == .Idle, "the phase is put back");
	}

	/// A queued removal is applied by the frame, not by the call that queued it, which is what
	/// lets a handler remove the view it is running inside.
	[Test]
	public static void BeginFrameDrainsTheMutationQueue()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = new View();
		child.AddRef(); // kept alive past the removal so the assertion can read it
		defer child.ReleaseRef();
		root.AddView(child);

		child.QueueRemove();
		Test.Assert(child.Parent == root, "not yet");

		context.BeginFrame(1.0f / 60.0f);

		Test.Assert(child.Parent == null);
		Test.Assert(!child.IsPendingDeletion);
	}

	[Test]
	public static void BeginFrameAdvancesTheClocks()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		context.BeginFrame(0.25f);
		context.BeginFrame(0.5f);

		Test.Assert(context.DeltaTime == 0.5f, "the LAST frame's delta");
		Test.Assert(context.TotalTime == 0.75f, "accumulated");
	}

	/// Drawing walks the tree and clears the redraw damage, the frame having satisfied it.
	[Test]
	public static void DrawRootViewWalksTheTreeAndClearsTheDamage()
	{
		MakeTree(let context, let root, 100, 100);
		defer { root.ReleaseRef(); delete context; }

		let child = new ViewGroup();
		root.AddView(child);
		context.UpdateRootView(root);
		context.MarkNeedsRedraw();

		let vg = scope VGContext();
		context.DrawRootView(root, vg);

		Test.Assert(!context.NeedsRedraw);
		Test.Assert(context.CurrentPhase == .Idle, "the phase is put back");
	}
}
