using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// ViewGroup's tree API: adding, reparenting, removing, reordering, finding by name, and the
/// lifetime guarantees a destroyed group owes anything still holding one of its children.
class ViewGroupTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static void MakeTree(out UIContext context, out RootView root,
		float width = 800, float height = 600)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, width, height);
	}

	// ---- Adding -----------------------------------------------------------------------------

	[Test]
	public static void AddingAChildCountsItAndWiresItUp()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		Test.Assert(group.ChildCount == 0);

		let child = new TestView(50, 30);
		group.AddView(child);

		Test.Assert(group.ChildCount == 1);
		Test.Assert(group.GetChildAt(0) == child);
		Test.Assert(child.Parent == group);
		Test.Assert(child.Context == context);
	}

	/// Null, self and a duplicate are all rejected QUIETLY: a tree edit driven by data should
	/// not have to pre-check every one of these.
	[Test]
	public static void AddingNullSelfOrADuplicateIsRejected()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);

		group.AddView(null);
		Test.Assert(group.ChildCount == 0);

		group.AddView(group);
		Test.Assert(group.ChildCount == 0, "a group cannot contain itself");

		let child = new TestView(50, 30);
		group.AddView(child);
		group.AddView(child);
		Test.Assert(group.ChildCount == 1, "added twice, held once");
	}

	/// Adding a child that already has a parent REPARENTS it rather than sharing it.
	[Test]
	public static void AddingAParentedChildReparentsIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let first = new TestGroup();
		let second = new TestGroup();
		root.AddView(first);
		root.AddView(second);

		let child = new TestView(50, 30);
		first.AddView(child);
		Test.Assert(first.ChildCount == 1);

		second.AddView(child);

		Test.Assert(first.ChildCount == 0);
		Test.Assert(second.ChildCount == 1);
		Test.Assert(child.Parent == second);
	}

	/// A plain AddView keeps whatever layout the child already carried; the two argument form
	/// REPLACES it wholesale, so an unmentioned field goes back to its default.
	[Test]
	public static void AddViewKeepsTheChildsLayoutUnlessGivenANewOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);

		let kept = new TestView(50, 30);
		var intent = LayoutStyle();
		intent.Width = .(SizeSpec.Match(), true);
		intent.FlexGrow = .(2.0f, true);
		intent.Margin = .(Thickness(4, 4, 4, 4), true);
		kept.SetLayout(intent);
		group.AddView(kept);
		Test.Assert(kept.Layout == intent);

		let replaced = new TestView(50, 30);
		var old = LayoutStyle();
		old.FlexGrow = .(1.0f, true);
		replaced.SetLayout(old);

		var fresh = LayoutStyle();
		fresh.Height = .(SizeSpec.Fixed(Unit.Dp(12.0f)), true);
		group.AddView(replaced, fresh);

		Test.Assert(replaced.Layout == fresh);
		Test.Assert(replaced.Layout.FlexGrow.Value == 0.0f, "the old grow did not survive");
	}

	/// The placement record travels WITH the view. Moving it from a flex to a grid keeps every
	/// field, so each container reads what it understands and the rest waits for the next one.
	[Test]
	public static void ReparentingKeepsTheWholeLayoutIntent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let flex = new FlexLayout();
		let grid = new GridLayout();
		root.AddView(flex);
		root.AddView(grid);

		let child = new TestView(50, 30);
		var intent = LayoutStyle();
		intent.FlexGrow = .(3.0f, true);
		intent.GridRow = 1;
		intent.GridColumn = 2;
		intent.Dock = .Bottom;

		flex.AddView(child, intent);
		Test.Assert(child.Layout == intent);

		grid.AddView(child);
		Test.Assert(child.Parent == grid);
		Test.Assert(child.Layout == intent, "the grid fields were waiting all along");

		let group = new TestGroup();
		root.AddView(group);
		group.InsertView(child, 0);
		Test.Assert(child.Layout == intent);
	}

	/// Setting the SAME layout marks no damage: a control that re-asserts its placement every
	/// frame must not force a relayout every frame.
	[Test]
	public static void SetLayoutOnlyMarksDamageWhenSomethingChanged()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let child = new TestView(50, 30);
		root.AddView(child);
		UITest.LayoutPass(context, root);
		context.ClearLayoutDamage();
		Test.Assert(!context.NeedsLayout);

		child.SetLayout(child.Layout);
		Test.Assert(!context.NeedsLayout, "an identical value is not a change");

		var changed = child.Layout;
		changed.Margin = .(Thickness(1, 2, 3, 4), true);
		child.SetLayout(changed);
		Test.Assert(context.NeedsLayout);
	}

	/// A VISUAL invalidation asks for a redraw without asking for a relayout.
	///
	/// That distinction is what keeps a hover tint, a press state or a focus ring from
	/// relaying out the tree every frame the pointer moves. A plain Invalidate stays the safe
	/// default and asks for both.
	[Test]
	public static void AVisualInvalidationRedrawsWithoutRelayingOut()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TestView(50, 20);
		root.AddView(view);
		// A tree mutation damages layout, which is the safe default.
		Test.Assert(context.NeedsLayout);
		Test.Assert(context.NeedsRedraw);

		UITest.LayoutPass(context, root);
		context.ClearLayoutDamage();
		Test.Assert(!context.NeedsLayout);

		view.InvalidateVisual();
		Test.Assert(!context.NeedsLayout, "no relayout for a repaint");
		Test.Assert(context.NeedsRedraw);

		view.Invalidate();
		Test.Assert(context.NeedsLayout);
	}

	// ---- Removing ---------------------------------------------------------------------------

	[Test]
	public static void RemovingClearsTheParentAndTheContext()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(50, 30);
		child.AddRef(); // held past the removal
		defer child.ReleaseRef();
		group.AddView(child);

		group.RemoveView(child);

		Test.Assert(group.ChildCount == 0);
		Test.Assert(child.Parent == null);
		Test.Assert(child.Context == null);
	}

	[Test]
	public static void RemovingEveryChildClearsThemAll()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let first = new TestView(50, 30);
		first.AddRef();
		defer first.ReleaseRef();
		let second = new TestView(50, 30);
		second.AddRef();
		defer second.ReleaseRef();
		group.AddView(first);
		group.AddView(second);

		group.RemoveAllViews();

		Test.Assert(group.ChildCount == 0);
		Test.Assert(first.Parent == null);
		Test.Assert(second.Parent == null);
	}

	[Test]
	public static void InsertingPlacesAChildAtAnIndex()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let first = new TestView(50, 30);
		let last = new TestView(50, 30);
		group.AddView(first);
		group.AddView(last);

		let middle = new TestView(50, 30);
		group.InsertView(middle, 1);

		Test.Assert(group.ChildCount == 3);
		Test.Assert(group.GetChildAt(0) == first);
		Test.Assert(group.GetChildAt(1) == middle);
		Test.Assert(group.GetChildAt(2) == last);
	}

	/// A pure REORDER: the index changes without a detach and reattach, so the context and the
	/// registration survive it. An out of range index clamps, and a non child is ignored.
	[Test]
	public static void MovingAChildReordersWithoutDetaching()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		let c = new TestView(50, 30);
		group.AddView(a);
		group.AddView(b);
		group.AddView(c);

		group.MoveView(c, 0); // c a b
		Test.Assert(group.GetChildAt(0) == c);
		Test.Assert(group.GetChildAt(1) == a);
		Test.Assert(group.GetChildAt(2) == b);
		Test.Assert(c.Parent == group);
		Test.Assert(c.Context == context, "no detach happened");

		group.MoveView(c, 99); // clamped to last: a b c
		Test.Assert(group.GetChildAt(2) == c);
		Test.Assert(group.GetChildAt(0) == a);

		group.MoveView(a, 1); // a forward move: b a c
		Test.Assert(group.GetChildAt(0) == b);
		Test.Assert(group.GetChildAt(1) == a);

		let stranger = new TestView(50, 30);
		defer stranger.ReleaseRef();
		group.MoveView(stranger, 0);
		Test.Assert(group.ChildCount == 3);
		Test.Assert(group.GetChildAt(0) == b, "a non child changed nothing");
	}

	// ---- Geometry ---------------------------------------------------------------------------

	[Test]
	public static void ContentBoundsAccountsForThePadding()
	{
		let group = new TestGroup();
		defer group.ReleaseRef();
		group.Padding = .(10, 20, 30, 40);
		group.Layout(0, 0, 200, 100);

		let content = group.ContentBounds;

		Test.Assert(content.X == 10);
		Test.Assert(content.Y == 20);
		Test.Assert(content.Width == 200 - 10 - 30);
		Test.Assert(content.Height == 100 - 20 - 40);
	}

	// ---- Hit testing ------------------------------------------------------------------------

	[Test]
	public static void HitTestingFindsTheDeepestChildAndMissesOutsideTheBounds()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(400, 300);
		group.AddView(child);
		UITest.LayoutPass(context, root);

		Test.Assert(root.HitTest(.(10, 10)) == child);
		Test.Assert(root.HitTest(.(-5, -5)) == null);
		Test.Assert(root.HitTest(.(500, 400)) == null);
	}

	/// Hidden and interaction disabled take the SUBTREE out; not hit testable takes only the
	/// view itself out, so the pointer passes through it to what is behind.
	[Test]
	public static void TheThreeGatesDisqualifyDifferentAmounts()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(400, 300);
		group.AddView(child);
		UITest.LayoutPass(context, root);

		child.Visibility = .Hidden;
		Test.Assert(root.HitTest(.(10, 10)) != child);
		child.Visibility = .Visible;

		child.IsInteractionEnabled = false;
		Test.Assert(root.HitTest(.(10, 10)) != child);
		child.IsInteractionEnabled = true;

		child.IsHitTestVisible = false;
		Test.Assert(root.HitTest(.(10, 10)) == group, "through the child, onto the group");
	}

	[Test]
	public static void OverlappingChildrenAreHitTopmostFirst()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let under = new TestView(400, 300);
		let over = new TestView(400, 300);
		group.AddView(under);
		group.AddView(over);
		UITest.LayoutPass(context, root);

		Test.Assert(root.HitTest(.(10, 10)) == over, "the last added draws last, so hits first");
	}

	/// A render transform does not relayout, so the child is hit where it is DRAWN and not
	/// where its bounds still say it is.
	[Test]
	public static void HitTestingAppliesTheInverseTransform()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(400, 300);
		group.AddView(child);
		UITest.LayoutPass(context, root);

		child.Transform.Translation = .(50, 0);

		Test.Assert(root.HitTest(.(60, 10)) == child, "at the drawn position");
		Test.Assert(root.HitTest(.(10, 10)) != child, "not where it was laid out");
	}

	// ---- Finding by name --------------------------------------------------------------------

	[Test]
	public static void FindByNameSearchesTheWholeSubtree()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);

		let direct = new TestView(50, 30);
		direct.Name.Set("direct");
		group.AddView(direct);

		let inner = new TestGroup();
		group.AddView(inner);
		let deeper = new TestGroup();
		inner.AddView(deeper);
		let nested = new TestView(50, 30);
		nested.Name.Set("nested");
		deeper.AddView(nested);

		Test.Assert(group.FindByName("direct") == direct);
		Test.Assert(group.FindByName("nested") == nested, "found at three levels down");
		Test.Assert(group.FindByName("missing") == null);
	}

	/// The typed form answers null when the name matches but the TYPE does not, rather than
	/// handing back something the caller then has to check.
	[Test]
	public static void TheTypedFindByNameChecksTheTypeToo()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let child = new TestView(50, 30);
		child.Name.Set("target");
		group.AddView(child);

		Test.Assert(group.FindByName<TestView>("target") == child);
		Test.Assert(group.FindByName<TestGroup>("target") == null, "the name matched, the type did not");
	}

	// ---- Destruction ------------------------------------------------------------------------

	/// A destroyed group must not leave an externally held child pointing at freed memory, and
	/// that child must be reusable afterwards.
	[Test]
	public static void DestroyingAGroupClearsItsChildrensBackPointers()
	{
		let child = new TestView(50, 30);
		// The creation reference is ours, held past both groups. Each AddView CONSUMES one,
		// so each group gets an added reference of its own.
		defer child.ReleaseRef();

		{
			let group = new TestGroup();
			child.AddRef();
			group.AddView(child);
			Test.Assert(child.Parent == group);
			group.ReleaseRef();
		}

		Test.Assert(child.Parent == null, "not a pointer into freed memory");

		let second = new TestGroup();
		defer second.ReleaseRef();
		child.AddRef();
		second.AddView(child);
		Test.Assert(child.Parent == second, "reusable: nothing touched the dead parent");
	}

	/// A still ATTACHED subtree going away must leave nothing stale in the registry, or a
	/// manager holding an id would resolve it to freed memory.
	[Test]
	public static void DestroyingAnAttachedSubtreeDetachesItFromTheContext()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		context.AddRootView(root);

		let child = new TestView(50, 30);
		child.AddRef();
		defer child.ReleaseRef();

		let group = new TestGroup();
		root.AddView(group);
		group.AddView(child);
		let childId = child.Id;
		Test.Assert(context.GetViewById(childId) == child, "attached and registered");

		root.RemoveView(group);

		Test.Assert(context.GetViewById(childId) == null, "the group's destructor detached it");
		Test.Assert(child.Parent == null);
	}
}
