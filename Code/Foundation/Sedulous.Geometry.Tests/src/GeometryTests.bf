using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Tests;

/// The runtime mesh format: the stream layouts, the index buffer, the geometry operations,
/// and the design point the whole thing turns on, which is that a SkinnedMesh IS a
/// StaticMesh and its static stream is usable anywhere one is expected.
class GeometryTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// These sizes are a contract with the shader, not an implementation detail. Beef is
	/// free to reorder a struct's fields for packing, so without [CRepr] this is exactly
	/// the kind of thing that changes silently under an unrelated edit and shows up as
	/// garbage geometry.
	[Test]
	public static void TheStreamLayoutsAreTheSizesTheGpuExpects()
	{
		Test.Assert(sizeof(StaticMeshVertex) == 52, scope $"static vertex is {sizeof(StaticMeshVertex)}");
		Test.Assert(sizeof(VertexSkinning) == 24, scope $"skinning is {sizeof(VertexSkinning)}");
		Test.Assert(StaticMesh.VertexStride == 52);
		Test.Assert(SkinnedMesh.SkinningStride == 24);
		Test.Assert(alignof(StaticMeshVertex) == 4, "packed, not SIMD aligned");
		Test.Assert(alignof(VertexSkinning) == 4);
	}

	/// The fields are where the layout says they are. Sizes alone would still pass if two
	/// same sized fields swapped places, which is precisely what reordering would do.
	[Test]
	public static void TheVertexFieldsSitAtTheDeclaredOffsets()
	{
		var vertex = StaticMeshVertex();
		let start = (uint8*)&vertex;
		Test.Assert((uint8*)&vertex.Position - start == 0);
		Test.Assert((uint8*)&vertex.Normal - start == 12);
		Test.Assert((uint8*)&vertex.TexCoord - start == 24);
		Test.Assert((uint8*)&vertex.Color - start == 32);
		Test.Assert((uint8*)&vertex.Tangent - start == 36);

		var skinning = VertexSkinning();
		let skinStart = (uint8*)&skinning;
		Test.Assert((uint8*)&skinning.Joints - skinStart == 0);
		Test.Assert((uint8*)&skinning.Weights - skinStart == 8);
	}

	[Test]
	public static void TheIndexBufferStoresAtItsFormatWidth()
	{
		let narrow = scope IndexBuffer(.U16);
		Test.Assert(narrow.IndexSize == 2);
		narrow.Resize(3);
		narrow.AddTriangle(0, 1, 2);
		Test.Assert(narrow.Count == 3);
		Test.Assert(narrow.Get(0) == 0);
		Test.Assert(narrow.Get(2) == 2);
		Test.Assert(narrow.DataSize == 6);
		Test.Assert(narrow.RawData != null);

		let wide = scope IndexBuffer(.U32);
		Test.Assert(wide.IndexSize == 4);
		wide.Resize(2);
		wide.Set(0, 70000); // beyond what 16 bits can hold
		Test.Assert(wide.Get(0) == 70000);
	}

	/// Out of range access is dropped rather than trapping, and an empty buffer hands back
	/// null rather than a pointer into nothing. A malformed mesh should render wrong, not
	/// take the process down.
	[Test]
	public static void TheIndexBufferIsSafeAtItsEdges()
	{
		let indices = scope IndexBuffer(.U32);
		Test.Assert(indices.RawData == null, "empty means no pointer to hand out");
		Test.Assert(indices.Get(0) == 0, "reading nothing reads zero");
		indices.Set(0, 5); // no storage yet, so this goes nowhere
		Test.Assert(indices.Count == 0);

		indices.Resize(2);
		indices.AddTriangle(1, 2, 3); // one more than there is room for
		Test.Assert(indices.Get(0) == 1);
		Test.Assert(indices.Get(1) == 2);
		Test.Assert(indices.Get(2) == 0, "the third had nowhere to go");
		Test.Assert(indices.Count == 2, "and the count did not grow to fit it");

		indices.Clear();
		Test.Assert(indices.Count == 0);
		Test.Assert(indices.RawData == null);
	}

	/// Resize rewinds the append cursor, which is what lets a builder size the buffer once
	/// and then stream into it.
	[Test]
	public static void ResizeRewindsTheAppendCursor()
	{
		let indices = scope IndexBuffer(.U32);
		indices.Resize(3);
		indices.AddTriangle(7, 8, 9);
		Test.Assert(indices.Get(0) == 7);

		indices.Resize(3);
		indices.AddTriangle(1, 2, 3);
		Test.Assert(indices.Get(0) == 1, "the second fill started from the beginning");
		Test.Assert(indices.Get(2) == 3);
	}

	[Test]
	public static void AQuadGetsNormalsTangentsAndBounds()
	{
		let mesh = Primitives.Quad(2.0f, 2.0f);
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 4);
		Test.Assert(mesh.IndexCount == 6);
		Test.Assert(mesh.SubMeshes.Count == 1);

		mesh.GenerateNormals();
		for (let vertex in mesh.Vertices)
		{
			Test.Assert(Near(vertex.Normal.Z, 1.0f), "the quad faces +Z");
			let tangent = Float3(vertex.Tangent.X, vertex.Tangent.Y, vertex.Tangent.Z);
			Test.Assert(Near(LengthSquared(tangent), 1.0f), "the tangent xyz is unit length");
			Test.Assert(Near(Abs(vertex.Tangent.W), 1.0f), "and the handedness is plus or minus one");
		}

		mesh.CalculateBounds();
		Test.Assert(Near(mesh.Bounds.Min.X, -1.0f));
		Test.Assert(Near(mesh.Bounds.Max.Y, 1.0f));
		Test.Assert(mesh.VertexDataSize == 4 * 52);
		Test.Assert(mesh.VertexData != null);
	}

	/// The substitutability the class hierarchy exists for: a skinned mesh handed to
	/// something expecting a static one works, and that something can still discover and
	/// reach the skinning stream without knowing the concrete type.
	[Test]
	public static void ASkinnedMeshIsUsableWhereAStaticOneIsExpected()
	{
		let skinned = scope SkinnedMesh();
		skinned.SkeletonIndex = 3;
		skinned.Vertices.Add(.(Float3(0, 0, 0), Float3(0, 1, 0), Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		skinned.Vertices.Add(.(Float3(1, 0, 0), Float3(0, 1, 0), Float2(1, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		skinned.Vertices.Add(.(Float3(0, 1, 0), Float3(0, 1, 0), Float2(0, 1), 0xFFFFFFFF, Float3(1, 0, 0)));

		var influence = VertexSkinning();
		influence.Joints[0] = 2;
		influence.Weights = .(1, 0, 0, 0);
		for (int i < 3)
			skinned.Skinning.Add(influence);

		// Held as the base type, which is how a renderer holds it.
		StaticMesh asStatic = skinned;
		asStatic.CalculateBounds();
		Test.Assert(asStatic.VertexCount == 3);
		Test.Assert(Near(asStatic.Bounds.Max.X, 1.0f));

		Test.Assert(asStatic.IsSkinned, "it can say what it really is");
		Test.Assert(asStatic.SkinningStream.Length == 3);
		Test.Assert(asStatic.SkinningStream[0].Joints[0] == 2);

		let down = asStatic as SkinnedMesh;
		Test.Assert(down != null);
		Test.Assert(down.SkeletonIndex == 3);
		Test.Assert(down.SkinningDataSize == 3 * 24);

		let plain = scope StaticMesh();
		Test.Assert(!plain.IsSkinned);
		Test.Assert(plain.SkinningStream.Length == 0);
		Test.Assert((plain as SkinnedMesh) == null);
	}

	/// Every mesh gets its own id. A renderer caches GPU geometry against this, and never
	/// against the pointer: a reloaded mesh can land on a just freed address and silently
	/// inherit the dead one's buffers.
	[Test]
	public static void EveryMeshGetsItsOwnId()
	{
		let first = scope StaticMesh();
		let second = scope StaticMesh();
		let skinned = scope SkinnedMesh();

		Test.Assert(first.Uid != second.Uid);
		Test.Assert(second.Uid != skinned.Uid);
		Test.Assert(first.Uid != skinned.Uid);
	}

	[Test]
	public static void TheCubeSphereAndPlaneAreWellFormed()
	{
		let cube = Primitives.Cube(2.0f);
		defer delete cube;
		Test.Assert(cube.VertexCount == 24, "four vertices per face, so the normals stay hard");
		Test.Assert(cube.IndexCount == 36);
		Test.Assert(Near(cube.Bounds.Min.X, -1.0f));
		Test.Assert(Near(cube.Bounds.Max.Z, 1.0f));

		let sphere = Primitives.Sphere(1.0f, 16, 8);
		defer delete sphere;
		Test.Assert(sphere.IndexCount == 16 * 8 * 6);
		for (let vertex in sphere.Vertices)
			Test.Assert(Near(Length(vertex.Position), 1.0f, 0.01f), "every point sits on the radius");

		let plane = Primitives.Plane(4.0f, 4.0f, 2, 2);
		defer delete plane;
		Test.Assert(plane.VertexCount == 9, "three by three grid of corners");
		Test.Assert(plane.IndexCount == 2 * 2 * 6);
	}

	[Test]
	public static void TheCylinderConeAndTorusAreWellFormed()
	{
		let cylinder = Primitives.Cylinder(0.5f, 2.0f, 16);
		defer delete cylinder;
		Test.Assert(cylinder.VertexCount == 1 + 16 + 1 + 16 + (16 + 1) * 2);
		Test.Assert(cylinder.IndexCount == 16 * 3 * 2 + 16 * 6);
		Test.Assert(Near(cylinder.Bounds.Min.Y, -1.0f));
		Test.Assert(Near(cylinder.Bounds.Max.Y, 1.0f));
		Test.Assert(Near(cylinder.Bounds.Max.X, 0.5f));
		for (let vertex in cylinder.Vertices)
		{
			let radial = Length(Float3(vertex.Position.X, 0.0f, vertex.Position.Z));
			Test.Assert(radial < 0.5f + 0.001f, "nothing outside the wall radius");
			Test.Assert(Near(Abs(vertex.Position.Y), 1.0f), "every vertex is on a cap plane");
		}

		let cone = Primitives.Cone(0.5f, 1.0f, 16);
		defer delete cone;
		Test.Assert(cone.VertexCount == 1 + 16 + 1 + 16);
		Test.Assert(cone.IndexCount == 16 * 6);
		Test.Assert(Near(cone.Bounds.Max.Y, 0.5f));
		Test.Assert(Near(cone.Bounds.Min.Y, -0.5f));

		let torus = Primitives.Torus(1.0f, 0.25f, 16, 8);
		defer delete torus;
		Test.Assert(torus.VertexCount == (16 + 1) * (8 + 1));
		Test.Assert(torus.IndexCount == 16 * 8 * 6);
		for (let vertex in torus.Vertices)
		{
			let onRing = Normalized(Float3(vertex.Position.X, 0.0f, vertex.Position.Z));
			Test.Assert(Near(Length(vertex.Position - onRing * 1.0f), 0.25f, 0.01f),
				"every point is a tube radius from its ring centre");
		}
	}

	/// A degenerate parameter is clamped to something buildable rather than producing an
	/// empty or malformed mesh: a primitive is often a placeholder, and a placeholder that
	/// crashes is worse than a coarse one.
	[Test]
	public static void DegenerateSegmentCountsAreClampedNotHonoured()
	{
		let sphere = Primitives.Sphere(1.0f, 0, 0);
		defer delete sphere;
		Test.Assert(sphere.IndexCount == 3 * 2 * 6, "clamped to three segments and two rings");

		let cylinder = Primitives.Cylinder(0.5f, 1.0f, 1);
		defer delete cylinder;
		Test.Assert(cylinder.VertexCount > 0);
		Test.Assert(cylinder.IndexCount == 3 * 3 * 2 + 3 * 6);

		let plane = Primitives.Plane(1.0f, 1.0f, 0, 0);
		defer delete plane;
		Test.Assert(plane.VertexCount == 4, "clamped to a single quad");
		Test.Assert(plane.IndexCount == 6);
	}

	[Test]
	public static void ClearForReloadEmptiesBothStreamsInPlace()
	{
		let mesh = scope SkinnedMesh();
		let uid = mesh.Uid;
		mesh.Vertices.Add(.());
		mesh.Skinning.Add(.());
		mesh.SkeletonIndex = 5;
		mesh.Name.Set("before");

		mesh.ClearForReload();

		Test.Assert(mesh.VertexCount == 0);
		Test.Assert(mesh.SkinningStream.Length == 0);
		Test.Assert(mesh.SkeletonIndex == -1);
		Test.Assert(mesh.Name.IsEmpty);
		Test.Assert(mesh.LodCount == 1);
		// In place is the whole point: the object outside references point at is the same
		// object, so a GPU cache keyed on the id still finds it.
		Test.Assert(mesh.Uid == uid);
	}

	/// Mirrored UVs flip the handedness. Without it, a normal map lights the mirrored half
	/// of a model inside out, which is a subtle enough artefact to ship by accident.
	[Test]
	public static void MirroredUvsProduceNegativeHandedness()
	{
		let mesh = scope StaticMesh();
		mesh.Indices.Resize(6);

		AddTriangle(mesh, 0.0f, false);
		AddTriangle(mesh, 2.0f, true);
		mesh.SubMeshes.Add(.(0, 6, 0, .Triangles));

		mesh.GenerateTangents();

		for (int i < 3)
			Test.Assert(mesh.Vertices[i].Tangent.W == 1.0f, scope $"vertex {i} should be right handed");
		for (int i = 3; i < 6; i++)
			Test.Assert(mesh.Vertices[i].Tangent.W == -1.0f, scope $"vertex {i} should be left handed");

		// And the mirrored tangent genuinely points the other way.
		Test.Assert(Near(mesh.Vertices[0].Tangent.X, 1.0f));
		Test.Assert(Near(mesh.Vertices[3].Tangent.X, -1.0f));
	}

	private static void AddTriangle(StaticMesh mesh, float xBase, bool mirrored)
	{
		let start = mesh.VertexCount;
		let u0 = mirrored ? 1.0f : 0.0f;
		let u1 = mirrored ? 0.0f : 1.0f;
		mesh.Vertices.Add(.(Float3(xBase, 0, 0), Float3(0, 0, 1), Float2(u0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(xBase + 1.0f, 0, 0), Float3(0, 0, 1), Float2(u1, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(xBase, 1, 0), Float3(0, 0, 1), Float2(u0, 1), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Indices.AddTriangle(start, start + 1, start + 2);
	}

	/// Normals are smoothed across shared vertices, so a shared vertex ends up with the
	/// average of the faces meeting there rather than the last one written.
	[Test]
	public static void NormalsAreSmoothedAcrossSharedVertices()
	{
		let mesh = scope StaticMesh();
		// Two triangles meeting along an edge, folded 90 degrees about it.
		mesh.Vertices.Add(.(Float3(0, 0, 0), Float3.Zero, Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(1, 0, 0), Float3.Zero, Float2(1, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(0, 1, 0), Float3.Zero, Float2(0, 1), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(0, 0, 1), Float3.Zero, Float2(1, 1), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Indices.Resize(6);
		mesh.Indices.AddTriangle(0, 1, 2);
		mesh.Indices.AddTriangle(0, 3, 1);

		mesh.GenerateNormals();

		for (let vertex in mesh.Vertices)
			Test.Assert(Near(LengthSquared(vertex.Normal), 1.0f), "every normal comes out unit length");

		// Vertices 0 and 1 are on the shared edge, so they average both faces and end up
		// pointing between them; 2 and 3 belong to one face each.
		let shared = mesh.Vertices[0].Normal;
		let single = mesh.Vertices[2].Normal;
		Test.Assert(!NearlyEqual(shared, single), "a shared vertex is not just the last face written");
		Test.Assert(shared.Y > 0.0f && shared.Z > 0.0f, "it leans towards both faces");
	}

	/// A mesh with no indices is treated as sequential triples, which is what an unindexed
	/// import produces.
	[Test]
	public static void AnUnindexedMeshIsTreatedAsSequentialTriangles()
	{
		let mesh = scope StaticMesh();
		mesh.Vertices.Add(.(Float3(0, 0, 0), Float3(0, 0, 1), Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(1, 0, 0), Float3(0, 0, 1), Float2(1, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(0, 1, 0), Float3(0, 0, 1), Float2(0, 1), 0xFFFFFFFF, Float3(1, 0, 0)));
		Test.Assert(mesh.IndexCount == 0);

		mesh.GenerateTangents();
		for (let vertex in mesh.Vertices)
		{
			let tangent = Float3(vertex.Tangent.X, vertex.Tangent.Y, vertex.Tangent.Z);
			Test.Assert(Near(LengthSquared(tangent), 1.0f), "the triangle was found without indices");
		}
	}

	/// The tangent is orthogonalised against the normal. A raw UV derived tangent is not
	/// perpendicular to it in general, and a TBN built from a skewed basis lights a normal
	/// map subtly wrong everywhere rather than obviously wrong somewhere.
	[Test]
	public static void TangentsAreOrthogonalToTheirNormal()
	{
		let mesh = scope StaticMesh();
		// A triangle in the XZ plane, but with normals leaned into X so the UV derived
		// tangent, which runs along X, is nowhere near perpendicular to them.
		let leaned = Normalized(Float3(1, 1, 0));
		mesh.Vertices.Add(.(Float3(0, 0, 0), leaned, Float2(0, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(1, 0, 0), leaned, Float2(1, 0), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(0, 0, 1), leaned, Float2(0, 1), 0xFFFFFFFF, Float3(1, 0, 0)));
		mesh.Indices.Resize(3);
		mesh.Indices.AddTriangle(0, 1, 2);

		mesh.GenerateTangents();

		for (let vertex in mesh.Vertices)
		{
			let tangent = Float3(vertex.Tangent.X, vertex.Tangent.Y, vertex.Tangent.Z);
			Test.Assert(Near(LengthSquared(tangent), 1.0f), "still unit length");
			Test.Assert(Near(Dot(tangent, vertex.Normal), 0.0f),
				scope $"tangent is not perpendicular to the normal: {Dot(tangent, vertex.Normal)}");
		}
	}

	/// Every sphere triangle winds counter clockwise seen from OUTSIDE, so its geometric
	/// face normal points away from the centre.
	///
	/// Worth testing directly because getting it backwards is invisible in every other
	/// measurement: the vertices are still on the radius, the counts are still right, and
	/// the only symptom is that back face culling hides the entire shell.
	[Test]
	public static void SphereTrianglesFaceOutward()
	{
		let sphere = Primitives.Sphere(1.0f, 12, 6);
		defer delete sphere;

		let triangles = sphere.IndexCount / 3;
		Test.Assert(triangles > 0);

		for (uint32 t < triangles)
		{
			let p0 = sphere.Vertices[(int)sphere.Indices.Get(t * 3 + 0)].Position;
			let p1 = sphere.Vertices[(int)sphere.Indices.Get(t * 3 + 1)].Position;
			let p2 = sphere.Vertices[(int)sphere.Indices.Get(t * 3 + 2)].Position;

			let faceNormal = Cross(p1 - p0, p2 - p0);
			let centroid = (p0 + p1 + p2) * (1.0f / 3.0f);

			// A degenerate triangle at the poles has no meaningful normal; the ones with
			// area have to point outward.
			if (LengthSquared(faceNormal) <= 0.000001f)
				continue;

			Test.Assert(Dot(faceNormal, centroid) > 0.0f,
				scope $"triangle {t} winds inward, so culling would hide it");
		}
	}

	/// Across EVERY primitive: a triangle's winding agrees with the shading normals of its
	/// own vertices.
	///
	/// This is the invariant the per shape winding rules add up to, and it holds without
	/// knowing anything about the shape. The sphere test above derives outwardness from
	/// the geometry instead, so the two do not share an assumption: if the normals and the
	/// winding were consistently wrong together, that one still catches it.
	[Test]
	public static void EveryPrimitiveWindsToAgreeWithItsNormals()
	{
		let meshes = scope List<StaticMesh>();
		defer { for (let mesh in meshes) delete mesh; }

		meshes.Add(Primitives.Quad(2.0f, 2.0f));
		meshes.Add(Primitives.Cube(2.0f));
		meshes.Add(Primitives.Plane(4.0f, 4.0f, 3, 3));
		meshes.Add(Primitives.Sphere(1.0f, 12, 6));
		meshes.Add(Primitives.Cylinder(0.5f, 2.0f, 12));
		meshes.Add(Primitives.Cone(0.5f, 1.0f, 12));
		meshes.Add(Primitives.Torus(1.0f, 0.25f, 12, 8));

		for (let mesh in meshes)
		{
			let triangles = mesh.IndexCount / 3;
			Test.Assert(triangles > 0);

			for (uint32 t < triangles)
			{
				let i0 = mesh.Indices.Get(t * 3 + 0);
				let i1 = mesh.Indices.Get(t * 3 + 1);
				let i2 = mesh.Indices.Get(t * 3 + 2);
				let p0 = mesh.Vertices[(int)i0].Position;
				let p1 = mesh.Vertices[(int)i1].Position;
				let p2 = mesh.Vertices[(int)i2].Position;

				let faceNormal = Cross(p1 - p0, p2 - p0);
				// A pole or seam triangle can be degenerate, and a degenerate triangle has
				// no winding to be wrong about.
				if (LengthSquared(faceNormal) <= 0.000001f)
					continue;

				let shading = mesh.Vertices[(int)i0].Normal + mesh.Vertices[(int)i1].Normal + mesh.Vertices[(int)i2].Normal;
				Test.Assert(Dot(faceNormal, shading) > 0.0f,
					scope $"triangle {t} is wound against its own normals");
			}
		}
	}

	[Test]
	public static void PackedColoursPutRedInTheLowByte()
	{
		Test.Assert(StaticMesh.PackColor(Float4(1, 0, 0, 1)) == 0xFF0000FF);
		Test.Assert(StaticMesh.PackColor(Float4(0, 1, 0, 1)) == 0xFF00FF00);
		Test.Assert(StaticMesh.PackColor(Float4(0, 0, 1, 1)) == 0xFFFF0000);
		Test.Assert(StaticMesh.PackColor(Float4(1, 1, 1, 1)) == 0xFFFFFFFF);
		// Out of range channels clamp rather than wrapping around to something unrelated.
		Test.Assert(StaticMesh.PackColor(Float4(2, -1, 0, 1)) == 0xFF0000FF);
	}
}
