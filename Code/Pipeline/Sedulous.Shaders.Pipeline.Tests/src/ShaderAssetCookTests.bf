using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;

namespace Sedulous.Shaders.Pipeline.Tests;

/// The source side shader cook: two files on a mount, inlined into one cooked shader.
class ShaderAssetCookTests
{
	private const String cSourceRoot = "scratch_shaders_pipeline_src";
	private const String cCookedRoot = "scratch_shaders_pipeline_out";
	private const String cProductType = "Sedulous.Shaders.Resource.ShaderSource";

	private const String cVertex =
		"float4 main(uint id : SV_VertexID) : SV_Position { return float4(0,0,0,1); }\n";
	private const String cFragment = "float4 main() : SV_Target { return float4(1,0,0,1); }\n";

	private static void Save(NativeFileSystem mount, StringView name, StringView text)
		=> Test.Assert(mount.Save(name, Span<uint8>((uint8*)text.Ptr, text.Length)) case .Ok);

	[Test]
	public static void BothSourceFilesAreInlinedIntoTheCookedShader()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		defer
		{
			RemoveDirectoryRecursive(cSourceRoot);
			RemoveDirectoryRecursive(cCookedRoot);
		}

		ShadersPipeline.RegisterAll();
		ShaderResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		Save(sourceMount, "lit.vs.hlsl", cVertex);
		Save(sourceMount, "lit.fs.hlsl", cFragment);

		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("lit", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope ShaderAsset();
			ShaderImporter.Import("lit", "lit.vs.hlsl", "lit.fs.hlsl", asset);

			let builder = scope ShaderAssetBuilder();
			Test.Assert(builder.AssetType == typeof(ShaderAsset));

			// The FRAGMENT file is a second source input, the vertex one being the implicit
			// file name, so editing it has to dirty this shader's recipe.
			let dependencies = scope AssetDependencies();
			builder.ScanDependencies(asset, scope AssetBuildContext(), dependencies);
			Test.Assert(dependencies.Files.Count == 1);
			Test.Assert(dependencies.Files[0].Value == "lit.fs.hlsl");

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let object = database.ReadObject(id);
		Test.Assert(object != null);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ShaderSource;
		Test.Assert(cooked != null);
		defer delete cooked;

		Test.Assert(cooked.Name == "lit");
		Test.Assert(cooked.VertexSource == cVertex);
		Test.Assert(cooked.FragmentSource == cFragment);
	}

	/// A source file that is not there is an ERROR rather than an empty shader: an empty one
	/// would cook, ship, and fail to draw with nothing said about why.
	[Test]
	public static void AMissingSourceFileFailsTheBuild()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		defer
		{
			RemoveDirectoryRecursive(cSourceRoot);
			RemoveDirectoryRecursive(cCookedRoot);
		}

		ShadersPipeline.RegisterAll();
		ShaderResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("missing", cProductType);
		Test.Assert(instance != null);

		let asset = scope ShaderAsset();
		ShaderImporter.Import("missing", "does_not_exist.vs.hlsl", "does_not_exist.fs.hlsl", asset);

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope ShaderAssetBuilder().Build(asset, context) case .Err);
	}
}
