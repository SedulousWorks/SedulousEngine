using System;
using System.Collections;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Shaders;

namespace Sedulous.Render.Tests;

/// Effects: which materials select an effect's variant (an effect group whose gate is above
/// nought turns its flag on), the flag's name in the variant table, and PBR's buffer, which no
/// longer carries the wind (the block stays sixty four bytes, its former wind lanes padding).
class WindTests
{
	/// An effect's table as the shader system serves it, parsed from an effect block (the
	/// engine's own is wind.hlsli's; these tests are of the rule, not of wind's parameters).
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

	[Test]
	public static void AMaterialTurnsAnEffectsVariantOnThroughItsGroupsGateAboveNought()
	{
		Test.Assert(MeshRenderer.MaterialEffectFlags(null) == .None);

		let wind = WindTable();
		defer delete wind;
		let plain = MaterialPresets.CreatePbr("plain");
		defer delete plain;
		plain.AddEffectGroup(wind);
		Test.Assert(MeshRenderer.MaterialEffectFlags(plain) == .None, "gate nought: off");

		let card = MaterialPresets.CreatePbr("card");
		defer delete card;
		card.AddEffectGroup(wind);
		card.SetDefaultFloat("Wind.Strength", 0.2f);
		Test.Assert(MeshRenderer.MaterialEffectFlags(card) == .Wind);
		card.SetDefaultFloat("Wind.Speed", 5.0f); // not the gate: the variant is the gate's alone
		card.SetDefaultFloat("Wind.Strength", 0.0f);
		Test.Assert(MeshRenderer.MaterialEffectFlags(card) == .None);

		// A material without the group (built without the table, or on a shader that cannot
		// sway) never sways, and the old property name reaches nothing.
		let unlit = MaterialPresets.CreateUnlit("unlit");
		defer delete unlit;
		unlit.SetDefaultFloat("WindStrength", 1.0f);
		unlit.SetDefaultFloat("Wind.Strength", 1.0f);
		Test.Assert(MeshRenderer.MaterialEffectFlags(unlit) == .None);

		// The rule is the effect's flag, whatever the effect: a group whose table names another
		// flag turns that one on.
		let fade = scope ShaderEffect();
		wind.CopyTo(fade);
		fade.Name.Set("Fade");
		fade.Flag = .Dither;
		let both = MaterialPresets.CreatePbr("both");
		defer delete both;
		both.AddEffectGroup(wind);
		both.AddEffectGroup(fade);
		both.SetDefaultFloat("Fade.Strength", 1.0f);
		Test.Assert(MeshRenderer.MaterialEffectFlags(both) == .Dither);
	}

	[Test]
	public static void PbrsBufferHasNoWindLanesAndTheBlockStaysSixtyFourBytes()
	{
		let pbr = MaterialPresets.CreatePbr("pbr");
		defer delete pbr;

		Test.Assert(!pbr.FindProperty("WindStrength", ?));
		Test.Assert(!pbr.FindProperty("WindSpeed", ?));
		Test.Assert(!pbr.FindProperty("WindHeight", ?));
		// The properties around the old lanes have not moved, so an existing cooked material
		// reads the same bytes it always did.
		Test.Assert(pbr.FindProperty("Roughness", let roughness) && (roughness.Offset == 20));
		Test.Assert(pbr.FindProperty("EmissiveColor", let emissive) && (emissive.Offset == 32)); // 24 and 28 are padding
		Test.Assert(pbr.FindProperty("AlphaCutoff", let cutoff) && (cutoff.Offset == 56)); // 60 is padding
		Test.Assert(pbr.UniformDataSize == 64);
		Test.Assert(pbr.EffectGroupCount == 0, "built without the effect's table: no group");

		// The group's offsets are the effect's, in its own buffer.
		let wind = WindTable();
		defer delete wind;
		pbr.AddEffectGroup(wind);
		Test.Assert(pbr.EffectGroupCount == 1);
		let group = pbr.GetEffectGroup(0);
		Test.Assert(group.Name == "Wind");
		Test.Assert(group.Flag == .Wind);
		Test.Assert(group.UniformSize == 16);
		Test.Assert((group.GateIndex == 0) && (group.Properties[0].Name == "Strength"));
		Test.Assert(group.FindProperty("Speed", let speed) && (speed.Offset == 4));
		Test.Assert(group.FindProperty("Height", let height) && (height.Offset == 8));
		Test.Assert(pbr.UniformDataSize == 64, "the shader's buffer untouched");

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

	/// The effect's block is in the material's set (b1), so the shadow and the pick of a swaying
	/// draw bind it, with the built-in programs, which read the same block the forward stage does.
	[Test]
	public static void AnActiveEffectSelectsItsVariantAndBindsTheMaterialsSet()
	{
		let context = RenderRecordContext();
		let wind = WindTable();
		defer delete wind;
		let card = MaterialPresets.CreatePbr("card");
		defer delete card;
		card.AddEffectGroup(wind);
		let still = MeshRenderer.DepthLikeFor(context, card, false, false);
		Test.Assert(!still.MaterialSet);
		Test.Assert(!still.Config.ShaderFlags.HasFlag(.Wind));

		card.SetDefaultFloat("Wind.Strength", 0.3f);
		for (int pass < 2)
		{
			let pick = pass == 1;
			let sway = MeshRenderer.DepthLikeFor(context, card, true, pick);
			Test.Assert(sway.MaterialSet);
			Test.Assert(sway.Config.ShaderFlags.HasFlag(.Wind));
			Test.Assert(sway.Config.ShaderName == (pick ? "pick_ids" : "shadow_depth"));
		}
	}

	/// A tree: bark in slot zero, a masked foliage card in slot one. The prepass and the shadows
	/// cut the foliage's holes, as the forward does: drawn with slot zero's choice, the cards
	/// would write their whole quads' depth, and the gaps would show the clear colour. Slots that
	/// draw alike stay one draw of the whole mesh; a detail chain's level keeps its ranges.
	[Test]
	public static void EachSubmeshDrawsItsDepthWithItsOwnSlotsMaterialAMaskedSlotAsACutOut()
	{
		let context = RenderRecordContext();
		let bark = MaterialPresets.CreatePbr("bark");
		defer delete bark;
		let leaves = MaterialPresets.CreatePbr("leaves");
		defer delete leaves;
		leaves.Pipeline.BlendMode = .Masked;
		Material[2] slots = .(bark, leaves);
		SubMesh[2] subs = .(.(0, 300, 0, .Triangles), .(300, 120, 1, .Triangles));
		let ranges = scope List<MeshRenderer.DepthLikeRange>();
		for (int pass < 2)
		{
			let pick = pass == 1;
			MeshRenderer.DepthLikeRanges(context, bark, &slots[0], 2, .(&subs[0], 2), false, false, pick, ranges);
			Test.Assert(ranges.Count == 2);
			Test.Assert((ranges[0].Material === bark) && (ranges[1].Material === leaves));
			Test.Assert(!ranges[1].Whole && (ranges[1].StartIndex == 300) && (ranges[1].IndexCount == 120));
			let cut = MeshRenderer.DepthLikeFor(context, ranges[1].Material, false, pick);
			Test.Assert(cut.Config.ShaderFlags.HasFlag(.AlphaTest));
			Test.Assert(cut.MaterialSet);
		}

		// Two opaque slots draw alike: one draw of the whole mesh, as before.
		let trim = MaterialPresets.CreatePbr("trim");
		defer delete trim;
		Material[2] opaque = .(bark, trim);
		MeshRenderer.DepthLikeRanges(context, bark, &opaque[0], 2, .(&subs[0], 2), false, true, false, ranges);
		Test.Assert((ranges.Count == 1) && ranges[0].Whole);

		// One masked material in every slot: one whole draw with it.
		Material[2] allLeaves = .(leaves, leaves);
		MeshRenderer.DepthLikeRanges(context, leaves, &allLeaves[0], 2, .(&subs[0], 2), false, false, false, ranges);
		Test.Assert((ranges.Count == 1) && ranges[0].Whole && (ranges[0].Material === leaves));

		// No submeshes: the whole mesh with slot zero. A slot out of range draws as slot zero.
		MeshRenderer.DepthLikeRanges(context, leaves, null, 0, default, false, false, false, ranges);
		Test.Assert((ranges.Count == 1) && ranges[0].Whole && (ranges[0].Material === leaves));
		subs[1].MaterialIndex = 7;
		MeshRenderer.DepthLikeRanges(context, bark, &slots[0], 2, .(&subs[0], 2), false, false, false, ranges);
		Test.Assert((ranges.Count == 1) && (ranges[0].Material === bark), "both bark now: alike");

		// A detail chain's level keeps its ranges even when they draw alike (the buffer holds
		// every level).
		MeshRenderer.DepthLikeRanges(context, bark, &opaque[0], 2, .(&subs[0], 2), true, false, false, ranges);
		Test.Assert(ranges.Count == 2);
	}

	/// The pane's opaque item: its frame in the prepass and the shadows, never its glass (the
	/// transparent item draws that, in no depth pass). Unsplit, both draw alike as one.
	[Test]
	public static void AnItemOfAMeshSplitByCategoryDrawsItsOwnCategorysRangesAlone()
	{
		let context = RenderRecordContext();
		let frame = MaterialPresets.CreatePbr("frame");
		defer delete frame;
		let glass = MaterialPresets.CreatePbr("glass");
		defer delete glass;
		glass.Pipeline.BlendMode = .AlphaBlend;
		Test.Assert(RenderCategories.CategoryForMaterial(frame) == RenderCategories.Opaque);
		Test.Assert(RenderCategories.CategoryForMaterial(glass) == RenderCategories.Transparent);
		Test.Assert(RenderCategories.MeshSlotCategory(frame, 0.5f) == RenderCategories.Masked, "fading: out of the prepass");
		Test.Assert(RenderCategories.MeshSlotCategory(glass, 0.5f) == RenderCategories.Transparent);

		Material[2] slots = .(frame, glass);
		SubMesh[2] subs = .(.(0, 60, 0, .Triangles), .(60, 12, 1, .Triangles));
		let item = scope MeshRenderData();
		item.Material = frame;
		item.SubmeshMaterials = &slots[0];
		item.SubmeshMaterialCount = 2;
		item.Category = RenderCategories.Opaque;
		item.CategorySlots = true;
		let ranges = scope List<MeshRenderer.DepthLikeRange>();
		MeshRenderer.DepthLikeRanges(context, frame, &slots[0], 2, .(&subs[0], 2), false, false, false, ranges, item);
		Test.Assert((ranges.Count == 1) && (ranges[0].Material === frame));
		Test.Assert(!ranges[0].Whole && (ranges[0].IndexCount == 60), "the frame's indices, not the whole mesh's");

		item.CategorySlots = false; // not split: the plain program for both, so one whole draw
		MeshRenderer.DepthLikeRanges(context, frame, &slots[0], 2, .(&subs[0], 2), false, false, false, ranges, item);
		Test.Assert((ranges.Count == 1) && ranges[0].Whole);
	}

	/// The pane's transparent item: its glass blends with the transparent pass's one colour
	/// target, never with the frame's opaque five (the frame is slot zero, the item's material).
	/// Unsplit, a slot of another pass keeps the mesh's pipeline, as before.
	[Test]
	public static void AnItemOfAMeshSplitByCategoryDrawsItsSlotsWithTheirOwnPipelines()
	{
		let context = RenderRecordContext();
		let frame = MaterialPresets.CreatePbr("frame");
		defer delete frame;
		let glass = MaterialPresets.CreatePbr("glass");
		defer delete glass;
		glass.Pipeline.BlendMode = .AlphaBlend;
		let item = scope MeshRenderData();
		item.Material = frame;
		item.Category = RenderCategories.Transparent;
		item.CategorySlots = true;
		let meshConfig = MeshRenderer.ConfigFor(item, frame, context, false);
		Test.Assert(meshConfig.ColorTargetCount == 5);
		let own = MeshRenderer.SlotConfigFor(item, meshConfig, glass, context, false);
		Test.Assert((own.BlendMode == .AlphaBlend) && (own.ColorTargetCount == 1));

		item.CategorySlots = false;
		let kept = MeshRenderer.SlotConfigFor(item, meshConfig, glass, context, false);
		Test.Assert(kept.ColorTargetCount == 5);
	}
}
