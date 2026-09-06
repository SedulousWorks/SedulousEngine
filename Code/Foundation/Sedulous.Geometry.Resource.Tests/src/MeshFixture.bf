using System;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Resource;
using Sedulous.Core;
using Sedulous.VFS;

namespace Sedulous.Geometry.Resource.Tests;

/// A scratch mount, a content database over it, and a resource manager with the mesh
/// factories registered. The whole stack, so nothing here is measured against a stand-in.
class MeshFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;
	public StaticMeshFactory StaticMeshes = new .() ~ delete _;
	public SkinnedMeshFactory SkinnedMeshes = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView root, JobSystem jobs = null)
	{
		GeometryResources.RegisterAll();

		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset");
		Manager = new ResourceManager(Database, jobs);

		Manager.AddFactory(StaticMeshes);
		Manager.AddFactory(SkinnedMeshes);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Cooks a mesh into the database and returns its identity.
	public Guid CookStatic(StringView name, StaticMesh mesh)
	{
		let instance = Database.RootGroup.CreateInstance(name, "Sedulous.Geometry.StaticMeshSource");
		let source = scope StaticMeshSource();
		StaticMeshSource.FromMesh(mesh, source);
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}

	public Guid CookSkinned(StringView name, SkinnedMesh mesh)
	{
		let instance = Database.RootGroup.CreateInstance(name, "Sedulous.Geometry.SkinnedMeshSource");
		let source = scope SkinnedMeshSource();
		SkinnedMeshSource.FromMesh(mesh, source);
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}

	/// Writes a source object directly, for the cases that need a payload a cook would
	/// never produce.
	public Guid Store(StringView name, StringView typeName, ISerializable source)
	{
		let instance = Database.RootGroup.CreateInstance(name, typeName);
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}
}
