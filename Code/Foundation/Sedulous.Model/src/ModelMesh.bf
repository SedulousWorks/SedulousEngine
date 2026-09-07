using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Model;

/// A mesh as an importer read it: raw vertex and index bytes, a layout describing them,
/// and the parts that split them by material.
///
/// Deliberately untyped. A model file decides its own vertex layout, so the buffer is
/// bytes plus a VertexElement list rather than an array of some fixed struct. The
/// converter into the engine's runtime mesh is what imposes a layout.
class ModelMesh
{
	public String Name = new .() ~ delete _;

	private List<uint8> mVertexData = new .() ~ delete _;
	private List<uint8> mIndexData = new .() ~ delete _;
	private List<ModelMeshPart> mParts = new .() ~ delete _;
	private List<VertexElement> mVertexElements = new .() ~ delete _;

	private int32 mVertexCount;
	private int32 mVertexStride;
	private int32 mIndexCount;
	private bool mUse32BitIndices;

	public PrimitiveTopology Topology = .Triangles;
	public AABB Bounds;
	public bool HasNormals;
	public bool HasTangents;

	public int32 VertexCount => mVertexCount;
	public int32 VertexStride => mVertexStride;
	public int32 IndexCount => mIndexCount;
	public bool Use32BitIndices => mUse32BitIndices;

	public Span<ModelMeshPart> Parts => .(mParts.Ptr, mParts.Count);
	public Span<VertexElement> VertexElements => .(mVertexElements.Ptr, mVertexElements.Count);

	public void AddPart(ModelMeshPart part) => mParts.Add(part);
	public void AddVertexElement(VertexElement element) => mVertexElements.Add(element);

	// ---- vertex data ----

	public void AllocateVertices(int32 count, int32 stride)
	{
		mVertexCount = count;
		mVertexStride = stride;
		mVertexData.Clear();
		mVertexData.Resize((int)count * (int)stride);
	}

	/// The raw bytes, or null when there are none.
	public uint8* VertexData => mVertexData.IsEmpty ? null : mVertexData.Ptr;
	public int32 VertexDataSize => mVertexCount * mVertexStride;

	/// Copies bytes into the vertex buffer. Refused rather than truncated when they do not
	/// fit: a partly written vertex buffer draws garbage.
	public bool SetVertexData(Span<uint8> data)
	{
		if (mVertexData.IsEmpty || (data.Length > mVertexData.Count))
			return false;
		Internal.MemCpy(mVertexData.Ptr, data.Ptr, data.Length);
		return true;
	}

	// ---- index data ----

	public void AllocateIndices(int32 count, bool use32Bit)
	{
		mIndexCount = count;
		mUse32BitIndices = use32Bit;
		mIndexData.Clear();
		mIndexData.Resize((int)count * (use32Bit ? 4 : 2));
	}

	public uint8* IndexData => mIndexData.IsEmpty ? null : mIndexData.Ptr;
	public int32 IndexDataSize => mIndexCount * (mUse32BitIndices ? 4 : 2);

	/// Copies 16 bit indices in. Refused when the buffer was allocated for 32 bit ones,
	/// because writing them anyway would halve the index count silently.
	public bool SetIndexData(Span<uint16> indices)
	{
		let bytes = indices.Length * 2;
		if (mIndexData.IsEmpty || mUse32BitIndices || (bytes > mIndexData.Count))
			return false;
		Internal.MemCpy(mIndexData.Ptr, indices.Ptr, bytes);
		return true;
	}

	public bool SetIndexData(Span<uint32> indices)
	{
		let bytes = indices.Length * 4;
		if (mIndexData.IsEmpty || !mUse32BitIndices || (bytes > mIndexData.Count))
			return false;
		Internal.MemCpy(mIndexData.Ptr, indices.Ptr, bytes);
		return true;
	}

	// ---- skinning helpers ----

	/// Turns a non skinned mesh into a skinned one by binding every vertex to one joint at
	/// full weight.
	///
	/// For a model whose mesh is rigid but which has to travel through the skinned path
	/// anyway, such as a prop parented to a hand. Widens every vertex by 24 bytes.
	///
	/// Does nothing to a mesh that already has joints: it would double the skinning data
	/// and leave the second copy unread.
	public void AddUniformSkinning(int32 jointIndex)
	{
		for (let element in mVertexElements)
		{
			if (element.Semantic == .Joints)
				return;
		}
		if (mVertexData.IsEmpty || (mVertexCount == 0))
			return;

		let oldStride = mVertexStride;
		let newStride = oldStride + 24; // uint16[4] joints, then Float4 weights

		let widened = scope List<uint8>();
		widened.Resize((int)mVertexCount * (int)newStride);

		for (int32 i < mVertexCount)
		{
			let source = (int)i * (int)oldStride;
			let destination = (int)i * (int)newStride;

			Internal.MemCpy(widened.Ptr + destination, mVertexData.Ptr + source, oldStride);

			let joints = (uint16*)(widened.Ptr + destination + oldStride);
			joints[0] = (uint16)jointIndex;
			joints[1] = 0;
			joints[2] = 0;
			joints[3] = 0;

			let weights = (float*)(widened.Ptr + destination + oldStride + 8);
			weights[0] = 1.0f;
			weights[1] = 0.0f;
			weights[2] = 0.0f;
			weights[3] = 0.0f;
		}

		mVertexData.Clear();
		mVertexData.AddRange(widened);
		mVertexStride = newStride;

		mVertexElements.Add(.(.Joints, .UShort4, oldStride));
		mVertexElements.Add(.(.Weights, .Float4, oldStride + 8));
	}

	/// Scales every vertex position, for a file authored in different units.
	public void ScalePositions(Float3 scale)
	{
		let offset = OffsetOf(.Position);
		if ((offset < 0) || mVertexData.IsEmpty)
			return;

		for (int32 i < mVertexCount)
		{
			let position = (Float3*)(mVertexData.Ptr + (int)i * (int)mVertexStride + offset);
			position.X *= scale.X;
			position.Y *= scale.Y;
			position.Z *= scale.Z;
		}
	}

	/// Rewrites joint indices through a mapping, where remap[old] is the new index.
	///
	/// Needed whenever a skeleton is rebuilt or merged: the vertices still name the old
	/// joints, and left alone they would animate to whatever now sits at those indices.
	public void RemapJointIndices(Span<int32> remap)
	{
		let offset = OffsetOf(.Joints);
		if ((offset < 0) || mVertexData.IsEmpty)
			return;

		for (int32 i < mVertexCount)
		{
			let joints = (uint16*)(mVertexData.Ptr + (int)i * (int)mVertexStride + offset);
			for (int j < 4)
			{
				let old = (int)joints[j];
				// An index outside the mapping is left alone rather than remapped to
				// nothing: the vertex keeps pointing where it did, which is wrong in a way
				// someone can see instead of silently binding to joint zero.
				if ((old >= 0) && (old < remap.Length))
					joints[j] = (uint16)remap[old];
			}
		}
	}

	/// Recomputes the bounds from the position element.
	public void CalculateBounds()
	{
		let offset = OffsetOf(.Position);
		if (mVertexData.IsEmpty || (mVertexCount == 0) || (offset < 0))
		{
			Bounds = .(Float3.Zero, Float3.Zero);
			return;
		}

		var min = Float3(FloatMax, FloatMax, FloatMax);
		var max = Float3(-FloatMax, -FloatMax, -FloatMax);

		for (int32 i < mVertexCount)
		{
			Float3 position = default;
			Internal.MemCpy(&position, mVertexData.Ptr + (int)i * (int)mVertexStride + offset, sizeof(Float3));
			min = Min(min, position);
			max = Max(max, position);
		}

		Bounds = .(min, max);
	}

	/// The byte offset of a semantic within a vertex, or -1 when the layout has none.
	public int OffsetOf(VertexSemantic semantic)
	{
		for (let element in mVertexElements)
		{
			if (element.Semantic == semantic)
				return element.Offset;
		}
		return -1;
	}
}
