using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;
using Sedulous.Pipeline.Cook;

namespace Sedulous.Pipeline.Cook.Tests;

/// A scratch project with the four mounts a cook needs: the source content, the cooked
/// products, the source files, and the cache the pipeline database lives in.
///
/// REAL mounts and real files throughout. What these cases measure is whether a cook decides
/// correctly what to rebuild, and that decision reads sizes and modification times off a
/// filesystem: a stand in would be measuring the stand in.
class CookFixture
{
	public NativeFileSystem ContentFs ~ delete _;
	public NativeFileSystem CookedFs ~ delete _;
	public NativeFileSystem SourcesFs ~ delete _;
	public NativeFileSystem CacheFs ~ delete _;

	public SerializerFactory SourceFactory ~ delete _;
	public SerializerFactory CookedFactory ~ delete _;
	public ContentDatabase SourceDb ~ delete _;
	public ContentDatabase CookedDb ~ delete _;

	public BuilderRegistry Builders = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView name)
	{
		mRoot.Set(name);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);
		for (let directory in scope String[](  "Content", "Cooked", "Sources", "Cache"))
			CreateDirectory(SubPath(directory, .. scope String()));

		ContentFs = new NativeFileSystem(SubPath("Content", .. scope String()));
		CookedFs = new NativeFileSystem(SubPath("Cooked", .. scope String()));
		SourcesFs = new NativeFileSystem(SubPath("Sources", .. scope String()));
		CacheFs = new NativeFileSystem(SubPath("Cache", .. scope String()));
		OpenDatabases();

		Builders.Register(new CookWidgetBuilder());
		Builders.Register(new ChainBuilder());
		Builders.Register(new VariantBuilder());

		CookWidgetBuilder.CurrentVersion = 1;
		CookWidgetBuilder.ShouldFail = false;
		CookTestTypes.RegisterAll();
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	public StringView Root => mRoot;

	public void SubPath(StringView name, String outPath) => PathJoin(mRoot, name, outPath);

	private void OpenDatabases()
	{
		SourceFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		CookedFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		SourceDb = new ContentDatabase(ContentFs, SourceFactory, "xasset");
		CookedDb = new ContentDatabase(CookedFs, CookedFactory, "rasset");
	}

	/// Re-opens both databases from disk, which is what a fresh editor session does.
	public void Reopen()
	{
		delete SourceDb;
		delete CookedDb;
		delete SourceFactory;
		delete CookedFactory;
		OpenDatabases();
	}

	/// A driver over this fixture. The CALLER owns it.
	public CookDriver MakeDriver(JobSystem jobs = null)
		=> new CookDriver(SourceDb, CookedDb, Builders, SourcesFs, CacheFs, jobs);

	public Guid AddWidget(StringView name, int32 quality, StringView file = default)
	{
		let instance = SourceDb.RootGroup.CreateInstance(name,
			"Sedulous.Pipeline.Cook.Tests.CookWidgetAsset");
		Test.Assert(instance != null);

		let asset = scope CookWidgetAsset();
		asset.Quality = quality;
		asset.FileName.Set(file);
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	public Guid AddVariant(StringView name)
	{
		let instance = SourceDb.RootGroup.CreateInstance(name,
			"Sedulous.Pipeline.Cook.Tests.VariantAsset");
		Test.Assert(instance != null);
		let asset = scope VariantAsset();
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	public Guid AddChain(StringView name, Guid readDep, Guid refDep = .Empty)
	{
		let instance = SourceDb.RootGroup.CreateInstance(name,
			"Sedulous.Pipeline.Cook.Tests.ChainAsset");
		Test.Assert(instance != null);
		let asset = scope ChainAsset();
		asset.ReadDep = readDep;
		asset.RefDep = refDep;
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	public void WriteSourceFile(StringView name, StringView text)
	{
		Test.Assert(SourcesFs.Save(name, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	/// What a cooked product says, or minus one when there is none.
	public int32 CookedValue(Guid id) => ValueIn(CookedDb, id);

	public static int32 ValueIn(ContentDatabase database, Guid id)
	{
		let object = database.ReadObject(id);
		if (object == null)
			return -1;
		defer delete object;

		let product = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as CookWidgetProduct;
		return (product != null) ? product.CookedValue : -1;
	}

	/// How many items a fresh plan says are dirty.
	public static int PlanDirty(CookDriver driver)
	{
		let plan = scope CookPlan();
		driver.Plan(plan);
		return plan.Dirty.Count;
	}
}
