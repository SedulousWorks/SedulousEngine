namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class KeyboardTests
{
	/// Test view that records whether OnKeyDown was called.
	class KeyTestView : View
	{
		public KeyCode LastKey;
		public bool KeyDownReceived;

		public this() { IsFocusable = true; }

		public override void OnKeyDown(KeyEventArgs e)
		{
			LastKey = e.Key;
			KeyDownReceived = true;
		}
	}

	/// Test view implementing IAcceleratorHandler.
	class AccelTestView : View, IAcceleratorHandler
	{
		public bool AccelHandled;
		public KeyCode AccelKey;

		public bool HandleAccelerator(KeyCode key, KeyModifiers modifiers)
		{
			AccelKey = key;
			AccelHandled = true;
			return true;
		}
	}

	[Test]
	public static void KeyDown_RoutedToFocused()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let layout = new FrameLayout();
		ctx.Root.AddView(layout);

		let view = new KeyTestView();
		layout.AddView(view);
		ctx.DoLayout();

		ctx.FocusManager.SetFocus(view);

		ctx.InputManager.ProcessKeyDown(.Space, .None, false);
		Test.Assert(view.KeyDownReceived);
		Test.Assert(view.LastKey == .Space);
	}

	[Test]
	public static void KeyDown_NotRoutedWithoutFocus()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let layout = new FrameLayout();
		ctx.Root.AddView(layout);

		let view = new KeyTestView();
		layout.AddView(view);
		ctx.DoLayout();

		// No focus set.
		ctx.InputManager.ProcessKeyDown(.Space, .None, false);
		Test.Assert(!view.KeyDownReceived);
	}

	[Test]
	public static void Accelerator_FoundTopDown()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(400, 300);

		let layout = new FrameLayout();
		ctx.Root.AddView(layout);

		let accel = new AccelTestView();
		layout.AddView(accel);
		ctx.DoLayout();

		// Alt+A should find the accelerator handler.
		ctx.InputManager.ProcessKeyDown(.A, .Alt, false);
		Test.Assert(accel.AccelHandled);
		Test.Assert(accel.AccelKey == .A);
	}
}
