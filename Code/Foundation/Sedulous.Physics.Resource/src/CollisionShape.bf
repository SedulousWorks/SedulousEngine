using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Physics.Resource;

/// The runtime product a collider binds, which hands its blob to the world as a cooked
/// shape.
class CollisionShape
{
	public bool Convex = false;

	public List<uint8> Blob = new .() ~ delete _;

	/// The debug triangles, three vertices per triangle.
	public List<Float3> Outline = new .() ~ delete _;

	/// BORROWED: the shape lives as long as the resource does, and a body reads this only
	/// while it is being created.
	public Span<uint8> Bytes => Blob;
}
