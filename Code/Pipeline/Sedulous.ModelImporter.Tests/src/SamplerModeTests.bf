using System;
using Sedulous.Model;
using Sedulous.RHI;

namespace Sedulous.ModelImporter.Tests;

/// A model's wrap modes as the renderer's.
class SamplerModeTests
{
	/// The two enumerations list the same three modes in a DIFFERENT order, so this is the
	/// case that fails if the conversion is ever replaced by a cast.
	[Test]
	public static void WrapModesConvertRatherThanCast()
	{
		Test.Assert(ModelSamplerModes.FromWrap(.Repeat) == AddressMode.Repeat);
		Test.Assert(ModelSamplerModes.FromWrap(.MirroredRepeat) == AddressMode.MirrorRepeat);
		Test.Assert(ModelSamplerModes.FromWrap(.ClampToEdge) == AddressMode.ClampToEdge);
	}

	/// The base colour's sampler is the one a material takes, and a material naming no sampler
	/// at all repeats, which is the format's own default.
	[Test]
	public static void AMaterialTakesItsBaseColourTexturesSampler()
	{
		let model = scope Model();
		var sampler = TextureSampler();
		sampler.WrapS = .ClampToEdge;
		sampler.WrapT = .MirroredRepeat;
		let samplerIndex = model.AddSampler(sampler);

		let texture = MeshFixture.Gray(128);
		texture.SamplerIndex = samplerIndex;
		let textureIndex = model.AddTexture(texture);

		let material = new ModelMaterial();
		material.BaseColorTextureIndex = textureIndex;
		model.AddMaterial(material);

		ModelSamplerModes.For(model, material, let u, let v);
		Test.Assert(u == AddressMode.ClampToEdge);
		Test.Assert(v == AddressMode.MirrorRepeat);

		let plain = new ModelMaterial();
		model.AddMaterial(plain);
		ModelSamplerModes.For(model, plain, let plainU, let plainV);
		Test.Assert(plainU == AddressMode.Repeat);
		Test.Assert(plainV == AddressMode.Repeat);
	}
}
