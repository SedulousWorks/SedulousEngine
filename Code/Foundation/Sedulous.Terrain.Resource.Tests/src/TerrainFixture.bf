using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.VFS;

namespace Sedulous.Terrain.Resource.Tests;

/// A scratch mount, a content database over it, and the terrain, splat and heightfield
/// factories: the real cook and bind path, since the point of the terrain factory is the
/// resolution of its sub resources through the same manager.
class TerrainFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;

	public TerrainFactory Terrains = new .() ~ delete _;
	public SplatWeightsFactory Splats = new .() ~ delete _;
	public HeightfieldFactory Heightfields = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	/// The type names an instance stores. Spelled out, because those strings ARE the format.
	public const String TerrainTypeName = "Sedulous.Terrain.Resource.TerrainSource";
	public const String SplatTypeName = "Sedulous.Terrain.Resource.SplatWeightsSource";
	public const String HeightfieldTypeName = "Sedulous.Heightfield.Resource.HeightfieldSource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so a test states exactly which types
		// it expects to resolve.
		TerrainResources.RegisterAll(Serializables);
		HeightfieldResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// A manager with all three factories registered.
	///
	/// THE CALLER OWNS what comes back, and this fixture must outlive it.
	public ResourceManager CreateManager()
	{
		let manager = new ResourceManager(Database);
		TerrainResources.AddFactories(manager, Terrains, Splats);
		HeightfieldResources.AddFactories(manager, Heightfields);
		return manager;
	}

	public Guid AuthorHeightfield(StringView name, Heightfield field)
	{
		let source = scope HeightfieldSource();
		HeightfieldSource.FromHeightfield(field, source);

		let instance = Database.RootGroup.CreateInstance(name, HeightfieldTypeName);
		instance.WriteObject(source).IgnoreError();
		instance.WriteData(HeightfieldSource.HeightStream,
			HeightfieldSource.HeightBlob(field)).IgnoreError();
		return instance.Id;
	}

	public Guid AuthorSplatWeights(StringView name, SplatWeights weights)
	{
		let source = scope SplatWeightsSource();
		SplatWeightsSource.FromWeights(weights, source);

		let instance = Database.RootGroup.CreateInstance(name, SplatTypeName);
		instance.WriteObject(source).IgnoreError();
		instance.WriteData(SplatWeightsSource.WeightStream,
			SplatWeightsSource.WeightBlob(weights)).IgnoreError();
		instance.WriteData(SplatWeightsSource.IndexStream,
			SplatWeightsSource.IndexBlob(weights)).IgnoreError();
		return instance.Id;
	}

	public Guid AuthorTerrain(StringView name, TerrainSource source)
	{
		let instance = Database.RootGroup.CreateInstance(name, TerrainTypeName);
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}

	/// Writes a palette sidecar: the geometry header, then the texels.
	public void WritePalette(Guid terrainId, StringView stream, uint32 sliceSize, uint32 mipCount,
		uint32 sliceCount, Span<uint8> texels)
	{
		let instance = Database.GetInstance(terrainId);
		let payload = scope System.Collections.List<uint8>();
		payload.Reserve(sizeof(uint32) * 3 + texels.Length);

		var header = uint32[3](sliceSize, mipCount, sliceCount);
		let headerBytes = Span<uint8>((uint8*)&header[0], sizeof(uint32) * 3);
		payload.AddRange(headerBytes);
		payload.AddRange(texels);

		instance.WriteData(stream, .(payload.Ptr, payload.Count)).IgnoreError();
	}
}
