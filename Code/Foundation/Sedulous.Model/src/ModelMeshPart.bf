namespace Sedulous.Model;

/// A range of a mesh's index buffer drawn with one material.
struct ModelMeshPart
{
	public int32 IndexStart;
	public int32 IndexCount;
	/// Index into the model's materials, or -1 for none.
	public int32 MaterialIndex = -1;

	public this() { IndexStart = 0; IndexCount = 0; MaterialIndex = -1; }

	public this(int32 indexStart, int32 indexCount, int32 materialIndex = -1)
	{
		IndexStart = indexStart; IndexCount = indexCount; MaterialIndex = materialIndex;
	}
}
