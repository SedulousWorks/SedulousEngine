using System;

namespace Sedulous.Geometry.Tooling;

/// Flags controlling what to import from a model.
enum ModelImportFlags
{
	None = 0,
	/// Import static meshes (non-skinned).
	Meshes = 1 << 0,
	/// Import skinned meshes.
	SkinnedMeshes = 1 << 1,
	/// Import skeletons from skins.
	Skeletons = 1 << 2,
	/// Import animations.
	Animations = 1 << 3,
	/// Import textures/images.
	Textures = 1 << 4,
	/// Import materials (as material definitions).
	Materials = 1 << 5,

	/// Import all geometry (meshes + skinned meshes).
	AllGeometry = Meshes | SkinnedMeshes,
	/// Import all animation data (skeletons + animations).
	AllAnimation = Skeletons | Animations,
	/// Import everything.
	All = Meshes | SkinnedMeshes | Skeletons | Animations | Textures | Materials
}

/// Options for model import.
class ModelImportOptions
{
	/// What to import.
	public ModelImportFlags Flags = .All;

	/// Base path for resolving texture file references.
	/// If empty, uses the model file's directory.
	public String BasePath = new .() ~ delete _;

	/// Path of the model file being imported.
	/// Used to construct dedup keys for embedded textures.
	public String ModelPath = new .() ~ delete _;

	/// Scale factor to apply to all geometry.
	public float Scale = 1.0f;

	/// Whether to generate normals if not present.
	public bool GenerateNormals = true;

	/// Whether to generate tangents if not present.
	public bool GenerateTangents = true;

	/// Whether to calculate bounds for meshes.
	public bool CalculateBounds = true;

	/// Whether to flip UV V coordinate (for DirectX-style textures).
	public bool FlipUVs = false;

	/// Whether to merge meshes that share the same material.
	public bool MergeMeshes = false;

	/// Whether to recenter mesh vertices so the bounding box center is at the origin.
	/// Useful for models whose origin is at the bottom instead of the center.
	/// For static meshes, shifts all vertex positions.
	/// For skinned meshes, shifts vertex positions and adjusts skeleton
	/// InverseBindPose and RootCorrection matrices to preserve correct skinning.
	public bool RecenterMeshes = false;

	/// Maximum bones per vertex for skinned meshes.
	public int32 MaxBonesPerVertex = 4;

	/// Create default options importing everything.
	public static ModelImportOptions Default => new .();

	/// Create options for static mesh import only.
	public static ModelImportOptions StaticMeshOnly()
	{
		let opts = new ModelImportOptions();
		opts.Flags = .Meshes | .Textures | .Materials;
		return opts;
	}

	/// Create options for skinned mesh with animations.
	public static ModelImportOptions SkinnedWithAnimations()
	{
		let opts = new ModelImportOptions();
		opts.Flags = .SkinnedMeshes | .Skeletons | .Animations | .Textures | .Materials;
		return opts;
	}
}
