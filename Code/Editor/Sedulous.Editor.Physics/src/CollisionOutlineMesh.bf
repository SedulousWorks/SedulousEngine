using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Physics.Resource;

namespace Sedulous.Editor.Physics;

/// A cooked collider's display outline, a flat triangle list, as a static mesh the
/// thumbnail stage can draw.
static class CollisionOutlineMesh
{
	/// False when the outline has no whole triangle; the mesh is left cleared.
	public static bool Build(CollisionShape shape, StaticMesh mesh)
	{
		mesh.ClearForReload();
		let count = shape.Outline.Count - (shape.Outline.Count % 3);
		if (count < 3)
			return false;
		mesh.Vertices.Reserve(count);
		mesh.Indices.Resize((uint32)count);
		for (int i < count)
		{
			mesh.Vertices.Add(.(shape.Outline[i], .(0, 1, 0), .(0, 0), 0xFFFFFFFFu, Float4(1, 0, 0, 1)));
			mesh.Indices.Add((uint32)i);
		}
		mesh.GenerateNormals();
		mesh.GenerateTangents();
		mesh.CalculateBounds();
		mesh.SubMeshes.Add(.(0, (int32)mesh.IndexCount, 0, .Triangles));
		return true;
	}
}
