using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The parts a widget places or draws itself mirror in right to left: a part at the inline start
// moves to the other edge with its shape mirrored, and text aligned to its start goes with it.

/// The mirroring helpers a widget places its parts with in right to left.
class MirrorTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void TheHelpersPlaceAPartAsFarFromTheRightAsItWasFromTheLeft()
	{
		let area = Rect(10.0f, 0.0f, 100.0f, 20.0f);
		Test.Assert(Near(Rect.MirroredX(15.0f, area, true), 105.0f));
		Test.Assert(Near(Rect.MirroredX(15.0f, area, false), 15.0f));
		let part = Rect.MirroredIn(Rect(12.0f, 2.0f, 20.0f, 10.0f), area, true);
		Test.Assert(Near(part.X, 88.0f));
		Test.Assert(Near(part.Y, 2.0f));
		Test.Assert(Near(part.Width, 20.0f));
	}
}
