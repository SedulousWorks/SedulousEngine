using System;

namespace Sedulous.Geometry;

/// Describes a vertex attribute within a vertex buffer
public struct VertexAttribute : IDisposable
{
	public String name;
	public AttributeType type;
	public int32 offset;
	public int32 size;

	public this(StringView name, AttributeType type, int32 offset, int32 size)
	{
		this.name = new String(name);
		this.type = type;
		this.offset = offset;
		this.size = size;
	}

	public void Dispose() mut
	{
		delete name;
	}
}
