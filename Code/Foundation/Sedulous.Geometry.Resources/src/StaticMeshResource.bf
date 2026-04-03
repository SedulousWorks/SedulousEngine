using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;

namespace Sedulous.Geometry.Resources;

/// CPU-side mesh resource wrapping a Mesh.
class StaticMeshResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("staticmesh");

	private StaticMesh mMesh;
	private bool mOwnsMesh;

	/// The underlying mesh data.
	public StaticMesh Mesh => mMesh;

	public this()
	{
		mMesh = null;
		mOwnsMesh = false;
	}

	public this(StaticMesh mesh, bool ownsMesh = false)
	{
		mMesh = mesh;
		mOwnsMesh = ownsMesh;
	}

	public ~this()
	{
		if (mOwnsMesh && mMesh != null)
			delete mMesh;
	}

	/// Sets the mesh. Takes ownership if ownsMesh is true.
	public void SetMesh(StaticMesh mesh, bool ownsMesh = false)
	{
		if (mOwnsMesh && mMesh != null)
			delete mMesh;
		mMesh = mesh;
		mOwnsMesh = ownsMesh;
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mMesh == null)
				return .InvalidData;

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

				for (int32 i = 0; i < vertexCount; i++)
				{
					let v = mMesh.Vertices[i];
					positions.Add(v.Position.X); positions.Add(v.Position.Y); positions.Add(v.Position.Z);
					normals.Add(v.Normal.X); normals.Add(v.Normal.Y); normals.Add(v.Normal.Z);
					uvs.Add(v.TexCoord.X); uvs.Add(v.TexCoord.Y);
					colors.Add((int32)v.Color);
					tangents.Add(v.Tangent.X); tangents.Add(v.Tangent.Y); tangents.Add(v.Tangent.Z);
				}

				s.ArrayFloat("positions", positions);
				s.ArrayFloat("normals", normals);
				s.ArrayFloat("uvs", uvs);
				s.ArrayInt32("colors", colors);
				s.ArrayFloat("tangents", tangents);

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
			int32 submeshCount = (int32)(mMesh.SubMeshes?.Count ?? 0);
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
		}
		else
		{
			// Reading
			let mesh = new StaticMesh();

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

				s.ArrayFloat("positions", positions);
				s.ArrayFloat("normals", normals);
				s.ArrayFloat("uvs", uvs);
				s.ArrayInt32("colors", colors);
				s.ArrayFloat("tangents", tangents);

				for (int32 i = 0; i < vertexCount; i++)
				{
					var v = StaticMeshVertex();
					if (i * 3 + 2 < positions.Count)
						v.Position = Vector3(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]);
					if (i * 3 + 2 < normals.Count)
						v.Normal = Vector3(normals[i * 3], normals[i * 3 + 1], normals[i * 3 + 2]);
					if (i * 2 + 1 < uvs.Count)
						v.TexCoord = Vector2(uvs[i * 2], uvs[i * 2 + 1]);
					if (i < colors.Count)
						v.Color = (uint32)colors[i];
					if (i * 3 + 2 < tangents.Count)
						v.Tangent = Vector3(tangents[i * 3], tangents[i * 3 + 1], tangents[i * 3 + 2]);
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
					mesh.SetIndex(i, (uint32)indices[i]);
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

			SetMesh(mesh, true);
		}

		return .Ok;
	}

	/// Creates a cube mesh resource.
	public static StaticMeshResource CreateCube(float size = 1.0f)
	{
		let mesh = MeshBuilder.CreateCube(size);
		return new StaticMeshResource(mesh, true);
	}

	/// Creates a sphere mesh resource.
	public static StaticMeshResource CreateSphere(float radius = 0.5f, int32 segments = 32, int32 rings = 16)
	{
		let mesh = MeshBuilder.CreateSphere(radius, segments, rings);
		return new StaticMeshResource(mesh, true);
	}

	/// Creates a plane mesh resource.
	public static StaticMeshResource CreatePlane(float width = 1.0f, float height = 1.0f, int32 segmentsX = 1, int32 segmentsZ = 1)
	{
		let mesh = MeshBuilder.CreatePlane(width, height, segmentsX, segmentsZ);
		return new StaticMeshResource(mesh, true);
	}

	/// Creates a cylinder mesh resource.
	public static StaticMeshResource CreateCylinder(float radius = 0.5f, float height = 1.0f, int32 segments = 32)
	{
		let mesh = MeshBuilder.CreateCylinder(radius, height, segments);
		return new StaticMeshResource(mesh, true);
	}
}
