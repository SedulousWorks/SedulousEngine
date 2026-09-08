using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Texture;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.Texture.Resource.Tests;

/// A scratch mount, a content database over it, a null device, and the texture factory
/// registered. The whole stack, because a device backed factory measured against a stand
/// in would prove nothing about the part that needs a device.
class TextureFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public IBackend Backend ~ delete _;
	public IDevice Device;
	public TextureFactory Textures ~ delete _;

	private String mRoot = new .() ~ delete _;

	/// The type name an instance stores. Spelled out, because that string is the format: a
	/// reader resolves the primary by hashing it.
	public const String TypeName = "Sedulous.Texture.Resource.TextureResource";

	public this(StringView root, JobSystem jobs = null)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		// Its own registry rather than the global one, so a test states exactly the types
		// it expects to resolve.
		TextureResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "asset", Serializables);

		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		Textures = new TextureFactory(Device);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Cooks a texture: the record as the primary, the pixels as the "data" stream.
	public Guid Author(StringView name, TextureResource record, Span<uint8> pixels)
	{
		let instance = Database.RootGroup.CreateInstance(name, TypeName);
		instance.WriteObject(record).IgnoreError();
		if (!pixels.IsEmpty)
			instance.WriteData("data", pixels).IgnoreError();
		return instance.Id;
	}

	/// A 2x2 sRGB texture with recognisable bytes.
	public Guid AuthorSimple(StringView name, uint32 width = 2, uint32 height = 2)
	{
		let record = scope TextureResource();
		record.Width = width;
		record.Height = height;
		record.Format = .RGBA8UnormSrgb;
		record.WrapU = .ClampToEdge;
		record.WrapV = .ClampToEdge;
		record.Anisotropy = 8.0f;

		let pixels = scope List<uint8>();
		pixels.Resize((int)width * (int)height * 4);
		for (int i = 0; i < pixels.Count; i++)
			pixels[i] = (uint8)(i * 3);

		return Author(name, record, pixels);
	}
}
