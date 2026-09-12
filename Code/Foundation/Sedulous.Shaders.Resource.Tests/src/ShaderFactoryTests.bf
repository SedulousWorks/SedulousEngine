using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Resource;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;

namespace Sedulous.Shaders.Resource.Tests;

/// Authoring a shader into a content database and loading it back as a runtime handle,
/// through the whole stack rather than against a stand in.
class ShaderFactoryTests
{
	/// A scratch mount, a database over it, a null device, a shader system, and the factory.
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;
		public IBackend Backend;
		public IDevice Device;
		public Sedulous.Shaders.ShaderCompiler Compiler ~ delete _;
		public ShaderSystem Shaders ~ delete _;
		public ShaderFactory Shader ~ delete _;

		private String mRoot = new String() ~ delete _;

		public this(StringView root)
		{
			ShaderResources.RegisterAll();

			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			Mount = new NativeFileSystem(mRoot);
			Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Factory, "asset");
			Manager = new ResourceManager(Database, null);

			Backend = NullRhi.CreateBackend();
			let adapters = Backend.EnumerateAdapters();
			if (adapters[0].CreateDevice(.()) case .Ok(let device))
				Device = device;

			let compiler = new Sedulous.Shaders.ShaderCompiler();
			if (compiler.Initialize() case .Ok)
				Compiler = compiler;
			else
				delete compiler;

			Shaders = (Compiler != null) ? new ShaderSystem(Compiler, Device)
				: new ShaderSystem(Device);
			Shader = new ShaderFactory(Shaders);
			Manager.AddFactory(Shader);
		}

		public ~this()
		{
			// The shader system holds GPU modules, so it goes before the device does. The
			// field order handles that, and this only tears down what the fixture created
			// outside of it.
			delete Shaders;
			Shaders = null;
			if (Device != null)
				Device.Destroy();
			if (Backend != null)
			{
				Backend.Destroy();
				delete Backend;
			}
			RemoveDirectoryRecursive(mRoot);
		}

		/// Authors a shader whose fragment stage depends on a flag, so a variant request is
		/// distinguishable.
		public Guid Cook(StringView name, StringView fragment = default)
		{
			let instance = Database.RootGroup.CreateInstance(name,
				"Sedulous.Shaders.Resource.ShaderSource");

			let record = scope ShaderSource();
			record.Name.Set(name);
			record.VertexSource.Set("""
				float4 main(uint id : SV_VertexID) : SV_Position {
				    return float4(0, 0, 0, 1);
				}
				""");
			record.FragmentSource.Set(fragment.IsEmpty ? """
				float4 main() : SV_Target0 {
				#ifdef SKINNED
				    return float4(1, 0, 0, 1);
				#else
				    return float4(0, 0, 1, 1);
				#endif
				}
				""" : fragment);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}
	}

	/// An authored shader loads as a handle whose variants resolve through the shared system.
	[Test]
	public static void AnAuthoredShaderLoadsAsAHandle()
	{
		let fixture = scope Fixture("scratch_shader_resource");
		if (fixture.Compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		let id = fixture.Cook("material");
		let proxy = fixture.Manager.Bind<ShaderResource>(id);
		let shader = proxy.Get;

		Test.Assert(shader != null, "the record built a product");
		Test.Assert(shader.Name == "material");

		// The variants come from the SHARED system, which the factory registered the
		// sources with. Nothing was registered by hand here.
		Test.Assert(shader.GetVariant(.Vertex, .None) != null);
		Test.Assert(shader.GetVariant(.Fragment, .None) != null);

		// The flag reaches the compile, so it is a different module.
		let plain = shader.GetVariant(.Fragment, .None);
		let skinned = shader.GetVariant(.Fragment, .Skinned);
		Test.Assert(skinned !== plain, "a flagged variant is its own module");
	}

	/// Building the resource INVALIDATES the shader, so a reload drops stale variants and
	/// moves the version a pipeline cache watches.
	[Test]
	public static void BuildingInvalidatesAndBumpsTheVersion()
	{
		let fixture = scope Fixture("scratch_shader_reload");
		if (fixture.Compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		let id = fixture.Cook("reloaded");
		let proxy = fixture.Manager.Bind<ShaderResource>(id);
		let shader = proxy.Get;
		Test.Assert(shader != null);

		// The factory invalidated on build, so the version has already moved off zero.
		let afterBuild = shader.Version;
		Test.Assert(afterBuild >= 1, "the build bumped the version");

		let before = shader.GetVariant(.Fragment, .None);
		Test.Assert(before != null);

		// A second build, as a reload would do.
		fixture.Shaders.RegisterSource("reloaded", .Fragment,
			"float4 main() : SV_Target0 { return float4(0, 1, 0, 1); }");
		fixture.Shaders.InvalidateShader("reloaded");

		Test.Assert(shader.Version > afterBuild, "the version moved again");
		let after = shader.GetVariant(.Fragment, .None);
		Test.Assert(after != null, "and the shader still resolves");
	}

	/// A handle with no system behind it answers rather than crashing, which is the shape a
	/// caller sees if a product outlives its system.
	[Test]
	public static void AnUninitializedHandleIsHarmless()
	{
		let shader = scope ShaderResource();
		Test.Assert(shader.Name.IsEmpty);
		Test.Assert(shader.Version == 0);
		Test.Assert(shader.GetVariant(.Fragment, .None) == null);
	}

	/// A record with no name builds nothing: the name is the key every variant is stored
	/// under, so an empty one would collide with every other unnamed shader.
	[Test]
	public static void AnUnnamedRecordIsRefused()
	{
		let fixture = scope Fixture("scratch_shader_unnamed");

		let instance = fixture.Database.RootGroup.CreateInstance("unnamed",
			"Sedulous.Shaders.Resource.ShaderSource");
		let record = scope ShaderSource();
		record.VertexSource.Set("float4 main() : SV_Position { return 0; }");
		instance.WriteObject(record).IgnoreError();

		let proxy = fixture.Manager.Bind<ShaderResource>(instance.Id);
		Test.Assert(proxy.Get == null, "an unnamed record produces no product");
	}
}
