using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

/// The latch every shell's keys and buttons keep: a press and its release in one frame read as
/// both, a repeat of the state is no new edge, and a frame's start clears the edges but not the
/// state.
class ButtonLatchTests
{
	[Test]
	public static void ButtonLatchKeepsTheFramesEdges()
	{
		ButtonLatch latch = .();
		latch.Set(true);
		latch.Set(true); // a repeat
		latch.Set(false);
		latch.Set(true);
		Test.Assert(latch.Down && latch.Pressed && latch.Released);

		latch.BeginFrame();
		Test.Assert(latch.Down && !latch.Pressed && !latch.Released);
		latch.Set(true);
		Test.Assert(!latch.Pressed, "held is not pressed again");
	}

	/// A tap whose press and release share a frame reads as pressed and released, and up.
	[Test]
	public static void APressAndReleaseInOneFrameReadAsBoth()
	{
		ButtonLatch latch = .();
		latch.BeginFrame();
		latch.Set(true);
		latch.Set(false);
		Test.Assert(!latch.Down && latch.Pressed && latch.Released);
	}
}
