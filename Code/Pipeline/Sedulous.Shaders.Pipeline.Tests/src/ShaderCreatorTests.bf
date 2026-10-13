using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Shaders;
using Sedulous.VFS;

namespace Sedulous.Shaders.Pipeline.Tests;

/// File > New's Shader and a dropped .hlsl: the starter compiles against the engine's library,
/// a new shader links its starter and takes its instance's name, and a dropped file is staged and
/// linked under its stem.
class ShaderCreatorTests
{
	private static ShaderAsset ReadAsset(Instance instance)
	{
		let object = instance.ReadObject();
		return (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ShaderAsset : null;
	}

	[Test]
	public static void TheStarterCompilesEveryVariantAgainstTheEnginesLibrary()
	{
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		{
			let probe = scope ShaderCompiler();
			if (probe.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		var options = ShaderCheckOptions();
		options.ShaderLibrary = DataPath(dataRoot, "Shaders", .. scope .());
		let check = scope ShaderCheck();
		check.Run(ShaderCreators.cStarter, "Shader.hlsl", options);
		for (let error in check.Errors)
			Console.WriteLine(error.Format(.. scope .()));
		Test.Assert(check.IsOk);
		Test.Assert(check.Block.Properties.Count == 6);
		Test.Assert(check.VertexMask == (ShaderFlags.Skinned | .Instanced));
	}

	[Test]
	public static void ANewShaderLinksItsStarterFileAndTakesItsInstancesName()
	{
		ShadersPipeline.RegisterAll();
		let db = "scratch_shader_creator_db";
		let sources = PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), "scratch_shader_creator_src", .. scope .());
		RemoveDirectoryRecursive(db);
		RemoveDirectoryRecursive(sources);
		CreateDirectory(db);
		CreateDirectory(sources);
		defer { RemoveDirectoryRecursive(db); RemoveDirectoryRecursive(sources); }

		let mount = scope NativeFileSystem(db);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let creators = scope AssetCreatorRegistry();
		ShaderCreators.Register(creators);
		let creator = creators.FindByLabel("Low-Level Shader");
		Test.Assert((creator != null) && (creator.Category == "Materials"));

		let first = creator.Create(null, database.RootGroup, sources, "Lava");
		let second = creator.Create(null, database.RootGroup, sources, "Lava");
		Test.Assert((first != null) && (second != null));
		Test.Assert(database.RootGroup.GetGroup("Shaders") != null, "its default folder");

		let asset = ReadAsset(second);
		Test.Assert(asset != null);
		defer delete asset;
		// The second took a unique name, and its shader name and file follow it.
		Test.Assert((asset.Name == second.Name) && (asset.Name != first.Name));
		let expected = scope $"{second.Name}.hlsl";
		Test.Assert(asset.FileName.Value == expected);
		Test.Assert(asset.VertexEntryPoint == "VSMain");
		Test.Assert(FileExists(PathJoin(sources, expected, .. scope .())));
	}

	[Test]
	public static void ADroppedHlslIsStagedIntoSourcesAndLinkedNamedByItsStem()
	{
		ShadersPipeline.RegisterAll();
		let root = PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), "scratch_shader_import", .. scope .());
		let db = "scratch_shader_import_db";
		let sources = PathJoin(root, "Sources", .. scope .());
		RemoveDirectoryRecursive(root);
		RemoveDirectoryRecursive(db);
		CreateDirectory(root);
		CreateDirectory(sources);
		CreateDirectory(db);
		defer { RemoveDirectoryRecursive(root); RemoveDirectoryRecursive(db); }
		let loose = PathJoin(root, "Hologram.hlsl", .. scope .());
		Test.Assert(WriteFile(loose, Span<uint8>((uint8*)ShaderCreators.cStarter.Ptr, ShaderCreators.cStarter.Length)) case .Ok);

		let mount = scope NativeFileSystem(db);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let importer = scope ShaderFileImporter();
		Test.Assert(importer.Accepts("hlsl"));
		Test.Assert(!importer.Accepts("hlsli"), "a library include is not a shader");
		let context = scope ImportContext(sources);
		let imported = importer.Import(loose, context, database.RootGroup, null, null, null);
		Test.Assert(imported case .Ok(let instance));
		let asset = ReadAsset(instance);
		Test.Assert(asset != null);
		defer delete asset;
		Test.Assert((asset.Name == "Hologram") && (asset.FileName.Value == "Hologram.hlsl"));
		Test.Assert(FileExists(PathJoin(sources, "Hologram.hlsl", .. scope .())));
	}

	/// The surface creators: Lit and Unlit Surface Shader beside Low-Level Shader, each starter a
	/// surface shader that compiles, every program and variant, against the engine's library.
	[Test]
	public static void TheSurfaceStartersCompileAsSurfaceShaders()
	{
		let creators = scope AssetCreatorRegistry();
		ShaderCreators.Register(creators);
		Test.Assert(creators.FindByLabel("Lit Surface Shader") != null);
		Test.Assert(creators.FindByLabel("Unlit Surface Shader") != null);
		Test.Assert(creators.FindByLabel("Low-Level Shader") != null);
		Test.Assert(creators.FindByLabel("Shader") == null, "renamed");
		{
			let compiler = scope ShaderCompiler();
			if (compiler.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		var options = ShaderCheckOptions();
		let library = DataPath(FindDataRoot(.. scope String()), "Shaders", .. scope .());
		options.ShaderLibrary = library;
		for (let (text, model) in scope (StringView, SurfaceModel)[]((ShaderCreators.cLitSurfaceStarter, .Lit),
			(ShaderCreators.cUnlitSurfaceStarter, .Unlit)))
		{
			let check = scope ShaderCheck();
			check.Run(text, "Starter.hlsl", options);
			let errors = scope String();
			for (let error in check.Errors)
				error.Format(errors..Append('\n'));
			Test.Assert(check.IsOk, errors);
			Test.Assert(check.Surface == model);
			Test.Assert(!check.HasVertex, "the lava's Vertex() is a commented example");
			Test.Assert(check.Programs.Count == 3);
		}
	}
}
