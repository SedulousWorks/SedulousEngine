using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// A loaded prefab follows its record: a change the context is told of reloads it, and a
/// deletion evicts it, so a spawn never comes from what is no longer on disk.
static class AuthoredResourceNotifyTests
{
	/// A source database in a scratch directory, a manager over it with the prefab factory, and
	/// a context whose resources it is.
	private class Bed
	{
		public String Dir = new .() ~ delete _;
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public ContentDatabase Database ~ delete _;
		public PrefabFactory Prefabs = new .() ~ delete _;
		public ResourceManager Resources ~ delete _;
		public EditorContext Context = new .() ~ delete _;

		public this(StringView name)
		{
			SceneResources.RegisterAll();
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, Dir);
			RemoveDirectoryRecursive(Dir);
			CreateDirectory(Dir);
			Mount = new NativeFileSystem(Dir);
			Factory = XmlSerializerFactory();
			Database = new ContentDatabase(Mount, Factory, "xasset");
			Resources = new ResourceManager(Database);
			Resources.AddFactory(Prefabs);
			Context.Resources = Resources;
		}

		public ~this()
		{
			Context.Resources = null;
			RemoveDirectoryRecursive(Dir);
		}

		/// Stores (or rewrites) the prefab `name`: one entity named `root`.
		public Guid Store(StringView name, StringView root)
		{
			let template = scope Scene(name);
			template.CreateEntity(root);
			let instance = Database.RootGroup.CreateInstance(name, cPrefabType);
			Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);
			return instance.Id;
		}
	}

	private const String cPrefabType = "Sedulous.Scene.Resource.PrefabDocument";

	/// The name of the root the loaded prefab spawns, read from its payload alone.
	private static void RootName(PrefabResource prefab, String outName)
	{
		Test.Assert(prefab != null);
		let scene = scope Scene("level");
		let payload = prefab.OpenPayload();
		defer delete payload;
		let root = PrefabSpawn.Spawn(scene, payload, prefab.Id);
		Test.Assert(root.IsAssigned);
		outName.Set(scene.GetEntityName(root));
	}

	[Test]
	public static void AChangeTheContextIsToldOfReloadsTheLoadedPrefab()
	{
		let bed = scope Bed("scratch_notify_prefab_reload");
		let crate = bed.Store("crate", "Crate");
		let proxy = bed.Resources.Bind<PrefabResource>(crate);
		Test.Assert(RootName(proxy.Get, .. scope .()) == "Crate");

		Test.Assert(bed.Store("crate", "Barrel") == crate, "the same record rewritten");
		Test.Assert(RootName(proxy.Get, .. scope .()) == "Crate", "loaded: the file is not read again");

		Test.Assert(bed.Context.NotifyAssetExternallyModified(crate) == 0, "no page edits it");
		Test.Assert(proxy.State == .Ready);
		Test.Assert(RootName(proxy.Get, .. scope .()) == "Barrel", "the held handle reads the record again");

		// A record nothing has loaded: no handle is made for it.
		let lamp = bed.Store("lamp", "Lamp");
		bed.Context.NotifyAssetExternallyModified(lamp);
		Test.Assert(bed.Resources.FindHandle(lamp) == null);
	}

	[Test]
	public static void ADeletionTheContextIsToldOfEvictsTheLoadedPrefab()
	{
		let bed = scope Bed("scratch_notify_prefab_evict");
		let crate = bed.Store("crate", "Crate");
		let proxy = bed.Resources.Bind<PrefabResource>(crate);
		Test.Assert(proxy.Get != null);

		// A deleted record of a type no factory here reads as authored is left to its cook.
		bed.Context.NotifyAssetDeleted(crate, "crate", "Sedulous.Scene.Resource.SceneDocument");
		Test.Assert(proxy.State == .Ready, "not a prefab's deletion: kept");

		Test.Assert(bed.Database.DeleteInstance(crate) case .Ok);
		bed.Context.NotifyAssetDeleted(crate, "crate", cPrefabType);
		Test.Assert(proxy.State == .Failed, "evicted");
		Test.Assert(proxy.Get == null, "a held reference reads unbound");
		Test.Assert(bed.Resources.FindHandle(crate) != null, "its handle kept for the record's return");
		Test.Assert(bed.Resources.Bind<PrefabResource>(crate).Get == null, "nothing on disk to bind it from");

		// The record comes back under its identity: told, the same handle revives.
		{
			let template = scope Scene("crate");
			template.CreateEntity("Returned");
			let instance = bed.Database.RootGroup.CreateInstanceWithId(crate, "crate", cPrefabType);
			Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);
		}
		bed.Context.NotifyAssetExternallyModified(crate);
		Test.Assert(proxy.State == .Ready);
		Test.Assert(RootName(proxy.Get, .. scope .()) == "Returned");
	}
}
