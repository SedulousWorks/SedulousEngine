using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The two pane splitter: its ratio, its layout arithmetic, and collapsing a pane to its own
/// content without losing the ratio.
class SplitViewTests
{
	[Test]
	public static void TheDefaultsAreAHorizontalEvenSplit()
	{
		let split = new SplitView();
		defer split.ReleaseRef();

		Test.Assert(split.Orientation == .Horizontal);
		Test.Assert(split.SplitRatio == 0.5f);
	}

	[Test]
	public static void SetPanesAdoptsBothAndReadsThemBack()
	{
		let split = new SplitView();
		defer split.ReleaseRef();

		let first = new Panel();
		let second = new Panel();
		first.AddRef();
		second.AddRef();
		defer { first.ReleaseRef(); second.ReleaseRef(); }

		split.SetPanes(first, second);
		Test.Assert(split.FirstPane == first);
		Test.Assert(split.SecondPane == second);
		Test.Assert(split.ChildCount == 2);
	}

	[Test]
	public static void TheRatioClampsAndReportsTheChange()
	{
		let split = new SplitView();
		defer split.ReleaseRef();

		var fired = false;
		var lastRatio = -1.0f;
		split.OnSplitChanged.Add(new [&fired, &lastRatio](sender, ratio) =>
			{
				fired = true;
				lastRatio = ratio;
			});

		split.SplitRatio = 2.0f;
		Test.Assert(split.SplitRatio == 1.0f);
		Test.Assert(fired);
		Test.Assert(lastRatio == 1.0f);

		split.SplitRatio = -1.0f;
		Test.Assert(split.SplitRatio == 0.0f);
	}

	/// The arithmetic: the divider's own thickness comes off the top, and what is left is what
	/// the ratio divides.
	[Test]
	public static void TheDividerThicknessComesOutBeforeTheRatio()
	{
		let split = new SplitView();
		defer split.ReleaseRef();

		let first = new Panel();
		let second = new Panel();
		first.AddRef();
		second.AddRef();
		defer { first.ReleaseRef(); second.ReleaseRef(); }

		split.SetPanes(first, second);
		split.SplitRatio = 0.5f;
		split.Measure(BoxConstraints.Tight(200.0f, 100.0f));
		split.Layout(0.0f, 0.0f, 200.0f, 100.0f);

		// 200 less the 6px divider is 194; half each is 97.
		Test.Assert(first.Width == 97.0f);
		Test.Assert(second.Width == 97.0f);
		Test.Assert(first.Height == 100.0f);
	}

	/// Collapsing shrinks a pane to its content's minimum, gives the rest to the other, drops
	/// the divider entirely, and LEAVES the ratio alone so expanding restores the user's size.
	[Test]
	public static void CollapsingAPaneShrinksItToItsContentAndKeepsTheRatio()
	{
		let split = new SplitView();
		defer split.ReleaseRef();
		split.Orientation = .Vertical;

		let first = new Panel();
		first.AddRef();
		defer first.ReleaseRef();

		// The second pane is a bar whose content is 26 pixels tall.
		let second = new FlexLayout();
		second.AddRef();
		defer second.ReleaseRef();
		second.Direction = .Vertical;

		let bar = new Panel();
		LayoutStyle barStyle = .();
		barStyle.Width = SizeSpec.Match();
		barStyle.Height = SizeSpec.Fixed(Unit.Px(26.0f));
		second.AddView(bar, barStyle);

		split.SetPanes(first, second);
		split.SplitRatio = 0.5f;

		split.Measure(BoxConstraints.Tight(300.0f, 200.0f));
		split.Layout(0.0f, 0.0f, 300.0f, 200.0f);
		Test.Assert(!split.AnyPaneCollapsed);
		Test.Assert(first.Height == 97.0f);

		split.SetPaneCollapsed(.Second, true);
		Test.Assert(split.IsPaneCollapsed(.Second));
		Test.Assert(split.AnyPaneCollapsed);

		split.Measure(BoxConstraints.Tight(300.0f, 200.0f));
		split.Layout(0.0f, 0.0f, 300.0f, 200.0f);
		Test.Assert(second.Height == 26.0f);
		Test.Assert(first.Height == 200.0f - 26.0f, "no divider space is reserved");
		Test.Assert(split.SplitRatio == 0.5f, "the ratio survives the collapse");

		split.SetPaneCollapsed(.Second, false);
		Test.Assert(!split.AnyPaneCollapsed);
		split.Measure(BoxConstraints.Tight(300.0f, 200.0f));
		split.Layout(0.0f, 0.0f, 300.0f, 200.0f);
		Test.Assert(first.Height == 97.0f, "restored at the preserved ratio");
	}
}
