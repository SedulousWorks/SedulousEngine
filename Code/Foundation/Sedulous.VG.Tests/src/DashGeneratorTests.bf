using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Cutting a polyline into dashes.
class DashGeneratorTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static float TotalLength(List<List<Float2>> dashes)
	{
		var total = 0.0f;
		for (let dash in dashes)
		{
			for (int i = 1; i < dash.Count; i++)
				total += Distance(dash[i], dash[i - 1]);
		}
		return total;
	}

	[Test]
	public static void AnEvenPatternCutsALineIntoAlternatingDashes()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));
		let pattern = scope float[](10, 10);

		let dashes = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(dashes); }
		DashGenerator.GenerateDashes(points, false, pattern, 0.0f, dashes);

		Test.Assert(dashes.Count == 5, "a hundred units of ten on, ten off");
		Test.Assert(Near(TotalLength(dashes), 50.0f), "half the line is drawn");

		Test.Assert(dashes[0].Count == 2);
		Test.Assert(Near(dashes[0][0].X, 0.0f));
		Test.Assert(Near(dashes[0][1].X, 10.0f));
		Test.Assert(Near(dashes[1][0].X, 20.0f), "the gap was skipped");
	}

	/// The offset is a PHASE into the pattern, which is what an animated marching ants
	/// effect steps.
	[Test]
	public static void TheOffsetShiftsThePattern()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));
		let pattern = scope float[](10, 10);

		let shifted = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(shifted); }
		DashGenerator.GenerateDashes(points, false, pattern, 5.0f, shifted);

		Test.Assert(Near(shifted[0][0].X, 0.0f));
		Test.Assert(Near(shifted[0][1].X, 5.0f), "the first dash is half consumed");
	}

	/// It wraps, so a caller can keep increasing the offset forever.
	[Test]
	public static void TheOffsetWrapsInBothDirections()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));
		let pattern = scope float[](10, 10);

		let forward = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(forward); }
		DashGenerator.GenerateDashes(points, false, pattern, 25.0f, forward);

		let backward = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(backward); }
		DashGenerator.GenerateDashes(points, false, pattern, -15.0f, backward);

		Test.Assert(forward.Count == backward.Count);
		Test.Assert(Near(TotalLength(forward), TotalLength(backward)));
	}

	/// A dash that spans a corner keeps going: the pattern measures along the polyline, not
	/// per edge.
	[Test]
	public static void ADashContinuesAroundACorner()
	{
		let points = scope Float2[](.(0, 0), .(10, 0), .(10, 10));
		let pattern = scope float[](15, 5);

		let dashes = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(dashes); }
		DashGenerator.GenerateDashes(points, false, pattern, 0.0f, dashes);

		Test.Assert(dashes[0].Count == 3, "the corner is a vertex of the dash");
		Test.Assert(Near(dashes[0][1].X, 10.0f) && Near(dashes[0][1].Y, 0.0f));
		Test.Assert(Near(dashes[0][2].Y, 5.0f), "and it carries on up the second edge");
	}

	/// A closed polyline walks one more edge than it has points, back to the first.
	[Test]
	public static void AClosedPolylineWalksItsFinalEdge()
	{
		let square = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let pattern = scope float[](40, 40);

		let open = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(open); }
		DashGenerator.GenerateDashes(square, false, pattern, 0.0f, open);

		let closed = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(closed); }
		DashGenerator.GenerateDashes(square, true, pattern, 0.0f, closed);

		Test.Assert(Near(TotalLength(open), 30.0f), "three edges");
		Test.Assert(Near(TotalLength(closed), 40.0f), "four, including the closing one");
	}

	/// An ODD length pattern does NOT alternate here: the dash test is the element's index
	/// modulo two, and a one element pattern is index zero forever, so everything is a
	/// dash. A pattern of ten draws the whole line, in ten unit pieces.
	///
	/// This DIVERGES FROM SVG, which repeats an odd list to make it even, so a dasharray of
	/// "10" is ten on and ten off. Pinned as the behaviour actually is, because that is what
	/// the renderer draws today and an SVG import would need the doubling applied before it
	/// gets here.
	[Test]
	public static void AnOddPatternNeverAlternates()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));
		let pattern = scope float[](10);

		let dashes = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(dashes); }
		DashGenerator.GenerateDashes(points, false, pattern, 0.0f, dashes);

		Test.Assert(Near(TotalLength(dashes), 100.0f), "solid, not dashed");
		Test.Assert(dashes.Count == 10, "in one piece per pattern element");

		// Doubling it by hand gives what SVG would have drawn.
		let doubled = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(doubled); }
		DashGenerator.GenerateDashes(points, false, scope float[](10, 10), 0.0f, doubled);
		Test.Assert(Near(TotalLength(doubled), 50.0f));
	}

	/// Degenerate inputs produce nothing rather than looping forever or faulting.
	[Test]
	public static void DegenerateInputsProduceNothing()
	{
		let dashes = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(dashes); }

		let single = scope Float2[](.(0, 0));
		DashGenerator.GenerateDashes(single, false, scope float[](10, 10), 0.0f, dashes);
		Test.Assert(dashes.IsEmpty, "one point is not a line");

		let points = scope Float2[](.(0, 0), .(100, 0));
		DashGenerator.GenerateDashes(points, false, .(), 0.0f, dashes);
		Test.Assert(dashes.IsEmpty, "no pattern");

		// An all zero pattern would consume nothing per step and never advance.
		DashGenerator.GenerateDashes(points, false, scope float[](0, 0), 0.0f, dashes);
		Test.Assert(dashes.IsEmpty);
	}

	/// A zero length edge is skipped rather than dividing by its length.
	[Test]
	public static void AZeroLengthEdgeIsSkipped()
	{
		let points = scope Float2[](.(0, 0), .(0, 0), .(100, 0));
		let pattern = scope float[](10, 10);

		let dashes = scope List<List<Float2>>();
		defer { ClearAndDeleteItems!(dashes); }
		DashGenerator.GenerateDashes(points, false, pattern, 0.0f, dashes);

		Test.Assert(Near(TotalLength(dashes), 50.0f));
	}
}
