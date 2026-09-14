using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.VFS;

namespace Sedulous.Terrain.Pipeline.Tests;

/// A scratch database for the terrain cook, with the shared grid it references.
class TerrainFixture
{
	public NativeFileSystem Mount ~ delete _;
	public NativeFileSystem SourceMount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public ContentDatabase Database ~ delete _;

	private String mRoot = new .() ~ delete _;
	private String mSourceRoot = new .() ~ delete _;

	public this(StringView name)
	{
		mRoot.Set(name);
		mSourceRoot.Set(scope $"{name}_src");
		for (let root in scope String[](mRoot, mSourceRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}

		TerrainPipeline.RegisterAll();
		TerrainResources.RegisterAll();
		HeightfieldResources.RegisterAll();

		Mount = new NativeFileSystem(mRoot);
		SourceMount = new NativeFileSystem(mSourceRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "rasset");
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
		RemoveDirectoryRecursive(mSourceRoot);
	}

	/// A cooked heightfield for the terrain to reference.
	public Guid AddHeightfield(StringView name = "hf")
	{
		let instance = Database.RootGroup.CreateInstance(name,
			"Sedulous.Heightfield.Resource.HeightfieldSource");
		Test.Assert(instance != null);

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let record = scope HeightfieldSource();
		HeightfieldSource.FromHeightfield(grid, record);
		Test.Assert(instance.WriteObject(record) case .Ok);
		Test.Assert(instance.WriteData(HeightfieldSource.HeightStream,
			HeightfieldSource.HeightBlob(grid)) case .Ok);
		return instance.Id;
	}

	public Instance AddTerrainProduct(StringView name = "terrain")
	{
		let instance = Database.RootGroup.CreateInstance(name,
			"Sedulous.Terrain.Resource.TerrainSource");
		Test.Assert(instance != null);
		return instance;
	}

	/// Cooks the asset into the instance.
	public void Cook(TerrainAsset asset, Instance output)
	{
		let context = scope AssetBuildContext();
		context.Sources = SourceMount;
		context.Output = output;
		context.Database = Database;
		context.SourceDatabase = Database;
		Test.Assert(scope TerrainAssetBuilder().Build(asset, context) case .Ok);
	}

	/// Whether a palette sidecar stream is present on the instance.
	public static bool HasStream(Instance instance, StringView name)
	{
		let stream = instance.ReadData(name);
		if (stream == null)
			return false;
		delete stream;
		return true;
	}

	/// Reads a palette sidecar's header and texels.
	public static void ReadPalette(Instance instance, StringView name, List<uint8> outTexels,
		out uint32 outSliceSize, out uint32 outMipCount, out uint32 outSliceCount)
	{
		outSliceSize = 0;
		outMipCount = 0;
		outSliceCount = 0;

		let stream = instance.ReadData(name);
		Test.Assert(stream != null, scope String(name));
		defer delete stream;

		uint32[3] header = .();
		Test.Assert(stream.Read(.((uint8*)&header, sizeof(uint32[3]))) == sizeof(uint32[3]));
		outSliceSize = header[0];
		outMipCount = header[1];
		outSliceCount = header[2];

		let bytes = TerrainPaletteData.SliceBytes(header[0], header[1]) * (int)header[2];
		outTexels.Count = bytes;
		Test.Assert(stream.Read(outTexels) == bytes);
	}
}
