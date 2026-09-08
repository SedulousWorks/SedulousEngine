using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene.Resource;
using Sedulous.VFS;

namespace Sedulous.Scene.Resource.Integration.Tests;

/// A scratch directory, a content database over it, and the scene document types
/// registered. The real stack: SceneStorage is measured against a database that writes
/// files, because the two entry points exist to cross that boundary.
class SceneContentFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;

	private String mRoot = new .() ~ delete _;

	/// The type names an instance stores. Spelled out, because that string is the format:
	/// a reader resolves the primary by hashing it.
	public const String SceneTypeName = "Sedulous.Scene.Resource.SceneDocument";
	public const String PrefabTypeName = "Sedulous.Scene.Resource.PrefabDocument";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so a test states exactly the types
		// it expects to resolve and nothing another test registered leaks in.
		SceneResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Reopens the database over the same files, which is what a later session does. A
	/// round trip that never reopens proves only that the in memory object survived.
	public ContentDatabase Reopen()
	{
		delete Database;
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
		return Database;
	}
}
