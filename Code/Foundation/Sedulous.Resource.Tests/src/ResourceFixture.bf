using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// A scratch mount, a content database over it, and a resource manager on top: the whole
/// stack, so nothing here is tested against a stand-in.
class ResourceFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;
	private String mRoot = new .() ~ delete _;

	public this(StringView root)
	{
		TestSerializables.RegisterAll();

		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset");
		Manager = new ResourceManager(Database);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Stores a source object and returns its identity.
	public Guid Author(StringView name, int32 width, int32 height)
	{
		let instance = Database.RootGroup.CreateInstance(name, "Sedulous.Resource.Tests.TestSource");
		let source = scope TestSource();
		source.Width = width;
		source.Height = height;
		source.EditorNotePosition = 99;
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}
}
