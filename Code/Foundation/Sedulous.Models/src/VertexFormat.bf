using System;

namespace Sedulous.Models;

/// Vertex element semantic types
public enum VertexSemantic
{
	Position,
	Normal,
	TexCoord,
	Color,
	Tangent,
	Joints,
	Weights
}

/// Vertex element data formats
public enum VertexElementFormat
{
	Float,
	Float2,
	Float3,
	Float4,
	Byte4,
	UShort2,
	UShort4
}

/// Describes a single element in a vertex format
public struct VertexElement
{
	public VertexSemantic Semantic;
	public VertexElementFormat Format;
	public int32 Offset;
	public int32 SemanticIndex; // For multiple UV channels, etc.

	public this(VertexSemantic semantic, VertexElementFormat format, int32 offset, int32 semanticIndex = 0)
	{
		Semantic = semantic;
		Format = format;
		Offset = offset;
		SemanticIndex = semanticIndex;
	}

	/// Get the size of this element in bytes
	public int32 Size
	{
		get
		{
			switch (Format)
			{
			case .Float: return 4;
			case .Float2: return 8;
			case .Float3: return 12;
			case .Float4: return 16;
			case .Byte4: return 4;
			case .UShort2: return 4;
			case .UShort4: return 8;
			}
		}
	}
}
