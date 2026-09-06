namespace Sedulous.Geometry;

/// A contiguous index range with its own material and topology.
struct SubMesh
{
	public int32 StartIndex;
	public int32 IndexCount;
	public int32 MaterialIndex;
	public PrimitiveType Primitive = .Triangles;

	public this() { StartIndex = 0; IndexCount = 0; MaterialIndex = 0; Primitive = .Triangles; }

	public this(int32 startIndex, int32 indexCount, int32 materialIndex, PrimitiveType primitive)
	{
		StartIndex = startIndex;
		IndexCount = indexCount;
		MaterialIndex = materialIndex;
		Primitive = primitive;
	}
}
