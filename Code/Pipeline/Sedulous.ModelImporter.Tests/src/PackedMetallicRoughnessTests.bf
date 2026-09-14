using System;
using System.Collections;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// Baking a format's separate metalness and roughness maps into the one packed map the
/// renderer samples.
class PackedMetallicRoughnessTests
{
	/// The packed convention is green for roughness and blue for metalness. Wiring either
	/// source straight into the packed slot instead would put its value in EVERY channel, so
	/// the two distinct greys here are what tells the two apart.
	[Test]
	public static void TheTwoGreyMapsLandInTheirOwnChannels()
	{
		let model = scope Model();
		let rough = model.AddTexture(MeshFixture.Gray(200));
		let metal = model.AddTexture(MeshFixture.Gray(60));

		let packed = scope List<uint8>();
		PackedMetallicRoughness.Bake(model, rough, metal, packed, let width, let height);
		Test.Assert(packed.Count == 2 * 2 * 4);
		Test.Assert(width == 2);
		Test.Assert(height == 2);
		Test.Assert(packed[0] == 255); // red carries nothing
		Test.Assert(packed[1] == 200); // green is roughness
		Test.Assert(packed[2] == 60);  // blue is metalness
		Test.Assert(packed[3] == 255);
	}

	/// A MISSING map bakes as identity, so the material's scalar factor still carries the
	/// value rather than being multiplied away by a black channel.
	[Test]
	public static void AMissingMapBakesIdentity()
	{
		let model = scope Model();
		let rough = model.AddTexture(MeshFixture.Gray(200));

		let packed = scope List<uint8>();
		PackedMetallicRoughness.Bake(model, rough, -1, packed, let width, let height);
		Test.Assert(packed.Count == 2 * 2 * 4);
		Test.Assert(packed[1] == 200);
		Test.Assert(packed[2] == 255);
	}

	/// Both sources are DATA maps, so both must be classified linear: decoding one as sRGB
	/// would bend every value it carries.
	[Test]
	public static void BothSourcesClassifyAsData()
	{
		let model = scope Model();
		let rough = model.AddTexture(MeshFixture.Gray(200));
		let metal = model.AddTexture(MeshFixture.Gray(60));

		let material = new ModelMaterial();
		material.SeparateRoughnessTextureIndex = rough;
		material.SeparateMetalnessTextureIndex = metal;
		model.AddMaterial(material);

		let linear = scope List<bool>();
		ModelTextureClassify.LinearTextures(model, linear);
		Test.Assert(linear.Count == 2);
		Test.Assert(linear[0]);
		Test.Assert(linear[1]);
	}
}
