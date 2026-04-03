namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class PathBuilderTests
{
	[Test]
	public static void MoveTo_LineTo_CreatesCommands()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(10, 20);
		builder.LineTo(30, 40);
		builder.LineTo(50, 60);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 3);
		Test.Assert(path.Commands[0] == .MoveTo);
		Test.Assert(path.Commands[1] == .LineTo);
		Test.Assert(path.Commands[2] == .LineTo);
		Test.Assert(path.PointCount == 3);
	}

	[Test]
	public static void Close_AddsCloseCommand()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 4);
		Test.Assert(path.Commands[3] == .Close);
	}

	[Test]
	public static void ToPath_ReturnsImmutableCopy()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 10);

		let path1 = builder.ToPath();
		defer delete path1;
		builder.LineTo(20, 20);
		let path2 = builder.ToPath();
		defer delete path2;

		// path1 should not have the extra LineTo
		Test.Assert(path1.CommandCount == 2);
		Test.Assert(path2.CommandCount == 3);
	}

	[Test]
	public static void ArcTo_GeneratesCubics()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(100, 0);
		// Quarter circle arc
		builder.ArcTo(100, 100, 0, false, true, 0, 100);

		let path = builder.ToPath();
		defer delete path;
		// Should have MoveTo + at least one CubicTo
		Test.Assert(path.CommandCount >= 2);

		bool hasCubic = false;
		for (let cmd in path.Commands)
		{
			if (cmd == .CubicTo)
				hasCubic = true;
		}
		Test.Assert(hasCubic);
	}

	[Test]
	public static void Clear_Resets()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 10);
		builder.Clear();

		Test.Assert(builder.CommandCount == 0);
		Test.Assert(builder.CurrentPoint == Vector2.Zero);
	}

	[Test]
	public static void QuadTo_AddsTwoPoints()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.QuadTo(5, 10, 10, 0);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 2);
		Test.Assert(path.Commands[1] == .QuadTo);
		Test.Assert(path.PointCount == 3); // MoveTo(1) + QuadTo(2)
	}

	[Test]
	public static void CubicTo_AddsThreePoints()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.CubicTo(5, 10, 15, 10, 20, 0);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 2);
		Test.Assert(path.Commands[1] == .CubicTo);
		Test.Assert(path.PointCount == 4); // MoveTo(1) + CubicTo(3)
	}

	[Test]
	public static void ImplicitMoveTo_WhenNoneProvided()
	{
		let builder = scope PathBuilder();
		builder.LineTo(10, 10);

		let path = builder.ToPath();
		defer delete path;
		// Should have added implicit MoveTo(0,0)
		Test.Assert(path.CommandCount == 2);
		Test.Assert(path.Commands[0] == .MoveTo);
	}
}
