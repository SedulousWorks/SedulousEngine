using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Physics.Resource;

namespace Samples.PhysicsPlayground;

/// The two shapes this sample cooks at startup.
///
/// Cooked rather than primitive because that is the whole point of them: a triangle mesh
/// carries per triangle material slots a ray reports back, and a hull is the only cooked shape
/// allowed to move.
static class CookedShapes
{
	/// A two panel ramp, a sloped one and a flat top, in MATERIAL SLOTS one and two so the
	/// crosshair ray can say which it hit. THE CALLER OWNS the result; null if cooking fails.
	public static CollisionShape Ramp()
	{
		let positions = scope Float3[](
			.(6.0f, 0.0f, -3.0f), .(6.0f, 0.0f, 3.0f),   // the low edge
			.(12.0f, 3.0f, 3.0f), .(12.0f, 3.0f, -3.0f), // the high edge
			.(18.0f, 3.0f, 3.0f), .(18.0f, 3.0f, -3.0f)); // the flat top end
		let indices = scope uint32[](0, 1, 2, 0, 2, 3,   // the sloped panel
			3, 2, 4, 3, 4, 5);                            // the flat panel
		let slots = scope uint32[](1, 1, 2, 2);

		let blob = scope List<uint8>();
		if (!ShapeCooking.CookTriangleMesh(positions, indices, slots, blob))
			return null;
		return Wrap(blob, false);
	}

	/// A lumpy hull dropped onto the ramp.
	public static CollisionShape Boulder()
	{
		let points = scope List<Float3>();
		let axes = scope Float3[](.(0.9f, 0, 0), .(0, 0.7f, 0), .(0, 0, 0.8f));
		for (let axis in axes)
		{
			points.Add(axis);
			points.Add(.(-axis.X, -axis.Y, -axis.Z));
		}
		points.Add(.(0.5f, 0.5f, 0.5f));
		points.Add(.(-0.5f, 0.5f, -0.5f));

		let blob = scope List<uint8>();
		if (!ShapeCooking.CookConvexHull(points, blob))
			return null;
		return Wrap(blob, true);
	}

	/// The blob plus its OUTLINE, because a cooked shape has no primitive the debug drawer
	/// could fall back to: without the triangles it is invisible.
	private static CollisionShape Wrap(List<uint8> blob, bool convex)
	{
		let shape = new CollisionShape();
		shape.Convex = convex;
		shape.Blob.AddRange(blob);
		ShapeCooking.ExtractShapeTriangles(blob, shape.Outline);
		return shape;
	}
}
