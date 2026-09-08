using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// One subpath reduced to a polyline.
class FlattenedSubPath
{
	public List<Float2> Points = new .() ~ delete _;
	public bool IsClosed = false;

	public this() {}

	public this(bool isClosed)
	{
		IsClosed = isClosed;
	}
}
