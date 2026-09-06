using System;
using Sedulous.Core;

namespace Sedulous.Geometry;

/// Procedural primitive meshes, for debug shapes, placeholders and tests.
///
/// Each returns a fully formed StaticMesh: static stream, 32 bit indices, one submesh,
/// generated tangents and bounds. THE CALLER OWNS what comes back and deletes it.
static class Primitives
{
	private const uint32 cWhite = 0xFFFFFFFF;

	/// A quad in the XY plane facing +Z, two triangles.
	public static StaticMesh Quad(float width = 1.0f, float height = 1.0f)
	{
		let mesh = new StaticMesh();
		let hw = width * 0.5f;
		let hh = height * 0.5f;

		mesh.Vertices.Add(.(Float3(-hw, -hh, 0), Float3(0, 0, 1), Float2(0, 1), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(hw, -hh, 0), Float3(0, 0, 1), Float2(1, 1), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(hw, hh, 0), Float3(0, 0, 1), Float2(1, 0), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(Float3(-hw, hh, 0), Float3(0, 0, 1), Float2(0, 0), cWhite, Float3(1, 0, 0)));

		mesh.Indices.Resize(6);
		for (let i in uint32[6](0, 1, 2, 0, 2, 3))
			mesh.Indices.Add(i);

		Finish(mesh);
		return mesh;
	}

	/// An axis aligned cube of edge `size`, 24 vertices so each face keeps a hard normal.
	public static StaticMesh Cube(float size = 1.0f)
	{
		let mesh = new StaticMesh();
		let h = size * 0.5f;

		mesh.Indices.Resize(36); // 6 faces x 2 triangles x 3 indices
		AddFace(mesh, .(-h, -h, h), .(1, 0, 0), .(0, 1, 0), .(0, 0, 1), size);   // +Z
		AddFace(mesh, .(h, -h, -h), .(-1, 0, 0), .(0, 1, 0), .(0, 0, -1), size); // -Z
		AddFace(mesh, .(h, -h, h), .(0, 0, -1), .(0, 1, 0), .(1, 0, 0), size);   // +X
		AddFace(mesh, .(-h, -h, -h), .(0, 0, 1), .(0, 1, 0), .(-1, 0, 0), size); // -X
		AddFace(mesh, .(-h, h, h), .(1, 0, 0), .(0, 0, -1), .(0, 1, 0), size);   // +Y
		AddFace(mesh, .(-h, -h, -h), .(1, 0, 0), .(0, 0, 1), .(0, -1, 0), size); // -Y

		Finish(mesh);
		return mesh;
	}

	/// A subdivided grid in the XZ plane.
	public static StaticMesh Plane(float width = 1.0f, float depth = 1.0f,
		uint32 xSegments = 1, uint32 zSegments = 1)
	{
		let mesh = new StaticMesh();
		let xs = (xSegments < 1) ? (uint32)1 : xSegments;
		let zs = (zSegments < 1) ? (uint32)1 : zSegments;

		for (uint32 z <= zs)
		{
			for (uint32 x <= xs)
			{
				let u = (float)x / (float)xs;
				let v = (float)z / (float)zs;
				mesh.Vertices.Add(.(Float3((u - 0.5f) * width, 0.0f, (v - 0.5f) * depth),
					Float3(0, 1, 0), Float2(u, v), cWhite, Float3(1, 0, 0)));
			}
		}

		mesh.Indices.Resize(xs * zs * 6);
		let rowStride = xs + 1;
		for (uint32 z < zs)
		{
			for (uint32 x < xs)
			{
				let i0 = z * rowStride + x;
				let i1 = i0 + 1;
				let i2 = i0 + rowStride;
				let i3 = i2 + 1;
				mesh.Indices.AddTriangle(i0, i2, i1);
				mesh.Indices.AddTriangle(i1, i2, i3);
			}
		}

		Finish(mesh);
		return mesh;
	}

	/// A UV sphere with `segments` longitudes and `rings` latitudes.
	public static StaticMesh Sphere(float radius = 0.5f, uint32 segments = 32, uint32 rings = 16)
	{
		let mesh = new StaticMesh();
		let seg = (segments < 3) ? (uint32)3 : segments;
		let rng = (rings < 2) ? (uint32)2 : rings;

		for (uint32 r <= rng)
		{
			let v = (float)r / (float)rng;
			let phi = v * Pi; // pole to pole
			let sinPhi = Sin(phi);
			let cosPhi = Cos(phi);
			for (uint32 s <= seg)
			{
				let u = (float)s / (float)seg;
				let theta = u * TwoPi;
				let n = Float3(Cos(theta) * sinPhi, cosPhi, Sin(theta) * sinPhi);
				mesh.Vertices.Add(.(n * radius, n, Float2(u, v), cWhite, Float3(1, 0, 0)));
			}
		}

		mesh.Indices.Resize(seg * rng * 6);
		let rowStride = seg + 1;
		for (uint32 r < rng)
		{
			for (uint32 s < seg)
			{
				let i0 = r * rowStride + s;
				let i1 = i0 + 1;
				let i2 = i0 + rowStride;
				let i3 = i2 + 1;
				// Counter clockwise seen from OUTSIDE. Getting the last two swapped
				// reverses the front face inward, and back face culling then hides the
				// entire outer shell, which is a confusing thing to debug from a
				// screenshot.
				mesh.Indices.AddTriangle(i0, i1, i2);
				mesh.Indices.AddTriangle(i1, i3, i2);
			}
		}

		Finish(mesh);
		return mesh;
	}

	/// A capped cylinder about the Y axis. The caps carry hard axial normals on their own
	/// vertex rings; the side wall carries radial normals with a duplicated seam column so
	/// the UVs run 0..1 without wrapping.
	public static StaticMesh Cylinder(float radius = 0.5f, float height = 1.0f, uint32 segments = 32)
	{
		let mesh = new StaticMesh();
		let seg = (segments < 3) ? (uint32)3 : segments;
		let hh = height * 0.5f;

		let topCenter = mesh.VertexCount;
		mesh.Vertices.Add(.(Float3(0, hh, 0), Float3(0, 1, 0), Float2(0.5f, 0.5f), cWhite, Float3(1, 0, 0)));
		let topRing = mesh.VertexCount;
		for (uint32 i < seg)
		{
			let a = TwoPi * (float)i / (float)seg;
			let x = Cos(a) * radius;
			let z = Sin(a) * radius;
			mesh.Vertices.Add(.(Float3(x, hh, z), Float3(0, 1, 0),
				Float2(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f), cWhite, Float3(1, 0, 0)));
		}

		let bottomCenter = mesh.VertexCount;
		mesh.Vertices.Add(.(Float3(0, -hh, 0), Float3(0, -1, 0), Float2(0.5f, 0.5f), cWhite, Float3(1, 0, 0)));
		let bottomRing = mesh.VertexCount;
		for (uint32 i < seg)
		{
			let a = TwoPi * (float)i / (float)seg;
			let x = Cos(a) * radius;
			let z = Sin(a) * radius;
			mesh.Vertices.Add(.(Float3(x, -hh, z), Float3(0, -1, 0),
				Float2(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f), cWhite, Float3(1, 0, 0)));
		}

		let sideStart = mesh.VertexCount;
		for (uint32 i <= seg)
		{
			let u = (float)i / (float)seg;
			let a = TwoPi * u;
			let x = Cos(a) * radius;
			let z = Sin(a) * radius;
			let n = Normalized(Float3(x, 0, z));
			mesh.Vertices.Add(.(Float3(x, hh, z), n, Float2(u, 0), cWhite, Float3(1, 0, 0)));
			mesh.Vertices.Add(.(Float3(x, -hh, z), n, Float2(u, 1), cWhite, Float3(1, 0, 0)));
		}

		mesh.Indices.Resize(seg * 3 * 2 + seg * 6);
		for (uint32 i < seg) // top cap, counter clockwise from above
			mesh.Indices.AddTriangle(topCenter, topRing + (i + 1) % seg, topRing + i);
		for (uint32 i < seg) // bottom cap, counter clockwise from below
			mesh.Indices.AddTriangle(bottomCenter, bottomRing + i, bottomRing + (i + 1) % seg);
		for (uint32 i < seg)
		{
			let topLeft = sideStart + i * 2;
			let bottomLeft = topLeft + 1;
			let topRight = topLeft + 2;
			let bottomRight = topRight + 1;
			mesh.Indices.AddTriangle(topLeft, topRight, bottomLeft);
			mesh.Indices.AddTriangle(topRight, bottomRight, bottomLeft);
		}

		Finish(mesh);
		return mesh;
	}

	/// A cone about the Y axis with its apex at +Y. The sides get slanted normals; the base
	/// gets its own flat normal ring.
	public static StaticMesh Cone(float radius = 0.5f, float height = 1.0f, uint32 segments = 32)
	{
		let mesh = new StaticMesh();
		let seg = (segments < 3) ? (uint32)3 : segments;
		let hh = height * 0.5f;

		mesh.Vertices.Add(.(Float3(0, hh, 0), Float3(0, 1, 0), Float2(0.5f, 0), cWhite, Float3(1, 0, 0)));
		for (uint32 i < seg)
		{
			let a = TwoPi * (float)i / (float)seg;
			let x = Cos(a) * radius;
			let z = Sin(a) * radius;
			let n = Normalized(Float3(x, radius, z));
			mesh.Vertices.Add(.(Float3(x, -hh, z), n, Float2((float)i / (float)seg, 1), cWhite, Float3(1, 0, 0)));
		}

		let baseCenter = mesh.VertexCount;
		mesh.Vertices.Add(.(Float3(0, -hh, 0), Float3(0, -1, 0), Float2(0.5f, 0.5f), cWhite, Float3(1, 0, 0)));
		for (uint32 i < seg)
		{
			let a = TwoPi * (float)i / (float)seg;
			let x = Cos(a) * radius;
			let z = Sin(a) * radius;
			mesh.Vertices.Add(.(Float3(x, -hh, z), Float3(0, -1, 0),
				Float2(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f), cWhite, Float3(1, 0, 0)));
		}

		mesh.Indices.Resize(seg * 6);
		for (uint32 i < seg) // sides
			mesh.Indices.AddTriangle(0, 1 + (i + 1) % seg, 1 + i);
		for (uint32 i < seg) // base
			mesh.Indices.AddTriangle(baseCenter, baseCenter + 1 + i, baseCenter + 1 + (i + 1) % seg);

		Finish(mesh);
		return mesh;
	}

	/// A torus about the Y axis, with the same outward winding as Sphere.
	public static StaticMesh Torus(float radius = 1.0f, float tubeRadius = 0.3f,
		uint32 segments = 32, uint32 tubeSegments = 16)
	{
		let mesh = new StaticMesh();
		let seg = (segments < 3) ? (uint32)3 : segments;
		let tseg = (tubeSegments < 3) ? (uint32)3 : tubeSegments;

		for (uint32 i <= seg)
		{
			let u = (float)i / (float)seg;
			let theta = u * TwoPi;
			let ct = Cos(theta);
			let st = Sin(theta);
			for (uint32 j <= tseg)
			{
				let v = (float)j / (float)tseg;
				let phi = v * TwoPi;
				let cp = Cos(phi);
				let sp = Sin(phi);
				let position = Float3((radius + tubeRadius * cp) * ct, tubeRadius * sp,
					(radius + tubeRadius * cp) * st);
				let center = Float3(radius * ct, 0, radius * st);
				mesh.Vertices.Add(.(position, Normalized(position - center),
					Float2(u, v), cWhite, Float3(1, 0, 0)));
			}
		}

		mesh.Indices.Resize(seg * tseg * 6);
		let rowStride = tseg + 1;
		for (uint32 i < seg)
		{
			for (uint32 j < tseg)
			{
				let a = i * rowStride + j;
				let b = a + 1;
				let c = a + rowStride;
				let d = c + 1;
				mesh.Indices.AddTriangle(a, b, c);
				mesh.Indices.AddTriangle(b, d, c);
			}
		}

		Finish(mesh);
		return mesh;
	}

	/// Adds a quad face, four vertices and two triangles, anchored at `origin` and
	/// spanning `size` along the unit edges. The caller sizes the index buffer first;
	/// these append through its cursor.
	private static void AddFace(StaticMesh mesh, Float3 origin, Float3 eu, Float3 ev, Float3 n, float size)
	{
		let start = mesh.VertexCount;
		let u = eu * size;
		let v = ev * size;

		mesh.Vertices.Add(.(origin, n, Float2(0, 1), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(origin + u, n, Float2(1, 1), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(origin + u + v, n, Float2(1, 0), cWhite, Float3(1, 0, 0)));
		mesh.Vertices.Add(.(origin + v, n, Float2(0, 0), cWhite, Float3(1, 0, 0)));

		mesh.Indices.AddTriangle(start, start + 1, start + 2);
		mesh.Indices.AddTriangle(start, start + 2, start + 3);
	}

	private static void Finish(StaticMesh mesh)
	{
		mesh.GenerateTangents();
		mesh.CalculateBounds();
		mesh.SubMeshes.Add(.(0, (int32)mesh.IndexCount, 0, .Triangles));
	}
}
