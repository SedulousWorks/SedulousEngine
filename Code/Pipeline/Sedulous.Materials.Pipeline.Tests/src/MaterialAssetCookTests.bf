using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;
using System.Collections;

namespace Sedulous.Materials.Pipeline.Tests;

/// The source side material cook: a material authored in code, captured into an asset naming a
/// shader, cooked into a database, and read back. On a built-in shader the authored layout is the
/// product's; on a custom shader the shader's cooked property table lays the product out and the
/// authored material supplies the values.
///
/// No GPU and no shader compiler: what a material cook produces is AUTHORING data, and the
/// declared properties and their packed defaults are the whole of it.
class MaterialAssetCookTests
{
	private const String cRoot = "scratch_materials_pipeline";
	private const String cProductType = "Sedulous.Materials.Resource.MaterialSource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	[Test]
	public static void AnAuthoredMaterialCooksIntoItsSource()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		MaterialResources.RegisterAll();
		MaterialsPipeline.RegisterAll();

		// A built-in shader, by name: no shader asset to lay the material out by.
		let shaderId = Guid();
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("lit", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let builder = scope MaterialBuilder("litMat");
			builder.Shader("lit")
				.Transparent()
				.Color("tint", .(0.1f, 0.2f, 0.3f, 1.0f))
				.Float("metallic", 0.7f)
				.Texture("albedoMap");
			// The builder hands the material over and is empty afterwards.
			let authored = builder.Build();
			defer delete authored;

			let asset = scope MaterialAsset();
			MaterialSource.FromMaterial(authored, shaderId, asset.Source);

			let assetBuilder = scope MaterialAssetBuilder();
			Test.Assert(assetBuilder.AssetType == typeof(MaterialAsset));
			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(assetBuilder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let object = database.ReadObject(id);
		Test.Assert(object != null);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as MaterialSource;
		Test.Assert(cooked != null);
		defer delete cooked;

		Test.Assert(cooked.Name == "litMat");
		Test.Assert(cooked.ShaderId == shaderId);
		Test.Assert(cooked.BlendMode == .AlphaBlend); // what Transparent asked for
		Test.Assert(cooked.DepthMode == .ReadOnly);

		Test.Assert(cooked.PropertyNames.Count == 3);
		Test.Assert(cooked.PropertyNames[0] == "tint");
		Test.Assert(cooked.PropertyNames[1] == "metallic");
		Test.Assert(cooked.PropertyNames[2] == "albedoMap");
		Test.Assert(cooked.PropertyTypes[2] == (uint8)MaterialPropertyType.Texture2D);

		// The uniform block is the two numeric defaults, packed and rounded to sixteen bytes,
		// which is what a constant buffer wants: a float4 then a float.
		Test.Assert(cooked.UniformDefaults.Count == 32);
		Test.Assert(Near(*(float*)(cooked.UniformDefaults.Ptr + 16), 0.7f));
	}

	/// A material on a custom shader takes its layout from the shader's cooked property table: the
	/// shader's order and offsets, each value from the authored material by name where the type
	/// still matches, else the shader's default; a property or texture the shader no longer has is
	/// dropped. The material reads the shader's content, so a shader edit re-cooks it.
	[Test]
	public static void AMaterialOnACustomShaderIsLaidOutByTheShadersTable()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		MaterialResources.RegisterAll();
		MaterialsPipeline.RegisterAll();
		ShaderResources.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");

		// The cooked shader: Bands moved after a new RimColor, Tint retyped to float, Steps retyped
		// to an int of the same size, ShadowColor unchanged, and AlbedoMap still a texture.
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("properties {\n  Color ShadowColor = (0, 0, 1, 1);\n  Color RimColor = (1, 1, 0, 1);\n  float Bands = 3;\n  float Tint = 0.25;\n  int Steps = 4;\n  Texture AlbedoMap;\n  Sampler MainSampler;\n}\n", block);
		Test.Assert(block.IsOk);
		let shader = scope ShaderSource();
		shader.Name.Set("toon");
		shader.SetProperties(block);
		let shaderInstance = database.RootGroup.CreateInstance("toon", "Sedulous.Shaders.Resource.ShaderSource");
		Test.Assert(shaderInstance.WriteObject(shader) case .Ok);

		// The authored material, from an older version of the shader.
		let authored = scope MaterialBuilder("toonMat")
			..Shader("toon")
			..Color("Tint", .(0.5f, 0.5f, 0.5f, 1.0f)) // now a float
			..Color("ShadowColor", .(0.2f, 0.1f, 0.3f, 1.0f))
			..Float("Bands", 5.0f)
			..Float("Gone", 1.0f) // no longer declared
			..Float("Steps", 2.5f) // now an int, the same size
			..Texture("AlbedoMap")
			..Texture("Removed")
			.Build();
		defer delete authored;
		let asset = scope MaterialAsset();
		MaterialSource.FromMaterial(authored, shaderInstance.Id, asset.Source);
		let albedo = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let removed = Guid(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
		asset.Source.TextureSlots.Add(new String("AlbedoMap"));
		asset.Source.TextureIds.Add(albedo);
		asset.Source.TextureSlots.Add(new String("Removed"));
		asset.Source.TextureIds.Add(removed);

		let builder = scope MaterialAssetBuilder();
		let dependencies = scope AssetDependencies();
		builder.ScanDependencies(asset, scope AssetBuildContext(), dependencies);
		Test.Assert((dependencies.Reads.Count == 1) && (dependencies.Reads[0] == shaderInstance.Id), "a shader edit re-cooks the material");

		let materialInstance = database.RootGroup.CreateInstance("mat", cProductType);
		let context = scope AssetBuildContext();
		context.Database = database;
		context.Output = materialInstance;
		Test.Assert(builder.Build(asset, context) case .Ok);

		let object = database.ReadObject(materialInstance.Id);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as MaterialSource;
		Test.Assert(cooked != null);
		defer delete cooked;
		Test.Assert(cooked.PropertyNames.Count == 7);
		Test.Assert(cooked.PropertyNames[0] == "ShadowColor");
		Test.Assert(cooked.PropertyNames[1] == "RimColor");
		Test.Assert(cooked.PropertyNames[2] == "Bands");
		Test.Assert(cooked.PropertyNames[3] == "Tint");
		Test.Assert(cooked.PropertyTypes[3] == (uint8)MaterialPropertyType.Float);
		Test.Assert(cooked.PropertyOffsets[2] == 32);
		Test.Assert(cooked.UniformDefaults.Count == (int)block.UniformSize);
		float At(int offset) => *(float*)(cooked.UniformDefaults.Ptr + offset);
		Test.Assert(Near(At(0), 0.2f) && Near(At(8), 0.3f), "ShadowColor: the authored value");
		Test.Assert(Near(At(16), 1.0f), "RimColor: new, the shader's default");
		Test.Assert(Near(At(32), 5.0f), "Bands: the authored value at its new offset");
		Test.Assert(Near(At(36), 0.25f), "Tint: retyped, the shader's default");
		Test.Assert(*(int32*)(cooked.UniformDefaults.Ptr + 40) == 4, "Steps: retyped at the same size, the shader's default, an int");
		Test.Assert((cooked.TextureSlots.Count == 1) && (cooked.TextureSlots[0] == "AlbedoMap") && (cooked.TextureIds[0] == albedo));
	}

	/// A material on a custom shader that has not cooked fails, rather than cooking a layout the
	/// shader does not read.
	[Test]
	public static void AMaterialWhoseShaderHasNotCookedFails()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		MaterialResources.RegisterAll();
		MaterialsPipeline.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let authored = scope MaterialBuilder("m")..Shader("custom")..Float("A", 1.0f).Build();
		defer delete authored;
		let asset = scope MaterialAsset();
		MaterialSource.FromMaterial(authored, Guid(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9), asset.Source);
		let context = scope AssetBuildContext();
		context.Database = database;
		context.Output = database.RootGroup.CreateInstance("m", cProductType);
		Test.Assert(scope MaterialAssetBuilder().Build(asset, context) case .Err);
	}
}
