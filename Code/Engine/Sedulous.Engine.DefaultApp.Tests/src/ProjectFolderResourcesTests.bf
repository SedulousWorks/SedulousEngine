using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.Scene.Resource;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Engine.DefaultApp.Tests;

/// A game run from its project folder gives its application one database for the resources:
/// its cooked products over its sources (LayeredContentDatabase). The manager the application
/// makes over it binds a prefab, which is never cooked, from the sources, and a product from
/// the cooked database; a source record of a type the cook builds never reaches its factory.
class ProjectFolderResourcesTests
{
	[Test]
	public static void TheManagerBindsAPrefabFromTheSourcesAndAProductFromTheCooked()
	{
		let root = "scratch_project_folder_resources";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		let contentDir = PathJoin(root, "Content", .. scope .());
		let cookedDir = PathJoin(root, "Cooked", .. scope .());
		CreateDirectory(contentDir);
		CreateDirectory(cookedDir);
		SceneResources.RegisterAll();
		PhysicsResources.RegisterAll();

		// The player's two databases, as it opens a project folder.
		let contentMount = scope NativeFileSystem(contentDir);
		let cookedMount = scope NativeFileSystem(cookedDir);
		let xml = XmlSerializerFactory();
		defer delete xml;
		SerializerFactory binary = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete binary;
		let sources = scope ContentDatabase(contentMount, xml, "xasset");
		let cooked = scope ContentDatabase(cookedMount, binary, "asset");

		// A prefab, authored and never cooked.
		Guid prefab;
		{
			let template = scope Sedulous.Scene.Scene("crate");
			template.CreateEntity("Crate");
			let instance = sources.RootGroup.CreateInstance("crate", "Sedulous.Scene.Resource.PrefabDocument");
			Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);
			prefab = instance.Id;
		}
		// A cooked product, and a record of its cooked type that only the sources hold.
		Guid material;
		Guid sourceOnly;
		{
			let record = scope PhysicalMaterialSource();
			record.Friction = 0.25f;
			let product = cooked.RootGroup.CreateInstance("ice", "Sedulous.Physics.Resource.PhysicalMaterialSource");
			Test.Assert(product.WriteObject(record) case .Ok);
			material = product.Id;
			let below = sources.RootGroup.CreateInstance("mud", "Sedulous.Physics.Resource.PhysicalMaterialSource");
			Test.Assert(below.WriteObject(record) case .Ok);
			sourceOnly = below.Id;
		}

		let view = scope LayeredContentDatabase(cooked, sources);
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Subsystems.Startup();
		app.SetContentDatabase(view);
		app.SetSceneDatabase(sources);
		app.OnStartup(host);

		let resources = app.Resources;
		Test.Assert((resources != null) && ((resources.Database as LayeredContentDatabase) == view), "the manager reads the view");
		Test.Assert(resources.HasFactory(ResourceManager.ProductTypeIdOf<PhysicalMaterial>()));

		let loaded = resources.Bind<PrefabResource>(prefab);
		Test.Assert(loaded.State == .Ready, "the prefab from the sources");
		Test.Assert(loaded.Get.Name == "crate");
		Test.Assert(loaded.Get.Encoding == .Binary, "its text read into the binary wire with the app's managers");

		let ice = resources.Bind<PhysicalMaterial>(material);
		Test.Assert(ice.State == .Ready, "the product from the cooked database");
		Test.Assert(Math.Abs(ice.Get.Friction - 0.25f) < 1e-5f);

		Test.Assert(resources.Bind<PhysicalMaterial>(sourceOnly).State == .Failed,
			"a source record of a cooked type is not handed to its factory");

		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
		Test.Assert(view.GetInstance(prefab) == null, "the manager gone, its predicate went with it");
		Test.Assert(view.GetInstance(material) != null);
	}
}
