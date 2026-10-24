using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Rect: eepp's Rectf behaviour (Left/Top/Right/Bottom, contains, intersect), on x/y/w/h
/// storage.
class RectTests
{
	[Test]
	public static void DefaultIsZero()
	{
		let r = Rect();
		Test.Assert(r.X == 0.0f);
		Test.Assert(r.Y == 0.0f);
		Test.Assert(r.Width == 0.0f);
		Test.Assert(r.Height == 0.0f);
		Test.Assert(r.IsEmpty);
	}

	[Test]
	public static void EdgesAndAccessors()
	{
		let r = Rect(10.0f, 20.0f, 30.0f, 40.0f);
		Test.Assert(r.Left == 10.0f);
		Test.Assert(r.Top == 20.0f);
		Test.Assert(r.Right == 40.0f);
		Test.Assert(r.Bottom == 60.0f);
		Test.Assert(r.Position == Float2(10.0f, 20.0f));
		Test.Assert(r.Size == Float2(30.0f, 40.0f));
		Test.Assert(r.Center == Float2(25.0f, 40.0f));
		Test.Assert(!r.IsEmpty);
	}

	[Test]
	public static void FromLTRBMatchesEdges()
	{
		Test.Assert(Rect.FromLTRB(10.0f, 20.0f, 40.0f, 60.0f) == Rect(10.0f, 20.0f, 30.0f, 40.0f));
	}

	[Test]
	public static void FromMinMax()
	{
		Test.Assert(Rect.FromMinMax(.(1.0f, 2.0f), .(5.0f, 8.0f)) == Rect(1.0f, 2.0f, 4.0f, 6.0f));
	}

	[Test]
	public static void ContainsPoint()
	{
		let r = Rect(0.0f, 0.0f, 100.0f, 50.0f);
		Test.Assert(r.Contains(Float2(50.0f, 25.0f)));
		Test.Assert(r.Contains(Float2(0.0f, 0.0f)), "edge inclusive");
		Test.Assert(r.Contains(Float2(100.0f, 50.0f)), "edge inclusive");
		Test.Assert(!r.Contains(Float2(101.0f, 25.0f)));
		Test.Assert(!r.Contains(Float2(50.0f, -1.0f)));
	}

	[Test]
	public static void ContainsRect()
	{
		let outer = Rect(0.0f, 0.0f, 100.0f, 100.0f);
		Test.Assert(outer.Contains(Rect(10.0f, 10.0f, 20.0f, 20.0f)));
		Test.Assert(!outer.Contains(Rect(90.0f, 90.0f, 20.0f, 20.0f)));
	}

	[Test]
	public static void Intersects()
	{
		let a = Rect(0.0f, 0.0f, 50.0f, 50.0f);
		Test.Assert(a.Intersects(Rect(25.0f, 25.0f, 50.0f, 50.0f)));
		Test.Assert(!a.Intersects(Rect(60.0f, 0.0f, 10.0f, 10.0f)));
		Test.Assert(!a.Intersects(Rect(50.0f, 0.0f, 10.0f, 10.0f)), "touching, not overlapping");
	}

	[Test]
	public static void IntersectOverlap()
	{
		Test.Assert(Rect.Intersect(Rect(0.0f, 0.0f, 50.0f, 50.0f), Rect(25.0f, 25.0f, 50.0f, 50.0f)) == Rect(25.0f, 25.0f, 25.0f, 25.0f));
	}

	[Test]
	public static void IntersectDisjointIsEmpty()
	{
		Test.Assert(Rect.Intersect(Rect(0.0f, 0.0f, 10.0f, 10.0f), Rect(100.0f, 100.0f, 10.0f, 10.0f)).IsEmpty);
	}

	[Test]
	public static void MergeUnion()
	{
		Test.Assert(Rect.Merge(Rect(0.0f, 0.0f, 10.0f, 10.0f), Rect(20.0f, 5.0f, 10.0f, 10.0f)) == Rect(0.0f, 0.0f, 30.0f, 15.0f));
	}

	[Test]
	public static void RectangleRoundTrip()
	{
		let r = Rect(3.0f, 4.0f, 5.0f, 6.0f);
		let cr = r.ToRectangle();
		Test.Assert(cr.X == 3.0f);
		Test.Assert(cr.Width == 5.0f);
		Test.Assert(Rect.FromRectangle(cr) == r);
	}
}
