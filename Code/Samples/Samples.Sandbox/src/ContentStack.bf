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
using Sedulous.Image;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.ModelImporter;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Samples.Sandbox;

/// The cook and bind stack: a content database over a scratch directory, a resource manager,
/// and every factory the sandbox's assets need.
///
/// It is one object because the pieces have one LIFETIME between them: the manager owns the
/// cooked products the scene points at, the database backs the manager, and the mount backs the
/// database. Tearing any of them down early leaves live entities holding freed meshes.
class ContentStack
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

	public bool IsOpen => mDatabase != null;
	public ContentDatabase Database => mDatabase;
	public ResourceManager Resources => mResources;
	public bool HasTextures => mTextureFactory != null;

	public bool Open(StringView outputDirectory, IDevice device)
	{
		if (Directory.CreateDirectory(outputDirectory) case .Err)
		{
			if (!Directory.Exists(outputDirectory))
				return false;
		}

		ModelResources.RegisterAll();
		TextureResources.RegisterAll();

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

		// Without a device there are no GPU textures, so the materials simply keep their
		// untextured colours rather than the sample refusing to run.
		if (device != null)
		{
			mTextureFactory = new TextureFactory(device);
			mResources.AddFactory(mTextureFactory);
		}

		return true;
	}

	/// Cooks a model file and binds it back. Null when the file is missing or did not parse.
	public ModelResource CookModel(StringView namePrefix, StringView path)
	{
		if (mDatabase == null)
			return null;

		Guid modelId;
		switch (ModelLoadAndCook.LoadAndCook(path, mDatabase, namePrefix))
		{
		case .Ok(let id): modelId = id;
		case .Err(let result):
			Console.Error.WriteLine(scope $"Sandbox: model import failed ({result}) for {namePrefix}");
			return null;
		}

		let bound = mResources.Bind<ModelResource>(modelId);
		if (bound.Get == null)
			Console.Error.WriteLine("Sandbox: model bind failed");
		return bound.Get;
	}

	/// Imports an image through the asset pipeline and binds the runtime texture that owns its
	/// GPU view. Null when there is no device, or the file is not there.
	public Texture CookTexture(StringView instanceName, StringView sourceDirectory,
		StringView fileName)
	{
		if ((mDatabase == null) || (mTextureFactory == null))
			return null;

		let asset = scope TextureAsset();
		TextureImporter.Import2D(fileName, .Srgb, asset);

		let instance = mDatabase.RootGroup.CreateInstance(instanceName,
			"Sedulous.Texture.Resource.TextureResource");
		if (instance == null)
			return null;

		// The SOURCE mount is separate from the output one: the importer resolves the file
		// name against where the images live, not against where the cooked bytes go.
		let sources = scope NativeFileSystem(sourceDirectory);
		let builder = scope TextureAssetBuilder();
		let context = scope AssetBuildContext();
		context.Sources = sources;
		context.Output = instance;
		context.Database = mDatabase;
		context.Serializers = mSerializers;
		if (!(builder.Build(asset, context) case .Ok))
			return null;

		let bound = mResources.Bind<Texture>(instance.Id);
		return bound.Get;
	}
}
