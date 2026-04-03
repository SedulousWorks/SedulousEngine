using System;
using System.Collections;

namespace Sedulous.Geometry;

/// Vertex buffer for mesh vertex data
public class VertexBuffer
{
	private uint8[] mData ~ delete _;
	private int32 mVertexSize;
	private int32 mVertexCount;
	private List<VertexAttribute> mAttributes ~ DeleteContainerAndDisposeItems!(_);

	public int32 VertexCount => mVertexCount;
	public int32 VertexSize => mVertexSize;
	public List<VertexAttribute> Attributes => mAttributes;

	public this(int32 vertexSize)
	{
		mVertexSize = vertexSize;
		mVertexCount = 0;
		mAttributes = new List<VertexAttribute>();
	}

	public void Reserve(int32 count)
	{
		int32 newSize = count * mVertexSize;
		if (mData == null || mData.Count < newSize)
		{
			let newData = new uint8[newSize];
			if (mData != null)
			{
				Internal.MemCpy(&newData[0], &mData[0], mData.Count);
				delete mData;
			}
			mData = newData;
		}
	}

	public void Resize(int32 count)
	{
		mVertexCount = count;
		Reserve(count);
	}

	public void AddAttribute(StringView name, AttributeType type, int32 offset, int32 size)
	{
		mAttributes.Add(VertexAttribute(name, type, offset, size));
	}

	public void SetVertexData<T>(int32 vertexIndex, int32 offset, T value) where T : struct
	{
		var value;
		if (vertexIndex >= mVertexCount) return;

		int32 dataOffset = vertexIndex * mVertexSize + offset;
		Internal.MemCpy(&mData[dataOffset], &value, sizeof(T));
	}

	public T GetVertexData<T>(int32 vertexIndex, int32 offset) where T : struct
	{
		T result = default;
		if (vertexIndex < mVertexCount)
		{
			int32 dataOffset = vertexIndex * mVertexSize + offset;
			Internal.MemCpy(&result, &mData[dataOffset], sizeof(T));
		}
		return result;
	}

	public uint8* GetRawData()
	{
		if (mData == null || mData.Count == 0)
			return null;
		return &mData[0];
	}

	public int32 GetDataSize() => mVertexCount * mVertexSize;
}
