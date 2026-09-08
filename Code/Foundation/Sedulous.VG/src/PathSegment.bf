using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// One step of a path, as iteration yields it.
struct PathSegment
{
	public PathCommand Command = .MoveTo;
	/// This command's own points, NOT including where the pen already was.
	public Span<Float2> Points = default;
	/// Where the pen was before this segment, which every curve needs as its first point.
	public Float2 StartPoint = .Zero;

	public this() {}
}
