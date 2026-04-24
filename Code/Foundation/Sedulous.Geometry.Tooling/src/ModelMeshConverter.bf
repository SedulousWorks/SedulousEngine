using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry;
using Sedulous.Models;

namespace Sedulous.Geometry.Tooling;

/// Result of converting a skinned model mesh.
struct SkinnedMeshConversionResult : IDisposable
{
	/// The converted skinned mesh (caller owns).
	public SkinnedMesh Mesh;

	/// Node-to-skeleton-bone mapping for animation channel remapping.
	/// Index by node index to get skeleton bone index (-1 if not a skin joint).
	public int32[] NodeToBoneMapping;

	public void Dispose() mut
	{
		if (NodeToBoneMapping != null)
		{
			delete NodeToBoneMapping;
			NodeToBoneMapping = null;
		}
		// Mesh is owned by caller
	}
}

/// Converts Model data to Geometry mesh data.
/// Handles joint index remapping so that vertex joint indices directly match skeleton bone indices.
static class ModelMeshConverter
{
	/// Converts a ModelMesh to a basic Mesh (non-skinned).
	/// @param generateMissingNormals If true and source had no normals, generate from geometry.
	/// @param generateMissingTangents If true and source had no tangents, generate from geometry.
	public static StaticMesh ConvertToStaticMesh(ModelMesh modelMesh, bool generateMissingNormals = true, bool generateMissingTangents = true)
	{
		if (modelMesh == null)
			return null;

		let mesh = new StaticMesh();

		// Find vertex element offsets
		int32 posOffset = 0, normalOffset = 12, texCoordOffset = 24, colorOffset = -1, tangentOffset = -1;

		for (let element in modelMesh.VertexElements)
		{
			switch (element.Semantic)
			{
			case .Position: posOffset = element.Offset;
			case .Normal: normalOffset = element.Offset;
			case .TexCoord: texCoordOffset = element.Offset;
			case .Color: colorOffset = element.Offset;
			case .Tangent: tangentOffset = element.Offset;
			default:
			}
		}

		let srcData = modelMesh.GetVertexData();
		let srcStride = modelMesh.VertexStride;

		// Allocate and set vertices
		mesh.ResizeVertices(modelMesh.VertexCount);

		for (int32 i = 0; i < modelMesh.VertexCount; i++)
		{
			uint8* v = srcData + i * srcStride;

			mesh.Vertices[i].Position = *(Vector3*)(v + posOffset);
			mesh.Vertices[i].Normal = *(Vector3*)(v + normalOffset);
			mesh.Vertices[i].TexCoord = *(Vector2*)(v + texCoordOffset);
			mesh.Vertices[i].Color = (colorOffset >= 0) ? *(uint32*)(v + colorOffset) : 0xFFFFFFFF;
			mesh.Vertices[i].Tangent = (tangentOffset >= 0) ? *(Vector3*)(v + tangentOffset) : Vector3.Zero;
		}

		// Copy indices
		if (modelMesh.IndexCount > 0)
		{
			mesh.Indices.Resize(modelMesh.IndexCount);
			let srcIdx = modelMesh.GetIndexData();

			if (modelMesh.Use32BitIndices)
			{
				let indices = (uint32*)srcIdx;
				for (int32 i = 0; i < modelMesh.IndexCount; i++)
					mesh.Indices.SetIndex(i, indices[i]);
			}
			else
			{
				let indices = (uint16*)srcIdx;
				for (int32 i = 0; i < modelMesh.IndexCount; i++)
					mesh.Indices.SetIndex(i, (uint32)indices[i]);
			}
		}

		// Create SubMeshes from ModelMeshParts (preserves per-primitive material indices)
		if (modelMesh.Parts != null && modelMesh.Parts.Count > 0)
		{
			for (let part in modelMesh.Parts)
				mesh.AddSubMesh(SubMesh(part.IndexStart, part.IndexCount, part.MaterialIndex));
		}
		else
		{
			// Fallback: single submesh covering entire mesh
			mesh.AddSubMesh(SubMesh(0, modelMesh.IndexCount));
		}

		// Generate normals/tangents if source data was missing
		if (generateMissingNormals && !modelMesh.HasNormals)
			mesh.GenerateNormals();
		if (generateMissingTangents && !modelMesh.HasTangents)
			mesh.GenerateTangents();

		return mesh;
	}

	/// Converts a ModelMesh to a SkinnedMesh using the provided skin for joint mapping.
	/// The resulting mesh has joint indices that directly match the skeleton bone ordering.
	/// Returns the mesh and a node-to-bone mapping for animation channel remapping.
	/// @param generateMissingNormals If true and source had no normals, generate from geometry.
	/// @param generateMissingTangents If true and source had no tangents, generate from geometry.
	public static Result<SkinnedMeshConversionResult> ConvertToSkinnedMesh(ModelMesh modelMesh, ModelSkin skin, bool generateMissingNormals = true, bool generateMissingTangents = true)
	{
		if (modelMesh == null)
			return .Err;

		if (skin == null || skin.Joints.Count == 0)
			return .Err;

		// Find vertex element offsets
		int32 posOffset = 0, normalOffset = 12, texCoordOffset = 24, colorOffset = -1, tangentOffset = -1;
		int32 jointsOffset = -1, weightsOffset = -1;

		for (let element in modelMesh.VertexElements)
		{
			switch (element.Semantic)
			{
			case .Position: posOffset = element.Offset;
			case .Normal: normalOffset = element.Offset;
			case .TexCoord: texCoordOffset = element.Offset;
			case .Color: colorOffset = element.Offset;
			case .Tangent: tangentOffset = element.Offset;
			case .Joints: jointsOffset = element.Offset;
			case .Weights: weightsOffset = element.Offset;
			}
		}

		if (jointsOffset < 0 || weightsOffset < 0)
			return .Err;  // No skinning data

		let skinnedMesh = new SkinnedMesh();
		let srcData = modelMesh.GetVertexData();
		let srcStride = modelMesh.VertexStride;

		skinnedMesh.ResizeVertices(modelMesh.VertexCount);

		for (int32 i = 0; i < modelMesh.VertexCount; i++)
		{
			uint8* v = srcData + i * srcStride;
			SkinnedVertex vertex = .();

			vertex.Position = *(Vector3*)(v + posOffset);
			vertex.Normal = *(Vector3*)(v + normalOffset);
			vertex.TexCoord = *(Vector2*)(v + texCoordOffset);
			vertex.Color = (colorOffset >= 0) ? *(uint32*)(v + colorOffset) : 0xFFFFFFFF;
			vertex.Tangent = (tangentOffset >= 0) ? *(Vector3*)(v + tangentOffset) : Vector3.Zero;

			// Joint indices are already indices into the skin's joints array,
			// which is exactly what we want for skeleton bone indices
			vertex.Joints = *(uint16[4]*)(v + jointsOffset);
			vertex.Weights = *(Vector4*)(v + weightsOffset);

			skinnedMesh.SetVertex(i, vertex);
		}

		// Copy indices
		if (modelMesh.IndexCount > 0)
		{
			skinnedMesh.ReserveIndices(modelMesh.IndexCount);
			let srcIdx = modelMesh.GetIndexData();

			if (modelMesh.Use32BitIndices)
			{
				let indices = (uint32*)srcIdx;
				for (int32 i = 0; i < modelMesh.IndexCount; i++)
					skinnedMesh.AddIndex(indices[i]);
			}
			else
			{
				let indices = (uint16*)srcIdx;
				for (int32 i = 0; i < modelMesh.IndexCount; i++)
					skinnedMesh.AddIndex((uint32)indices[i]);
			}
		}

		// Create SubMeshes from ModelMeshParts (preserves per-primitive material indices)
		if (modelMesh.Parts != null && modelMesh.Parts.Count > 0)
		{
			for (let part in modelMesh.Parts)
				skinnedMesh.AddSubMesh(SubMesh(part.IndexStart, part.IndexCount, part.MaterialIndex));
		}
		else
		{
			// Fallback: single submesh covering entire mesh
			skinnedMesh.AddSubMesh(SubMesh(0, modelMesh.IndexCount));
		}

		// Generate normals/tangents if source data was missing
		if (generateMissingNormals && !modelMesh.HasNormals)
			skinnedMesh.GenerateNormals();
		if (generateMissingTangents && !modelMesh.HasTangents)
			skinnedMesh.GenerateTangents();

		skinnedMesh.CalculateBounds();

		// Build node-to-bone mapping for animation channel remapping
		// This allows converting animation channel targets (node indices) to skeleton bone indices
		// We need to know the max node count to size the array properly
		int32 maxNodeIndex = 0;
		for (let nodeIdx in skin.Joints)
		{
			if (nodeIdx > maxNodeIndex)
				maxNodeIndex = nodeIdx;
		}

		let nodeToSkinJoint = new int32[maxNodeIndex + 1];
		for (int i = 0; i < nodeToSkinJoint.Count; i++)
			nodeToSkinJoint[i] = -1;

		for (int32 skinJointIdx = 0; skinJointIdx < skin.Joints.Count; skinJointIdx++)
		{
			let nodeIdx = skin.Joints[skinJointIdx];
			if (nodeIdx >= 0 && nodeIdx < nodeToSkinJoint.Count)
				nodeToSkinJoint[nodeIdx] = skinJointIdx;
		}

		return .Ok(.()
		{
			Mesh = skinnedMesh,
			NodeToBoneMapping = nodeToSkinJoint
		});
	}
}
