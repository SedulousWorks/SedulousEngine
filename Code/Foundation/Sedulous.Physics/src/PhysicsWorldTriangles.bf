using System;
using System.Collections;
using Sedulous.Core;
using joltc_Beef;

namespace Sedulous.Physics;

extension PhysicsWorld
{
	/// The world space triangles of bodies' collision shapes that touch `bounds`, appended to
	/// `outTriangles` (three positions per triangle, counter clockwise seen from outside). Each
	/// shape is built as CreateBody builds it (compounds, scale, cooked meshes, a plane as wide
	/// as its half extent, heightfields without their holes) and placed as the body is, a
	/// compound giving its leaves' triangles, so a consumer such as the navigation bake sees
	/// exactly what the bodies collide with. Triangles are not cut at `bounds`: one that touches
	/// it comes whole (Recast clips to its own bounds as it rasterizes). Needs no world.
	///
	/// Returns the number of bodies whose shape did not build.
	public static int AppendBodyTriangles(Span<BodyDesc> bodies, AABB bounds, List<Float3> outTriangles)
	{
		JoltRuntime.Acquire();
		defer JoltRuntime.Release();

		var boxMin = ToJolt(bounds.Min);
		var boxMax = ToJolt(bounds.Max);
		int failed = 0;
		for (let body in bodies)
		{
			let shape = BuildShape(body);
			if (shape == null)
			{
				failed++;
				continue;
			}
			defer JPH_Shape_Destroy(shape);

			var position = ToJolt(body.Position);
			var rotation = ToJolt(body.Rotation);
			let triangles = jcb_shape_world_triangles(shape, &position, &rotation, &boxMin, &boxMax);
			if (triangles == null)
				continue;
			defer jcb_blob_destroy(triangles);

			let count = (int)jcb_blob_size(triangles) / sizeof(float);
			let values = (float*)jcb_blob_data(triangles);
			for (int i = 0; i + 2 < count; i += 3)
				outTriangles.Add(.(values[i], values[i + 1], values[i + 2]));
		}
		return failed;
	}
}
