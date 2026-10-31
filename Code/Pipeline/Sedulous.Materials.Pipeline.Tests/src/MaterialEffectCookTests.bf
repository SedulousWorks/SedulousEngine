using System;
using System.Collections;
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
using Sedulous.Xml.Serialization;

namespace Sedulous.Materials.Pipeline.Tests;

/// The effect groups across the material pipeline: they follow the shader's vertex variants (a
/// material moved between two shaders that declare WIND keeps its Wind group, values and all; one
/// moved to a shader that does not, loses it), and a stored sample material of data version three
/// reads, migrates its wind lanes into a Wind group, and cooks.
class MaterialEffectCookTests
{
	private const String cRoot = "scratch_materials_effects";

	private static ShaderEffect WindTable()
	{
		let block = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("effect Wind : WIND\n{\n    float Strength = 0 [0, 2] (gate);\n" +
			"    float Speed = 1 [0, 20];\n    float Height = 1 [0.01, 100];\n}\n", 0, block);
		Test.Assert(block.IsOk);
		let effect = new ShaderEffect();
		block.Effect.CopyTo(effect);
		return effect;
	}

	/// The float at `offset` in the source's first group (Wind: Strength 0, Speed 4, Height 8).
	private static float WindValueOf(MaterialSource source, int offset = 0)
	{
		if (source.Effects.IsEmpty || (source.Effects[0].Values.Count < offset + sizeof(float)))
			return -1.0f;
		return *(float*)(source.Effects[0].Values.Ptr + offset);
	}

	[Test]
	public static void AMaterialKeepsItsWindGroupOnAShaderThatDeclaresWindAndLosesItOnOneThatDoesNot()
	{
		let wind = WindTable();
		defer delete wind;
		let card = MaterialPresets.CreatePbr("card");
		defer delete card;
		card.AddEffectGroup(wind);
		card.SetDefaultFloat("Wind.Strength", 0.4f);
		let source = scope MaterialSource();
		MaterialSource.FromMaterial(card, .(), source);
		Test.Assert(source.Effects.Count == 1);

		// Built-in to built-in: Phong's vertex stage declares WIND as PBR's does.
		MaterialShaderLayout.SetBuiltInShader(source, .Phong);
		Test.Assert((source.Effects.Count == 1) && (source.Effects[0].Name == "Wind"));
		Test.Assert(Math.Abs(WindValueOf(source) - 0.4f) < 1e-5f);

		// To a custom shader whose vertex stage declares WIND: kept.
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Parse("properties {\n  Color BaseColor = (1, 1, 1, 1);\n}\n", block);
		Test.Assert(block.IsOk);
		let sways = scope ShaderSource();
		sways.Name.Set("sways");
		sways.SetProperties(block);
		sways.VertexVariantMask = (uint32)(ShaderFlags.Skinned | .Wind);
		MaterialShaderLayout.SetShader(source, Guid(1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0), sways);
		Test.Assert(source.Effects.Count == 1);
		Test.Assert(Math.Abs(WindValueOf(source) - 0.4f) < 1e-5f);

		// To one that does not: dropped.
		let still = scope ShaderSource();
		still.Name.Set("still");
		still.SetProperties(block);
		still.VertexVariantMask = (uint32)ShaderFlags.Skinned;
		MaterialShaderLayout.SetShader(source, Guid(3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0), still);
		Test.Assert(source.Effects.IsEmpty);

		// Back on a built-in: no group to carry, so none (the factory gives it the effect's
		// defaults where it has the shader system).
		MaterialShaderLayout.SetBuiltInShader(source, .Pbr);
		Test.Assert(source.Effects.IsEmpty);
	}

	/// A stored PaperKid material, the file as it is tracked (data version three, the wind in
	/// PBR's lanes, off): it reads, migrates into a Wind group holding the lanes' values, and
	/// cooks to a source of today's PBR layout.
	[Test]
	public static void AStoredSampleMaterialReadsMigratesAndCooks()
	{
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		let stored = PathJoin(dataRoot, "SampleProjects/PaperKid/Content/Models/KidBike/KidBike/Skin.xasset", .. scope String());
		let text = scope List<uint8>();
		Test.Assert(ReadFile(stored, text) case .Ok, stored);

		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }
		Test.Assert(WriteFile(PathJoin(cRoot, "Skin.xasset", .. scope String()), text) case .Ok);

		MaterialResources.RegisterAll();
		MaterialsPipeline.RegisterAll();
		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory xml = scope (stream, mode) => new XmlSerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, xml, "xasset");
		let instance = database.GetInstance(Guid.Parse("4ae6c178-f80c-6b4a-a6d3-085450837775").Value);
		Test.Assert(instance != null);
		let object = instance.ReadObject();
		Test.Assert(object != null);
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as MaterialAsset;
		Test.Assert(asset != null);
		defer delete asset;

		let source = asset.Source;
		Test.Assert(source.ShaderName == "forward");
		for (let name in source.PropertyNames)
			Test.Assert(!name.StartsWith("Wind"), name);
		Test.Assert(source.Effects.Count == 1);
		Test.Assert(source.Effects[0].Name == "Wind");
		// The lanes' stored values (24, 28 and 60 in its buffer): off, still, the default height.
		Test.Assert(WindValueOf(source, 0) == 0.0f);
		Test.Assert(WindValueOf(source, 4) == 0.0f);
		Test.Assert(WindValueOf(source, 8) == 1.0f);
		Test.Assert(ForwardMaterialContract.IsComplete(source));

		// Cooked: today's PBR table, the group carried.
		let cookedMount = scope NativeFileSystem(PathJoin(cRoot, "cooked", .. scope String()));
		CreateDirectory(PathJoin(cRoot, "cooked", .. scope String()));
		SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let cookedDatabase = scope ContentDatabase(cookedMount, binary, "rasset");
		let output = cookedDatabase.RootGroup.CreateInstance("Skin", "Sedulous.Materials.Resource.MaterialSource");
		let context = scope AssetBuildContext();
		context.Output = output;
		Test.Assert(scope MaterialAssetBuilder().Build(asset, context) case .Ok);
		let cookedObject = cookedDatabase.ReadObject(output.Id);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(cookedObject)) as MaterialSource;
		Test.Assert(cooked != null);
		defer delete cooked;
		let pbr = MaterialPresets.CreatePbr("today");
		defer delete pbr;
		Test.Assert(cooked.PropertyNames.Count == pbr.PropertyCount);
		Test.Assert((cooked.Effects.Count == 1) && (cooked.Effects[0].Name == "Wind"));
	}
}
