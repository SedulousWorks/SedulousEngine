using System;
using System.Collections;
using joltc_Beef;

namespace Sedulous.Physics.Tests;

/// The shape cooking seam joltc itself does not expose: a shape's binary state out to a
/// blob and back, and the triangles of one for a debug outline.
///
/// These run against the LIBRARY rather than against anything of ours, so a joltc or Jolt
/// upgrade that moves the seam fails here rather than somewhere downstream.
class JoltCookingTests
{
	/// Jolt's factory and type registry must exist before a shape is built or restored, and
	/// bringing them up twice is not allowed, so every case brackets its own.
	private static mixin Jolt()
	{
		Test.Assert(JPH_Init());
		defer:mixin JPH_Shutdown();
	}

	/// The corners of a unit cube, which is the smallest hull worth building.
	private static void CubePoints(List<JPH_Vec3> outPoints)
	{
		for (int i < 8)
			outPoints.Add(.()
				{
					x = ((i & 1) != 0) ? 0.5f : -0.5f,
					y = ((i & 2) != 0) ? 0.5f : -0.5f,
					z = ((i & 4) != 0) ? 0.5f : -0.5f
				});
	}

	[Test]
	public static void AConvexHullSavesAndRestoresAsItself()
	{
		Jolt!();

		let points = scope List<JPH_Vec3>();
		CubePoints(points);

		let settings = JPH_ConvexHullShapeSettings_Create(points.Ptr, (uint32)points.Count,
			JPH_DEFAULT_CONVEX_RADIUS);
		Test.Assert(settings != null);
		jcb_convex_hull_settings_set_hull_tolerance(settings, 1.0e-3f);

		let shape = (JPH_Shape*)JPH_ConvexHullShapeSettings_CreateShape(settings);
		JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);
		Test.Assert(shape != null);
		defer JPH_Shape_Destroy(shape);

		let blob = jcb_shape_save(shape);
		Test.Assert(blob != null);
		defer jcb_blob_destroy(blob);
		Test.Assert(jcb_blob_size(blob) > 0);

		// The blob is SELF DESCRIBING: what comes back knows it is a hull without being told.
		let restored = jcb_shape_restore(jcb_blob_data(blob), jcb_blob_size(blob));
		Test.Assert(restored != null);
		defer JPH_Shape_Destroy(restored);
		Test.Assert(JPH_Shape_GetSubType(restored) == .JPH_ShapeSubType_ConvexHull);

		let volume = JPH_Shape_GetVolume(restored);
		Test.Assert((volume > 0.9f) && (volume < 1.2f), "a unit cube, give or take its convex radius");
	}

	/// A triangle mesh carries a material slot per triangle in Jolt's per triangle USER
	/// DATA, which is what a ray hit reads back as its surface. It has to survive the round
	/// trip, or a cooked level loses its surface types.
	[Test]
	public static void ATriangleMeshKeepsItsPerTriangleUserData()
	{
		Jolt!();

		let vertices = scope List<JPH_Vec3>();
		vertices.Add(.() { x = -1, y = 0, z = -1 });
		vertices.Add(.() { x = 1, y = 0, z = -1 });
		vertices.Add(.() { x = 1, y = 0, z = 1 });
		vertices.Add(.() { x = -1, y = 0, z = 1 });

		let triangles = scope List<JPH_IndexedTriangle>();
		triangles.Add(.() { i1 = 0, i2 = 1, i3 = 2, materialIndex = 0, userData = 7 });
		triangles.Add(.() { i1 = 0, i2 = 2, i3 = 3, materialIndex = 0, userData = 9 });

		let settings = JPH_MeshShapeSettings_Create2(vertices.Ptr, (uint32)vertices.Count,
			triangles.Ptr, (uint32)triangles.Count);
		Test.Assert(settings != null);
		JPH_MeshShapeSettings_SetPerTriangleUserData(settings, true);

		let shape = (JPH_Shape*)JPH_MeshShapeSettings_CreateShape(settings);
		JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);
		Test.Assert(shape != null);
		defer JPH_Shape_Destroy(shape);

		let blob = jcb_shape_save(shape);
		Test.Assert(blob != null);
		defer jcb_blob_destroy(blob);

		let restored = jcb_shape_restore(jcb_blob_data(blob), jcb_blob_size(blob));
		Test.Assert(restored != null);
		defer JPH_Shape_Destroy(restored);
		Test.Assert(JPH_Shape_GetSubType(restored) == .JPH_ShapeSubType_Mesh);

		// Cast down at the quad and read the slot the hit face was cooked with.
		var origin = JPH_Vec3() { x = 0.5f, y = 1.0f, z = 0.5f };
		var direction = JPH_Vec3() { x = 0.0f, y = -2.0f, z = 0.0f };
		var hit = JPH_RayCastResult();
		Test.Assert(JPH_Shape_CastRay(restored, &origin, &direction, &hit));

		JPH_SubShapeID remainder = 0;
		let leaf = JPH_Shape_GetLeafShape(restored, hit.subShapeID2, &remainder);
		Test.Assert(leaf != null);
		let slot = JPH_MeshShape_GetTriangleUserData((JPH_MeshShape*)leaf, remainder);
		Test.Assert((slot == 7) || (slot == 9), "the cooked slot, whichever half was hit");
	}

	/// The triangles come back as float triples, three vertices per triangle, which is the
	/// shape a debug outline draws.
	[Test]
	public static void AMeshGivesUpItsTrianglesForAnOutline()
	{
		Jolt!();

		let vertices = scope List<JPH_Vec3>();
		vertices.Add(.() { x = -1, y = 0, z = -1 });
		vertices.Add(.() { x = 1, y = 0, z = -1 });
		vertices.Add(.() { x = 1, y = 0, z = 1 });
		vertices.Add(.() { x = -1, y = 0, z = 1 });

		let triangles = scope List<JPH_IndexedTriangle>();
		triangles.Add(.() { i1 = 0, i2 = 1, i3 = 2 });
		triangles.Add(.() { i1 = 0, i2 = 2, i3 = 3 });

		let settings = JPH_MeshShapeSettings_Create2(vertices.Ptr, (uint32)vertices.Count,
			triangles.Ptr, (uint32)triangles.Count);
		let shape = (JPH_Shape*)JPH_MeshShapeSettings_CreateShape(settings);
		JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);
		Test.Assert(shape != null);
		defer JPH_Shape_Destroy(shape);

		let blob = jcb_shape_triangles(shape);
		Test.Assert(blob != null);
		defer jcb_blob_destroy(blob);

		// Nine floats per triangle, and the quad is two of them.
		let floats = (int)jcb_blob_size(blob) / sizeof(float);
		Test.Assert(floats == (2 * 9));

		// Every vertex sits on the quad's own plane.
		let values = (float*)jcb_blob_data(blob);
		for (int i = 1; i < floats; i += 3)
			Test.Assert(Math.Abs(values[i]) < 0.001f, "the quad is flat in Y");
	}

	/// A blob that is not a shape is REFUSED rather than read: Jolt indexes its construct
	/// table with the leading byte unvalidated, so bytes from anywhere else would be read as
	/// whatever that byte happened to say.
	[Test]
	public static void BytesThatAreNotAShapeAreRefused()
	{
		Jolt!();

		Test.Assert(jcb_shape_restore(null, 0) == null);

		uint8[4] empty = .();
		Test.Assert(jcb_shape_restore(&empty[0], 0) == null);

		// Past the last subtype Jolt knows.
		uint8[8] foreign = .(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
		Test.Assert(jcb_shape_restore(&foreign[0], 8) == null);

		// A valid leading byte with nothing behind it: the read runs off the end and the
		// restore fails rather than trusting a short blob.
		uint8[1] truncated = .((uint8)JPH_ShapeSubType.JPH_ShapeSubType_ConvexHull);
		Test.Assert(jcb_shape_restore(&truncated[0], 1) == null);
	}
}
