using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Materials.Pipeline.Tests;

/// The source side material cook: a material authored in code, captured into an asset naming a
/// shader, cooked into a database, and read back.
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

		let shaderId = Guid(0x11223344, 0x5566, 0x7788, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
			0x00);
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
}
