namespace Sedulous.Engine.Navigation;

using System;
using Sedulous.Core.Mathematics;

/// Interface for input geometry providers.
interface IInputGeometryProvider
{
	/// Gets the vertex data (float[3] per vertex).
	float* Vertices { get; }

	/// Gets the number of vertices.
	int32 VertexCount { get; }

	/// Gets the triangle indices (int32[3] per triangle).
	int32* Triangles { get; }

	/// Gets the number of triangles.
	int32 TriangleCount { get; }

	/// Gets the bounding box.
	BoundingBox Bounds { get; }
}

/// Simple input geometry holder.
class InputGeometry : IInputGeometryProvider
{
	private float[] mVertices ~ delete _;
	private int32[] mTriangles ~ delete _;
	private int32 mVertexCount;
	private int32 mTriangleCount;
	private BoundingBox mBounds;

	/// Creates input geometry from vertex and triangle data.
	public this(Span<float> vertices, Span<int32> triangles)
	{
		mVertexCount = (int32)(vertices.Length / 3);
		mTriangleCount = (int32)(triangles.Length / 3);

		mVertices = new float[vertices.Length];
		vertices.CopyTo(mVertices);

		mTriangles = new int32[triangles.Length];
		triangles.CopyTo(mTriangles);

		CalculateBounds();
	}

	/// Creates input geometry from vertex and triangle arrays.
	public this(float[] vertices, int32[] triangles)
	{
		mVertexCount = (int32)(vertices.Count / 3);
		mTriangleCount = (int32)(triangles.Count / 3);

		mVertices = new float[vertices.Count];
		Internal.MemCpy(&mVertices[0], &vertices[0], vertices.Count * sizeof(float));

		mTriangles = new int32[triangles.Count];
		Internal.MemCpy(&mTriangles[0], &triangles[0], triangles.Count * sizeof(int32));

		CalculateBounds();
	}

	public float* Vertices => &mVertices[0];
	public int32 VertexCount => mVertexCount;
	public int32* Triangles => &mTriangles[0];
	public int32 TriangleCount => mTriangleCount;
	public BoundingBox Bounds => mBounds;

	private void CalculateBounds()
	{
		if (mVertexCount == 0)
		{
			mBounds = BoundingBox(Vector3.Zero, Vector3.Zero);
			return;
		}

		Vector3 min = Vector3(float.MaxValue);
		Vector3 max = Vector3(float.MinValue);

		for (int32 i = 0; i < mVertexCount; i++)
		{
			float x = mVertices[i * 3 + 0];
			float y = mVertices[i * 3 + 1];
			float z = mVertices[i * 3 + 2];

			min.X = Math.Min(min.X, x);
			min.Y = Math.Min(min.Y, y);
			min.Z = Math.Min(min.Z, z);

			max.X = Math.Max(max.X, x);
			max.Y = Math.Max(max.Y, y);
			max.Z = Math.Max(max.Z, z);
		}

		mBounds = BoundingBox(min, max);
	}
}
