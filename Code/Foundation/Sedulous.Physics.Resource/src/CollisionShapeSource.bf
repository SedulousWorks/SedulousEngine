using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Physics.Resource;

/// The cooked record for a collision shape.
///
/// The blob is the backend's own binary shape state, and the outline is the debug triangles
/// CACHED beside it: a gizmo draws the shape without restoring it, which a debug view would
/// otherwise do every frame for every collider on screen.
[Serializable]
class CollisionShapeSource
{
	/// Informational only, since the blob describes itself. It is what an inspector reads to
	/// say whether the shape may be dynamic without restoring it to find out.
	public bool Convex = false;

	/// The backend's binary shape state.
	public List<uint8> ShapeBlob = new .() ~ delete _;

	/// The debug triangles as flat floats: three per vertex, nine per triangle.
	public List<float> Outline = new .() ~ delete _;
}
