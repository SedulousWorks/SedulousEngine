using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Pipeline.Importer.Tests;

/// An asset as a file importer writes one, counting its payload's reads.
[Serializable(0, true)] // afterRead
class SourcedAsset : Asset
{
	public static int Reads;

	public void AfterRead()
	{
		Reads++;
	}
}

/// The registry for this project's serializable types, generated from the declarations.
[SerializableRegistry]
static class ImporterTestTypes
{
}

/// A re-import asks whether another asset shares the copy under the sources tree it would
/// overwrite; the answer comes from the database's records, not from reading every asset.
class SharedCopyTests
{
	private const String cRoot = "scratch_importer_shared_copy";

	[Test]
	public static void ASharedCopyIsFoundFromTheRecordsWithoutReadingThem()
	{
		ImporterTestTypes.RegisterAll();
		RemoveDirectoryRecursive(cRoot);
		Test.Assert(CreateDirectory(cRoot));
		defer RemoveDirectoryRecursive(cRoot);
		let mount = scope NativeFileSystem(cRoot);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let typeName = "Sedulous.Pipeline.Importer.Tests.SourcedAsset";

		{
			let database = scope ContentDatabase(mount, factory, "asset");
			let textures = database.RootGroup.CreateGroup("textures");
			let asset = scope SourcedAsset();
			asset.FileName.Set("stone.png");
			Test.Assert(textures.CreateInstance("stone", typeName).WriteObject(asset) case .Ok);
			Test.Assert(textures.CreateGroup("copies").CreateInstance("stone", typeName).WriteObject(asset) case .Ok);
			asset.FileName.Set("grass.png");
			Test.Assert(database.RootGroup.CreateInstance("grass", typeName).WriteObject(asset) case .Ok);
		}

		// A fresh database: what it knows comes from the scan.
		SourcedAsset.Reads = 0;
		let database = scope ContentDatabase(mount, factory, "asset");
		let stone = database.GetInstanceByPath("textures/stone");
		let copy = database.GetInstanceByPath("textures/copies/stone");
		let grass = database.GetInstanceByPath("grass");
		Test.Assert((stone != null) && (copy != null) && (grass != null));
		Test.Assert(stone.SourceName == "stone.png", "an asset's record names its file");
		Test.Assert(ImportPaths.SourcesCopyUsedByOther(grass.OwningGroup, "stone.png", stone),
			"another asset, in another group, shares the copy");
		Test.Assert(ImportPaths.SourcesCopyUsedByOther(stone.OwningGroup, "stone.png", copy));
		Test.Assert(!ImportPaths.SourcesCopyUsedByOther(stone.OwningGroup, "grass.png", grass),
			"the only asset made from it");
		Test.Assert(SourcedAsset.Reads == 0, "and no asset was read to learn it");
	}
}
