using System;
using Sedulous.Core;

namespace Sedulous.Geometry;

/// Where a ray met a mesh, in the mesh's space.
struct MeshRayHit
{
	/// Along the ray, in units of the ray's direction.
	public float Distance;
	public Float3 Position;
	/// The triangle's, facing the ray.
	public Float3 Normal;
	/// The hit triangle's corners.
	public Float3[3] Corners;
}

/// A ray against a mesh's triangles on the CPU: the nearest hit on its base level (LOD 0, the
/// shape every coarser level approximates), both faces counted, with the triangle's corners, so
/// a caller can take the nearest corner (vertex snapping). The ray is in the mesh's own space;
/// a caller with a world ray transforms it by the inverse world matrix WITHOUT normalizing the
/// direction, so the hit's distance stays the world distance along the world ray.
static class MeshRaycast
{
	/// The ray's intersection with triangle (a, b, c), both faces: the distance in units of
	/// `direction`, or a negative value when it misses (Moller-Trumbore).
	public static float RayTriangle(Float3 origin, Float3 direction, Float3 a, Float3 b, Float3 c)
	{
		let ab = b - a;
		let ac = c - a;
		let p = Cross(direction, ac);
		let det = Dot(ab, p);
		if (Math.Abs(det) < 1e-12f)
			return -1.0f; // parallel to the triangle (or a degenerate one)
		let inv = 1.0f / det;
		let s = origin - a;
		let u = Dot(s, p) * inv;
		if ((u < 0.0f) || (u > 1.0f))
			return -1.0f;
		let q = Cross(s, ab);
		let v = Dot(direction, q) * inv;
		if ((v < 0.0f) || (u + v > 1.0f))
			return -1.0f;
		return Dot(ac, q) * inv;
	}

	/// The nearest hit of the ray on `mesh`'s LOD 0 triangles within `maxDistance` (in units
	/// of `direction`); false when it misses or the mesh has no triangles on the CPU.
	public static bool Raycast(StaticMesh mesh, Float3 origin, Float3 direction, float maxDistance, out MeshRayHit outHit)
	{
		outHit = .();
		var hit = false;
		var best = maxDistance;
		if (mesh.SubMeshes.IsEmpty)
			Test(mesh, 0, (mesh.IndexCount > 0) ? mesh.IndexCount : mesh.VertexCount, origin, direction, ref best, ref hit, ref outHit);
		for (let sub in mesh.SubMeshes)
		{
			if ((sub.Primitive == .Triangles) && (sub.StartIndex >= 0) && (sub.IndexCount > 0))
				Test(mesh, (uint32)sub.StartIndex, (uint32)sub.IndexCount, origin, direction, ref best, ref hit, ref outHit);
		}
		return hit;
	}

	/// The corner of the hit triangle nearest the hit point.
	public static Float3 NearestCorner(MeshRayHit hit)
	{
		var nearest = hit.Corners[0];
		var bestDistance = LengthSquared(hit.Corners[0] - hit.Position);
		for (int i = 1; i < 3; i++)
		{
			let d = LengthSquared(hit.Corners[i] - hit.Position);
			if (d < bestDistance)
			{
				bestDistance = d;
				nearest = hit.Corners[i];
			}
		}
		return nearest;
	}

	/// The vertex index the `index`th corner names; false past the vertices (a malformed
	/// index never reads past them).
	private static bool VertexIndex(StaticMesh mesh, uint32 index, out uint32 outVertex)
	{
		outVertex = (mesh.IndexCount > 0) ? mesh.Indices.Get(index) : index;
		return outVertex < mesh.VertexCount;
	}

	/// The triangles of [first, first + count), nearer than `best`.
	private static void Test(StaticMesh mesh, uint32 first, uint32 count, Float3 origin, Float3 direction, ref float best, ref bool hit, ref MeshRayHit outHit)
	{
		let limit = (mesh.IndexCount > 0) ? mesh.IndexCount : mesh.VertexCount;
		for (var i = first; (i + 2 < first + count) && (i + 2 < limit); i += 3)
		{
			let okA = VertexIndex(mesh, i, let ia);
			let okB = VertexIndex(mesh, i + 1, let ib);
			let okC = VertexIndex(mesh, i + 2, let ic);
			if (!okA || !okB || !okC)
				continue;
			let a = mesh.Vertices[(int)ia].Position;
			let b = mesh.Vertices[(int)ib].Position;
			let c = mesh.Vertices[(int)ic].Position;
			let t = RayTriangle(origin, direction, a, b, c);
			if ((t < 0.0f) || (t >= best))
				continue;
			best = t;
			hit = true;
			outHit.Distance = t;
			outHit.Position = origin + direction * t;
			var n = Cross(b - a, c - a);
			n = (LengthSquared(n) > 0.0f) ? Normalized(n) : Float3.UnitY;
			outHit.Normal = (Dot(n, direction) > 0.0f) ? -n : n;
			outHit.Corners = .(a, b, c);
		}
	}
}
