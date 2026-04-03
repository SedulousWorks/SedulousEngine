using System;
using Sedulous.Core.Mathematics;
using System.Collections;
namespace Sedulous.Geometry;

/// Static vertex format for meshes (48 bytes total)
[CRepr]
public struct StaticMeshVertex
{
	public Vector3 Position;      // 12 bytes - Local space position
	public Vector3 Normal;        // 12 bytes - Surface normal
	public Vector2 TexCoord;      // 8 bytes  - UV coordinates
	public uint32 Color;          // 4 bytes  - Packed RGBA color
	public Vector3 Tangent;       // 12 bytes - Tangent vector
	// Total: 48 bytes

	public this()
	{
		Position = .Zero;
		Normal = Vector3(0, 1, 0);
		TexCoord = .Zero;
		Color = 0xFFFFFFFF; // White
		Tangent = Vector3(1, 0, 0);
	}

	public this(Vector3 position, Vector3 normal, Vector2 texCoord, uint32 color, Vector3 tangent)
	{
		Position = position;
		Normal = normal;
		TexCoord = texCoord;
		Color = color;
		Tangent = tangent;
	}
}

/// Mesh
public class StaticMesh
{
	/// Optional name (for debugging/import).
	public String Name = new .() ~ delete _;
	private List<StaticMeshVertex> mVertices ~ delete _;
	private IndexBuffer mIndices ~ delete _;
	private List<SubMesh> mSubMeshes ~ delete _;
	private BoundingBox mBounds;
	private int32 mIndexWritePos = 0;

	public List<StaticMeshVertex> Vertices => mVertices;
	public IndexBuffer Indices => mIndices;
	public List<SubMesh> SubMeshes => mSubMeshes;
	public BoundingBox Bounds => mBounds;

	public int32 VertexCount => (int32)mVertices.Count;
	public int32 IndexCount => mIndices.IndexCount;
	public int32 VertexSize => sizeof(StaticMeshVertex);

	public this()
	{
		mVertices = new List<StaticMeshVertex>();
		mIndices = new IndexBuffer(.UInt32);
		mSubMeshes = new List<SubMesh>();
		mBounds = BoundingBox(.Zero, .Zero);
	}

	/// Get raw vertex data pointer for GPU upload
	public uint8* GetVertexData()
	{
		if (mVertices.Count == 0)
			return null;
		return (uint8*)mVertices.Ptr;
	}

	/// Get raw index data pointer for GPU upload
	public uint8* GetIndexData()
	{
		if (mIndices.IndexCount == 0)
			return null;
		return mIndices.GetRawData();
	}

	/// Add a vertex
	public void AddVertex(StaticMeshVertex vertex)
	{
		mVertices.Add(vertex);
	}

	/// Set vertex at index
	public void SetVertex(int32 index, StaticMeshVertex vertex)
	{
		mVertices[index] = vertex;
	}

	/// Get vertex at index
	public StaticMeshVertex GetVertex(int32 index)
	{
		return mVertices[index];
	}

	/// Resize vertex buffer
	public void ResizeVertices(int32 count)
	{
		mVertices.Resize(count);
	}

	/// Reserve space for indices
	public void ReserveIndices(int32 count)
	{
		mIndices.Resize(count);
		mIndexWritePos = 0;
	}

	/// Add an index (must call ReserveIndices first)
	public void AddIndex(uint32 index)
	{
		if (mIndexWritePos < mIndices.IndexCount)
		{
			mIndices.SetIndex(mIndexWritePos, index);
			mIndexWritePos++;
		}
	}

	/// Add a triangle (3 indices) - must call ReserveIndices first
	public void AddTriangle(uint32 i0, uint32 i1, uint32 i2)
	{
		AddIndex(i0);
		AddIndex(i1);
		AddIndex(i2);
	}

	/// Set index at position
	public void SetIndex(int32 position, uint32 value)
	{
		mIndices.SetIndex(position, value);
	}

	/// Add a submesh
	public void AddSubMesh(SubMesh subMesh)
	{
		mSubMeshes.Add(subMesh);
	}

	/// Calculate and return bounding box from vertices.
	public BoundingBox GetBounds()
	{
		CalculateBounds();
		return mBounds;
	}

	/// Calculate bounding box from vertices
	public void CalculateBounds()
	{
		if (mVertices.Count == 0)
		{
			mBounds = BoundingBox(.Zero, .Zero);
			return;
		}

		var min = Vector3(float.MaxValue);
		var max = Vector3(float.MinValue);

		for (var vertex in mVertices)
		{
			min = Vector3.Min(min, vertex.Position);
			max = Vector3.Max(max, vertex.Position);
		}

		mBounds = BoundingBox(min, max);
	}

	/// Generate smooth normals from geometry
	public void GenerateNormals()
	{
		if (mVertices.Count == 0)
			return;

		bool hasIndices = mIndices != null && mIndices.IndexCount > 0;
		int32 triangleCount = hasIndices ? mIndices.IndexCount / 3 : (int32)mVertices.Count / 3;

		if (triangleCount == 0)
			return;

		// Initialize normals to zero
		for (int32 i = 0; i < mVertices.Count; i++)
		{
			var v = mVertices[i];
			v.Normal = .Zero;
			mVertices[i] = v;
		}

		// Accumulate face normals for each triangle
		for (int32 t = 0; t < triangleCount; t++)
		{
			int32 i0, i1, i2;
			if (hasIndices)
			{
				i0 = (int32)mIndices.GetIndex(t * 3);
				i1 = (int32)mIndices.GetIndex(t * 3 + 1);
				i2 = (int32)mIndices.GetIndex(t * 3 + 2);
			}
			else
			{
				i0 = t * 3;
				i1 = t * 3 + 1;
				i2 = t * 3 + 2;
			}

			var v0 = mVertices[i0].Position;
			var v1 = mVertices[i1].Position;
			var v2 = mVertices[i2].Position;

			// Calculate face normal from cross product of edges
			var edge1 = v1 - v0;
			var edge2 = v2 - v0;
			var faceNormal = Vector3.Cross(edge1, edge2);

			// Accumulate to each vertex
			var vert0 = mVertices[i0];
			var vert1 = mVertices[i1];
			var vert2 = mVertices[i2];
			vert0.Normal = vert0.Normal + faceNormal;
			vert1.Normal = vert1.Normal + faceNormal;
			vert2.Normal = vert2.Normal + faceNormal;
			mVertices[i0] = vert0;
			mVertices[i1] = vert1;
			mVertices[i2] = vert2;
		}

		// Normalize all normals
		for (int32 i = 0; i < mVertices.Count; i++)
		{
			var v = mVertices[i];
			if (v.Normal.LengthSquared() > 0.0001f)
				v.Normal = Vector3.Normalize(v.Normal);
			else
				v.Normal = Vector3.Up;
			mVertices[i] = v;
		}
	}

	/// Generate tangent vectors for normal mapping
	public void GenerateTangents()
	{
		if (mVertices.Count == 0)
			return;

		bool hasIndices = mIndices != null && mIndices.IndexCount > 0;
		int32 triangleCount = hasIndices ? mIndices.IndexCount / 3 : (int32)mVertices.Count / 3;

		if (triangleCount == 0)
			return;

		// Initialize tangents to zero
		for (int32 i = 0; i < mVertices.Count; i++)
		{
			var v = mVertices[i];
			v.Tangent = .Zero;
			mVertices[i] = v;
		}

		// Calculate tangents for each triangle
		for (int32 t = 0; t < triangleCount; t++)
		{
			int32 i0, i1, i2;
			if (hasIndices)
			{
				i0 = (int32)mIndices.GetIndex(t * 3);
				i1 = (int32)mIndices.GetIndex(t * 3 + 1);
				i2 = (int32)mIndices.GetIndex(t * 3 + 2);
			}
			else
			{
				i0 = t * 3;
				i1 = t * 3 + 1;
				i2 = t * 3 + 2;
			}

			var v0 = mVertices[i0];
			var v1 = mVertices[i1];
			var v2 = mVertices[i2];

			var deltaPos1 = v1.Position - v0.Position;
			var deltaPos2 = v2.Position - v0.Position;
			var deltaUV1 = v1.TexCoord - v0.TexCoord;
			var deltaUV2 = v2.TexCoord - v0.TexCoord;

			float denominator = deltaUV1.X * deltaUV2.Y - deltaUV2.X * deltaUV1.Y;
			Vector3 tangent = .Zero;
			if (Math.Abs(denominator) > 0.0001f)
			{
				float r = 1.0f / denominator;
				tangent = (deltaPos1 * deltaUV2.Y - deltaPos2 * deltaUV1.Y) * r;
			}

			v0.Tangent = v0.Tangent + tangent;
			v1.Tangent = v1.Tangent + tangent;
			v2.Tangent = v2.Tangent + tangent;
			mVertices[i0] = v0;
			mVertices[i1] = v1;
			mVertices[i2] = v2;
		}

		// Normalize and orthogonalize tangents
		for (int32 i = 0; i < mVertices.Count; i++)
		{
			var v = mVertices[i];
			if (v.Tangent.LengthSquared() > 0.0001f)
			{
				// Gram-Schmidt orthogonalization
				v.Tangent = v.Tangent - v.Normal * Vector3.Dot(v.Normal, v.Tangent);
				if (v.Tangent.LengthSquared() > 0.0001f)
					v.Tangent = Vector3.Normalize(v.Tangent);
				else
					v.Tangent = GenerateDefaultTangent(v.Normal);
			}
			else
			{
				v.Tangent = GenerateDefaultTangent(v.Normal);
			}
			mVertices[i] = v;
		}
	}

	private static Vector3 GenerateDefaultTangent(Vector3 normal)
	{
		Vector3 tangent;
		if (Math.Abs(normal.Y) < 0.9f)
			tangent = Vector3.Cross(normal, Vector3.Up);
		else
			tangent = Vector3.Cross(normal, Vector3.Right);

		if (tangent.LengthSquared() > 0.0001f)
			return Vector3.Normalize(tangent);
		return Vector3.Right;
	}

	/// Pack a color from Vector4 (0-1 range) to uint32
	public static uint32 PackColor(Vector4 color)
	{
		uint8 r = (uint8)(Math.Clamp(color.X, 0, 1) * 255);
		uint8 g = (uint8)(Math.Clamp(color.Y, 0, 1) * 255);
		uint8 b = (uint8)(Math.Clamp(color.Z, 0, 1) * 255);
		uint8 a = (uint8)(Math.Clamp(color.W, 0, 1) * 255);
		return (uint32)r | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)a << 24);
	}

	/// Pack a color from Color to uint32
	public static uint32 PackColor(Color color)
	{
		return PackColor(color.ToVector4());
	}
}