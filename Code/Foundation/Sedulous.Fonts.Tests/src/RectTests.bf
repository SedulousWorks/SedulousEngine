using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

class RectTests
{
	[Test]
	static void TestRectDefaultConstructor()
	{
		let rect = Rect();

		Test.Assert(rect.X == 0);
		Test.Assert(rect.Y == 0);
		Test.Assert(rect.Width == 0);
		Test.Assert(rect.Height == 0);
		Test.Assert(rect.IsEmpty);
	}

	[Test]
	static void TestRectConstructor()
	{
		let rect = Rect(10, 20, 100, 50);

		Test.Assert(rect.X == 10);
		Test.Assert(rect.Y == 20);
		Test.Assert(rect.Width == 100);
		Test.Assert(rect.Height == 50);
		Test.Assert(!rect.IsEmpty);
	}

	[Test]
	static void TestRectBounds()
	{
		let rect = Rect(10, 20, 100, 50);

		Test.Assert(rect.Left == 10);
		Test.Assert(rect.Top == 20);
		Test.Assert(rect.Right == 110);
		Test.Assert(rect.Bottom == 70);
	}

	[Test]
	static void TestRectContains()
	{
		let rect = Rect(10, 20, 100, 50);

		// Inside
		Test.Assert(rect.Contains(50, 40));

		// On edges
		Test.Assert(rect.Contains(10, 20)); // Top-left corner
		Test.Assert(!rect.Contains(110, 70)); // Bottom-right corner (exclusive)

		// Outside
		Test.Assert(!rect.Contains(5, 40));
		Test.Assert(!rect.Contains(50, 10));
		Test.Assert(!rect.Contains(150, 40));
		Test.Assert(!rect.Contains(50, 100));
	}

	[Test]
	static void TestRectFromBounds()
	{
		let rect = Rect.FromBounds(10, 20, 110, 70);

		Test.Assert(rect.X == 10);
		Test.Assert(rect.Y == 20);
		Test.Assert(rect.Width == 100);
		Test.Assert(rect.Height == 50);
	}
}
