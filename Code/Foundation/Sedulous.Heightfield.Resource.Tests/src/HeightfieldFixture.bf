using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.VFS;

namespace Sedulous.Heightfield.Resource.Tests;

/// A scratch mount, a content database over it, and the heightfield factory: the real cook
/// and bind path rather than a stand in for it.
class HeightfieldFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public HeightfieldFactory Heightfields = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	/// The type name an instance stores. Spelled out, because that string IS the format: a
	/// reader resolves the primary by hashing it.
	public const String TypeName = "Sedulous.Heightfield.Resource.HeightfieldSource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so a test states exactly which types
		// it expects to resolve.
		HeightfieldResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Cooks a grid: the metadata as the primary, the samples as the sidecar stream.
	public Guid Author(StringView name, Heightfield field)
	{
		let source = scope HeightfieldSource();
		HeightfieldSource.FromHeightfield(field, source);

		let instance = Database.RootGroup.CreateInstance(name, TypeName);
		instance.WriteObject(source).IgnoreError();
		instance.WriteData(HeightfieldSource.HeightStream,
			HeightfieldSource.HeightBlob(field)).IgnoreError();
		return instance.Id;
	}

	/// A 65 grid over a 64 by 64 world with a Y range of zero to ten, ramping along +X.
	public static Heightfield MakeRampX()
	{
		let field = new Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		for (int32 z = 0; z < 65; z++)
		{
			for (int32 x = 0; x < 65; x++)
				field.SetSample(x, z, (uint16)((float)x / 64.0f * 65535.0f + 0.5f));
		}
		return field;
	}
}
