using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Cuts a polyline into dashes.
static class DashGenerator
{
	/// Below this a length is nothing: a zero length edge has no direction, and a pattern
	/// element that has run out must not loop forever consuming none of it.
	private const float cEpsilon = 0.0001f;

	/// Splits `points` by an alternating dash and gap `pattern`, appending each dash as its
	/// own polyline.
	///
	/// EVEN indices are dashes and odd ones gaps, and an ODD LENGTH pattern is walked
	/// TWICE: SVG says a pattern of odd length repeats to an even one, so `5 3 2` runs as
	/// `5 3 2 5 3 2` and each element alternates its meaning on the second pass. Walking
	/// the raw pattern instead would make every element a dash or a gap forever, and a
	/// three element pattern would draw as one long dash with no gaps.
	///
	/// THE CALLER OWNS the lists appended to `output`.
	public static void GenerateDashes(Span<Float2> points, bool closed, Span<float> pattern,
		float offset, List<List<Float2>> output)
	{
		if ((points.Length < 2) || pattern.IsEmpty)
			return;

		// The cycle actually walked: the pattern, or the pattern twice when its length is odd.
		let cycle = ((pattern.Length % 2) == 0) ? pattern.Length : (pattern.Length * 2);

		var patternLength = 0.0f;
		for (int i < cycle)
			patternLength += pattern[i % pattern.Length];
		// An all zero pattern would consume nothing per step and never advance.
		if (patternLength <= 0.0f)
			return;

		// The offset is a PHASE: it wraps into one period, so a caller animating a marching
		// ants effect can just keep increasing it.
		var dashOffset = offset;
		while (dashOffset < 0.0f)
			dashOffset += patternLength;
		while (dashOffset >= patternLength)
			dashOffset -= patternLength;

		// Where in the pattern that phase lands, and how much of that element is left.
		int patternIndex = 0;
		var patternRemaining = 0.0f;
		{
			var accumulated = 0.0f;
			for (int i = 0; i < cycle; i++)
			{
				let element = pattern[i % pattern.Length];
				if ((accumulated + element) > dashOffset)
				{
					patternIndex = i;
					patternRemaining = element - (dashOffset - accumulated);
					break;
				}
				accumulated += element;
			}
		}

		var isDash = (patternIndex % 2) == 0;
		List<Float2> current = null;

		if (isDash)
		{
			current = new List<Float2>();
			output.Add(current);
		}

		// A closed polyline walks one more edge than it has points, back to the first.
		let edgeCount = closed ? points.Length : (points.Length - 1);
		for (int i = 0; i < edgeCount; i++)
		{
			let p0 = points[i];
			let p1 = points[(i + 1) % points.Length];

			var direction = p1 - p0;
			let edgeLength = Length(direction);
			if (edgeLength < cEpsilon)
				continue;
			direction = direction / edgeLength;

			var edgeRemaining = edgeLength;
			var position = p0;

			// One edge can span several pattern elements, and one element several edges, so
			// the walk advances by whichever runs out first.
			while (edgeRemaining > cEpsilon)
			{
				let step = Min(edgeRemaining, patternRemaining);
				let next = position + (direction * step);

				if (isDash)
				{
					if (current == null)
					{
						current = new List<Float2>();
						output.Add(current);
					}
					if (current.IsEmpty)
						current.Add(position);
					current.Add(next);
				}

				edgeRemaining -= step;
				patternRemaining -= step;
				position = next;

				if (patternRemaining > cEpsilon)
					continue;

				patternIndex = (patternIndex + 1) % cycle;
				patternRemaining = pattern[patternIndex % pattern.Length];
				isDash = (patternIndex % 2) == 0;
				// Cleared whichever way it turned: the next dash is a SEPARATE polyline,
				// or the gap has nothing to append to.
				current = null;
			}
		}
	}
}
