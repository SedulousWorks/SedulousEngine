using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

class WindowEventTests
{
	[Test]
	public static void TestEventTypeOnly()
	{
		let evt = WindowEvent(.Shown);

		Test.Assert(evt.Type == .Shown);
		Test.Assert(evt.Data1 == 0);
		Test.Assert(evt.Data2 == 0);
	}

	[Test]
	public static void TestEventWithData()
	{
		let evt = WindowEvent(.Resized, 1280, 720);

		Test.Assert(evt.Type == .Resized);
		Test.Assert(evt.Data1 == 1280);
		Test.Assert(evt.Data2 == 720);
	}

	[Test]
	public static void TestAllEventTypes()
	{
		// Verify all event types can be created
		Test.Assert(WindowEvent(.Shown).Type == .Shown);
		Test.Assert(WindowEvent(.Hidden).Type == .Hidden);
		Test.Assert(WindowEvent(.Exposed).Type == .Exposed);
		Test.Assert(WindowEvent(.Moved, 10, 20).Type == .Moved);
		Test.Assert(WindowEvent(.Resized, 800, 600).Type == .Resized);
		Test.Assert(WindowEvent(.Minimized).Type == .Minimized);
		Test.Assert(WindowEvent(.Maximized).Type == .Maximized);
		Test.Assert(WindowEvent(.Restored).Type == .Restored);
		Test.Assert(WindowEvent(.MouseEnter).Type == .MouseEnter);
		Test.Assert(WindowEvent(.MouseLeave).Type == .MouseLeave);
		Test.Assert(WindowEvent(.FocusGained).Type == .FocusGained);
		Test.Assert(WindowEvent(.FocusLost).Type == .FocusLost);
		Test.Assert(WindowEvent(.CloseRequested).Type == .CloseRequested);
		Test.Assert(WindowEvent(.EnterFullscreen).Type == .EnterFullscreen);
		Test.Assert(WindowEvent(.LeaveFullscreen).Type == .LeaveFullscreen);
	}
}
