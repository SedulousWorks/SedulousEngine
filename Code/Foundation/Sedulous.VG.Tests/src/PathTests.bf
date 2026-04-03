namespace Sedulous.VG.Tests;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class PathTests
{
	[Test]
	public static void GetBounds_CorrectRect()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(10, 20);
		builder.LineTo(30, 40);
		builder.LineTo(5, 50);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		let bounds = path.GetBounds();

		Test.Assert(Math.Abs(bounds.X - 5.0f) < 0.01f);
		Test.Assert(Math.Abs(bounds.Y - 20.0f) < 0.01f);
		Test.Assert(Math.Abs(bounds.Width - 25.0f) < 0.01f);
		Test.Assert(Math.Abs(bounds.Height - 30.0f) < 0.01f);
	}

	[Test]
	public static void Contains_Inside()
	{
		// Simple square 0,0 -> 10,10
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Contains(.(5, 5), .EvenOdd));
	}

	[Test]
	public static void Contains_Outside()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(!path.Contains(.(15, 5), .EvenOdd));
		Test.Assert(!path.Contains(.(5, 15), .EvenOdd));
		Test.Assert(!path.Contains(.(-5, 5), .EvenOdd));
	}

	[Test]
	public static void SubPathCount_MultipleMoves()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 10);
		builder.MoveTo(20, 20);
		builder.LineTo(30, 30);
		builder.MoveTo(40, 40);
		builder.LineTo(50, 50);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.SubPathCount == 3);
	}

	[Test]
	public static void GetLength_StraightLine()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);

		let path = builder.ToPath();
		defer delete path;
		let len = path.GetLength();
		Test.Assert(Math.Abs(len - 10.0f) < 0.01f);
	}

	[Test]
	public static void GetPointAtDistance_MidPoint()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);

		let path = builder.ToPath();
		defer delete path;
		let pt = path.GetPointAtDistance(5.0f);
		Test.Assert(Math.Abs(pt.X - 5.0f) < 0.01f);
		Test.Assert(Math.Abs(pt.Y) < 0.01f);
	}

	[Test]
	public static void Iterator_YieldsCorrectSegments()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		var iter = path.GetIterator();
		PathSegment seg = ?;

		Test.Assert(iter.GetNext(out seg));
		Test.Assert(seg.Command == .MoveTo);

		Test.Assert(iter.GetNext(out seg));
		Test.Assert(seg.Command == .LineTo);

		Test.Assert(iter.GetNext(out seg));
		Test.Assert(seg.Command == .Close);

		Test.Assert(!iter.GetNext(out seg));
	}
}
