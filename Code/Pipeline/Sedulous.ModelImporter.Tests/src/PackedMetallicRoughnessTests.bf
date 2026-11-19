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

	/// A base colour's alpha uses are each cutoff its materials test at, and whether one blends.
	/// Leaves tested at two cutoffs (the same cutoff twice counts once), a veil blending with the
	/// same texture, glass (transmissive, drawn blended) with another; an opaque material reads no
	/// alpha, and a normal map is no base colour.
	[Test]
	public static void ABaseColoursAlphaUsesAreEachCutoffAndWhetherOneBlends()
	{
		let model = scope Model();
		let leaves = model.AddTexture(MeshFixture.Gray(255));
		let leavesNormal = model.AddTexture(MeshFixture.Gray(255));
		let bark = model.AddTexture(MeshFixture.Gray(255));
		let glassTexture = model.AddTexture(MeshFixture.Gray(255));
		let grass = model.AddTexture(MeshFixture.Gray(255));
		ModelMaterial Material(AlphaMode mode, float cutoff, int32 baseColour)
		{
			let material = new ModelMaterial();
			material.AlphaMode = mode;
			material.AlphaCutoff = cutoff;
			material.BaseColorTextureIndex = baseColour;
			model.AddMaterial(material);
			return material;
		}
		Material(.Mask, 0.5f, leaves).NormalTextureIndex = leavesNormal;
		Material(.Mask, 0.3f, leaves);
		Material(.Mask, 0.5f, leaves);
		Material(.Blend, 0.5f, leaves);
		Material(.Opaque, 0.5f, bark);
		Material(.Opaque, 0.5f, glassTexture).Transmission = 1.0f;
		Material(.Mask, 0.45f, grass);
		Material(.Opaque, 0.5f, grass); // reads no alpha: grass keeps its cutoff's copy

		let uses = scope List<TextureAlphaUses>();
		defer { ClearAndDeleteItems(uses); }
		ModelTextureClassify.ClassifyBaseColorAlpha(model, uses);
		Test.Assert(uses.Count == 5);
		let leafUses = uses[leaves];
		Test.Assert(leafUses.Cutoffs.Count == 2);
		Test.Assert(leafUses.Cutoffs[0] == ModelTextureClassify.AlphaCutoffStep(0.3f), "ascending, once each");
		Test.Assert(leafUses.Cutoffs[1] == ModelTextureClassify.AlphaCutoffStep(0.5f));
		Test.Assert(leafUses.Blended);
		Test.Assert(leafUses.OwnCutoff == 0, "the veil blends with it: its own asset stays plain");
		Test.Assert(uses[leavesNormal].Cutoffs.IsEmpty);
		Test.Assert(uses[bark].Cutoffs.IsEmpty);
		Test.Assert(!uses[bark].Blended);
		Test.Assert(uses[glassTexture].Blended);
		Test.Assert(uses[grass].OwnCutoff == ModelTextureClassify.AlphaCutoffStep(0.45f), "its own asset keeps the cutoff");
		Test.Assert(ModelTextureClassify.AlphaCopySuffix(ModelTextureClassify.AlphaCutoffStep(0.5f), .. scope .())
			!= ModelTextureClassify.AlphaCopySuffix(ModelTextureClassify.AlphaCutoffStep(0.3f), .. scope .()));
	}
}
