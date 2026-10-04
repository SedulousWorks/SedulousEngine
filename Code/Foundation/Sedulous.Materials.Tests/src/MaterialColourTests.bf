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
}
