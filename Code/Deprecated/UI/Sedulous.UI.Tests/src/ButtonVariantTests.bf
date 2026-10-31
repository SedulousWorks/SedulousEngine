using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The button variants: an icon in place of text, a button that keeps clicking while held, and
/// one whose face is an arbitrary view.
class ButtonVariantTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	// ---- IconButton ---------------------------------------------------------------------------

	/// The size given is the ICON's, and the chrome is added around it.
	///
	/// Measuring the whole button as that size instead would let the padding inset the draw by
	/// room the measure never reserved, and the icon would come out smaller than asked for.
	[Test]
	public static void AnIconButtonMeasuresItsIconPlusItsChrome()
	{
		let button = new IconButton(null, 24);
		defer button.ReleaseRef();

		button.Measure(BoxConstraints(0, 100, 0, 100));

		Test.Assert(button.MeasuredSize.X == 30, "24 plus the default 3 either side");
		Test.Assert(button.MeasuredSize.Y == 30);
	}

	[Test]
	public static void AnIconButtonClicksAndIsFocusable()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new IconButton(null, 20);
		root.AddView(button);

		var clicked = false;
		button.OnClick.Add(new [&clicked](b) => { clicked = true; });

		button.FireClick();

		Test.Assert(clicked);
		Test.Assert(button.IsFocusable);
	}

	[Test]
	public static void AnIconButtonMovesThroughThePressedState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new IconButton(null, 20);
		root.AddView(button);

		let down = scope MouseEventArgs();
		down.Set(5, 5, .Left);
		button.OnMouseDown(down);
		Test.Assert(button.IsPressed);

		let up = scope MouseEventArgs();
		up.Set(5, 5, .Left);
		button.OnMouseUp(up);
		Test.Assert(!button.IsPressed);
	}

	// ---- RepeatButton -------------------------------------------------------------------------

	/// The keyboard still clicks exactly once: the repeat is a mouse hold, not an activation.
	[Test]
	public static void ARepeatButtonClicksOnceFromTheKeyboard()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new RepeatButton("Hold");
		root.AddView(button);

		var clicks = 0;
		button.OnClick.Add(new [&clicks](b) => { clicks++; });

		let returnKey = scope KeyEventArgs();
		returnKey.Set(.Return, .None, false);
		button.OnKeyDown(returnKey);

		Test.Assert(clicks == 1);
	}

	/// Held: nothing before the delay, then a click, then more at the interval.
	[Test]
	public static void ARepeatButtonRepeatsWhileHeld()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new RepeatButton("Hold");
		button.RepeatDelay = 0.1f;
		button.RepeatInterval = 0.05f;
		root.AddView(button);

		var clicks = 0;
		button.OnClick.Add(new [&clicks](b) => { clicks++; });

		let down = scope MouseEventArgs();
		down.Set(10, 10, .Left);
		button.OnMouseDown(down);

		button.UpdateRepeat(0.05f);
		Test.Assert(clicks == 0, "still inside the delay");

		button.UpdateRepeat(0.06f); // 0.11 total, past the 0.1 delay
		Test.Assert(clicks >= 1);

		let before = clicks;
		button.UpdateRepeat(0.1f);
		Test.Assert(clicks > before);
	}

	/// Releasing stops it, and a later update does nothing.
	[Test]
	public static void ARepeatButtonStopsOnRelease()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new RepeatButton("Hold");
		button.RepeatDelay = 0.05f;
		button.RepeatInterval = 0.02f;
		root.AddView(button);

		var clicks = 0;
		button.OnClick.Add(new [&clicks](b) => { clicks++; });

		let down = scope MouseEventArgs();
		down.Set(10, 10, .Left);
		button.OnMouseDown(down);
		let up = scope MouseEventArgs();
		up.Set(10, 10, .Left);
		button.OnMouseUp(up);

		let afterRelease = clicks;
		button.UpdateRepeat(0.2f);

		Test.Assert(clicks == afterRelease);
	}

	// ---- ContentButton ------------------------------------------------------------------------
	//
	// The variant with the least coverage elsewhere.

	/// The content is measured loose and the chrome is added around it.
	[Test]
	public static void AContentButtonMeasuresItsContentPlusItsChrome()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new ContentButton(new TestView(40, 20));
		root.AddView(button);

		button.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(button.MeasuredSize.X == 40 + 24, "the default 12 either side");
		Test.Assert(button.MeasuredSize.Y == 20 + 16);
	}

	/// Content smaller than the button sits in the middle of the content box at its own size,
	/// rather than being stretched to fill it.
	[Test]
	public static void AContentButtonCentresContentSmallerThanItself()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let content = new TestView(40, 20);
		let button = new ContentButton(content);
		root.AddView(button);

		button.Measure(BoxConstraints.Loose(400, 300));
		button.Layout(0, 0, 200, 100);

		// Content box is 200-24 by 100-16, so the content is inset by the padding plus half
		// the slack on each axis.
		Test.Assert(content.Bounds.X == 12 + (176 - 40) / 2);
		Test.Assert(content.Bounds.Y == 8 + (84 - 20) / 2);
		Test.Assert(content.Bounds.Width == 40, "its own size, not the box's");
		Test.Assert(content.Bounds.Height == 20);
	}

	/// The content is NOT a child: a hit lands on the button, never on what it is showing, so
	/// the whole face is one click target.
	[Test]
	public static void AContentButtonsContentIsNotAChild()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let content = new TestView(40, 20);
		let button = new ContentButton(content);
		root.AddView(button);
		button.Measure(BoxConstraints.Loose(400, 300));
		button.Layout(0, 0, 200, 100);

		// A `button is ViewGroup` check would not even compile - ContentButton is not in that
		// hierarchy - so the hit test is what is left to assert.
		Test.Assert(button.HitTest(.(100, 50)) == button);
		Test.Assert(content.Parent == null);
	}

	/// The button owns its content, so replacing it releases the one held before, and handing
	/// back the content already held neither double releases nor leaks.
	[Test]
	public static void ReplacingTheContentReleasesTheOneHeldBefore()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let first = new TestView(40, 20);
		first.AddRef(); // the test's own reference, so it outlives the button letting go
		defer first.ReleaseRef();

		let button = new ContentButton(first);
		root.AddView(button);
		Test.Assert(first.RefCount == 2);

		button.SetContent(new TestView(10, 10));
		Test.Assert(first.RefCount == 1, "the button let go of the first");

		let second = button.Content;
		second.AddRef();
		button.SetContent(second);
		Test.Assert(second.RefCount == 1, "held exactly once, by the button");
	}
}
