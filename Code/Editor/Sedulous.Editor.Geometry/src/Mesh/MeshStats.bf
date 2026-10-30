using System;
using System.Collections;
using Sedulous.Geometry;

namespace Sedulous.Editor.Geometry;

/// The mesh page's read-only stat lines: counts, bounds, skinning, one row per submesh, and
/// the LOD chain when there is one; the page shows each as a row (Split).
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

	/// A stat line as a row: "Vertices: 1200" its name and value, "  [2] material 1 | 90 indices" a
	/// submesh's ("Submesh 2"), "  LOD 1: 400 triangles | ..." a level's. Appended.
	public static void Split(StringView line, String outName, String outValue)
	{
		var start = 0;
		while ((start < line.Length) && (line[start] == ' '))
			start++;
		let text = line.Substring(start);
		if (!text.IsEmpty && (text[0] == '['))
		{
			var close = 1;
			while ((close < text.Length) && (text[close] != ']'))
				close++;
			outName.AppendF("Submesh {}", text.Substring(1, close - 1));
			let rest = (close + 2 < text.Length) ? close + 2 : text.Length;
			outValue.Append(text.Substring(rest));
			return;
		}
		for (int i = 0; i + 1 < text.Length; i++)
		{
			if ((text[i] == ':') && (text[i + 1] == ' '))
			{
				outName.Append(text.Substring(0, i));
				outValue.Append(text.Substring(i + 2));
				return;
			}
		}
		outName.Append(text);
	}
}
