using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Pipeline.Tests;

/// Mesh sources built by hand, and the comparisons the optimiser cases need.
///
/// Everything the pass does is a REORDER, so an assertion has to compare what cannot change,
/// which is the triangle set as POSITIONS: index values are free to be remapped, geometry and
/// winding are not.
static class MeshSourceFixture
{
	private static int Stride => sizeof(StaticMeshVertex);

	/// A deliberately cache hostile grid: triangles emitted COLUMN major over a ROW major
	/// vertex layout, so consecutive triangles jump a whole row apart.
	///
	/// The worst case the optimiser has to visibly improve, which a friendly fixture could
	/// not show.
	public static void HostileGrid(uint32 n, StaticMeshSource outSource)
	{
		let side = n + 1;
		let vertices = scope List<StaticMeshVertex>();
		for (uint32 z < side)
		{
			for (uint32 x < side)
			{
				var vertex = StaticMeshVertex();
				vertex.Position = .((float)x, 0.0f, (float)z);
				vertex.TexCoord = .((float)x, (float)z);
				vertices.Add(vertex);
			}
		}
		SetVertices(outSource, vertices);

		outSource.IndexData.Clear();
		for (uint32 x < n)
		{
			for (uint32 z < n)
			{
				let a = z * side + x;
				let b = z * side + x + 1;
				let c = (z + 1) * side + x;
				let d = (z + 1) * side + x + 1;
				outSource.IndexData.AddRange(scope uint32[](a, c, b, b, c, d));
			}
		}

		ClearSubmeshes(outSource);
		AddSubmesh(outSource, 0, (int32)outSource.IndexData.Count, 0, .Triangles);
	}

	/// A two level fan over five shared vertices: three triangles at the base, one at the
	/// level, concatenated into the one index buffer.
	public static void TwoLevelFan(StaticMeshSource outSource)
	{
		let vertices = scope List<StaticMeshVertex>();
		for (uint32 i < 5)
		{
			var vertex = StaticMeshVertex();
			vertex.Position = .((float)i, (float)(i % 2), 0.0f);
			vertices.Add(vertex);
		}
		SetVertices(outSource, vertices);

		outSource.IndexData.Clear();
		outSource.IndexData.AddRange(scope uint32[](0, 1, 2, 0, 2, 3, 0, 3, 4));
		outSource.IndexData.AddRange(scope uint32[](0, 1, 4));

		ClearSubmeshes(outSource);
		AddSubmesh(outSource, 0, 9, 7, .Triangles);

		outSource.LodCount = 2;
		outSource.LodStart.Clear();
		outSource.LodIndexCount.Clear();
		outSource.LodCoverage.Clear();
		outSource.LodStart.Add(9);
		outSource.LodIndexCount.Add(3);
		outSource.LodCoverage.Add(1.0f);
		outSource.LodCoverage.Add(0.25f);
	}

	public static void SetVertices(StaticMeshSource source, List<StaticMeshVertex> vertices)
	{
		source.VertexBlob.Clear();
		source.VertexBlob.Count = vertices.Count * Stride;
		if (!vertices.IsEmpty)
			Internal.MemCpy(source.VertexBlob.Ptr, vertices.Ptr, source.VertexBlob.Count);
	}

	public static void SetSkinning(SkinnedMeshSource source, List<VertexSkinning> skinning)
	{
		source.SkinningBlob.Clear();
		source.SkinningBlob.Count = skinning.Count * sizeof(VertexSkinning);
		if (!skinning.IsEmpty)
			Internal.MemCpy(source.SkinningBlob.Ptr, skinning.Ptr, source.SkinningBlob.Count);
	}

	public static void ClearSubmeshes(StaticMeshSource source)
	{
		source.SubStart.Clear();
		source.SubCount.Clear();
		source.SubMaterial.Clear();
		source.SubPrimitive.Clear();
	}

	public static void AddSubmesh(StaticMeshSource source, int32 start, int32 count,
		int32 material, PrimitiveType primitive)
	{
		source.SubStart.Add(start);
		source.SubCount.Add(count);
		source.SubMaterial.Add(material);
		source.SubPrimitive.Add((uint8)primitive);
	}

	public static Float3 PositionOf(StaticMeshSource source, uint32 index)
		=> ((StaticMeshVertex*)source.VertexBlob.Ptr)[index].Position;

	private static bool Less(Float3 l, Float3 r)
	{
		if (l.X != r.X)
			return l.X < r.X;
		if (l.Y != r.Y)
			return l.Y < r.Y;
		return l.Z < r.Z;
	}

	/// The triangles of a range as sorted position triples, each rotated so its smallest
	/// corner leads.
	///
	/// Rotation PRESERVES winding, so two sets that compare equal describe the same surface
	/// facing the same way, whatever order the optimiser put them in.
	public static void TriangleSet(StaticMeshSource source, int32 start, int32 count,
		List<Float3[3]> outTriangles)
	{
		outTriangles.Clear();
		for (int32 i = 0; (i + 2) < count; i += 3)
		{
			var triangle = Float3[3](PositionOf(source, source.IndexData[start + i]),
				PositionOf(source, source.IndexData[start + i + 1]),
				PositionOf(source, source.IndexData[start + i + 2]));
			while (Less(triangle[1], triangle[0]) || Less(triangle[2], triangle[0]))
			{
				let first = triangle[0];
				triangle[0] = triangle[1];
				triangle[1] = triangle[2];
				triangle[2] = first;
			}
			outTriangles.Add(triangle);
		}

		outTriangles.Sort(scope (l, r) =>
			{
				for (int c < 3)
				{
					if (l[c] != r[c])
						return Less(l[c], r[c]) ? -1 : 1;
				}
				return 0;
			});
	}

	/// The triangle set of one submesh.
	public static void SubmeshTriangles(StaticMeshSource source, int submesh,
		List<Float3[3]> outTriangles)
		=> TriangleSet(source, source.SubStart[submesh], source.SubCount[submesh], outTriangles);

	public static bool SameTriangles(List<Float3[3]> a, List<Float3[3]> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			for (int c < 3)
			{
				if (a[i][c] != b[i][c])
					return false;
			}
		}
		return true;
	}
}
