using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Model;

/// A whole imported model: meshes, materials, bones, skins, animations and textures.
///
/// This is the IMPORTER's representation of a file, not the engine's runtime form. A
/// converter turns it into runtime meshes; keeping the two apart is what lets the importer
/// carry things the runtime has no use for, such as the file's original up axis.
///
/// The model OWNS everything in it. Bones reference each other as a tree, but that tree is
/// shape rather than ownership.
class Model
{
	public String Name = new .() ~ delete _;

	private List<ModelMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<ModelMaterial> mMaterials = new .() ~ DeleteContainerAndItems!(_);
	private List<ModelBone> mBones = new .() ~ DeleteContainerAndItems!(_);
	private List<ModelSkin> mSkins = new .() ~ DeleteContainerAndItems!(_);
	private List<ModelAnimation> mAnimations = new .() ~ DeleteContainerAndItems!(_);
	private List<ModelTexture> mTextures = new .() ~ DeleteContainerAndItems!(_);
	private List<TextureSampler> mSamplers = new .() ~ delete _;

	/// The root of the bone hierarchy, or -1 when there is none.
	public int32 RootBoneIndex = -1;

	/// The up axis the SOURCE file used. Kept so a later stage can stand a Z up model up
	/// without guessing which way it was meant to face.
	public CoordinateAxis OriginalUpAxis = .PositiveY;

	public AABB Bounds;

	public Span<ModelMesh> Meshes => .(mMeshes.Ptr, mMeshes.Count);
	public Span<ModelMaterial> Materials => .(mMaterials.Ptr, mMaterials.Count);
	public Span<ModelBone> Bones => .(mBones.Ptr, mBones.Count);
	public Span<ModelSkin> Skins => .(mSkins.Ptr, mSkins.Count);
	public Span<ModelAnimation> Animations => .(mAnimations.Ptr, mAnimations.Count);
	public Span<ModelTexture> Textures => .(mTextures.Ptr, mTextures.Count);
	public Span<TextureSampler> Samplers => .(mSamplers.Ptr, mSamplers.Count);

	// Adding TAKES OWNERSHIP in every case, and every one returns the INDEX the thing
	// landed at. A model refers to its own parts by index throughout (a mesh part names a
	// material, a texture names a sampler, a bone names its parent), so a loader that adds
	// something and then has to point at it needs the index back rather than counting.
	public int32 AddMesh(ModelMesh mesh)
	{
		let index = (int32)mMeshes.Count;
		mMeshes.Add(mesh);
		return index;
	}

	public int32 AddMaterial(ModelMaterial material)
	{
		let index = (int32)mMaterials.Count;
		mMaterials.Add(material);
		return index;
	}

	/// Also STAMPS the bone with its index, which is what everything downstream reads:
	/// BuildBoneHierarchy takes the root from it, a skin's joints are bone indices, and an
	/// animation channel names the bone it drives by index.
	public int32 AddBone(ModelBone bone)
	{
		let index = (int32)mBones.Count;
		bone.Index = index;
		mBones.Add(bone);
		return index;
	}

	public int32 AddSkin(ModelSkin skin)
	{
		let index = (int32)mSkins.Count;
		mSkins.Add(skin);
		return index;
	}

	public int32 AddAnimation(ModelAnimation animation)
	{
		let index = (int32)mAnimations.Count;
		mAnimations.Add(animation);
		return index;
	}

	public int32 AddTexture(ModelTexture texture)
	{
		let index = (int32)mTextures.Count;
		mTextures.Add(texture);
		return index;
	}

	public int32 AddSampler(TextureSampler sampler)
	{
		let index = (int32)mSamplers.Count;
		mSamplers.Add(sampler);
		return index;
	}

	/// The bounds of every mesh together. Each mesh's own bounds have to be current first.
	public void CalculateBounds()
	{
		if (mMeshes.IsEmpty)
		{
			Bounds = .(Float3.Zero, Float3.Zero);
			return;
		}

		var min = Float3(FloatMax, FloatMax, FloatMax);
		var max = Float3(-FloatMax, -FloatMax, -FloatMax);

		for (let mesh in mMeshes)
		{
			min = Min(min, mesh.Bounds.Min);
			max = Max(max, mesh.Bounds.Max);
		}

		Bounds = .(min, max);
	}

	/// Rebuilds the child links from the parent indices, and finds the root.
	///
	/// Rebuilt rather than maintained, because an importer sets parent indices as it reads
	/// nodes and cannot link a child to a parent it has not seen yet.
	public void BuildBoneHierarchy()
	{
		for (let bone in mBones)
			bone.ClearChildren();

		for (let bone in mBones)
		{
			// A parent index outside the list is bad data. Treated as a root rather than
			// followed, so a malformed file gives a flat skeleton instead of an
			// out of range read.
			if ((bone.ParentIndex >= 0) && (bone.ParentIndex < (int32)mBones.Count))
				mBones[bone.ParentIndex].AddChild(bone);
			else if (bone.ParentIndex < 0)
				RootBoneIndex = bone.Index;
		}
	}

	public ModelMesh GetMesh(StringView name)
	{
		for (let mesh in mMeshes)
		{
			if (mesh.Name == name)
				return mesh;
		}
		return null;
	}

	public ModelMaterial GetMaterial(StringView name)
	{
		for (let material in mMaterials)
		{
			if (material.Name == name)
				return material;
		}
		return null;
	}

	public ModelBone GetBone(StringView name)
	{
		for (let bone in mBones)
		{
			if (bone.Name == name)
				return bone;
		}
		return null;
	}

	public ModelAnimation GetAnimation(StringView name)
	{
		for (let animation in mAnimations)
		{
			if (animation.Name == name)
				return animation;
		}
		return null;
	}
}
