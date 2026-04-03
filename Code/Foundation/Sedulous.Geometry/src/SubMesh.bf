namespace Sedulous.Geometry;

/// Defines a portion of a mesh with its own material
public struct SubMesh
{
	public int32 startIndex;
	public int32 indexCount;
	public int32 materialIndex;
	public PrimitiveType primitiveType;

	public this(int32 startIndex, int32 indexCount, int32 materialIndex = 0, PrimitiveType primitiveType = .Triangles)
	{
		this.startIndex = startIndex;
		this.indexCount = indexCount;
		this.materialIndex = materialIndex;
		this.primitiveType = primitiveType;
	}
}
