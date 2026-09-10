using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Panel and the button base: the press cycle, the click, and the control state a theme keys
/// its drawables off.
class ButtonTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	// ---- Button -------------------------------------------------------------------------------

	/// A press and a release move the button in and out of its pressed state, and the state
	/// shows up where a theme reads it.
	[Test]
	public static void APressAndReleaseMoveThroughThePressedState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new Button("Test");
		root.AddView(button);
		UITest.LayoutPass(context, root);

		let down = scope MouseEventArgs();
		down.Set(10, 10, .Left);
		button.OnMouseDown(down);
		Test.Assert(button.IsPressed);
		Test.Assert(button.GetControlState().HasFlag(.Pressed));

		let up = scope MouseEventArgs();
		up.Set(10, 10, .Left);
		button.OnMouseUp(up);
		Test.Assert(!button.IsPressed);
	}

	[Test]
	public static void AButtonIsFocusableAndATabStop()
	{
		let button = new Button("Test");
		defer button.ReleaseRef();

		Test.Assert(button.IsFocusable);
		Test.Assert(button.IsTabStop);
	}

	/// Return, Space and OnActivate all click, which is what makes a button reachable by
	/// keyboard and by gamepad without each caller knowing how.
	[Test]
	public static void TheKeyboardAndActivationBothClick()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new Button("Test");
		root.AddView(button);
		var clicks = 0;
		button.OnClick.Add(new [&clicks](b) => { clicks++; });

		let returnKey = scope KeyEventArgs();
		returnKey.Set(.Return, .None, false);
		button.OnKeyDown(returnKey);
		Test.Assert(clicks == 1);

		let spaceKey = scope KeyEventArgs();
		spaceKey.Set(.Space, .None, false);
		button.OnKeyDown(spaceKey);
		Test.Assert(clicks == 2);

		button.OnActivate();
		Test.Assert(clicks == 3);
	}

	/// A DISABLED button does not click, however it is asked.
	[Test]
	public static void ADisabledButtonDoesNotClick()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new Button("Test");
		button.IsEnabled = false;
		root.AddView(button);
		var clicked = false;
		button.OnClick.Add(new [&clicked](b) => { clicked = true; });

		button.FireClick();

		Test.Assert(!clicked);
		Test.Assert(button.GetControlState().HasFlag(.Disabled));
	}

	/// A press that is released ELSEWHERE is not a click. Dragging off a button to cancel is
	/// what everyone expects, and it costs one hover check.
	[Test]
	public static void ReleasingAwayFromTheButtonDoesNotClick()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let button = new Button("Test");
		root.AddView(button);
		UITest.LayoutPass(context, root);
		var clicked = false;
		button.OnClick.Add(new [&clicked](b) => { clicked = true; });

		let down = scope MouseEventArgs();
		down.Set(10, 10, .Left);
		button.OnMouseDown(down);

		// Never hovered, since no input ran to make it so: the release finds IsHovered false.
		let up = scope MouseEventArgs();
		up.Set(10, 10, .Left);
		button.OnMouseUp(up);

		Test.Assert(!button.IsPressed, "the press was released");
		Test.Assert(!clicked, "but it was not a click");
	}

	/// A bound command that CANNOT execute disables the button and blocks the click, so a
	/// command's own availability drives the control without the control being told twice.
	[Test]
	public static void ACommandThatCannotExecuteDisablesTheButton()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let command = scope BlockedCommand();
		let button = new Button("Test");
		button.Command = command;
		root.AddView(button);
		var clicked = false;
		button.OnClick.Add(new [&clicked](b) => { clicked = true; });

		Test.Assert(button.GetControlState().HasFlag(.Disabled));

		button.FireClick();
		Test.Assert(!clicked);
		Test.Assert(command.Executions == 0);
	}

	/// And an executable one runs alongside the event.
	[Test]
	public static void AClickRunsTheBoundCommandAsWellAsTheEvent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let command = scope BlockedCommand();
		command.Allowed = true;
		let button = new Button("Test");
		button.Command = command;
		root.AddView(button);
		var clicked = false;
		button.OnClick.Add(new [&clicked](b) => { clicked = true; });

		button.FireClick();

		Test.Assert(clicked);
		Test.Assert(command.Executions == 1);
	}

	private class BlockedCommand : ICommand
	{
		public bool Allowed = false;
		public int32 Executions = 0;

		public bool CanExecute() => Allowed;
		public void Execute()
		{
			Executions++;
		}
	}

	// ---- Panel --------------------------------------------------------------------------------

	/// A panel STRETCHES its children across its content box, which is what separates it from a
	/// frame: a surface they fill, not a stack they are anchored in.
	[Test]
	public static void APanelStretchesItsChildrenAcrossItsContentBox()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let panel = new Panel();
		panel.Padding = .(10, 5, 10, 5);
		root.AddView(panel);
		let child = new TestView(50, 20);
		panel.AddView(child);

		panel.Measure(BoxConstraints.Tight(200, 100));
		panel.Layout(0, 0, 200, 100);

		Test.Assert(child.Bounds.X == 10);
		Test.Assert(child.Bounds.Y == 5);
		Test.Assert(child.Bounds.Width == 180, "the whole content width");
		Test.Assert(child.Bounds.Height == 90);
	}

	/// Wrapping, it is its largest child plus its own chrome.
	[Test]
	public static void APanelWrapsToItsLargestChildPlusItsChrome()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let panel = new Panel();
		panel.Padding = .(10, 5, 10, 5);
		root.AddView(panel);
		panel.AddView(new TestView(50, 20));
		panel.AddView(new TestView(80, 30));

		panel.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(panel.MeasuredSize.X == 80 + 20);
		Test.Assert(panel.MeasuredSize.Y == 30 + 10);
	}

	/// A Gone child contributes nothing and is not placed.
	[Test]
	public static void APanelSkipsAGoneChild()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let panel = new Panel();
		root.AddView(panel);
		let gone = new TestView(200, 200);
		gone.Visibility = .Gone;
		panel.AddView(gone);
		panel.AddView(new TestView(40, 20));

		panel.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(panel.MeasuredSize.X == 40);
		Test.Assert(panel.MeasuredSize.Y == 20);
	}
}
