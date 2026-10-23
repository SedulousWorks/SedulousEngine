using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.VFS;
using Sedulous.VG.Resource;

namespace Sedulous.VG.Resource.Tests;

/// A cooked vector image read back through its factory, and the module the engine composition
/// takes it from.
class VGResourceTests
{
	private const String cRoot = "scratch_vgresource_db";
	private const String cHeartSvg = """
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 21 L3 12 A5 5 0 0 1 12 5 A5 5 0 0 1 21 12 Z" fill="#E53935"/></svg>
		""";

	[Test]
	public static void ACookedVectorImageBindsAsItsProductTheSvgIntact()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		let serializables = scope SerializableRegistry();
		VGResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;
		let database = scope ContentDatabase(mount, serializers, "rasset", serializables);

		let heart = database.RootGroup.CreateInstance("heart", "Sedulous.VG.Resource.VectorImageResource");
		Test.Assert(heart != null);
		let cooked = scope VectorImageResource();
		cooked.Svg.Set(cHeartSvg);
		Test.Assert(heart.WriteObject(cooked) case .Ok);

		let factory = scope VectorImageFactory();
		Test.Assert(factory.CookedType == typeof(VectorImageResource));
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(factory);
		let image = manager.Bind<VectorImage>(heart.Id);
		Test.Assert(image.Get != null);
		Test.Assert(image.Get.Svg == cHeartSvg);
	}

	[Test]
	public static void TheModuleOffersTheVectorImagesFactoryUnderItsOwnId()
	{
		Test.Assert(VGResources.Module.Id == "vg");
		Test.Assert(VGResources.Module.Factories.Length == 1);
		Test.Assert(VGResources.Module.Factories[0].Cooked == typeof(VectorImageResource));
	}
}
