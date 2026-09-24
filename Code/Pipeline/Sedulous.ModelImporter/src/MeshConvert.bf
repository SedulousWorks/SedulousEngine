using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// A loaded model's mesh into the cooked geometry sources.
///
/// The loaders always produce INDEXED geometry, a non indexed primitive getting sequential
/// indices at load, so there is no other path here.
static class MeshConvert
{
	/// The model's indices, whichever width they arrived in, as the thirty two bit ones a
	/// cooked source stores.
	public static void CopyIndices(ModelMesh mesh, List<uint32> outIndices)
	{
		outIndices.Clear();

		let count = mesh.IndexCount;
		let data = mesh.IndexData;
		if ((data == null) || (count <= 0))
			return;

		outIndices.Reserve(count);
		if (mesh.Use32BitIndices)
		{
			let source = (uint32*)data;
			for (int32 i < count)
				outIndices.Add(source[i]);
		}
		else
		{
			let source = (uint16*)data;
			for (int32 i < count)
				outIndices.Add((uint32)source[i]);
		}
	}

	/// The model wide material indices ONE mesh's parts use, in first appearance order.
	///
	/// A cooked submesh's material index is a position in THIS list, a per mesh slot, never
	/// the model wide index, so the entity binds only the materials the mesh draws. A large
	/// model shares one material table across thousands of nodes: without the remap every
	/// one of them carries the whole table to reach the one or two materials it needs.
	public static void CollectMaterialSlots(ModelMesh mesh, List<int32> outSlots)
	{
		outSlots.Clear();
		for (let part in mesh.Parts)
		{
			if (part.MaterialIndex < 0)
				continue; // a part with no material claims no slot
			if (!outSlots.Contains(part.MaterialIndex))
				outSlots.Add(part.MaterialIndex);
		}
	}

	/// The model's parts as submesh ranges. A mesh with NO explicit parts becomes one submesh
	/// over the whole index buffer, which is what an unpartitioned mesh means.
	public static void CopyParts(ModelMesh mesh, StaticMeshSource outSource)
	{
		outSource.SubStart.Clear();
		outSource.SubCount.Clear();
		outSource.SubMaterial.Clear();
		outSource.SubPrimitive.Clear();

		let parts = mesh.Parts;
		if (parts.IsEmpty)
		{
			outSource.SubStart.Add(0);
			outSource.SubCount.Add(mesh.IndexCount);
			outSource.SubMaterial.Add(-1);
			outSource.SubPrimitive.Add((uint8)PrimitiveType.Triangles);
			return;
		}

		let slots = scope List<int32>();
		CollectMaterialSlots(mesh, slots);
		for (int i < parts.Length)
		{
			outSource.SubStart.Add(parts[i].IndexStart);
			outSource.SubCount.Add(parts[i].IndexCount);
			// The per mesh slot, minus one for a part with no material.
			outSource.SubMaterial.Add((int32)slots.IndexOf(parts[i].MaterialIndex));
			outSource.SubPrimitive.Add((uint8)PrimitiveType.Triangles);
		}
	}

	/// Fills a static source from a model mesh's streams.
	public static void StaticFromModel(ModelMesh mesh, StaticMeshSource outSource)
	{
		outSource.Name.Set(mesh.Name);

		let elements = mesh.VertexElements;
		let positionElement = ModelVertexRead.FindElement(elements, .Position);
		let normalElement = ModelVertexRead.FindElement(elements, .Normal);
		let texCoordElement = ModelVertexRead.FindElement(elements, .TexCoord);
		let colorElement = ModelVertexRead.FindElement(elements, .Color);
		let tangentElement = ModelVertexRead.FindElement(elements, .Tangent);

		let count = mesh.VertexCount;
		let stride = mesh.VertexStride;
		let bytes = mesh.VertexData;

		outSource.VertexBlob.Clear();
		outSource.VertexBlob.Count = count * sizeof(StaticMeshVertex);
		let destination = (StaticMeshVertex*)outSource.VertexBlob.Ptr;

		for (int32 i < count)
		{
			let vertex = bytes + (int)i * (int)stride;
			StaticMeshVertex converted = .();
			converted.Position = ModelVertexRead.ReadVec3(vertex, positionElement, .(0, 0, 0));
			converted.Normal = ModelVertexRead.ReadVec3(vertex, normalElement, .(0, 1, 0));
			converted.TexCoord = ModelVertexRead.ReadVec2(vertex, texCoordElement, .(0, 0));
			converted.Color = ModelVertexRead.ReadU32(vertex, colorElement, 0xFFFFFFFF);
			// The fourth component is the tangent basis's handedness.
			converted.Tangent = ModelVertexRead.ReadVec4(vertex, tangentElement, .(1, 0, 0, 1));
			destination[i] = converted;
		}

		CopyIndices(mesh, outSource.IndexData);
		CopyParts(mesh, outSource);

		// NO authored tangent stream, which plenty of models ship without: they are generated
		// here, or every vertex keeps the default and the tangent basis is wrong across the
		// whole mesh, so a normal mapped material shades wrong everywhere.
		if ((tangentElement == null) && (normalElement != null) && (texCoordElement != null)
			&& !outSource.IndexData.IsEmpty)
		{
			StaticMesh.GenerateTangents(.(destination, count), outSource.IndexData);
		}
	}

	/// Fills a skinned source: the static streams above, plus the parallel skinning one and
	/// the skeleton it belongs to.
	public static void SkinnedFromModel(ModelMesh mesh, int32 skeletonIndex,
		SkinnedMeshSource outSource)
	{
		StaticFromModel(mesh, outSource);
		outSource.SkeletonIndex = skeletonIndex;

		let elements = mesh.VertexElements;
		let jointsElement = ModelVertexRead.FindElement(elements, .Joints);
		let weightsElement = ModelVertexRead.FindElement(elements, .Weights);

		let count = mesh.VertexCount;
		let stride = mesh.VertexStride;
		let bytes = mesh.VertexData;

		outSource.SkinningBlob.Clear();
		outSource.SkinningBlob.Count = count * sizeof(VertexSkinning);
		let destination = (VertexSkinning*)outSource.SkinningBlob.Ptr;

		for (int32 i < count)
		{
			let vertex = bytes + (int)i * (int)stride;
			VertexSkinning skinning = .();
			if (jointsElement != null)
				Internal.MemCpy(&skinning.Joints, vertex + jointsElement.Offset, sizeof(uint16[4]));
			// A vertex with no weights belongs wholly to its first joint.
			skinning.Weights = ModelVertexRead.ReadVec4(vertex, weightsElement, .(1, 0, 0, 0));
			destination[i] = skinning;
		}
	}
}
