using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Shaders;

namespace Sedulous.Materials.Resource.Tests;

/// Effect groups stored: a version three PBR material's wind lanes migrate into a Wind group as
/// it is read, a material's groups round trip, and the factory with the shader system gives a
/// material the effects its shader declares.
class MaterialEffectSourceTests
{
	private static float FloatAt(List<uint8> bytes, uint32 offset)
	{
		if ((int)offset + sizeof(float) > bytes.Count)
			return -1.0f;
		return *(float*)(bytes.Ptr + offset);
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	private static int IndexOfName(List<String> names, StringView name)
	{
		for (int i < names.Count)
		{
			if (names[i] == name)
				return i;
		}
		return -1;
	}

	/// A PBR material as data version three stored it: the wind in the buffer's spare lanes.
	private static void LegacyPbrSource(MaterialSource outSource, float strength, float speed, float height)
	{
		let builder = scope MaterialBuilder("grass");
		builder..Shader("forward")..VertexLayout(.Mesh)
			..Color("BaseColor", .(0.2f, 0.6f, 0.2f, 1.0f))..Float("Metallic", 0.0f)..Float("Roughness", 0.8f)
			..Float("WindStrength", strength)..Float("WindSpeed", speed)
			..ColorHdr("EmissiveColor", .(0, 0, 0, 1))..Float("OcclusionStrength", 1.0f)..Float("NormalScale", 1.0f)
			..Float("AlphaCutoff", 0.5f)..Float("WindHeight", height)
			..Texture("AlbedoMap")..Texture("NormalMap")..Texture("MetallicRoughnessMap")..Texture("OcclusionMap")
			..Texture("EmissiveMap")..Sampler("MainSampler");
		let old = builder.Build();
		defer delete old;
		MaterialSource.FromMaterial(old, .(), outSource);
		outSource.ShaderName.Set("forward");
	}

	/// The Wind effect's table, as the shader system serves it. The caller owns it.
	public static ShaderEffect WindTable()
	{
		let block = scope ShaderEffectBlock();
		ShaderProperties.ParseEffect("effect Wind : WIND\n{\n    float Strength = 0 [0, 2] (gate);\n" +
			"    float Speed = 1 [0, 20];\n    float Height = 1 [0.01, 100];\n}\n", 0, block);
		Test.Assert(block.IsOk);
		let effect = new ShaderEffect();
		block.Effect.CopyTo(effect);
		return effect;
	}

	private static void RoundTrip(MaterialSource source, MaterialSource outLoaded)
	{
		ISerializable writable = source;
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);
		ISerializable readable = outLoaded;
		let reader = scope BinarySerializer(buffer, .Read);
		readable.Serialize(reader);
		Test.Assert(reader.IsOk);
	}

	[Test]
	public static void AVersionThreePbrMaterialsWindLanesMigrateIntoAWindGroup()
	{
		let source = scope MaterialSource();
		LegacyPbrSource(source, 0.3f, 2.0f, 0.7f);
		Test.Assert(IndexOfName(source.PropertyNames, "WindStrength") == 3);
		let before = source.PropertyNames.Count;
		let bytes = source.UniformDefaults.Count;

		source.MigrateWindLanes();
		Test.Assert(IndexOfName(source.PropertyNames, "WindStrength") < 0);
		Test.Assert(IndexOfName(source.PropertyNames, "WindSpeed") < 0);
		Test.Assert(IndexOfName(source.PropertyNames, "WindHeight") < 0);
		Test.Assert(source.PropertyNames.Count == before - 3);
		Test.Assert(source.PropertyTypes.Count == source.PropertyNames.Count);
		Test.Assert(source.PropertyOffsets.Count == source.PropertyNames.Count);
		Test.Assert(source.PropertySizes.Count == source.PropertyNames.Count);
		Test.Assert(source.PropertyBindings.Count == source.PropertyNames.Count);
		// The rest unmoved, the buffer's bytes as they were (the lanes are padding now).
		let emissive = IndexOfName(source.PropertyNames, "EmissiveColor");
		Test.Assert((emissive >= 0) && (source.PropertyOffsets[emissive] == 32));
		Test.Assert(source.UniformDefaults.Count == bytes);
		// Laid out as today's CreatePbr is: the same table, so it is complete and draws as one.
		let pbr = MaterialPresets.CreatePbr("today");
		defer delete pbr;
		let today = scope MaterialSource();
		MaterialSource.FromMaterial(pbr, .(), today);
		Test.Assert(today.PropertyNames.Count == source.PropertyNames.Count);
		for (int i < today.PropertyNames.Count)
		{
			Test.Assert(source.PropertyNames[i] == today.PropertyNames[i], today.PropertyNames[i]);
			Test.Assert(source.PropertyOffsets[i] == today.PropertyOffsets[i], today.PropertyNames[i]);
			Test.Assert(source.PropertyBindings[i] == today.PropertyBindings[i], today.PropertyNames[i]);
		}
		Test.Assert(ForwardMaterialContract.IsComplete(source));

		// The Wind group, holding the lanes' values.
		Test.Assert(source.Effects.Count == 1);
		let wind = source.Effects[0];
		Test.Assert(wind.Name == "Wind");
		Test.Assert(wind.Flag == (uint32)ShaderFlags.Wind);
		Test.Assert((wind.GateIndex == 0) && (wind.UniformSize == 16));
		Test.Assert(wind.PropertyNames.Count == 3);
		Test.Assert((wind.PropertyNames[0] == "Strength") && (wind.PropertyNames[1] == "Speed") && (wind.PropertyNames[2] == "Height"));
		Test.Assert(Near(FloatAt(wind.Values, 0), 0.3f));
		Test.Assert(Near(FloatAt(wind.Values, 4), 2.0f));
		Test.Assert(Near(FloatAt(wind.Values, 8), 0.7f));

		// Idempotent: nothing left to migrate, the group kept once.
		source.MigrateWindLanes();
		Test.Assert(source.Effects.Count == 1);
		Test.Assert(source.PropertyNames.Count == before - 3);

		// A custom shader's material keeps properties of those names: they are its own.
		let custom = scope MaterialSource();
		LegacyPbrSource(custom, 0.3f, 2.0f, 0.7f);
		custom.ShaderId = Guid.Create(); // any custom shader
		custom.MigrateWindLanes();
		Test.Assert(IndexOfName(custom.PropertyNames, "WindStrength") == 3);
		Test.Assert(custom.Effects.IsEmpty);
	}

	[Test]
	public static void ReadingMigratesAStoredPbrMaterialAndTheGroupRoundTrips()
	{
		let legacy = scope MaterialSource();
		LegacyPbrSource(legacy, 0.0f, 0.0f, 1.0f); // what every stored material holds: wind off
		let read = scope MaterialSource();
		RoundTrip(legacy, read);
		Test.Assert(IndexOfName(read.PropertyNames, "WindStrength") < 0);
		Test.Assert(read.Effects.Count == 1);
		Test.Assert(Near(FloatAt(read.Effects[0].Values, 0), 0.0f));
		Test.Assert(Near(FloatAt(read.Effects[0].Values, 8), 1.0f));

		// And the runtime material carries it, off.
		let material = read.ToMaterial("forward");
		defer delete material;
		Test.Assert(material.EffectGroupCount == 1);
		Test.Assert(material.GetEffectGroup(0).Name == "Wind");
		Test.Assert(material.GetEffectGroup(0).Flag == .Wind);
		Test.Assert(!material.GetEffectGroup(0).IsActive);

		// A material's groups round trip through FromMaterial and the stream.
		material.SetDefaultFloat("Wind.Strength", 0.5f);
		let again = scope MaterialSource();
		MaterialSource.FromMaterial(material, .(), again);
		let back = scope MaterialSource();
		RoundTrip(again, back);
		Test.Assert(back.Effects.Count == 1);
		Test.Assert(Near(FloatAt(back.Effects[0].Values, 0), 0.5f));
		Test.Assert(back.Effects[0].PropertyOffsets.Count == 3);
	}

	[Test]
	public static void WithTheShaderSystemTheFactoryGivesAMaterialTheEffectsItsShaderDeclares()
	{
		let fixture = scope MaterialFixture("scratch_mat_effect_db");
		// A PBR material saved without a group (made where no table was at hand).
		let pbr = MaterialPresets.CreatePbr("sways");
		defer delete pbr;
		let sways = scope MaterialSource();
		MaterialSource.FromMaterial(pbr, .(), sways);
		sways.ShaderName.Set("forward");
		let swaysId = fixture.CookMaterial("sways", sways);
		// A material carrying a group on a shader that does not declare WIND.
		let wind = WindTable();
		defer delete wind;
		let still = MaterialPresets.CreateUnlit("still", .(1, 1, 1, 1), "still_shader");
		defer delete still;
		still.AddEffectGroup(wind);
		let stillSource = scope MaterialSource();
		MaterialSource.FromMaterial(still, .(), stillSource);
		let stillId = fixture.CookMaterial("still", stillSource);

		// A game's shader system: the pack's lattices and effect tables, no compiler.
		let pack = scope CookedShaderPack();
		let error = scope String();
		Test.Assert(pack.AddEffect(wind, error));
		pack.AddDeclaredMask("forward", .Vertex, .Skinned | .Wind);
		pack.AddDeclaredMask("still_shader", .Vertex, .Skinned);
		fixture.Shaders.SetCookedPack(pack);
		defer fixture.Shaders.SetCookedPack(null);
		Test.Assert(fixture.Shaders.DeclaredVariants("forward", .Vertex) == (.Skinned | .Wind));

		let withSystem = scope MaterialFactory(fixture.Shaders);
		fixture.Manager.RemoveFactory(fixture.Materials);
		fixture.Manager.AddFactory(withSystem);
		{
			let swaysMaterial = fixture.Manager.Bind<Material>(swaysId);
			Test.Assert(swaysMaterial.Get != null);
			Test.Assert(swaysMaterial.Get.EffectGroupCount == 1);
			Test.Assert(swaysMaterial.Get.GetEffectGroup(0).Name == "Wind");
			Test.Assert(!swaysMaterial.Get.GetEffectGroup(0).IsActive, "the effect's defaults: off");
			let stillMaterial = fixture.Manager.Bind<Material>(stillId);
			Test.Assert(stillMaterial.Get != null);
			Test.Assert(stillMaterial.Get.EffectGroupCount == 0, "its shader cannot sway");
		}
		fixture.Manager.RemoveFactory(withSystem);
		fixture.Manager.AddFactory(fixture.Materials);
	}

	/// An authoring tool with the effects' tables (the material page, material_set_shader) lays a
	/// source's groups on them as the factory does a runtime material's: a declared effect the
	/// source lacks a group for gains one at its defaults, a group carried keeps its values, a
	/// group whose effect is not declared goes, and no effects leave the stored groups as they are.
	[Test]
	public static void AdoptDeclaredEffectsGivesASourceTheGroupsItsShaderDeclaresKeepingValues()
	{
		let library = scope ShaderEffectLibrary();
		let wind = WindTable();
		defer delete wind;
		Test.Assert(library.Add(wind, scope String()));
		let declares = ShaderFlags.Skinned | .Wind;

		// Made where no table was at hand (every new material): no group, then the effect's defaults.
		let pbr = MaterialPresets.CreatePbr("fresh");
		defer delete pbr;
		let fresh = scope MaterialSource();
		MaterialSource.FromMaterial(pbr, .(), fresh);
		Test.Assert(fresh.Effects.IsEmpty);
		fresh.AdoptDeclaredEffects(library.All, declares);
		Test.Assert(fresh.Effects.Count == 1);
		let group = fresh.Effects[0];
		Test.Assert(group.Name == "Wind");
		Test.Assert(group.Flag == (uint32)ShaderFlags.Wind);
		Test.Assert(group.PropertyNames.Count == 3);
		Test.Assert(Near(FloatAt(group.Values, group.PropertyOffsets[0]), 0.0f), "Strength: off");
		Test.Assert(Near(FloatAt(group.Values, group.PropertyOffsets[1]), 1.0f), "Speed");

		// A group carried keeps its values.
		let windy = MaterialPresets.CreatePbr("windy");
		defer delete windy;
		windy.AddEffectGroup(wind);
		windy.SetDefaultFloat("Wind.Strength", 0.6f);
		let kept = scope MaterialSource();
		MaterialSource.FromMaterial(windy, .(), kept);
		kept.AdoptDeclaredEffects(library.All, declares);
		Test.Assert(kept.Effects.Count == 1);
		Test.Assert(Near(FloatAt(kept.Effects[0].Values, kept.Effects[0].PropertyOffsets[0]), 0.6f));

		// No effects say nothing: the group stands.
		kept.AdoptDeclaredEffects(Span<ShaderEffect>(), .Skinned);
		Test.Assert(kept.Effects.Count == 1);

		// A shader that does not declare WIND: the group goes.
		kept.AdoptDeclaredEffects(library.All, .Skinned);
		Test.Assert(kept.Effects.IsEmpty);
	}
}
