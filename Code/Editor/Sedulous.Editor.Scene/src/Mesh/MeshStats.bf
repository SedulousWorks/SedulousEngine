using System;
using System.Collections;
using Sedulous.Geometry;

namespace Sedulous.Editor.Scene;

/// The mesh page's read-only stat lines: counts, bounds, skinning, one row per submesh, and
/// the LOD chain when there is one.
static class MeshStats
{
	/// Appends one line per stat; the caller owns the strings.
	public static void Lines(StaticMesh mesh, List<String> outLines)
	{
		outLines.Add(new $"Name: {mesh.Name}");
		outLines.Add(new $"Vertices: {mesh.VertexCount}");
		outLines.Add(new $"Indices: {mesh.IndexCount}");
		outLines.Add(new $"Submeshes: {mesh.SubMeshes.Count}");

		let size = mesh.Bounds.Size();
		outLines.Add(new $"Bounds: {size.X:F3} x {size.Y:F3} x {size.Z:F3}");
		outLines.Add(new $"Skinned: {mesh.IsSkinned ? "yes" : "no"}");

		for (int i < mesh.SubMeshes.Count)
		{
			let sm = mesh.SubMeshes[i];
			outLines.Add(new $"  [{i}] material {sm.MaterialIndex}  |  {sm.IndexCount} indices");
		}
		if (mesh.LodCount > 1)
		{
			outLines.Add(new $"LOD levels: {mesh.LodCount}");
			for (uint32 l < mesh.LodCount)
			{
				int64 indexTotal = 0;
				for (let sm in mesh.SubMeshesForLod(l))
					indexTotal += sm.IndexCount;
				let threshold = (l < (uint32)mesh.LodCoverage.Count) ? mesh.LodCoverage[(int)l] : 0.0f;
				if (l == 0)
					outLines.Add(new $"  LOD 0: {indexTotal / 3} triangles");
				else
					outLines.Add(new $"  LOD {l}: {indexTotal / 3} triangles  |  below {threshold:F3} coverage");
			}
		}
	}
}
