using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A flattened sub-path consisting of line segments
public class FlattenedSubPath
{
	/// The points forming this polyline
	public List<Vector2> Points = new .() ~ delete _;

	/// Whether this sub-path is closed
	public bool IsClosed;

	public this()
	{
	}

	public this(bool isClosed)
	{
		IsClosed = isClosed;
	}
}
