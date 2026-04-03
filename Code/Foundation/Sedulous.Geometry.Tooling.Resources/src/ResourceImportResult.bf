using System;
using System.Collections;
using Sedulous.Animation.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Geometry;
using Sedulous.Animation;
using Sedulous.Geometry.Tooling;

namespace Sedulous.Geometry.Tooling.Resources;

/// Resource-wrapped version of ModelImportResult.
/// Created by ResourceSerializer.SaveImportResult or ConvertToResources.
/// Holds resource wrappers with assigned GUIDs for registry building.
/// The resource wrappers do NOT own the underlying data (non-owning mode).
class ResourceImportResult
{
	/// Static mesh resources (non-owning wrappers).
	public List<StaticMeshResource> StaticMeshes = new .() ~ DeleteContainerAndItems!(_);

	/// Skinned mesh resources (non-owning wrappers).
	public List<SkinnedMeshResource> SkinnedMeshes = new .() ~ DeleteContainerAndItems!(_);

	/// Skeleton resources (non-owning wrappers).
	public List<SkeletonResource> Skeletons = new .() ~ DeleteContainerAndItems!(_);

	/// Texture resources (non-owning wrappers).
	public List<TextureResource> Textures = new .() ~ DeleteContainerAndItems!(_);

	/// Material resources (owning — these are newly created from ImportedMaterial).
	public List<MaterialResource> Materials = new .() ~ DeleteContainerAndItems!(_);

	/// Animation clip resources (non-owning wrappers).
	public List<AnimationClipResource> Animations = new .() ~ DeleteContainerAndItems!(_);

	/// Creates a ResourceImportResult from a ModelImportResult.
	/// The resource wrappers are non-owning (the ModelImportResult still owns the data).
	/// Materials are converted from ImportedMaterial to MaterialResource (owning).
	public static ResourceImportResult ConvertFrom(ModelImportResult result)
	{
		let res = new ResourceImportResult();

		// Convert textures first (materials need texture GUIDs)
		for (let tex in result.Textures)
		{
			let texRes = TextureResourceConverter.Convert(tex);
			if (texRes != null)
				res.Textures.Add(texRes);
		}

		// Convert materials using texture resources for GUIDs
		for (let mat in result.Materials)
		{
			let matRes = MaterialResourceConverter.Convert(mat, res.Textures);
			if (matRes != null)
				res.Materials.Add(matRes);
		}

		// Wrap static meshes
		for (let mesh in result.StaticMeshes)
		{
			let meshRes = new StaticMeshResource(mesh, false);
			meshRes.Name.Set(mesh.Name);
			res.StaticMeshes.Add(meshRes);
		}

		// Wrap skinned meshes
		for (let mesh in result.SkinnedMeshes)
		{
			let meshRes = new SkinnedMeshResource(mesh, false);
			meshRes.Name.Set(mesh.Name);

			// Link to skeleton via ResourceRef
			if (mesh.SkeletonIndex >= 0 && mesh.SkeletonIndex < res.Skeletons.Count)
			{
				let skelRes = res.Skeletons[mesh.SkeletonIndex];
				meshRes.SkeletonRef = Sedulous.Resources.ResourceRef(skelRes.Id, skelRes.Name);
			}

			res.SkinnedMeshes.Add(meshRes);
		}

		// Wrap skeletons
		for (let skeleton in result.Skeletons)
		{
			let skelRes = new SkeletonResource(skeleton, false);
			skelRes.Name.Set(skeleton.Name);
			res.Skeletons.Add(skelRes);
		}

		// Wrap animations
		for (let animation in result.Animations)
		{
			let animRes = new AnimationClipResource(animation, false);
			res.Animations.Add(animRes);
		}

		return res;
	}

	/// Take ownership of a skinned mesh resource (removes from this result).
	public SkinnedMeshResource TakeSkinnedMesh(int index)
	{
		if (index < 0 || index >= SkinnedMeshes.Count)
			return null;
		let mesh = SkinnedMeshes[index];
		SkinnedMeshes.RemoveAt(index);
		return mesh;
	}

	/// Take ownership of a static mesh resource (removes from this result).
	public StaticMeshResource TakeStaticMesh(int index)
	{
		if (index < 0 || index >= StaticMeshes.Count)
			return null;
		let mesh = StaticMeshes[index];
		StaticMeshes.RemoveAt(index);
		return mesh;
	}

	/// Take ownership of a skeleton resource (removes from this result).
	public SkeletonResource TakeSkeleton(int index)
	{
		if (index < 0 || index >= Skeletons.Count)
			return null;
		let skeleton = Skeletons[index];
		Skeletons.RemoveAt(index);
		return skeleton;
	}

	/// Take ownership of a texture resource (removes from this result).
	public TextureResource TakeTexture(int index)
	{
		if (index < 0 || index >= Textures.Count)
			return null;
		let texture = Textures[index];
		Textures.RemoveAt(index);
		return texture;
	}

	/// Take ownership of an animation resource (removes from this result).
	public AnimationClipResource TakeAnimation(int index)
	{
		if (index < 0 || index >= Animations.Count)
			return null;
		let anim = Animations[index];
		Animations.RemoveAt(index);
		return anim;
	}
}
