using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The measure store (View.Measure): within one layout pass a repeat request with the same
/// constraints is answered from the view's last answers, not by measuring its subtree again.
/// Nested flex containers measure a child more than once, and without the store that doubled
/// at every level: Raptor's editor measured the input map page's deepest views 206 times a
/// pass (85,588 measures for 628 views, 0.78 s a layout in Debug). A stored answer leaves the
/// subtree as its last real measure left it, so Layout measures it again first when that was
/// for other constraints: what a stack of requests lays out is the last one's, as before.
class MeasureStoreTests
{
	/// A leaf that fills the width it is given (50 when unbounded) and counts its measures.
	private class CountingView : View
	{
		public int Measures = 0;

		protected override void OnMeasure(BoxConstraints constraints)
		{
			Measures++;
			let width = BoxConstraints.IsBounded(constraints.MaxWidth) ? constraints.MaxWidth : 50.0f;
			MeasuredSize = .(constraints.ConstrainWidth(width), constraints.ConstrainHeight(20.0f));
		}
	}

	/// Asks its one child three times, 100 wide, then 60, then 100 again, and lays it out by
	/// the last answer: the case a stored answer must not get wrong.
	private class AskThrice : ViewGroup
	{
		protected override void OnMeasure(BoxConstraints constraints)
		{
			let child = GetChildAt(0);
			child.Measure(BoxConstraints.Tight(100.0f, 20.0f));
			child.Measure(BoxConstraints.Tight(60.0f, 20.0f));
			child.Measure(BoxConstraints.Tight(100.0f, 20.0f));
			MeasuredSize = child.MeasuredSize;
		}

		protected override void OnLayout(float left, float top, float width, float height)
		{
			let child = GetChildAt(0);
			child.Layout(0.0f, 0.0f, child.MeasuredSize.X, child.MeasuredSize.Y);
		}
	}

	/// Eight nested columns, each holding a leaf and the next column, every child stretched
	/// across (a cross axis Match: the re-measure that doubled per level).
	[Test]
	public static void DeepNestedColumnsMeasureALeafAFewTimesAPassNotHundreds()
	{
		let context = new UIContext();
		let root = new RootView();
		defer { root.ReleaseRef(); delete context; }
		UITest.Init(context, root, 400, 600);

		var stretch = LayoutStyle();
		stretch.Width = .(SizeSpec.Match(), true);
		let leaves = scope List<CountingView>();
		ViewGroup parent = root;
		for (int level < 8)
		{
			let column = new FlexLayout();
			column.Direction = .Vertical;
			let leaf = new CountingView();
			leaf.SetLayout(stretch);
			column.AddView(leaf);
			column.SetLayout(stretch);
			parent.AddView(column);
			parent = column;
			leaves.Add(leaf);
		}
		UITest.LayoutPass(context, root);
		for (let leaf in leaves)
			leaf.Measures = 0;
		UITest.LayoutPass(context, root); // one pass, counted

		// One more a level (each level's measured height is a new constraint below it), where
		// it doubled (2, 4, 8, ... 256).
		let deepest = leaves.Back.Measures;
		Console.WriteLine(scope $"measures of the deepest leaf in one pass: {deepest}");
		Test.Assert(deepest <= 12, scope $"the deepest leaf measured {deepest} times");
		// And the layout is the one a full re-measure gives: every leaf across the whole width.
		for (let leaf in leaves)
			Test.Assert(Math.Abs(leaf.Bounds.Width - 400.0f) < 0.01f, scope $"a leaf {leaf.Bounds.Width} wide");
	}

	/// The child is asked for 100, then 60, then 100 again: the third is answered from the
	/// store, while the child's own row still holds what the 60 gave it. Laid out at 100, the
	/// row's growing leaf must be 100 wide too, not 60.
	[Test]
	public static void AViewLaidOutByAStoredAnswerLaysItsSubtreeOutForThatAnswer()
	{
		let context = new UIContext();
		let root = new RootView();
		defer { root.ReleaseRef(); delete context; }
		UITest.Init(context, root, 400, 600);

		let asker = new AskThrice();
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		let leaf = new CountingView();
		var grow = LayoutStyle();
		grow.FlexGrow = .(1.0f, true);
		leaf.SetLayout(grow);
		row.AddView(leaf);
		asker.AddView(row);
		root.AddView(asker);
		UITest.LayoutPass(context, root);

		Test.Assert(Math.Abs(row.Bounds.Width - 100.0f) < 0.01f, scope $"the row is {row.Bounds.Width} wide");
		Test.Assert(Math.Abs(leaf.Bounds.Width - 100.0f) < 0.01f, scope $"the leaf is {leaf.Bounds.Width} wide");
	}

	/// An invalidation starts a new generation: the same constraints measure again.
	[Test]
	public static void AChangeBetweenMeasuresIsMeasuredAfresh()
	{
		let context = new UIContext();
		let root = new RootView();
		defer { root.ReleaseRef(); delete context; }
		UITest.Init(context, root, 400, 600);

		let leaf = new CountingView();
		root.AddView(leaf);
		UITest.LayoutPass(context, root);
		leaf.Measures = 0;
		leaf.Measure(BoxConstraints.Loose(200.0f, 50.0f));
		leaf.Measure(BoxConstraints.Loose(200.0f, 50.0f));
		Test.Assert(leaf.Measures == 1, "the repeat came from the store");
		leaf.Invalidate();
		leaf.Measure(BoxConstraints.Loose(200.0f, 50.0f));
		Test.Assert(leaf.Measures == 2);
	}
}
