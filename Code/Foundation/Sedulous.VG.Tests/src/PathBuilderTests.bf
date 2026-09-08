using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Building a path, and the two rules that keep a malformed one from reaching the
/// tessellator.
class PathBuilderTests
{
	private static int CountOf(Path path, PathCommand wanted)
	{
		var count = 0;
		for (let command in path.Commands)
		{
			if (command == wanted)
				count++;
		}
		return count;
	}

	/// A drawing command before the pen has been placed IMPLIES a move to the origin.
	/// Dropping it instead would produce a shape silently missing an edge.
	[Test]
	public static void ADrawBeforeAMoveImpliesOne()
	{
		let builder = scope PathBuilder();
		builder.LineTo(10, 10);

		let path = builder.ToPath();
		defer delete path;

		Test.Assert(path.CommandCount == 2);
		Test.Assert(path.Commands[0] == .MoveTo);
		Test.Assert(path.Points[0] == Float2.Zero);
		Test.Assert(path.Commands[1] == .LineTo);
	}

	/// Every drawing command carries the same rule.
	[Test]
	public static void EveryDrawCommandImpliesAMove()
	{
		for (let build in scope delegate void(PathBuilder)[](
			scope (b) => b.LineTo(1, 1),
			scope (b) => b.QuadTo(1, 1, 2, 2),
			scope (b) => b.CubicTo(1, 1, 2, 2, 3, 3),
			scope (b) => b.ArcTo(5, 5, 0, false, true, 5, 5)))
		{
			let builder = scope PathBuilder();
			build(builder);

			let path = builder.ToPath();
			defer delete path;
			Test.Assert(path.Commands[0] == .MoveTo);
		}
	}

	/// A Close before any move does NOTHING: there is no subpath to close, and emitting
	/// one leaves a command the iterator cannot place.
	[Test]
	public static void ACloseBeforeAnyMoveDoesNothing()
	{
		let builder = scope PathBuilder();
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.CommandCount == 0);
	}

	[Test]
	public static void ThePenFollowsWhatWasDrawn()
	{
		let builder = scope PathBuilder();
		Test.Assert(builder.CurrentPoint == Float2.Zero);

		builder.MoveTo(3, 4);
		Test.Assert(builder.CurrentPoint == Float2(3, 4));

		builder.LineTo(5, 6);
		Test.Assert(builder.CurrentPoint == Float2(5, 6));

		builder.QuadTo(7, 7, 8, 9);
		Test.Assert(builder.CurrentPoint == Float2(8, 9), "the endpoint, not the control");

		builder.CubicTo(1, 1, 2, 2, 10, 11);
		Test.Assert(builder.CurrentPoint == Float2(10, 11));

		builder.Close();
		Test.Assert(builder.CurrentPoint == Float2(3, 4), "back to the subpath start");
	}

	/// An arc is stored as the cubics that approximate it, so nothing downstream needs an
	/// arc case at all.
	[Test]
	public static void AnArcBecomesCubics()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.ArcTo(10, 10, 0, false, true, 10, 10);

		let path = builder.ToPath();
		defer delete path;

		Test.Assert(CountOf(path, .CubicTo) > 0);
		Test.Assert(CountOf(path, .MoveTo) == 1);
		Test.Assert(builder.CurrentPoint == Float2(10, 10), "the pen lands where asked");
	}

	/// An arc that produces nothing still leaves the pen where the caller said, because the
	/// position comes from the argument rather than from the last emitted point.
	[Test]
	public static void ADegenerateArcStillMovesThePen()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(5, 5);
		builder.ArcTo(10, 10, 0, false, true, 5, 5);

		Test.Assert(builder.CurrentPoint == Float2(5, 5));
		let path = builder.ToPath();
		defer delete path;
		Test.Assert(CountOf(path, .CubicTo) == 0, "nothing to draw");
	}

	/// Building a path leaves the builder usable, so one builder can emit a family of
	/// related paths.
	[Test]
	public static void BuildingDoesNotConsumeTheBuilder()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(1, 0);

		let first = builder.ToPath();
		defer delete first;

		builder.LineTo(2, 0);
		let second = builder.ToPath();
		defer delete second;

		Test.Assert(first.CommandCount == 2, "the first path did not grow");
		Test.Assert(second.CommandCount == 3);
	}

	[Test]
	public static void ClearingResetsEverything()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(5, 5);
		builder.LineTo(9, 9);
		builder.Clear();

		Test.Assert(builder.CommandCount == 0);
		Test.Assert(builder.CurrentPoint == Float2.Zero);

		// And the move state is reset too, so the next draw implies its own move.
		builder.LineTo(1, 1);
		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.Commands[0] == .MoveTo);
	}

	[Test]
	public static void ThePointOverloadsMatchTheComponentOnes()
	{
		let byComponent = scope PathBuilder();
		byComponent.MoveTo(1, 2);
		byComponent.LineTo(3, 4);
		byComponent.QuadTo(5, 6, 7, 8);
		byComponent.CubicTo(9, 10, 11, 12, 13, 14);
		let first = byComponent.ToPath();
		defer delete first;

		let byPoint = scope PathBuilder();
		byPoint.MoveTo(Float2(1, 2));
		byPoint.LineTo(Float2(3, 4));
		byPoint.QuadTo(Float2(5, 6), Float2(7, 8));
		byPoint.CubicTo(Float2(9, 10), Float2(11, 12), Float2(13, 14));
		let second = byPoint.ToPath();
		defer delete second;

		Test.Assert(first.PointCount == second.PointCount);
		for (int i = 0; i < first.PointCount; i++)
			Test.Assert(first.Points[i] == second.Points[i]);
	}
}
