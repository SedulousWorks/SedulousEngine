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

	/// The depth like passes (the depth prepass, the shadow maps, the pick): the built-in programs,
	/// or a material's own when its shader has them, which then bind the material's set two they
	/// were generated for.
	[Test]
	public static void AMaterialsOwnDepthAndPickProgramsReplaceTheBuiltIns()
	{
		let context = RenderRecordContext();
		let plain = MaterialPresets.CreatePbr("plain");
		defer delete plain;
		let builtIn = MeshRenderer.DepthLikeFor(context, plain, false, false);
		Test.Assert(builtIn.Config.ShaderName == "shadow_depth");
		Test.Assert(!builtIn.MaterialSet, "opaque, still: no set two");
		Test.Assert(builtIn.Config.DepthOnly);

		let waves = MaterialPresets.CreatePbr("waves");
		defer delete waves;
		waves.DepthShaderName.Set("waves.depth");
		waves.PickShaderName.Set("waves.pick");
		waves.Pipeline.CullMode = .None;
		let depth = MeshRenderer.DepthLikeFor(context, waves, true, false);
		Test.Assert(depth.Config.ShaderName == "waves.depth");
		Test.Assert(depth.MaterialSet);
		Test.Assert(depth.Config.ShaderFlags.HasFlag(.Instanced));
		Test.Assert(depth.Config.DepthOnly, "opaque: its vertex stage alone");
		let pick = MeshRenderer.DepthLikeFor(context, waves, false, true);
		Test.Assert(pick.Config.ShaderName == "waves.pick");
		Test.Assert(pick.Config.CullMode == .None, "as the material draws");

		// Masked: the cut-out's fragment runs, over the material's set two.
		waves.Pipeline.BlendMode = .Masked;
		let masked = MeshRenderer.DepthLikeFor(context, waves, false, false);
		Test.Assert(!masked.Config.DepthOnly);
		Test.Assert(masked.Config.ShaderFlags.HasFlag(.AlphaTest));

		// No material: the built-in.
		Test.Assert(MeshRenderer.DepthLikeFor(context, null, false, true).Config.ShaderName == "pick_ids");
	}
}
