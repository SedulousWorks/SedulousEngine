using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Generates dashed polylines from a solid polyline and a dash pattern
public static class DashGenerator
{
	/// Generate dashed segments from a polyline.
	/// Pattern alternates: [dash, gap, dash, gap, ...]. Must have even number of elements.
	/// Output is a list of polyline segments (each segment is a list of points).
	public static void GenerateDashes(Span<Vector2> points, bool closed, Span<float> pattern, float offset, List<List<Vector2>> output)
	{
		if (points.Length < 2 || pattern.Length == 0)
			return;

		// Calculate total pattern length
		float patternLength = 0;
		for (let p in pattern)
			patternLength += p;
		if (patternLength <= 0)
			return;

		// Normalize offset into pattern range
		var dashOffset = offset;
		while (dashOffset < 0)
			dashOffset += patternLength;
		while (dashOffset >= patternLength)
			dashOffset -= patternLength;

		// Find starting position in pattern
		int patternIdx = 0;
		float patternRemaining = 0;
		{
			float acc = 0;
			for (int i = 0; i < pattern.Length; i++)
			{
				if (acc + pattern[i] > dashOffset)
				{
					patternIdx = i;
					patternRemaining = pattern[i] - (dashOffset - acc);
					break;
				}
				acc += pattern[i];
			}
		}

		bool isDash = (patternIdx % 2) == 0; // Even indices are dashes
		List<Vector2> currentSegment = null;

		if (isDash)
		{
			currentSegment = new List<Vector2>();
			output.Add(currentSegment);
		}

		// Walk along the polyline
		let totalPoints = closed ? points.Length : points.Length - 1;
		for (int i = 0; i < totalPoints; i++)
		{
			let p0 = points[i];
			let p1 = points[(i + 1) % points.Length];

			var edgeDir = p1 - p0;
			let edgeLen = edgeDir.Length();
			if (edgeLen < 0.0001f)
				continue;
			edgeDir = edgeDir / edgeLen;

			float edgeRemaining = edgeLen;
			var currentPos = p0;

			while (edgeRemaining > 0.0001f)
			{
				let step = Math.Min(edgeRemaining, patternRemaining);
				let nextPos = currentPos + edgeDir * step;

				if (isDash)
				{
					if (currentSegment == null)
					{
						currentSegment = new List<Vector2>();
						output.Add(currentSegment);
					}
					if (currentSegment.Count == 0)
						currentSegment.Add(currentPos);
					currentSegment.Add(nextPos);
				}

				edgeRemaining -= step;
				patternRemaining -= step;
				currentPos = nextPos;

				if (patternRemaining <= 0.0001f)
				{
					// Advance to next pattern element
					patternIdx = (patternIdx + 1) % pattern.Length;
					patternRemaining = pattern[patternIdx];
					isDash = (patternIdx % 2) == 0;

					if (isDash)
						currentSegment = null; // Will be created on next dash point
					else
						currentSegment = null;
				}
			}
		}
	}
}
