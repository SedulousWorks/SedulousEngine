using System;
using System.Collections;
using Sedulous.Core;
using joltc_Beef;

namespace Sedulous.Physics;

/// Offline shape cooking, for the builder and the editor. The blobs feed ShapeKind.Cooked.
///
/// The blob format is the BACKEND'S own binary shape state: self describing, so a restore is
/// never told what it is holding, and versioned by the backend, so a cooked product is
/// recooked when the backend is upgraded. The asset pipeline's builder version is what
/// handles that.
static class ShapeCooking
{
	/// A convex hull from a point cloud.
	///
	/// The tolerance trades vertex count for fidelity: a point may sit that far outside the
	/// hull, and larger is a simpler hull. False on degenerate input, which is fewer than
	/// four points or four that share a plane.
	public static bool CookConvexHull(Span<Float3> points, List<uint8> outBlob,
		float hullTolerance = 1.0e-3f)
	{
		if (points.Length < 4)
			return false;

		// The factory has to exist before a shape can be built, and a cooker has no world to
		// have brought it up.
		JoltRuntime.Acquire();
		defer JoltRuntime.Release();

		let hull = scope List<JPH_Vec3>();
		for (let p in points)
			hull.Add(.() { x = p.X, y = p.Y, z = p.Z });

		let settings = JPH_ConvexHullShapeSettings_Create(hull.Ptr, (uint32)hull.Count,
			JPH_DEFAULT_CONVEX_RADIUS);
		if (settings == null)
			return false;
		defer JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);

		jcb_convex_hull_settings_set_hull_tolerance(settings, hullTolerance);
		let shape = (JPH_Shape*)JPH_ConvexHullShapeSettings_CreateShape(settings);
		if (shape == null)
			return false;
		defer JPH_Shape_Destroy(shape);

		return Save(shape, outBlob);
	}

	/// A static triangle mesh.
	///
	/// The material slots carry one index per triangle and are surfaced on a ray hit as its
	/// surface; empty is all nought. The index count must be a multiple of three. False on
	/// empty or malformed input.
	public static bool CookTriangleMesh(Span<Float3> positions, Span<uint32> indices,
		Span<uint32> triangleMaterialSlots, List<uint8> outBlob)
	{
		if (positions.IsEmpty || indices.IsEmpty || ((indices.Length % 3) != 0))
			return false;

		let triangleCount = indices.Length / 3;
		if (!triangleMaterialSlots.IsEmpty && (triangleMaterialSlots.Length != triangleCount))
			return false;

		JoltRuntime.Acquire();
		defer JoltRuntime.Release();

		let vertices = scope List<JPH_Vec3>();
		for (let p in positions)
			vertices.Add(.() { x = p.X, y = p.Y, z = p.Z });

		let triangles = scope List<JPH_IndexedTriangle>();
		for (int t = 0; t < triangleCount; t++)
		{
			// The material slot rides in the per triangle USER DATA rather than in the
			// backend's own material index, which stays nought: we use no backend materials,
			// and the user data is what a ray hit reads back.
			triangles.Add(.()
				{
					i1 = indices[t * 3 + 0],
					i2 = indices[t * 3 + 1],
					i3 = indices[t * 3 + 2],
					materialIndex = 0,
					userData = triangleMaterialSlots.IsEmpty ? 0 : triangleMaterialSlots[t]
				});
		}

		let settings = JPH_MeshShapeSettings_Create2(vertices.Ptr, (uint32)vertices.Count,
			triangles.Ptr, (uint32)triangles.Count);
		if (settings == null)
			return false;
		defer JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);

		JPH_MeshShapeSettings_SetPerTriangleUserData(settings, true);
		let shape = (JPH_Shape*)JPH_MeshShapeSettings_CreateShape(settings);
		if (shape == null)
			return false;
		defer JPH_Shape_Destroy(shape);

		return Save(shape, outBlob);
	}

	/// The triangles of a cooked blob, three positions per triangle, which is the outline
	/// geometry a debug gizmo draws. False if the blob does not restore.
	public static bool ExtractShapeTriangles(Span<uint8> blob, List<Float3> outTriangles)
	{
		JoltRuntime.Acquire();
		defer JoltRuntime.Release();

		let shape = Restore(blob);
		if (shape == null)
			return false;
		defer JPH_Shape_Destroy(shape);

		let triangles = jcb_shape_triangles(shape);
		if (triangles == null)
			return false;
		defer jcb_blob_destroy(triangles);

		let count = (int)jcb_blob_size(triangles) / sizeof(float);
		let values = (float*)jcb_blob_data(triangles);
		for (int i = 0; i < count; i += 3)
			outTriangles.Add(.(values[i], values[i + 1], values[i + 2]));
		return !outTriangles.IsEmpty;
	}

	/// Restores a blob into a live shape. Null when the bytes are not a shape this build can
	/// restore. THE CALLER OWNS what comes back.
	public static JPH_Shape* Restore(Span<uint8> blob)
	{
		if (blob.IsEmpty)
			return null;
		return jcb_shape_restore(blob.Ptr, (uint)blob.Length);
	}

	private static bool Save(JPH_Shape* shape, List<uint8> outBlob)
	{
		let blob = jcb_shape_save(shape);
		if (blob == null)
			return false;
		defer jcb_blob_destroy(blob);

		let size = (int)jcb_blob_size(blob);
		let from = outBlob.Count;
		outBlob.Count = from + size;
		Internal.MemCpy(&outBlob[from], jcb_blob_data(blob), size);
		return true;
	}
}
