using System;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Shaders;

namespace Sedulous.Render.Tests;

/// WIND: which materials select the sway variant, the flag's name in the variant table, and
/// the standard material's wind lanes sitting in the block's spare slots, so the block stays
/// sixty four bytes and a material without them is byte identical.
class WindTests
{
	[Test]
	public static void AMaterialOptsInThroughAStrengthAboveNought()
	{
		Test.Assert(!MeshRenderer.MaterialWantsWind(null));

		let plain = MaterialPresets.CreatePbr("plain");
		defer delete plain;
		// Declared, but at nought: no sway.
		Test.Assert(!MeshRenderer.MaterialWantsWind(plain));

		let card = MaterialPresets.CreatePbr("card");
		defer delete card;
		card.SetDefaultFloat("WindStrength", 0.2f);
		Test.Assert(MeshRenderer.MaterialWantsWind(card));
		card.SetDefaultFloat("WindStrength", 0.0f);
		Test.Assert(!MeshRenderer.MaterialWantsWind(card));

		// A material without the property, an older cooked source or an unlit one, never sways.
		let unlit = MaterialPresets.CreateUnlit("unlit");
		defer delete unlit;
		Test.Assert(!MeshRenderer.MaterialWantsWind(unlit));
	}

	[Test]
	public static void TheWindLanesAreTheBlocksSpareSlots()
	{
		let pbr = MaterialPresets.CreatePbr("pbr");
		defer delete pbr;

		Test.Assert(pbr.FindProperty("WindStrength", let strength));
		Test.Assert(pbr.FindProperty("WindSpeed", let speed));
		Test.Assert(pbr.FindProperty("WindHeight", let height));
		// The lanes after Roughness, which ends at twenty four.
		Test.Assert(strength.Offset == 24);
		Test.Assert(speed.Offset == 28);
		// And the one after AlphaCutoff.
		Test.Assert(height.Offset == 60);

		// The properties around them have not moved, so an existing cooked material reads the
		// same bytes it always did.
		Test.Assert(pbr.FindProperty("EmissiveColor", let emissive) && (emissive.Offset == 32));
		Test.Assert(pbr.FindProperty("AlphaCutoff", let cutoff) && (cutoff.Offset == 56));
		Test.Assert(pbr.UniformDataSize == 64);

		// The flag names its define, so a stage's variants line can declare it.
		Test.Assert(ShaderFlagNames.FlagFromName("WIND") == .Wind);
	}

	/// The snapshot carries its scene's clock, and a reset clears it, so the frame's own
	/// clock stands in for a snapshot nothing stamped.
	[Test]
	public static void TheSnapshotCarriesItsScenesClockAndAResetClearsIt()
	{
		let scene = scope ExtractedScene();
		Test.Assert(!scene.HasTime);

		scene.SetTime(12.5f, 12.4f);
		Test.Assert(scene.HasTime);
		Test.Assert(scene.TimeSeconds == 12.5f);
		Test.Assert(scene.PrevTimeSeconds == 12.4f);

		scene.Reset();
		Test.Assert(!scene.HasTime);
		Test.Assert(scene.TimeSeconds == 0.0f);
	}
}
