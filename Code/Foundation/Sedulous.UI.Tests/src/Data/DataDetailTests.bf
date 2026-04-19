namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Additional data virtualization tests: SelectionModel, ViewRecycler, FlattenedTreeAdapter.
class DataDetailTests
{
	// === SelectionModel ===

	[Test]
	public static void Selection_SingleMode_DeselectsPrevious()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Single;
		sel.Select(0);
		sel.Select(1);
		Test.Assert(!sel.IsSelected(0));
		Test.Assert(sel.IsSelected(1));
	}

	[Test]
	public static void Selection_MultipleMode_KeepsPrevious()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(0);
		sel.Select(1);
		Test.Assert(sel.IsSelected(0));
		Test.Assert(sel.IsSelected(1));
	}

	[Test]
	public static void Selection_Toggle()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Single;
		sel.Select(0);
		Test.Assert(sel.IsSelected(0));
		sel.Toggle(0);
		Test.Assert(!sel.IsSelected(0));
	}

	[Test]
	public static void Selection_ClearAll()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(0);
		sel.Select(1);
		sel.Select(2);
		sel.ClearSelection();
		Test.Assert(!sel.IsSelected(0));
		Test.Assert(!sel.IsSelected(1));
		Test.Assert(!sel.IsSelected(2));
	}

	[Test]
	public static void Selection_FirstSelected_NoSelection()
	{
		let sel = scope SelectionModel();
		Test.Assert(sel.FirstSelected == -1);
	}

	[Test]
	public static void Selection_FirstSelected_ReturnsAny()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(5);
		sel.Select(2);
		sel.Select(8);
		// HashSet order is undefined — just verify it returns one of the selected.
		let first = sel.FirstSelected;
		Test.Assert(first == 2 || first == 5 || first == 8);
	}

	[Test]
	public static void Selection_OnSelectionChanged_Fires()
	{
		let sel = scope SelectionModel();
		bool fired = false;
		sel.OnSelectionChanged.Add(new [&fired]() => { fired = true; });
		sel.Select(0);
		Test.Assert(fired);
	}

	[Test]
	public static void Selection_Deselect()
	{
		let sel = scope SelectionModel();
		sel.Select(3);
		sel.Deselect(3);
		Test.Assert(!sel.IsSelected(3));
	}

	[Test]
	public static void Selection_NoneMode_IgnoresSelect()
	{
		let sel = scope SelectionModel();
		sel.Mode = .None;
		sel.Select(0);
		Test.Assert(!sel.IsSelected(0));
	}

	// === ViewRecycler ===

	[Test]
	public static void Recycler_RecycleAndReuse()
	{
		let recycler = scope ViewRecycler();
		let view = new ColorView();

		recycler.Recycle(view, 0);
		Test.Assert(recycler.RecycledCount > 0);

		let reused = recycler.Acquire(0);
		Test.Assert(reused === view);
		delete view;
	}

	[Test]
	public static void Recycler_DifferentTypes_NotMixed()
	{
		let recycler = scope ViewRecycler();
		let v0 = new ColorView();
		let v1 = new ColorView();

		recycler.Recycle(v0, 0);
		recycler.Recycle(v1, 1);

		let got0 = recycler.Acquire(0);
		let got1 = recycler.Acquire(1);
		Test.Assert(got0 === v0);
		Test.Assert(got1 === v1);

		delete v0;
		delete v1;
	}

	[Test]
	public static void Recycler_Acquire_Empty_ReturnsNull()
	{
		let recycler = scope ViewRecycler();
		let result = recycler.Acquire(0);
		Test.Assert(result == null);
	}

	// === MomentumHelper ===

	[Test]
	public static void Momentum_DecaysOverTime()
	{
		var m = MomentumHelper();
		m.VelocityY = 1000;

		float totalDy = 0;
		for (int i = 0; i < 60; i++)
		{
			let (_, dy) = m.Update(1.0f / 60.0f);
			totalDy += dy;
		}

		// After 1 second of decay, should have moved and slowed.
		Test.Assert(totalDy > 0);
		Test.Assert(Math.Abs(m.VelocityY) < 1000); // slowed
	}

	[Test]
	public static void Momentum_ZeroVelocity_NoDelta()
	{
		var m = MomentumHelper();
		let (dx, dy) = m.Update(1.0f / 60.0f);
		Test.Assert(dx == 0 && dy == 0);
	}
}
