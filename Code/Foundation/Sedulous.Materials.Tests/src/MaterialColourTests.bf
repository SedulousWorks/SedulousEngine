using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;

namespace Sedulous.Materials.Tests;

/// A material's colours are authored sRGB and reach the GPU decoded: the colour property
/// types, the one upload encode, and the builtin templates that declare them.
class MaterialColourTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	[Test]
	public static void AuthoredColoursAreDecodedForTheGpuAndAFloat4IsNot()
	{
		let builder = scope MaterialBuilder("colours");
		let material = builder
			..Shader("forward")
			..Color("Tint", .(0.5f, 0.25f, 1.0f, 0.5f))
			..ColorHdr("Glow", .(0.5f, 0.0f, 1.0f, 3.0f))
			..Float4("Params", .(0.5f, 0.5f, 0.5f, 0.5f))
			.Build();
		defer delete material;
		Test.Assert(material.FindProperty("Tint", let tint) && (tint.Type == .Color) && tint.IsColor);
		Test.Assert(material.FindProperty("Glow", let glow) && (glow.Type == .ColorHdr) && glow.IsColor);
		Test.Assert(material.FindProperty("Params", let parameters) && !parameters.IsColor);

		// The authored bytes keep the colour as entered...
		let authored = material.DefaultUniformData;
		Test.Assert(Near(((Float4*)(authored.Ptr + tint.Offset)).X, 0.5f));

		// ...and the GPU's are linear: a Color decoded (alpha as is), a ColorHdr decoded and
		// scaled by its intensity (w of one), a plain Float4 copied.
		let gpu = scope List<uint8>();
		gpu.Resize(authored.Length);
		MaterialUniforms.EncodeForGpu(material, authored, gpu.Ptr);
		Float4 At(MaterialPropertyDef def) => *(Float4*)(gpu.Ptr + def.Offset);
		Test.Assert(Near(At(tint).X, SrgbToLinear(0.5f)));
		Test.Assert(Near(At(tint).Y, SrgbToLinear(0.25f)));
		Test.Assert(Near(At(tint).Z, 1.0f));
		Test.Assert(Near(At(tint).W, 0.5f), "alpha is coverage, not decoded");
		Test.Assert(Near(At(glow).X, SrgbToLinear(0.5f) * 3.0f));
		Test.Assert(Near(At(glow).Z, 3.0f));
		Test.Assert(Near(At(glow).W, 1.0f));
		Test.Assert(Near(At(parameters).X, 0.5f));
		Test.Assert(Near(At(parameters).W, 0.5f));
	}

	[Test]
	public static void TheBuiltinShadersColoursAreColourProperties()
	{
		let pbr = MaterialPresets.BuiltinTemplate("forward");
		Test.Assert(pbr != null);
		defer delete pbr;
		Test.Assert(pbr.FindProperty("BaseColor", let baseColor) && (baseColor.Type == .Color));
		Test.Assert(pbr.FindProperty("EmissiveColor", let emissive) && (emissive.Type == .ColorHdr));
		let unlit = MaterialPresets.BuiltinTemplate("unlit");
		Test.Assert(unlit != null);
		defer delete unlit;
		Test.Assert(unlit.FindProperty("BaseColor", let unlitBase) && (unlitBase.Type == .Color));
		Test.Assert(MaterialPresets.BuiltinTemplate("my_custom_shader") == null);
	}

	[Test]
	public static void ThePhongBuiltinLaysItsCbufferOutAsPhongPsReadsIt()
	{
		let phong = MaterialPresets.BuiltinTemplate("phong");
		Test.Assert(phong != null);
		defer delete phong;
		Test.Assert(phong.ShaderName == "phong");
		// The order phong.ps.hlsl's Material cbuffer declares, in 64 bytes.
		StringView[6] names = .("BaseColor", "SpecularColor", "EmissiveColor", "Shininess", "NormalScale", "AlphaCutoff");
		MaterialPropertyType[6] types = .(.Color, .Color, .ColorHdr, .Float, .Float, .Float);
		uint32[6] offsets = .(0, 16, 32, 48, 52, 56);
		for (int i < 6)
		{
			Test.Assert(phong.FindProperty(names[i], let found), scope String(names[i]));
			Test.Assert(found.Type == types[i], scope String(names[i]));
			Test.Assert(found.Offset == offsets[i], scope String(names[i]));
		}
		// Its maps in their slots, t0 to t3, then the sampler.
		for (let map in StringView[4]("AlbedoMap", "SpecularMap", "NormalMap", "EmissiveMap"))
		{
			Test.Assert(phong.FindProperty(map, let found), scope String(map));
			Test.Assert(found.Type == .Texture2D);
		}
		Test.Assert(phong.FindProperty("MainSampler", let sampler) && (sampler.Type == .Sampler));
		// No wind: a Phong material never asks for the swaying vertex variant.
		Test.Assert(!phong.FindProperty("WindStrength", ?));
	}

	[Test]
	public static void EachBuiltinIsKnownByItsShaderItsShortNameAndItsLabel()
	{
		Test.Assert(MaterialPresets.cBuiltinShadingCount == 3);
		Test.Assert(MaterialPresets.FindBuiltinShadingByShader("forward").Value.Shading == .Pbr);
		Test.Assert(MaterialPresets.FindBuiltinShadingByShader("unlit").Value.Shading == .Unlit);
		Test.Assert(MaterialPresets.FindBuiltinShadingByShader("phong").Value.Shading == .Phong);
		Test.Assert(!MaterialPresets.FindBuiltinShadingByShader("toon").HasValue);
		Test.Assert(MaterialPresets.FindBuiltinShadingByShortName("phong").Value.ShaderName == "phong");
		Test.Assert(MaterialPresets.FindBuiltinShadingByShortName("pbr").Value.ShaderName == "forward");
		Test.Assert(!MaterialPresets.FindBuiltinShadingByShortName("forward").HasValue);
		for (int i < MaterialPresets.cBuiltinShadingCount)
		{
			// Each made from its own builtin.
			let made = MaterialPresets.CreateBuiltin(MaterialPresets.BuiltinShadings[i].Shading, "m");
			defer delete made;
			Test.Assert(made.ShaderName == MaterialPresets.BuiltinShadings[i].ShaderName);
			Test.Assert((int)MaterialPresets.BuiltinShadings[i].Shading == i, "the table is in the enum's order");
		}
	}
}
