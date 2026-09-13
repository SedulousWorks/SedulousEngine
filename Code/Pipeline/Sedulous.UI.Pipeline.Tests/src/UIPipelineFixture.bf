using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.UI.Pipeline;
using Sedulous.UI.Resource;
using Sedulous.VFS;

namespace Sedulous.UI.Pipeline.Tests;

/// A scratch sources tree, a scratch cooked database over it, and a build context wired to
/// both: the whole stack a cook actually runs against.
///
/// Real mounts and real files rather than stand ins, because what these cases measure is that
/// the TEXT lives in the linked file and reaches the product through the mount. A fake mount
/// would be measuring the fake.
class UIPipelineFixture
{
	public NativeFileSystem Sources ~ delete _;
	public NativeFileSystem CookedMount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Cooked ~ delete _;
	public AssetBuildContext Context = new .() ~ delete _;

	private String mSourcesRoot = new .() ~ delete _;
	private String mCookedRoot = new .() ~ delete _;

	public this(StringView name)
	{
		mSourcesRoot.AppendF("scratch_uipipe_{}_src", name);
		mCookedRoot.AppendF("scratch_uipipe_{}_db", name);
		RemoveDirectoryRecursive(mSourcesRoot);
		RemoveDirectoryRecursive(mCookedRoot);
		CreateDirectory(mSourcesRoot);
		CreateDirectory(mCookedRoot);

		Sources = new NativeFileSystem(mSourcesRoot);
		CookedMount = new NativeFileSystem(mCookedRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Cooked = new ContentDatabase(CookedMount, Factory, "rasset");

		Context.Sources = Sources;
		Context.Database = Cooked;
		Context.Serializers = Factory;

		UIResources.RegisterAll();
		UIPipeline.RegisterAll();
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mSourcesRoot);
		RemoveDirectoryRecursive(mCookedRoot);
	}

	/// Stages a file under the sources tree, which is where an asset's link points.
	public void StageSource(StringView fileName, StringView text)
	{
		let path = scope String();
		PathJoin(mSourcesRoot, fileName, path);
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	/// Where a LOOSE file to import should be written, which is outside the project.
	public void LoosePath(StringView fileName, String outPath)
	{
		PathJoin(mCookedRoot, fileName, outPath);
	}

	public bool SourceExists(StringView fileName)
	{
		let path = scope String();
		PathJoin(mSourcesRoot, fileName, path);
		return FileExists(path);
	}

	public StringView SourcesRoot => mSourcesRoot;

	/// A fresh output instance for one cook.
	public Instance CreateOutput(StringView name, StringView typeName)
		=> Cooked.RootGroup.CreateInstance(name, typeName);
}
