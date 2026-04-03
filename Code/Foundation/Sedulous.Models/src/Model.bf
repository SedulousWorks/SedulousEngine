using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// The up axis of a coordinate system, as reported by the source file.
public enum CoordinateAxis
{
	PositiveX,
	NegativeX,
	PositiveY,
	NegativeY,
	PositiveZ,
	NegativeZ,
}

/// A complete 3D model with meshes, materials, skeleton, and animations
public class Model
{
	private String mName ~ delete _;
	private List<ModelMesh> mMeshes ~ DeleteContainerAndItems!(_);
	private List<ModelMaterial> mMaterials ~ DeleteContainerAndItems!(_);
	private List<ModelBone> mBones ~ DeleteContainerAndItems!(_);
	private List<ModelSkin> mSkins ~ DeleteContainerAndItems!(_);
	private List<ModelAnimation> mAnimations ~ DeleteContainerAndItems!(_);
	private List<ModelTexture> mTextures ~ DeleteContainerAndItems!(_);
	private List<TextureSampler> mSamplers ~ delete _;

	private BoundingBox mBounds;

	/// Index of the root bone (-1 if no hierarchy)
	public int32 RootBoneIndex = -1;

	/// The original up axis of the source file's coordinate system.
	/// Loaders set this so tooling can apply corrections during conversion.
	/// Default is Y-up (no correction needed for GLTF or already-converted files).
	public CoordinateAxis OriginalUpAxis = .PositiveY;

	public StringView Name => mName;
	public List<ModelMesh> Meshes => mMeshes;
	public List<ModelMaterial> Materials => mMaterials;
	public List<ModelBone> Bones => mBones;
	public List<ModelSkin> Skins => mSkins;
	public List<ModelAnimation> Animations => mAnimations;
	public List<ModelTexture> Textures => mTextures;
	public List<TextureSampler> Samplers => mSamplers;
	public BoundingBox Bounds => mBounds;

	public this()
	{
		mName = new String();
		mMeshes = new List<ModelMesh>();
		mMaterials = new List<ModelMaterial>();
		mBones = new List<ModelBone>();
		mSkins = new List<ModelSkin>();
		mAnimations = new List<ModelAnimation>();
		mTextures = new List<ModelTexture>();
		mSamplers = new List<TextureSampler>();
		mBounds = BoundingBox(.Zero, .Zero);
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}

	/// Add a mesh (takes ownership)
	public int32 AddMesh(ModelMesh mesh)
	{
		let index = (int32)mMeshes.Count;
		mMeshes.Add(mesh);
		return index;
	}

	/// Add a material (takes ownership)
	public int32 AddMaterial(ModelMaterial material)
	{
		let index = (int32)mMaterials.Count;
		mMaterials.Add(material);
		return index;
	}

	/// Add a bone (takes ownership)
	public int32 AddBone(ModelBone bone)
	{
		int32 index = (int32)mBones.Count;
		bone.Index = index;
		mBones.Add(bone);
		return index;
	}

	/// Add a skin (takes ownership)
	public int32 AddSkin(ModelSkin skin)
	{
		int32 index = (int32)mSkins.Count;
		mSkins.Add(skin);
		return index;
	}

	/// Add an animation (takes ownership)
	public int32 AddAnimation(ModelAnimation animation)
	{
		int32 index = (int32)mAnimations.Count;
		mAnimations.Add(animation);
		return index;
	}

	/// Add a texture (takes ownership)
	public int32 AddTexture(ModelTexture texture)
	{
		int32 index = (int32)mTextures.Count;
		mTextures.Add(texture);
		return index;
	}

	/// Add a sampler
	public int32 AddSampler(TextureSampler sampler)
	{
		int32 index = (int32)mSamplers.Count;
		mSamplers.Add(sampler);
		return index;
	}

	/// Calculate bounds from all meshes
	public void CalculateBounds()
	{
		if (mMeshes.Count == 0)
		{
			mBounds = BoundingBox(.Zero, .Zero);
			return;
		}

		var min = Vector3(float.MaxValue);
		var max = Vector3(float.MinValue);

		for (let mesh in mMeshes)
		{
			let meshBounds = mesh.Bounds;
			min = Vector3.Min(min, meshBounds.Min);
			max = Vector3.Max(max, meshBounds.Max);
		}

		mBounds = BoundingBox(min, max);
	}

	/// Build bone hierarchy from parent indices
	public void BuildBoneHierarchy()
	{
		// Clear existing children
		for (let bone in mBones)
		{
			bone.Children.Clear();
		}

		// Build hierarchy
		for (let bone in mBones)
		{
			if (bone.ParentIndex >= 0 && bone.ParentIndex < mBones.Count)
			{
				mBones[bone.ParentIndex].AddChild(bone);
			}
			else if (bone.ParentIndex < 0)
			{
				RootBoneIndex = bone.Index;
			}
		}
	}

	/// Get mesh by name
	public ModelMesh GetMesh(StringView name)
	{
		for (let mesh in mMeshes)
		{
			if (mesh.Name == name)
				return mesh;
		}
		return null;
	}

	/// Get material by name
	public ModelMaterial GetMaterial(StringView name)
	{
		for (let material in mMaterials)
		{
			if (material.Name == name)
				return material;
		}
		return null;
	}

	/// Get bone by name
	public ModelBone GetBone(StringView name)
	{
		for (let bone in mBones)
		{
			if (bone.Name == name)
				return bone;
		}
		return null;
	}

	/// Get animation by name
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
