using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using Sedulous.Animation;
using Sedulous.Animation.Resources;

using static Sedulous.Core.Mathematics.MathSerializerExtensions;
using static Sedulous.Resources.ResourceSerializerExtensions;

namespace Sedulous.Geometry.Resources;

/// CPU-side skinned mesh resource wrapping a SkinnedMesh.
/// Serializes mesh data + a ResourceRef to its skeleton.
/// Skeleton and animations are resolved at runtime via the resource system.
class SkinnedMeshResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("skinnedmesh");

	private SkinnedMesh mMesh;
	private bool mOwnsMesh;

	/// Serializable reference to the skeleton resource.
	public ResourceRef SkeletonRef;

	/// The underlying skinned mesh data.
	public SkinnedMesh Mesh => mMesh;

	public this()
	{
		mMesh = null;
		mOwnsMesh = false;
	}

	public this(SkinnedMesh mesh, bool ownsMesh = false)
	{
		mMesh = mesh;
		mOwnsMesh = ownsMesh;
	}

	public ~this()
	{
		if (mOwnsMesh && mMesh != null)
			delete mMesh;
		SkeletonRef.Dispose();
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mMesh == null)
				return .InvalidData;

			// Serialize mesh data
			SerializeMesh(s);

			// Serialize skeleton reference
			s.ResourceRef("skeletonRef", ref SkeletonRef);
		}
		else
		{
			// Deserialize mesh data
			DeserializeMesh(s);

			// Deserialize skeleton reference
			s.ResourceRef("skeletonRef", ref SkeletonRef);
		}

		return .Ok;
	}

	private void SerializeMesh(Serializer s)
	{
		s.BeginObject("mesh");

		int32 vertexCount = mMesh.VertexCount;
		s.Int32("vertexCount", ref vertexCount);

		if (vertexCount > 0)
		{
			s.BeginObject("vertices");

			let positions = scope List<float>();
			let normals = scope List<float>();
			let uvs = scope List<float>();
			let colors = scope List<int32>();
			let tangents = scope List<float>();
			let joints = scope List<int32>();
			let weights = scope List<float>();

			for (int32 i = 0; i < vertexCount; i++)
			{
				let v = mMesh.GetVertex(i);
				positions.Add(v.Position.X); positions.Add(v.Position.Y); positions.Add(v.Position.Z);
				normals.Add(v.Normal.X); normals.Add(v.Normal.Y); normals.Add(v.Normal.Z);
				uvs.Add(v.TexCoord.X); uvs.Add(v.TexCoord.Y);
				colors.Add((int32)v.Color);
				tangents.Add(v.Tangent.X); tangents.Add(v.Tangent.Y); tangents.Add(v.Tangent.Z);
				joints.Add((int32)v.Joints[0]); joints.Add((int32)v.Joints[1]);
				joints.Add((int32)v.Joints[2]); joints.Add((int32)v.Joints[3]);
				weights.Add(v.Weights.X); weights.Add(v.Weights.Y);
				weights.Add(v.Weights.Z); weights.Add(v.Weights.W);
			}

			s.ArrayFloat("positions", positions);
			s.ArrayFloat("normals", normals);
			s.ArrayFloat("uvs", uvs);
			s.ArrayInt32("colors", colors);
			s.ArrayFloat("tangents", tangents);
			s.ArrayInt32("joints", joints);
			s.ArrayFloat("weights", weights);

			s.EndObject();
		}

		// Write indices
		int32 indexCount = mMesh.IndexCount;
		s.Int32("indexCount", ref indexCount);

		if (indexCount > 0)
		{
			let indices = scope List<int32>();
			for (int32 i = 0; i < indexCount; i++)
				indices.Add((int32)mMesh.Indices.GetIndex(i));
			s.ArrayInt32("indices", indices);
		}

		// Write submeshes
		int32 submeshCount = (int32)mMesh.SubMeshes.Count;
		s.Int32("submeshCount", ref submeshCount);

		if (submeshCount > 0)
		{
			s.BeginObject("submeshes");

			for (int32 i = 0; i < submeshCount; i++)
			{
				let sm = mMesh.SubMeshes[i];
				s.BeginObject(scope $"sm{i}");

				int32 startIndex = sm.startIndex;
				int32 indexCnt = sm.indexCount;
				int32 materialIndex = sm.materialIndex;

				s.Int32("startIndex", ref startIndex);
				s.Int32("indexCount", ref indexCnt);
				s.Int32("materialIndex", ref materialIndex);

				s.EndObject();
			}

			s.EndObject();
		}

		s.EndObject();
	}

	private void DeserializeMesh(Serializer s)
	{
		s.BeginObject("mesh");

		let mesh = new SkinnedMesh();

		int32 vertexCount = 0;
		s.Int32("vertexCount", ref vertexCount);

		if (vertexCount > 0)
		{
			mesh.ResizeVertices(vertexCount);

			s.BeginObject("vertices");

			let positions = scope List<float>();
			let normals = scope List<float>();
			let uvs = scope List<float>();
			let colors = scope List<int32>();
			let tangents = scope List<float>();
			let joints = scope List<int32>();
			let weights = scope List<float>();

			s.ArrayFloat("positions", positions);
			s.ArrayFloat("normals", normals);
			s.ArrayFloat("uvs", uvs);
			s.ArrayInt32("colors", colors);
			s.ArrayFloat("tangents", tangents);
			s.ArrayInt32("joints", joints);
			s.ArrayFloat("weights", weights);

			for (int32 i = 0; i < vertexCount; i++)
			{
				SkinnedVertex v = .();
				if (i * 3 + 2 < positions.Count)
					v.Position = .(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]);
				if (i * 3 + 2 < normals.Count)
					v.Normal = .(normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]);
				if (i * 2 + 1 < uvs.Count)
					v.TexCoord = .(uvs[i * 2], uvs[i * 2 + 1]);
				if (i < colors.Count)
					v.Color = (uint32)colors[i];
				if (i * 3 + 2 < tangents.Count)
					v.Tangent = .(tangents[i * 3], tangents[i * 3 + 1], tangents[i * 3 + 2]);
				if (i * 4 + 3 < joints.Count)
					v.Joints = .((uint16)joints[i * 4], (uint16)joints[i * 4 + 1],
						(uint16)joints[i * 4 + 2], (uint16)joints[i * 4 + 3]);
				if (i * 4 + 3 < weights.Count)
					v.Weights = .(weights[i * 4], weights[i * 4 + 1],
						weights[i * 4 + 2], weights[i * 4 + 3]);
				mesh.SetVertex(i, v);
			}

			s.EndObject();
		}

		// Read indices
		int32 indexCount = 0;
		s.Int32("indexCount", ref indexCount);

		if (indexCount > 0)
		{
			mesh.ReserveIndices(indexCount);
			let indices = scope List<int32>();
			s.ArrayInt32("indices", indices);
			for (int32 i = 0; i < Math.Min(indexCount, (int32)indices.Count); i++)
				mesh.AddIndex((uint32)indices[i]);
		}

		// Read submeshes
		int32 submeshCount = 0;
		s.Int32("submeshCount", ref submeshCount);

		if (submeshCount > 0)
		{
			s.BeginObject("submeshes");

			for (int32 i = 0; i < submeshCount; i++)
			{
				s.BeginObject(scope $"sm{i}");

				int32 startIndex = 0, idxCount = 0, materialIndex = 0;
				s.Int32("startIndex", ref startIndex);
				s.Int32("indexCount", ref idxCount);
				s.Int32("materialIndex", ref materialIndex);

				mesh.AddSubMesh(SubMesh(startIndex, idxCount, materialIndex));
				s.EndObject();
			}

			s.EndObject();
		}

		mesh.CalculateBounds();
		s.EndObject();

		// Set the mesh
		if (mOwnsMesh && mMesh != null)
			delete mMesh;
		mMesh = mesh;
		mOwnsMesh = true;
	}

}
