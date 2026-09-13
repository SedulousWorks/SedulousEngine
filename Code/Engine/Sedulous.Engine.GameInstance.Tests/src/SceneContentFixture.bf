using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.GameInstance.Tests;

/// A scratch directory, a content database over it, and the scene document types
/// registered: what the load orchestration needs on the other side of the content
/// boundary, since loading a scene is exactly a trip across it.
class SceneContentFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String SceneTypeName = "Sedulous.Scene.Resource.SceneDocument";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so what resolves here is only what
		// this fixture asked for.
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
