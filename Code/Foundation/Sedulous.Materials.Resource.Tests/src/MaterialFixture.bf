using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders.Resource;
using Sedulous.Shaders;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.Materials.Resource.Tests;

/// A scratch mount, a database, a null device, and the three factories a material's build
/// reaches through: its own, the shader's, and the texture's.
///
/// All three, because the point of the factory is the EDGES it records mid build, and a
/// fixture missing one would test the material in isolation from the thing it depends on.
class MaterialFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;

	public IBackend Backend;
	public IDevice Device;
	public ShaderSystem Shaders ~ delete _;

	public MaterialFactory Materials = new .() ~ delete _;
	public ShaderFactory Shader ~ delete _;
	public TextureFactory Textures ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String MaterialTypeName = "Sedulous.Materials.Resource.MaterialSource";
	public const String ShaderTypeName = "Sedulous.Shaders.Resource.ShaderSource";
	public const String TextureTypeName = "Sedulous.Texture.Resource.TextureResource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		MaterialResources.RegisterAll(Serializables);
		ShaderResources.RegisterAll(Serializables);
		TextureResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		Manager = new ResourceManager(Database, null);

		Backend = NullRhi.CreateBackend();
		if (Backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device))
			Device = device;

		// No compiler: nothing here compiles a variant, and the material only needs the
		// shader's NAME.
		Shaders = new ShaderSystem(Device);
		Shader = new ShaderFactory(Shaders);
		Textures = new TextureFactory(Device);

		Manager.AddFactory(Materials);
		Manager.AddFactory(Shader);
		Manager.AddFactory(Textures);
	}

	public ~this()
	{
		// The shader system holds GPU modules, so it goes before the device.
		delete Shaders;
		Shaders = null;
		if (Device != null)
			Device.Destroy();
		if (Backend != null)
			Backend.Destroy();
		RemoveDirectoryRecursive(mRoot);
	}

	public Guid CookMaterial(StringView name, MaterialSource source)
	{
		let instance = Database.RootGroup.CreateInstance(name, MaterialTypeName);
		instance.WriteObject(source).IgnoreError();
		return instance.Id;
	}

	public Guid CookShader(StringView name)
	{
		let instance = Database.RootGroup.CreateInstance(name, ShaderTypeName);
		let record = scope ShaderSource();
		record.Name.Set(name);
		record.VertexSource.Set("float4 main() : SV_Position { return 0; }");
		record.FragmentSource.Set("float4 main() : SV_Target0 { return 1; }");
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}

	public Guid CookTexture(StringView name)
	{
		let instance = Database.RootGroup.CreateInstance(name, TextureTypeName);
		let record = scope TextureResource();
		record.Width = 2;
		record.Height = 2;
		record.Format = .RGBA8Unorm;
		instance.WriteObject(record).IgnoreError();

		uint8[16] pixels = .();
		instance.WriteData("data", .(&pixels[0], 16)).IgnoreError();
		return instance.Id;
	}
}
