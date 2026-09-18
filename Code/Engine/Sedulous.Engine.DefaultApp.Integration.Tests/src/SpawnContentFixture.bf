using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.DefaultApp.Integration.Tests;

/// A scratch directory, a content database that writes into it, and the scene document
/// types registered.
///
/// The REAL stack on purpose. The resolver's whole job is to cross from a content database
/// to a live entity, so a fake database would test the half that was never in doubt.
class SpawnContentFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;

	private String mRoot = new .() ~ delete _;

	/// The type name an instance stores. Spelled out, because that string IS the format: a
	/// reader resolves the primary by hashing it.
	public const String PrefabTypeName = "Sedulous.Scene.Resource.PrefabDocument";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so this states exactly the types it
		// expects to resolve and nothing another suite registered leaks in.
		SceneResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}
}
