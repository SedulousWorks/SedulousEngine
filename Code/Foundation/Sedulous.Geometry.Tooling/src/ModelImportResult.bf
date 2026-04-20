using System;
using System.Collections;
using Sedulous.Geometry;
using Sedulous.Animation;

namespace Sedulous.Geometry.Tooling;

/// Result of importing a model, containing all extracted data.
/// Uses direct data types - no resource system dependency.
/// Caller takes ownership of all data.
class ModelImportResult
{
	/// Imported static meshes.
	public List<StaticMesh> StaticMeshes = new .() ~ DeleteContainerAndItems!(_);

	/// Imported skinned meshes.
	public List<SkinnedMesh> SkinnedMeshes = new .() ~ DeleteContainerAndItems!(_);

	/// Imported skeletons.
	public List<Skeleton> Skeletons = new .() ~ DeleteContainerAndItems!(_);

	/// Imported textures (pixel data + name).
	public List<ImportedTexture> Textures = new .() ~ DeleteContainerAndItems!(_);

	/// Imported materials (PBR properties + texture references).
	public List<ImportedMaterial> Materials = new .() ~ DeleteContainerAndItems!(_);

	/// Imported animation clips.
	public List<AnimationClip> Animations = new .() ~ DeleteContainerAndItems!(_);

	/// Errors encountered during import.
	public List<String> Errors = new .() ~ DeleteContainerAndItems!(_);

	/// Warnings encountered during import.
	public List<String> Warnings = new .() ~ DeleteContainerAndItems!(_);

	/// Whether the import completed successfully (no errors).
	public bool Success => Errors.Count == 0;

	/// Total number of resources imported.
	public int TotalCount =>
		StaticMeshes.Count + SkinnedMeshes.Count + Skeletons.Count +
		Textures.Count + Materials.Count + Animations.Count;

	/// Add an error message.
	public void AddError(StringView message)
	{
		Errors.Add(new String(message));
	}

	/// Add a warning message.
	public void AddWarning(StringView message)
	{
		Warnings.Add(new String(message));
	}

	/// Find a static mesh by name.
	public StaticMesh FindStaticMesh(StringView name)
	{
		for (let mesh in StaticMeshes)
			if (mesh.Name == name)
				return mesh;
		return null;
	}

	/// Find a skinned mesh by name.
	public SkinnedMesh FindSkinnedMesh(StringView name)
	{
		for (let mesh in SkinnedMeshes)
			if (mesh.Name == name)
				return mesh;
		return null;
	}

	/// Find a skeleton by name.
	public Skeleton FindSkeleton(StringView name)
	{
		for (let skeleton in Skeletons)
			if (skeleton.Name == name)
				return skeleton;
		return null;
	}

	/// Find a texture by name.
	public ImportedTexture FindTexture(StringView name)
	{
		for (let texture in Textures)
			if (texture.Name == name)
				return texture;
		return null;
	}

	/// Find a material by name.
	public ImportedMaterial FindMaterial(StringView name)
	{
		for (let mat in Materials)
			if (mat.Name == name)
				return mat;
		return null;
	}

	/// Find an animation by name.
	public AnimationClip FindAnimation(StringView name)
	{
		for (let anim in Animations)
			if (anim.Name == name)
				return anim;
		return null;
	}
}
