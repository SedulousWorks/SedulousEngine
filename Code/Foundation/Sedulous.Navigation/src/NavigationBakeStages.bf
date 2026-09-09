using System.Collections;
using Sedulous.Core;

namespace Sedulous.Navigation;

/// OPT IN capture of the bake's intermediate stages, which is what a failed or surprising
/// bake is debugged with.
///
/// The live mesh's own triangles stay the ground truth for what queries run on; these show
/// how the bake ARRIVED there: where geometry rasterised, and where the region outlines went.
class NavigationBakeStages
{
	/// The simplified region contours as line SEGMENT PAIRS, two points per segment.
	public List<Float3> ContourLines = new .() ~ delete _;

	/// The walkable span tops from the rasterised heightfield, one point per cell, strided
	/// and capped: a diagnostic overlay rather than a point cloud export.
	public List<Float3> WalkableSamples = new .() ~ delete _;

	public void Clear()
	{
		ContourLines.Clear();
		WalkableSamples.Clear();
	}
}
