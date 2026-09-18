using System;

namespace Sedulous.Core;

/// The bounds a numeric member accepts, and the granularity it moves in.
///
/// A reader turns a bounded number into a slider and an unbounded one into a plain field,
/// so applying this is also the statement "this is a magnitude, not an arbitrary number".
///
/// Step zero means unspecified: the reader picks. Raptor carries {min, max, step, unused}
/// as a Float4, and the fourth component is documented unused, so it is not here.
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct RangeAttribute : Attribute
{
	public float Min;
	public float Max;
	public float Step;

	public this(float min, float max, float step = 0.0f)
	{
		Min = min;
		Max = max;
		Step = step;
	}
}
