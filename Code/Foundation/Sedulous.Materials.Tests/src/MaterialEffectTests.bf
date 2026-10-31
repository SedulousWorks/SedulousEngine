using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials.Tests;

/// Effect groups: a material carries an effect's parameters as a group of its own, apart from the
/// shader's properties and its buffer, addressed as `Effect.Property`; an instance overrides them
/// apart from the material's; the material system binds each group's buffer at binding one of the
/// material's set, in the vertex stage.
class MaterialEffectTests
{
	/// An effect's table, as the shader system serves it from an effect block. The caller owns it.
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

	private static float FloatAt(Span<uint8> bytes, uint32 offset)
	{
		if ((int)offset + sizeof(float) > bytes.Length)
			return -1.0f;
		return *(float*)(bytes.Ptr + offset);
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	[Test]
	public static void AGroupFromTheEffectsTableAddressedAsEffectProperty()
	{
		let wind = WindTable();
		defer delete wind;
		let matBuilder = scope MaterialBuilder("card");
		matBuilder..Shader("forward")..Color("BaseColor", .(1, 1, 1, 1))..Effect(wind);
		let mat = matBuilder.Build();
		defer delete mat;
		Test.Assert(mat.PropertyCount == 1, "the group is not a property");
		Test.Assert(mat.UniformDataSize == 16, "nor in the shader's buffer");
		Test.Assert(mat.EffectGroupCount == 1);
		let group = mat.GetEffectGroup(0);
		Test.Assert(group.Name == "Wind");
		Test.Assert(group.Flag == .Wind);
		Test.Assert(group.UniformSize == 16);
		Test.Assert(Near(FloatAt(group.Defaults, 0), 0.0f), "the table's defaults");
		Test.Assert(Near(FloatAt(group.Defaults, 4), 1.0f));
		Test.Assert(Near(FloatAt(group.Defaults, 8), 1.0f));
		Test.Assert(!group.IsActive);

		mat.SetDefaultFloat("Wind.Strength", 0.25f);
		Test.Assert(group.IsActive);
		Test.Assert(mat.FindEffectProperty("Wind.Height", let height, let index));
		Test.Assert((index == 0) && (height.Offset == 8));
		Test.Assert(!mat.FindEffectProperty("Wind.Gust", ?, ?));
		Test.Assert(!mat.FindEffectProperty("Fog.Strength", ?, ?));
		Test.Assert(!mat.FindEffectProperty("BaseColor", ?, ?), "a property's name has no dot");

		// Adopting the effects a shader declares: kept (values and all) while it declares the
		// flag, dropped when it does not.
		ShaderEffect[1] table = .(wind);
		mat.AdoptDeclaredEffects(table, .Skinned | .Wind);
		Test.Assert(mat.EffectGroupCount == 1);
		Test.Assert(Near(FloatAt(mat.GetEffectGroup(0).Defaults, 0), 0.25f));
		mat.AdoptDeclaredEffects(table, .Skinned);
		Test.Assert(mat.EffectGroupCount == 0);
		// And a shader that declares it gives a material without the group one, at the defaults.
		mat.AdoptDeclaredEffects(table, .Wind);
		Test.Assert(mat.EffectGroupCount == 1);
		Test.Assert(!mat.GetEffectGroup(0).IsActive);
	}

	[Test]
	public static void AnInstanceOverridesAGroupsValuesApartFromTheMaterials()
	{
		let wind = WindTable();
		defer delete wind;
		let matBuilder = scope MaterialBuilder("card");
		matBuilder..Shader("forward")..Float("Roughness", 0.5f)..Effect(wind);
		let mat = matBuilder.Build();
		defer delete mat;
		let instance = scope MaterialInstance(mat);
		Test.Assert(Near(FloatAt(instance.EffectData(0), 4), 1.0f));

		instance.ClearUniformDirty();
		instance.SetFloat("Wind.Speed", 6.0f);
		Test.Assert(instance.IsUniformDirty);
		Test.Assert(Near(FloatAt(instance.EffectData(0), 4), 6.0f));
		Test.Assert(Near(FloatAt(mat.GetEffectGroup(0).Defaults, 4), 1.0f), "the material untouched");
		Test.Assert(Near(FloatAt(instance.UniformData, 0), 0.5f), "nor the shader's buffer");

		instance.SetFloat4("Wind.Speed", .(9, 9, 9, 9)); // wider than the parameter: refused
		Test.Assert(Near(FloatAt(instance.EffectData(0), 4), 6.0f));
		instance.SetFloat("WindSpeed", 3.0f); // the old name reaches nothing
		Test.Assert(Near(FloatAt(instance.EffectData(0), 4), 6.0f));

		instance.ResetProperty("Wind.Speed");
		Test.Assert(Near(FloatAt(instance.EffectData(0), 4), 1.0f));
		instance.SetFloat("Wind.Strength", 0.4f);
		instance.SetFloat("Wind.Height", 2.0f);
		instance.ResetEffects();
		Test.Assert(Near(FloatAt(instance.EffectData(0), 0), 0.0f));
		Test.Assert(Near(FloatAt(instance.EffectData(0), 8), 1.0f));
	}

	[Test]
	public static void AnEffectGroupTakesItsOwnBufferInTheMaterialsSet()
	{
		let fixture = scope MaterialSystemFixture();
		let wind = WindTable();
		defer delete wind;
		let plainBuilder = scope MaterialBuilder("plain");
		plainBuilder..Shader("forward")..Color("BaseColor", .(1, 1, 1, 1))..Texture("AlbedoMap")..Sampler("MainSampler");
		let plain = plainBuilder.Build();
		defer delete plain;
		let cardBuilder = scope MaterialBuilder("card");
		cardBuilder..Shader("forward")..Color("BaseColor", .(1, 1, 1, 1))..Texture("AlbedoMap")..Sampler("MainSampler")..Effect(wind);
		let card = cardBuilder.Build();
		defer delete card;

		let plainLayout = fixture.System.GetOrCreateLayout(plain);
		let cardLayout = fixture.System.GetOrCreateLayout(card);
		Test.Assert((plainLayout != null) && (cardLayout != null));
		Test.Assert(cardLayout !== plainLayout, "the group makes it another layout");

		card.SetDefaultFloat("Wind.Strength", 0.3f);
		let instance = scope MaterialInstance(card);
		defer fixture.System.ReleaseInstance(instance);
		instance.SetFloat("Wind.Speed", 4.0f);
		Test.Assert(fixture.System.PrepareInstance(instance) != null);

		// A later override rewrites it.
		instance.SetFloat("Wind.Height", 0.5f);
		fixture.System.PrepareDirtyInstances();

		// Handed over for retirement with the uniform buffer, then gone from the system; it holds
		// the instance's values, by the effect's offsets.
		let detached = scope List<IBuffer>();
		fixture.System.DetachEffectBuffers(instance, detached);
		Test.Assert(detached.Count == 1);
		let written = (uint8*)detached[0].Map();
		Test.Assert(written != null);
		Test.Assert(Near(*(float*)(written + 0), 0.3f));
		Test.Assert(Near(*(float*)(written + 4), 4.0f));
		Test.Assert(Near(*(float*)(written + 8), 0.5f));
		detached[0].Unmap();
		let again = scope List<IBuffer>();
		fixture.System.DetachEffectBuffers(instance, again);
		Test.Assert(again.IsEmpty);
		var buffer = detached[0];
		fixture.Device.DestroyBuffer(ref buffer);
	}
}
