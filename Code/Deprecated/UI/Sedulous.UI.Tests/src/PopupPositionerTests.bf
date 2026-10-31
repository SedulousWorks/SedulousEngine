using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Where a popup goes: below its anchor by preference, flipped or clamped when that would put
/// it off screen.
class PopupPositionerTests
{
	private static Rectangle Screen => .(0, 0, 800, 600);

	// ---- BestFit ------------------------------------------------------------------------------

	/// The preference is BELOW the anchor, left edges aligned, which is where a dropdown reads
	/// as belonging to what opened it.
	[Test]
	public static void BestFitPrefersBelowTheAnchor()
	{
		let position = PopupPositioner.BestFit(.(100, 50, 80, 30), .(120, 40), Screen);

		Test.Assert(position.X == 100);
		Test.Assert(position.Y == 80, "the anchor's bottom edge");
	}

	/// No room below, so it FLIPS above rather than being clamped into the anchor: a popup
	/// covering what opened it is worse than one on the other side.
	[Test]
	public static void BestFitFlipsAboveWhenItWouldRunOffTheBottom()
	{
		let position = PopupPositioner.BestFit(.(100, 550, 80, 30), .(120, 40), Screen);

		Test.Assert(position.Y < 550);
		Test.Assert(position.Y == 510, "its own height above the anchor");
	}

	/// Horizontally it CLAMPS rather than flipping: a popup keeps its left edge near the
	/// anchor, and sliding it back is less disruptive than mirroring it.
	[Test]
	public static void BestFitClampsHorizontallyRatherThanFlipping()
	{
		let position = PopupPositioner.BestFit(.(750, 50, 80, 30), .(120, 40), Screen);

		Test.Assert(position.X + 120 <= 800);
		Test.Assert(position.X >= 0);
	}

	// ---- The plain placements -----------------------------------------------------------------

	[Test]
	public static void BelowAndAbovePlaceDirectly()
	{
		let below = PopupPositioner.Below(.(50, 100, 100, 30), .(80, 40), Screen);
		Test.Assert(below.X == 50);
		Test.Assert(below.Y == 130, "the anchor's bottom");

		let above = PopupPositioner.Above(.(50, 100, 100, 30), .(80, 40), Screen);
		Test.Assert(above.X == 50);
		Test.Assert(above.Y == 60, "its own height above the anchor's top");
	}

	[Test]
	public static void CentreCentresInTheScreen()
	{
		let position = PopupPositioner.Center(.(200, 100), Screen);

		Test.Assert(position.X == 300);
		Test.Assert(position.Y == 250);
	}

	// ---- Submenus -----------------------------------------------------------------------------

	/// A submenu goes to the RIGHT of its parent, with a small gap so the two borders do not
	/// sit on each other, and level with the row that opened it.
	[Test]
	public static void ASubmenuOpensToTheRightOfItsParent()
	{
		let position = PopupPositioner.Submenu(.(100, 50, 150, 200), .(120, 180), Screen);

		Test.Assert(position.X == 252, "the parent's right edge plus the gap");
		Test.Assert(position.Y == 50, "level with the anchor");
	}

	/// No room to the right, so it opens to the LEFT instead. A submenu clamped into its
	/// parent would cover the row that opened it.
	[Test]
	public static void ASubmenuFlipsLeftWhenThereIsNoRoom()
	{
		let position = PopupPositioner.Submenu(.(700, 50, 150, 200), .(120, 180), Screen);

		Test.Assert(position.X < 700);
		Test.Assert(position.X >= 0);
	}

	/// Everything stays inside the screen, whichever way it had to go.
	[Test]
	public static void NothingIsEverPlacedOffScreen()
	{
		let cases = scope Rectangle[](
			Rectangle(0, 0, 10, 10),
			Rectangle(790, 590, 10, 10),
			Rectangle(400, 300, 10, 10));

		for (let anchor in cases)
		{
			let size = Float2(200, 150);

			let best = PopupPositioner.BestFit(anchor, size, Screen);
			Test.Assert((best.X >= 0) && (best.X + size.X <= 800));
			Test.Assert(best.Y >= 0);

			let submenu = PopupPositioner.Submenu(anchor, size, Screen);
			Test.Assert(submenu.X >= 0);
			Test.Assert(submenu.Y >= 0);
		}
	}
}
