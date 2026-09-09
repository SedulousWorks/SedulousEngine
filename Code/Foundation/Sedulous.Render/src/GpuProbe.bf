using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One reflection probe as the shading reads it.
///
/// Packed so that, per cluster, the forward can pick the probe, box project the reflection ray
/// against it, and index its slice of the cube array.
[CRepr]
struct GpuProbe
{
	/// The capture centre in world space, and the intensity in the fourth.
	public Float4 Center = .(0, 0, 0, 1);
	/// The box's lower corner, and the blend distance in the fourth.
	public Float4 BoxMin = .(0, 0, 0, 1);
	/// The box's upper corner, and the slice into the array in the fourth.
	public Float4 BoxMax = .(0, 0, 0, 0);
	/// The level count, the priority, whether to box project, and one spare.
	public Float4 Params = .(1, 0, 1, 0);

	public this() {}
}
