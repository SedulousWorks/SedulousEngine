using Sedulous.Geometry;
using Sedulous.Materials;

namespace Samples.AnimatedCrowd;

/// One skinned mesh of the character, with the material it draws with.
///
/// A Quaternius character is SEVERAL skinned meshes over one skeleton, so the crowd draws one
/// instanced set per part unless they are merged.
struct SkinnedPart
{
	/// BORROWED from the cooked model, which owns both.
	public StaticMesh Mesh = null;
	public Material Material = null;
	/// Its index into the model's material list, which a merged submesh has to keep.
	public int32 MaterialIndex = -1;

	public this() {}

	public this(StaticMesh mesh, Material material, int32 materialIndex)
	{
		Mesh = mesh;
		Material = material;
		MaterialIndex = materialIndex;
	}
}
