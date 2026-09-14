using System;
using Sedulous.Animation.Pipeline;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model.Resource;
using Sedulous.Physics.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.ModelImporter.Tests;

/// A scratch project: a source content database, a sources tree, and the context an import
/// lands against.
///
/// REAL directories and a real database, because a fan out is measured by what it wrote: the
/// instances it created, their types, their identities, and the files it copied.
class ImportFixture
{
	public NativeFileSystem ContentFs ~ delete _;
	public NativeFileSystem CookedFs ~ delete _;
	public NativeFileSystem SourcesFs ~ delete _;
	public NativeFileSystem CacheFs ~ delete _;

	public SerializerFactory Factory ~ delete _;
	public SerializerFactory CookedFactory ~ delete _;
	public ContentDatabase Db ~ delete _;
	public ContentDatabase CookedDb ~ delete _;
	public ImportContext Context ~ delete _;

	/// Every builder the fan out's asset types need, so a case can cook what it imported.
	public BuilderRegistry Builders = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView name)
	{
		mRoot.Set(name);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);
		for (let directory in scope String[]("Content", "Cooked", "Sources", "Cache"))
			CreateDirectory(SubPath(directory, .. scope String()));

		ContentFs = new NativeFileSystem(SubPath("Content", .. scope String()));
		CookedFs = new NativeFileSystem(SubPath("Cooked", .. scope String()));
		SourcesFs = new NativeFileSystem(SubPath("Sources", .. scope String()));
		CacheFs = new NativeFileSystem(SubPath("Cache", .. scope String()));

		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		CookedFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Db = new ContentDatabase(ContentFs, Factory, "xasset");
		CookedDb = new ContentDatabase(CookedFs, CookedFactory, "rasset");
		Context = new ImportContext(SubPath("Sources", .. scope String()));

		Builders.Register(new ModelManifestAssetBuilder());
		Builders.Register(new TextureAssetBuilder());
		Builders.Register(new StaticMeshAssetBuilder());
		Builders.Register(new SkinnedMeshAssetBuilder());
		Builders.Register(new MaterialAssetBuilder());
		Builders.Register(new SkeletonAssetBuilder());
		Builders.Register(new AnimationClipAssetBuilder());

		// Every asset type the fan out writes has to be deserializable for a case to read one
		// back, and the manifest names the rest.
		ModelImporterPipeline.RegisterAll();
		TexturePipeline.RegisterAll();
		GeometryPipeline.RegisterAll();
		MaterialsPipeline.RegisterAll();
		AnimationPipeline.RegisterAll();
		PhysicsPipeline.RegisterAll();

		// And the PRODUCT types beside them, because a case that cooks then reads a product
		// back goes through the same registry.
		ModelResources.RegisterAll();
		TextureResources.RegisterAll();
		GeometryResources.RegisterAll();
		MaterialResources.RegisterAll();
		AnimationResources.RegisterAll();
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	public StringView Root => mRoot;
	public Group RootGroup => Db.RootGroup;

	public void SubPath(StringView name, String outPath) => PathJoin(mRoot, name, outPath);

	/// The path a dropped file would have. Only its NAME matters to an import handed a
	/// prepared model, but the provenance copy still reads it, so it has to exist.
	public void WriteDroppedFile(StringView name, StringView text, String outPath)
	{
		SubPath(name, outPath);
		WriteFile(outPath, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	/// A file beside the dropped one, in a subfolder when the name has a path in it, which is
	/// what a text model's references point at.
	public void WriteBeside(StringView relative, StringView text)
	{
		let path = scope String();
		SubPath(relative, path);
		let slash = path.LastIndexOf('/');
		if (slash > 0)
			CreateDirectory(StringView(path, 0, slash));
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	/// Reads an instance's manifest asset back, which the CALLER owns.
	public static ModelManifestAsset ReadManifest(Instance instance)
	{
		let object = instance.ReadObject();
		if (object == null)
			return null;
		return Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ModelManifestAsset;
	}
}
