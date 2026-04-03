using System;

namespace Sedulous.Models;

/// Defines a portion of a mesh that uses a specific material
public struct ModelMeshPart
{
	/// Starting index in the index buffer
	public int32 IndexStart;

	/// Number of indices in this part
	public int32 IndexCount;

	/// Material index (-1 for no material)
	public int32 MaterialIndex;

	public this(int32 indexStart, int32 indexCount, int32 materialIndex = -1)
	{
		IndexStart = indexStart;
		IndexCount = indexCount;
		MaterialIndex = materialIndex;
	}
}
