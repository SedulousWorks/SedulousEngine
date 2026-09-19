using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Scene.Resource.Tests;

/// A scratch content database holding prefabs, for spawning by id.
class PrefabDatabaseFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String cPrefabTypeName = "Sedulous.Scene.Resource.PrefabDocument";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		SceneResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Stores a prefab: a root named `name` with an Ammo component and one child.
	public Guid StoreTurret(StringView name, int32 rounds)
	{
		let template = scope Scene(name);
		let ammo = template.AddSystem<AmmoManager>();
		let root = template.CreateEntity("Turret");
		ammo.Add(root).Rounds = rounds;
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);

		let instance = Database.RootGroup.CreateInstance(name, cPrefabTypeName);
		Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok, "the prefab stored");
		return instance.Id;
	}
}
