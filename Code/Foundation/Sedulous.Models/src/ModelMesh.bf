using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// Primitive topology
public enum PrimitiveTopology
{
	Triangles,
	TriangleStrip,
	Lines,
	LineStrip,
	Points
}

/// A mesh within a model containing vertex and index data
public class ModelMesh
{
	private String mName ~ delete _;
	private uint8[] mVertexData ~ delete _;
	private uint8[] mIndexData ~ delete _;
	private List<ModelMeshPart> mParts ~ delete _;
	private List<VertexElement> mVertexElements ~ delete _;

	private int32 mVertexCount;
	private int32 mVertexStride;
	private int32 mIndexCount;
	private bool mUse32BitIndices;
	private PrimitiveTopology mTopology = .Triangles;
	private BoundingBox mBounds;

	/// Whether the source data contained normals (vs. synthesized defaults)
	private bool mHasNormals = false;
	/// Whether the source data contained tangents (vs. synthesized defaults)
	private bool mHasTangents = false;

	public StringView Name => mName;
	public int32 VertexCount => mVertexCount;
	public int32 VertexStride => mVertexStride;
	public int32 IndexCount => mIndexCount;
	public bool Use32BitIndices => mUse32BitIndices;
	public PrimitiveTopology Topology => mTopology;
	public BoundingBox Bounds => mBounds;
	public List<ModelMeshPart> Parts => mParts;
	public List<VertexElement> VertexElements => mVertexElements;
	/// Whether the source data contained normals
	public bool HasNormals => mHasNormals;
	/// Whether the source data contained tangents
	public bool HasTangents => mHasTangents;

	public this()
	{
		mName = new String();
		mParts = new List<ModelMeshPart>();
		mVertexElements = new List<VertexElement>();
		mBounds = BoundingBox(.Zero, .Zero);
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	public void SetTopology(PrimitiveTopology topology)
	{
		mTopology = topology;
	}

	/// Set whether source data contained normals
	public void SetHasNormals(bool value)
	{
		mHasNormals = value;
	}

	/// Set whether source data contained tangents
	public void SetHasTangents(bool value)
	{
		mHasTangents = value;
	}

	/// Add a vertex element descriptor
	public void AddVertexElement(VertexElement element)
	{
		mVertexElements.Add(element);
	}

	/// Allocate vertex buffer
	public void AllocateVertices(int32 count, int32 stride)
	{
		mVertexCount = count;
		mVertexStride = stride;

		delete mVertexData;
		mVertexData = new uint8[count * stride];
	}

	/// Allocate index buffer
	public void AllocateIndices(int32 count, bool use32Bit)
	{
		mIndexCount = count;
		mUse32BitIndices = use32Bit;

		int32 indexSize = use32Bit ? 4 : 2;
		delete mIndexData;
		mIndexData = new uint8[count * indexSize];
	}

	/// Get raw vertex data pointer
	public uint8* GetVertexData()
	{
		if (mVertexData == null || mVertexData.Count == 0)
			return null;
		return &mVertexData[0];
	}

	/// Get raw index data pointer
	public uint8* GetIndexData()
	{
		if (mIndexData == null || mIndexData.Count == 0)
			return null;
		return &mIndexData[0];
	}

	/// Get vertex data size in bytes
	public int32 GetVertexDataSize() => mVertexCount * mVertexStride;

	/// Get index data size in bytes
	public int32 GetIndexDataSize() => mIndexCount * (mUse32BitIndices ? 4 : 2);

	/// Set vertex data from typed array
	public void SetVertexData<T>(T[] data) where T : struct
	{
		if (mVertexData == null || data.Count * sizeof(T) > mVertexData.Count)
			return;

		Internal.MemCpy(&mVertexData[0], &data[0], data.Count * sizeof(T));
	}

	/// Set index data from uint16 array
	public void SetIndexData(uint16[] indices)
	{
		if (mIndexData == null || !mUse32BitIndices)
		{
			if (mIndexData != null && indices.Count * 2 <= mIndexData.Count)
			{
				Internal.MemCpy(&mIndexData[0], &indices[0], indices.Count * 2);
			}
		}
	}

	/// Set index data from uint32 array
	public void SetIndexData(uint32[] indices)
	{
		if (mIndexData == null || mUse32BitIndices)
		{
			if (mIndexData != null && indices.Count * 4 <= mIndexData.Count)
			{
				Internal.MemCpy(&mIndexData[0], &indices[0], indices.Count * 4);
			}
		}
	}

	/// Add a mesh part
	public void AddPart(ModelMeshPart part)
	{
		mParts.Add(part);
	}

	/// Set bounds
	public void SetBounds(BoundingBox bounds)
	{
		mBounds = bounds;
	}

	/// Converts a non-skinned mesh into a skinned one by adding uniform bone weighting.
	/// All vertices are assigned to a single joint with weight 1.0.
	/// Expands vertex buffer by 24 bytes/vertex (UShort4 joints + Float4 weights).
	public void AddUniformSkinning(int32 jointIndex)
	{
		// Skip if mesh already has joint data
		for (let element in mVertexElements)
			if (element.Semantic == .Joints)
				return;

		if (mVertexData == null || mVertexCount == 0)
			return;

		int32 oldStride = mVertexStride;
		int32 newStride = oldStride + 24; // +8 (UShort4) +16 (Float4)
		let newData = new uint8[mVertexCount * newStride];

		for (int32 i = 0; i < mVertexCount; i++)
		{
			int32 srcOffset = i * oldStride;
			int32 dstOffset = i * newStride;

			// Copy existing vertex data
			Internal.MemCpy(&newData[dstOffset], &mVertexData[srcOffset], oldStride);

			// Write joints: uint16[4] = (jointIndex, 0, 0, 0)
			uint16* joints = (uint16*)&newData[dstOffset + oldStride];
			joints[0] = (uint16)jointIndex;
			joints[1] = 0;
			joints[2] = 0;
			joints[3] = 0;

			// Write weights: float[4] = (1, 0, 0, 0)
			float* weights = (float*)&newData[dstOffset + oldStride + 8];
			weights[0] = 1.0f;
			weights[1] = 0.0f;
			weights[2] = 0.0f;
			weights[3] = 0.0f;
		}

		delete mVertexData;
		mVertexData = newData;
		mVertexStride = newStride;

		mVertexElements.Add(VertexElement(.Joints, .UShort4, oldStride));
		mVertexElements.Add(VertexElement(.Weights, .Float4, oldStride + 8));
	}

	/// Scales vertex positions by a non-uniform scale vector.
	public void ScalePositions(Vector3 scale)
	{
		int32 posOffset = -1;
		for (let element in mVertexElements)
		{
			if (element.Semantic == .Position)
			{
				posOffset = element.Offset;
				break;
			}
		}
		if (posOffset < 0 || mVertexData == null)
			return;

		for (int32 i = 0; i < mVertexCount; i++)
		{
			int32 offset = i * mVertexStride + posOffset;
			Vector3* pos = (Vector3*)&mVertexData[offset];
			pos.X *= scale.X;
			pos.Y *= scale.Y;
			pos.Z *= scale.Z;
		}
	}

	/// Remaps vertex joint indices using the provided mapping array.
	/// remap[oldJointIndex] = newJointIndex.
	public void RemapJointIndices(int32[] remap)
	{
		int32 jointsOffset = -1;
		for (let element in mVertexElements)
		{
			if (element.Semantic == .Joints)
			{
				jointsOffset = element.Offset;
				break;
			}
		}
		if (jointsOffset < 0 || mVertexData == null)
			return;

		for (int32 i = 0; i < mVertexCount; i++)
		{
			int32 offset = i * mVertexStride + jointsOffset;
			uint16* joints = (uint16*)&mVertexData[offset];
			for (int j = 0; j < 4; j++)
			{
				let oldIdx = (int32)joints[j];
				if (oldIdx >= 0 && oldIdx < remap.Count)
					joints[j] = (uint16)remap[oldIdx];
			}
		}
	}

	/// Calculate bounds from position data
	public void CalculateBounds()
	{
		if (mVertexData == null || mVertexCount == 0)
		{
			mBounds = BoundingBox(.Zero, .Zero);
			return;
		}

		// Find position element
		int32 posOffset = -1;
		for (let element in mVertexElements)
		{
			if (element.Semantic == .Position)
			{
				posOffset = element.Offset;
				break;
			}
		}

		if (posOffset < 0)
		{
			mBounds = BoundingBox(.Zero, .Zero);
			return;
		}

		var min = Vector3(float.MaxValue);
		var max = Vector3(float.MinValue);

		for (int32 i = 0; i < mVertexCount; i++)
		{
			int32 offset = i * mVertexStride + posOffset;
			Vector3 pos = default;
			Internal.MemCpy(&pos, &mVertexData[offset], sizeof(Vector3));

			min = Vector3.Min(min, pos);
			max = Vector3.Max(max, pos);
		}

		mBounds = BoundingBox(min, max);
	}
}
