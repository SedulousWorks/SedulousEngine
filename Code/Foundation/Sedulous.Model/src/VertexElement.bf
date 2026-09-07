namespace Sedulous.Model;

/// One element of a vertex layout: what it means, how it is stored, and where it sits.
struct VertexElement
{
	public VertexSemantic Semantic = .Position;
	public VertexElementFormat Format = .Float3;
	public int32 Offset;
	/// Distinguishes several of the same semantic, such as a second UV channel.
	public int32 SemanticIndex;

	public this()
	{
		Semantic = .Position; Format = .Float3; Offset = 0; SemanticIndex = 0;
	}

	public this(VertexSemantic semantic, VertexElementFormat format, int32 offset, int32 semanticIndex = 0)
	{
		Semantic = semantic; Format = format; Offset = offset; SemanticIndex = semanticIndex;
	}

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
