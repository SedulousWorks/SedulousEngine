namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class DashGeneratorTests
{
	[Test]
	public static void SimplePattern_CorrectSegmentCount()
	{
		// Line of length 20 with pattern [5, 5] should produce 2 dash segments
		Vector2[2] points = .(.(0, 0), .(20, 0));
		float[2] pattern = .(5, 5);
		let output = scope List<List<Vector2>>();
		defer { for (let seg in output) delete seg; }

		DashGenerator.GenerateDashes(Span<Vector2>(&points, 2), false, Span<float>(&pattern, 2), 0, output);

		Test.Assert(output.Count == 2);
	}

	[Test]
	public static void OffsetShiftsPattern()
	{
		Vector2[2] points = .(.(0, 0), .(20, 0));
		float[2] pattern = .(5, 5);

		let output1 = scope List<List<Vector2>>();
		defer { for (let seg in output1) delete seg; }
		DashGenerator.GenerateDashes(Span<Vector2>(&points, 2), false, Span<float>(&pattern, 2), 0, output1);

		let output2 = scope List<List<Vector2>>();
		defer { for (let seg in output2) delete seg; }
		DashGenerator.GenerateDashes(Span<Vector2>(&points, 2), false, Span<float>(&pattern, 2), 5.0f, output2);

		// With offset=5, we start in the gap, so first segment should be different
		// The counts may differ due to offset
		Test.Assert(output2.Count > 0);
	}

	[Test]
	public static void ClosedPath_Wraps()
	{
		// Triangle perimeter
		Vector2[3] points = .(.(0, 0), .(10, 0), .(5, 10));
		float[2] pattern = .(3, 3);
		let output = scope List<List<Vector2>>();
		defer { for (let seg in output) delete seg; }

		DashGenerator.GenerateDashes(Span<Vector2>(&points, 3), true, Span<float>(&pattern, 2), 0, output);

		// Should produce multiple dash segments
		Test.Assert(output.Count >= 2);
	}
}
