using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A single segment of a path, yielded during iteration
public struct PathSegment
{
	/// The command type for this segment
	public PathCommand Command;
	/// Points associated with this command (not including the start point)
	public Span<Vector2> Points;
	/// The pen position before this segment (the implicit start point)
	public Vector2 StartPoint;
}
