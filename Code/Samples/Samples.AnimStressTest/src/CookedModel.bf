using System;
using System.Collections;
using System.IO;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.ModelImporter;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Samples.AnimStressTest;

/// One model file, cooked at startup and bound back through the resource manager.
///
/// The whole stack lives here because it all has to OUTLIVE the entities: the manager owns the
/// cooked products, the database backs the manager, and the mount backs the database. Taking
/// any of them down early leaves live entities pointing at freed meshes.
///
/// An editor would cook offline and the runtime would only bind. The wiring on this side of the
/// seam is identical either way, which is the point of doing it here.
class CookedModel
{
	private SerializerFactory mSerializers = null ~ delete _;
	private NativeFileSystem mMount = null ~ delete _;
	private ContentDatabase mDatabase = null ~ delete _;
	private ResourceManager mResources = null ~ delete _;

	private StaticMeshFactory mMeshFactory = new .() ~ delete _;
	private SkinnedMeshFactory mSkinnedMeshFactory = new .() ~ delete _;
	private MaterialFactory mMaterialFactory = new .() ~ delete _;
	private SkeletonFactory mSkeletonFactory = new .() ~ delete _;
	private AnimationClipFactory mClipFactory = new .() ~ delete _;
	private ModelFactory mModelFactory = new .() ~ delete _;
	private TextureFactory mTextureFactory = null ~ delete _;

	private ModelResource mResource = null;
	private List<Material> mMaterials = new .() ~ delete _;
	private List<AnimationClip> mClips = new .() ~ delete _;
	private float mFit = 1.0f;

	/// Null until a cook succeeds. Everything downstream checks it, so a missing model file
	/// leaves an empty scene rather than a crash.
	public ModelResource Resource => mResource;
	/// Every material, indexed the way a submesh's material index indexes them.
	public List<Material> Materials => mMaterials;
	/// The clips a spawned instance picks from, so a crowd never moves in lockstep.
	public List<AnimationClip> Clips => mClips;
	/// The uniform scale that fits the model's largest extent to the target size.
	public float Fit => mFit;

	public bool Open(StringView outputDirectory, IDevice device)
	{
		if (Directory.CreateDirectory(outputDirectory) case .Err)
		{
			if (!Directory.Exists(outputDirectory))
				return false;
		}

		ModelResources.RegisterAll();

		mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mMount = new NativeFileSystem(outputDirectory);
		mDatabase = new ContentDatabase(mMount, mSerializers, "rasset");
		mResources = new ResourceManager(mDatabase, null);

		mResources.AddFactory(mMeshFactory);
		mResources.AddFactory(mSkinnedMeshFactory);
		mResources.AddFactory(mModelFactory);
		mResources.AddFactory(mMaterialFactory);
		mResources.AddFactory(mSkeletonFactory);
		mResources.AddFactory(mClipFactory);

		// The texture factory needs a device, so a headless run simply goes without and the
		// materials fall back to their untextured colours.
		if (device != null)
		{
			mTextureFactory = new TextureFactory(device);
			mResources.AddFactory(mTextureFactory);
		}

		return true;
	}

	/// Cooks and binds ONCE. Every spawned instance shares these products, and only the
	/// transform and the animation player differ.
	public bool Cook(StringView namePrefix, StringView path, float targetSize)
	{
		if (mDatabase == null)
			return false;

		Guid modelId;
		switch (ModelLoadAndCook.LoadAndCook(path, mDatabase, namePrefix))
		{
		case .Ok(let id): modelId = id;
		case .Err(let result):
			Console.Error.WriteLine(scope $"AnimStressTest: model import failed ({result})");
			return false;
		}

		let bound = mResources.Bind<ModelResource>(modelId);
		mResource = bound.Get;
		if (mResource == null)
		{
			Console.Error.WriteLine("AnimStressTest: model bind failed");
			return false;
		}

		// Auto fit, so a model authored in any unit lands at a usable size next to the floor.
		let extent = mResource.BoundsMax - mResource.BoundsMin;
		let largest = Math.Max(extent.X, Math.Max(extent.Y, extent.Z));
		mFit = (largest > 0.0001f) ? (targetSize / largest) : 1.0f;

		for (var material in ref mResource.Materials)
		{
			if (material.Get != null)
				mMaterials.Add(material.Get);
		}

		for (var clip in ref mResource.Animations)
		{
			if (clip.Get != null)
				mClips.Add(clip.Get);
		}

		return true;
	}
}
