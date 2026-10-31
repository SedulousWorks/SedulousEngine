using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The virtualised grid: the same machinery as ListView, flowed in two dimensions.
class GridViewTests
{
	/// Counts binds per position, so a per-layout rebind shows up rather than merely costing.
	private class BindCountingAdapter : ListAdapterBase
	{
		public int32 Count = 0;
		public System.Collections.List<int32> Binds = new .() ~ delete _;

		public this(int32 count)
		{
			Count = count;
			for (int32 i < count)
				Binds.Add(0);
		}

		public override int32 ItemCount => Count;
		public override View CreateView(int32 viewType) => new TestView(60.0f, 60.0f);
		// A block body, because Beef rejects ++ as the body of an => form.
		public override void BindView(View view, int32 position)
		{
			Binds[position]++;
		}
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 300, 300);
	}

	/// The adapter is BORROWED, so callers declare it before the teardown defer: Beef destroys
	/// scope locals in reverse declaration order, and one declared after would be freed while
	/// the grid's destructor still needs it.
	private static GridView AddGrid(UIContext context, RootView root, IListAdapter adapter)
	{
		let grid = new GridView();
		grid.SetAdapter(adapter);
		root.AddView(grid);
		UITest.LayoutPass(context, root);
		return grid;
	}

	// ---- Basics -------------------------------------------------------------------------------

	[Test]
	public static void AGridWithNoAdapterHasOnlyItsScrollBar()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = new GridView();
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(grid.VisualChildCount == 1);
		Test.Assert(grid.IsFocusable);
		Test.Assert(grid.IsTabStop);
		Test.Assert(grid.WantsArrowKeys);
	}

	[Test]
	public static void TheDefaultsAreSixtyBySixtyCellsFourApart()
	{
		let grid = new GridView();
		defer grid.ReleaseRef();

		Test.Assert(grid.CellWidth.Value == 60);
		Test.Assert(grid.CellHeight.Value == 60);
		Test.Assert(grid.CellSpacing.Value == 4);
		Test.Assert(grid.ScrollY == 0);
	}

	// ---- Flow ---------------------------------------------------------------------------------

	/// The column count follows the WIDTH, so the grid reflows rather than scrolling sideways.
	///
	/// The gaps are one fewer than the cells, so the spacing goes back on before dividing:
	/// four 60s with 4 between them need 252, not 256.
	[Test]
	public static void TheColumnCountFollowsTheWidth()
	{
		let adapter = scope SimpleListAdapter(50);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		Test.Assert(grid.ColumnsCount == 4, "300 fits four 64 pitch columns");
		Test.Assert(grid.GetItemAtPoint(0, 0) == 0);
		Test.Assert(grid.GetItemAtPoint(64, 0) == 1);

		// A narrower grid reflows to fewer columns, and the same item lands elsewhere.
		grid.Layout(0, 0, 140, 300);
		Test.Assert(grid.ColumnsCount == 2);
		Test.Assert(grid.GetItemAtPoint(64, 0) == 1);
		Test.Assert(grid.GetItemAtPoint(0, 64) == 2, "the third item wrapped onto row two");
	}

	/// A point past the last COLUMN is nothing, not the first cell of the next row.
	[Test]
	public static void APointPastTheLastColumnHitsNothing()
	{
		let adapter = scope SimpleListAdapter(50);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		Test.Assert(grid.GetItemAtPoint(64 * 3, 0) == 3, "the last column");
		Test.Assert(grid.GetItemAtPoint(64 * 4, 0) == -1, "past it");
	}

	/// A point past the last ITEM is nothing either, which is what makes a right click on the
	/// empty tail of a grid a background click.
	[Test]
	public static void APointPastTheLastItemHitsNothing()
	{
		let adapter = scope SimpleListAdapter(6);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		// Six items over four columns is a full row and a half.
		Test.Assert(grid.GetItemAtPoint(64, 64) == 5, "the last item");
		Test.Assert(grid.GetItemAtPoint(64 * 2, 64) == -1, "the empty tail of its row");
	}

	// ---- Virtualisation -----------------------------------------------------------------------

	/// Only the rows that can be seen exist as views.
	[Test]
	public static void OnlyTheVisibleRowsExist()
	{
		let adapter = scope SimpleListAdapter(400);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		// Four columns of 64 pitch in 300 tall is five rows plus the partial one.
		Test.Assert(grid.VisualChildCount > 1);
		Test.Assert(grid.VisualChildCount <= 4 * 6 + 1, "a screenful, not four hundred");
	}

	/// Scrolling REUSES cells rather than creating more.
	[Test]
	public static void ScrollingRecyclesCellsRatherThanCreatingThem()
	{
		let adapter = scope SimpleListAdapter(4000);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);
		let createdAtFirstLayout = grid.Recycler.CreatedCount;

		for (int32 i < 20)
		{
			grid.ScrollBy(64);
			UITest.LayoutPass(context, root);
		}

		Test.Assert(grid.Recycler.ReusedCount > 0);
		Test.Assert(grid.Recycler.CreatedCount == createdAtFirstLayout);
	}

	/// An ordinary layout pass rebinds NOTHING.
	///
	/// Rebinding every visible cell every pass is pure cost, and it clobbers any state a
	/// bound cell is holding; ListView has the same rule.
	[Test]
	public static void AnOrdinaryLayoutPassRebindsNothing()
	{
		let adapter = scope BindCountingAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		AddGrid(context, root, adapter);
		Test.Assert(adapter.Binds[0] == 1);

		UITest.LayoutPass(context, root);
		UITest.LayoutPass(context, root);

		Test.Assert(adapter.Binds[0] == 1, "still once");
	}

	[Test]
	public static void ScrollingClampsToTheExtent()
	{
		let adapter = scope SimpleListAdapter(200);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		grid.ScrollBy(-1000);
		Test.Assert(grid.ScrollY == 0);

		grid.ScrollBy(999999);
		Test.Assert(grid.ScrollY == grid.MaxScrollY);
	}

	// ---- Selection ----------------------------------------------------------------------------

	[Test]
	public static void SelectionPassesThroughToTheModel()
	{
		let adapter = scope SimpleListAdapter(20);
		let grid = new GridView();
		defer grid.ReleaseRef();
		grid.SetAdapter(adapter);

		grid.Selection.Select(5);
		Test.Assert(grid.Selection.IsSelected(5));
		Test.Assert(grid.Selection.SelectedCount == 1);
	}

	/// The selection is POSITIONAL, so a shrinking data set drops what no longer exists.
	///
	/// ListView prunes here and says why; GridView prunes the same way.
	[Test]
	public static void ShrinkingTheDataDropsSelectionPastTheEnd()
	{
		let big = scope SimpleListAdapter(20);
		let grid = new GridView();
		defer grid.ReleaseRef();

		grid.SetAdapter(big);
		grid.Selection.Select(15);
		Test.Assert(grid.Selection.IsSelected(15));

		big.Count = 4;
		big.NotifyDataSetChanged();

		Test.Assert(!grid.Selection.IsSelected(15));
		Test.Assert(grid.Selection.SelectedCount == 0);
	}

	/// A SMALLER adapter prunes for the same reason a shrunken data set does: the selection is
	/// positional, so an index past the new end would quietly highlight whichever cell
	/// inherits it.
	[Test]
	public static void SwappingInASmallerAdapterDropsSelectionPastTheEnd()
	{
		let big = scope SimpleListAdapter(20);
		let small = scope SimpleListAdapter(4);
		let grid = new GridView();
		defer grid.ReleaseRef();

		// Multiple, so both indices survive the second pick: Select alone replaces.
		grid.Selection.Mode = .Multiple;
		grid.SetAdapter(big);
		grid.Selection.Toggle(15);
		grid.Selection.Toggle(2);
		Test.Assert(grid.Selection.SelectedCount == 2);

		grid.SetAdapter(small);

		Test.Assert(!grid.Selection.IsSelected(15), "past the new end");
		Test.Assert(grid.Selection.IsSelected(2), "and a still valid index is kept");
	}

	// ---- Keys ---------------------------------------------------------------------------------

	/// A cell gets FIRST refusal on a key, and an unconsumed one falls through to navigation.
	[Test]
	public static void ACellSeesAKeyBeforeTheGridNavigatesWithIt()
	{
		let adapter = scope SimpleListAdapter(10);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);

		Test.Assert(grid.GetActiveView(0) != null);
		Test.Assert(grid.GetActiveView(999) == null);

		grid.Selection.Select(1);

		var seenPosition = -1;
		grid.OnItemKeyDown.Add(new [&seenPosition](position, args) =>
			{
				seenPosition = position;
				if (args.Key == .F2)
					args.Handled = true;
			});

		let f2 = scope KeyEventArgs();
		f2.Set(.F2, .None, false);
		grid.OnKeyDown(f2);
		Test.Assert(seenPosition == 1);
		Test.Assert(f2.Handled);
		Test.Assert(grid.Selection.FirstSelected() == 1, "navigation did not run");

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		grid.OnKeyDown(right);
		Test.Assert(seenPosition == 1, "the handler saw the pre-navigation position");
		Test.Assert(grid.Selection.FirstSelected() == 2, "and then navigation moved it");
	}

	/// Up and Down move by a ROW; Left and Right walk the sequence, so they wrap between rows
	/// rather than stopping at the edge of one.
	[Test]
	public static void TheArrowsMoveByRowAndBySequence()
	{
		let adapter = scope SimpleListAdapter(50);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let grid = AddGrid(context, root, adapter);
		Test.Assert(grid.ColumnsCount == 4);
		grid.Selection.Select(0);

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		grid.OnKeyDown(down);
		Test.Assert(grid.Selection.IsSelected(4), "a whole row on");

		let up = scope KeyEventArgs();
		up.Set(.Up, .None, false);
		grid.OnKeyDown(up);
		Test.Assert(grid.Selection.IsSelected(0));

		// Right from the last cell of a row wraps to the first of the next.
		grid.Selection.Select(3);
		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		grid.OnKeyDown(right);
		Test.Assert(grid.Selection.IsSelected(4));

		let end = scope KeyEventArgs();
		end.Set(.End, .None, false);
		grid.OnKeyDown(end);
		Test.Assert(grid.Selection.IsSelected(49));
		Test.Assert(grid.ScrollY == grid.MaxScrollY, "and scrolled to show it");

		let home = scope KeyEventArgs();
		home.Set(.Home, .None, false);
		grid.OnKeyDown(home);
		Test.Assert(grid.Selection.IsSelected(0));
		Test.Assert(grid.ScrollY == 0);
	}
}
