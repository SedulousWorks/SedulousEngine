namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class PopupPositionerTests
{
	[Test]
	public static void BestFit_PositionsBelowAnchor()
	{
		let anchor = RectangleF(100, 50, 80, 30);
		let popup = Vector2(120, 40);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.BestFit(anchor, popup, screen);
		Test.Assert(Math.Abs(x - 100) < 0.01f);
		Test.Assert(Math.Abs(y - 80) < 0.01f); // below anchor
	}

	[Test]
	public static void BestFit_FlipsAboveWhenClippingBottom()
	{
		let anchor = RectangleF(100, 550, 80, 30);
		let popup = Vector2(120, 40);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.BestFit(anchor, popup, screen);
		Test.Assert(y < 550); // flipped above
		Test.Assert(Math.Abs(y - 510) < 0.01f); // 550 - 40
	}

	[Test]
	public static void BestFit_ClampsHorizontally()
	{
		let anchor = RectangleF(750, 50, 80, 30);
		let popup = Vector2(120, 40);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.BestFit(anchor, popup, screen);
		Test.Assert(x + popup.X <= 800); // clamped to screen
	}

	[Test]
	public static void Center_CentersInScreen()
	{
		let popup = Vector2(200, 100);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.Center(popup, screen);
		Test.Assert(Math.Abs(x - 300) < 0.01f);
		Test.Assert(Math.Abs(y - 250) < 0.01f);
	}

	[Test]
	public static void Below_PositionsDirectlyBelow()
	{
		let anchor = RectangleF(50, 100, 100, 30);
		let popup = Vector2(80, 40);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.Below(anchor, popup, screen);
		Test.Assert(Math.Abs(x - 50) < 0.01f);
		Test.Assert(Math.Abs(y - 130) < 0.01f);
	}

	[Test]
	public static void Above_PositionsDirectlyAbove()
	{
		let anchor = RectangleF(50, 100, 100, 30);
		let popup = Vector2(80, 40);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.Above(anchor, popup, screen);
		Test.Assert(Math.Abs(x - 50) < 0.01f);
		Test.Assert(Math.Abs(y - 60) < 0.01f); // 100 - 40
	}

	[Test]
	public static void Submenu_PositionsToRight()
	{
		let parent = RectangleF(100, 50, 150, 200);
		let popup = Vector2(120, 180);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.Submenu(parent, popup, screen);
		Test.Assert(Math.Abs(x - 250) < 0.01f); // right edge of parent
		Test.Assert(Math.Abs(y - 50) < 0.01f);
	}

	[Test]
	public static void Submenu_FlipsLeftWhenClipping()
	{
		let parent = RectangleF(700, 50, 150, 200);
		let popup = Vector2(120, 180);
		let screen = RectangleF(0, 0, 800, 600);

		let (x, y) = PopupPositioner.Submenu(parent, popup, screen);
		Test.Assert(x < 700); // flipped to left
	}
}
