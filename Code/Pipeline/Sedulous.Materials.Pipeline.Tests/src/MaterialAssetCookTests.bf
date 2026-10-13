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

	/// The layout the cook applies, called directly (the editor previews a shader's material and
	/// re-lays a material out when its shader is switched): with nothing authored, every property
	/// takes the shader's default; the render state comes from the authored material.
	[Test]
	public static void AShadersTableLaysOutAFreshMaterialWithItsDefaults()
	{
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("properties {\n  Color BaseColor = (1, 0.5, 0.25, 1);\n  float Roughness = 0.7;\n  int Steps = 4;\n  Texture AlbedoMap;\n  Sampler MainSampler;\n}\n", block);
		Test.Assert(block.IsOk);
		let shader = scope ShaderSource();
		shader.Name.Set("lava");
		shader.SetProperties(block);

		let authored = scope MaterialSource();
		authored.Name.Set("preview");
		authored.BlendMode = .AlphaBlend;
		let product = scope MaterialSource();
		MaterialShaderLayout.LayOut(authored, shader, product);

		Test.Assert(product.Name == "preview");
		Test.Assert(product.ShaderName == "lava", "drawn with the shader's name");
		Test.Assert(product.BlendMode == .AlphaBlend);
		Test.Assert((product.PropertyNames.Count == 5) && (product.PropertyNames[3] == "AlbedoMap"));
		Test.Assert(product.TextureSlots.IsEmpty, "nothing bound: the slot takes the system default");
		Test.Assert(product.UniformDefaults.Count == (int)block.UniformSize);
		Test.Assert(Near(*(float*)(product.UniformDefaults.Ptr + 4), 0.5f));
		Test.Assert(Near(*(float*)(product.UniformDefaults.Ptr + 16), 0.7f));
		Test.Assert(*(int32*)(product.UniformDefaults.Ptr + 20) == 4);
	}

	/// A material moved to another shader keeps what still fits: a PBR material moved to the
	/// built-in Unlit keeps its BaseColor and its albedo texture; what Unlit lacks is dropped.
	[Test]
	public static void ValuesCarryOntoAnotherShadersLayoutByNameTypeAndSize()
	{
		let pbrMaterial = MaterialPresets.CreatePbr("m");
		defer delete pbrMaterial;
		let unlitMaterial = MaterialPresets.CreateUnlit("m");
		defer delete unlitMaterial;
		let pbr = scope MaterialSource();
		MaterialSource.FromMaterial(pbrMaterial, Guid(), pbr);
		let unlit = scope MaterialSource();
		MaterialSource.FromMaterial(unlitMaterial, Guid(), unlit);

		int IndexOf(MaterialSource source, StringView name)
		{
			for (int i < source.PropertyNames.Count)
				if (source.PropertyNames[i] == name)
					return i;
			return -1;
		}
		let baseIndex = IndexOf(pbr, "BaseColor");
		Test.Assert(baseIndex >= 0);
		Float4 red = .(1, 0, 0, 1);
		Internal.MemCpy(&pbr.UniformDefaults[(int)pbr.PropertyOffsets[baseIndex]], &red, sizeof(Float4));
		let albedo = Guid(5, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		pbr.TextureSlots.Add(new String("AlbedoMap"));
		pbr.TextureIds.Add(albedo);
		pbr.TextureSlots.Add(new String("NormalMap")); // Unlit has none
		pbr.TextureIds.Add(Guid(7, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0));

		MaterialShaderLayout.CarryValues(pbr, unlit);

		let unlitBase = IndexOf(unlit, "BaseColor");
		Test.Assert(unlitBase >= 0);
		let carried = *(Float4*)(unlit.UniformDefaults.Ptr + unlit.PropertyOffsets[unlitBase]);
		Test.Assert((carried.X == 1.0f) && (carried.Y == 0.0f));
		Test.Assert((unlit.TextureSlots.Count == 1) && (unlit.TextureSlots[0] == "AlbedoMap") && (unlit.TextureIds[0] == albedo));
	}

	/// A material switched onto a custom shader and back, as the material page's Shader row does
	/// it: on the shader it is the shader's layout with the shader's name and id, its BaseColor and
	/// render state kept; back on the built-in Unlit it is Unlit's layout, the id nil, the colour and
	/// state still kept.
	[Test]
	public static void AMaterialMovesOntoACustomShaderAndBackKeepingWhatFits()
	{
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("properties {\n  float Speed = 3;\n  Color BaseColor = (1, 1, 1, 1);\n}\n", block);
		Test.Assert(block.IsOk);
		let shader = scope ShaderSource();
		shader.Name.Set("lava");
		shader.SetProperties(block);

		let pbrMaterial = MaterialPresets.CreatePbr("m");
		defer delete pbrMaterial;
		let source = scope MaterialSource();
		MaterialSource.FromMaterial(pbrMaterial, Guid(), source);
		source.CullMode = .None;
		Float4 red = .(1, 0, 0, 1);
		Test.Assert(MaterialSourceRead.Write(source, "BaseColor", red));

		let lava = Guid(3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5);
		MaterialShaderLayout.SetShader(source, lava, shader);
		Test.Assert((source.ShaderId == lava) && (source.ShaderName == "lava"));
		Test.Assert((source.PropertyNames.Count == 2) && (source.PropertyNames[0] == "Speed"));
		Test.Assert(source.CullMode == .None);
		Test.Assert(MaterialSourceRead.Read<Float4>(source, "BaseColor") == red);
		Test.Assert(MaterialSourceRead.Read<float>(source, "Speed") == 3.0f, "the shader's default");

		MaterialShaderLayout.SetBuiltInShader(source, true);
		Test.Assert(source.ShaderId.IsNil && (source.ShaderName == "unlit"));
		Test.Assert(MaterialSourceRead.Find(source, "Speed") < 0, "Unlit's layout");
		Test.Assert(source.CullMode == .None);
		Test.Assert(MaterialSourceRead.Read<Float4>(source, "BaseColor") == red);
	}
}

/// Reads and writes a source's packed uniform by name, for the tests.
static class MaterialSourceRead
{
	public static int Find(MaterialSource source, StringView name)
	{
		for (int i < source.PropertyNames.Count)
			if (source.PropertyNames[i] == name)
				return i;
		return -1;
	}

	public static T Read<T>(MaterialSource source, StringView name)
	{
		let index = Find(source, name);
		Test.Assert(index >= 0);
		return *(T*)(source.UniformDefaults.Ptr + source.PropertyOffsets[index]);
	}

	public static bool Write<T>(MaterialSource source, StringView name, T value)
	{
		let index = Find(source, name);
		if (index < 0)
			return false;
		var v = value;
		Internal.MemCpy(source.UniformDefaults.Ptr + source.PropertyOffsets[index], &v, sizeof(T));
		return true;
	}
}
