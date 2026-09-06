using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;

namespace Sedulous.Geometry;

/// A cooked static mesh: the raw vertex stream, 32 bit indices, and the submesh table as
/// PARALLEL ARRAYS.
///
/// Parallel arrays rather than a list of SubMesh so every field is a list of primitives,
/// which the counted array path already describes. Bounds are not stored: they are
/// derivable from the vertices, and a stored copy is one more thing that can disagree with
/// the data it came from.
///
/// Raptor carries migrations here for two older payload shapes, a Float3 tangent and a
/// mis-gated LOD block. Neither is ported: no Sedulous payload was ever written in either
/// shape, and migration code for data that never existed is untestable by construction.
/// This is version 1 of a fresh format.
[Serializable(1)]
class StaticMeshSource
{
	public String Name = new .() ~ delete _;
	/// Raw StaticMeshVertex bytes.
	public List<uint8> VertexBlob = new .() ~ delete _;
	public List<uint32> IndexData = new .() ~ delete _;

	public List<int32> SubStart = new .() ~ delete _;
	public List<int32> SubCount = new .() ~ delete _;
	public List<int32> SubMaterial = new .() ~ delete _;
	/// PrimitiveType per submesh.
	public List<uint8> SubPrimitive = new .() ~ delete _;

	/// The LOD chain: levels 1..LodCount-1 as flattened per submesh index ranges into the
	/// SAME IndexData over the SAME VertexBlob, plus one coverage threshold per level.
	public uint32 LodCount = 1;
	public List<int32> LodStart = new .() ~ delete _;
	public List<int32> LodIndexCount = new .() ~ delete _;
	public List<float> LodCoverage = new .() ~ delete _;

	/// Captures a mesh into this source, for cooking.
	public static void FromMesh(StaticMesh mesh, StaticMeshSource outSource)
	{
		outSource.Name.Set(mesh.Name);

		outSource.VertexBlob.Clear();
		if (mesh.VertexDataSize > 0)
		{
			outSource.VertexBlob.Resize((int)mesh.VertexDataSize);
			Internal.MemCpy(outSource.VertexBlob.Ptr, mesh.VertexData, (int)mesh.VertexDataSize);
		}

		outSource.IndexData.Clear();
		outSource.IndexData.Reserve((int)mesh.IndexCount);
		for (uint32 i < mesh.IndexCount)
			outSource.IndexData.Add(mesh.Indices.Get(i));

		outSource.SubStart.Clear();
		outSource.SubCount.Clear();
		outSource.SubMaterial.Clear();
		outSource.SubPrimitive.Clear();
		for (let submesh in mesh.SubMeshes)
		{
			outSource.SubStart.Add(submesh.StartIndex);
			outSource.SubCount.Add(submesh.IndexCount);
			outSource.SubMaterial.Add(submesh.MaterialIndex);
			outSource.SubPrimitive.Add((uint8)submesh.Primitive);
		}

		outSource.LodCount = (mesh.LodCount > 0) ? mesh.LodCount : 1;
		outSource.LodStart.Clear();
		outSource.LodIndexCount.Clear();
		for (let submesh in mesh.LodSubMeshes)
		{
			outSource.LodStart.Add(submesh.StartIndex);
			outSource.LodIndexCount.Add(submesh.IndexCount);
		}

		outSource.LodCoverage.Clear();
		for (let coverage in mesh.LodCoverage)
			outSource.LodCoverage.Add(coverage);
	}

	/// Populates a mesh from this source, recomputing bounds.
	public void FillStatic(StaticMesh mesh)
	{
		mesh.Name.Set(Name);

		let vertexCount = VertexBlob.Count / sizeof(StaticMeshVertex);
		mesh.Vertices.Clear();
		mesh.Vertices.Resize(vertexCount);
		if (vertexCount > 0)
			Internal.MemCpy(mesh.Vertices.Ptr, VertexBlob.Ptr, vertexCount * sizeof(StaticMeshVertex));

		mesh.Indices.Resize((uint32)IndexData.Count);
		for (int i < IndexData.Count)
			mesh.Indices.Set((uint32)i, IndexData[i]);

		// The parallel tables are read defensively: a short one means the payload disagrees
		// with itself, and a submesh with a default material renders wrong where a read
		// past the end would not render at all.
		mesh.SubMeshes.Clear();
		for (int i < SubStart.Count)
		{
			let count = (i < SubCount.Count) ? SubCount[i] : 0;
			let material = (i < SubMaterial.Count) ? SubMaterial[i] : 0;
			uint8 primitive = (i < SubPrimitive.Count) ? SubPrimitive[i] : 0;
			mesh.SubMeshes.Add(.(SubStart[i], count, material, (PrimitiveType)primitive));
		}

		FillLodChain(mesh);
		mesh.CalculateBounds();
	}

	/// The LOD chain, VALIDATED. A table whose slice length does not match the submesh
	/// count, or whose ranges fall outside the index buffer, collapses to a single level:
	/// bad data renders at level 0 rather than crashing selection. Coarser levels mirror
	/// level 0's material and topology, since a coarser level never resorts its submeshes.
	private void FillLodChain(StaticMesh mesh)
	{
		mesh.LodCount = 1;
		mesh.LodSubMeshes.Clear();
		mesh.LodCoverage.Clear();

		let per = SubStart.Count;
		if ((LodCount <= 1) || (per == 0))
			return;

		if ((LodStart.Count != (int)(LodCount - 1) * per)
			|| (LodIndexCount.Count != LodStart.Count)
			|| (LodCoverage.Count != (int)LodCount))
			return;

		for (int i < LodStart.Count)
		{
			let start = (int64)LodStart[i];
			let count = (int64)LodIndexCount[i];
			if ((start < 0) || (count < 0) || (start + count > (int64)IndexData.Count))
				return;
		}

		mesh.LodCount = LodCount;
		for (let coverage in LodCoverage)
			mesh.LodCoverage.Add(coverage);

		for (int i < LodStart.Count)
		{
			let submesh = i % per;
			mesh.LodSubMeshes.Add(.(LodStart[i], LodIndexCount[i],
				mesh.SubMeshes[submesh].MaterialIndex, mesh.SubMeshes[submesh].Primitive));
		}
	}
}
