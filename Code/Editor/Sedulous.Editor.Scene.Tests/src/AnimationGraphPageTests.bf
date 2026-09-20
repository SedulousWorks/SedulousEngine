using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The graph page's headless halves: the seed, the nested edit model over the flat source,
/// its structural edits, the layout sync, the undo snapshot and the creator.
class AnimationGraphPageTests
{
	[Test]
	public static void TheDefaultSeedIsOneLayerWithAnIdleDefaultAndASpeedParam()
	{
		let asset = scope AnimationGraphAsset();
		AnimationGraphEdit.SeedDefault(asset);
		let s = asset.Source;
		Test.Assert((s.ParamName.Count == 1) && (s.ParamName[0] == "Speed") && (s.ParamType[0] == 0));
		Test.Assert((s.LayerName.Count == 1) && (s.LayerName[0] == "Base"));
		Test.Assert((s.StateName.Count == 1) && (s.StateName[0] == "Idle"));
		Test.Assert((s.StateNodeKind[0] == 0) && (s.LayerDefaultState[0] == 0));
		Test.Assert(s.TransitionSource.IsEmpty);
		Test.Assert((asset.LayerLayouts.Count == 1) && (asset.LayerLayouts[0].StatePositions.Count == 1));
		Test.Assert(asset.LayerLayouts[0].AnyStatePosition.Y == 40.0f);
	}

	[Test]
	public static void TheDocumentRoundTripsTheFlatSourceWithBlendTreesAndTransitions()
	{
		AnimationPipeline.RegisterAll();
		let a = scope AnimationGraphAsset();
		AnimationGraphEdit.SeedDefault(a);
		let doc = scope GraphDocument();
		doc.Load(a.Source);
		Test.Assert((doc.Params.Count == 1) && (doc.Layers.Count == 1) && (doc.Layers[0].States.Count == 1));

		let layer = doc.Layers[0];
		let run = layer.AddState("Run", 1);
		run.ParamIndex = 0;
		run.EntryClips.Add(Guid(0xAB, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x12));
		run.EntryThresholds.Add(0.5f);
		let t = layer.AddTransition(0, 1);
		t.Duration = 0.15f;
		let c = new GraphCondition();
		c.ParamIndex = 0;
		c.Op = 2; // greater
		c.Threshold = 0.1f;
		t.Conditions.Add(c);
		layer.MaskWeights.Add(1.0f);
		layer.MaskWeights.Add(0.5f);
		doc.AddLayer("Upper").Weight = 0.5f;
		doc.Store(a.Source);
		AnimationGraphEdit.SyncLayouts(a, doc);
		a.LayerLayouts[0].StatePositions[1] = .(420.0f, 200.0f);
		a.LayerLayouts[0].AnyStatePosition = .(25.0f, 75.0f);

		// The flat runs are laid out in order.
		let s = a.Source;
		Test.Assert((s.LayerStateStart[0] == 0) && (s.LayerStateCount[0] == 2));
		Test.Assert((s.LayerStateStart[1] == 2) && (s.LayerStateCount[1] == 0));
		Test.Assert((s.LayerMaskStart[0] == 0) && (s.LayerMaskCount[0] == 2) && (s.MaskWeight.Count == 2));
		Test.Assert((s.StateEntryStart[1] == 0) && (s.StateEntryCount[1] == 1));
		Test.Assert((s.TransitionConditionStart[0] == 0) && (s.TransitionConditionCount[0] == 1));

		// Through the serializer, the undo blob path, and back into a fresh model.
		let blob = scope List<uint8>();
		AnimationGraphEdit.Snapshot(a, blob);
		let b = scope AnimationGraphAsset();
		Test.Assert(AnimationGraphEdit.Apply(b, blob));
		let back = scope GraphDocument();
		back.Load(b.Source);
		Test.Assert(back.Layers.Count == 2);
		let l = back.Layers[0];
		Test.Assert(l.States.Count == 2);
		Test.Assert((l.States[1].Name == "Run") && (l.States[1].NodeKind == 1) && (l.States[1].ParamIndex == 0));
		Test.Assert((l.States[1].EntryClips.Count == 1) && (l.States[1].EntryClips[0] == run.EntryClips[0]));
		Test.Assert(Math.Abs(l.States[1].EntryThresholds[0] - 0.5f) < 1e-6f);
		Test.Assert((l.Transitions.Count == 1) && (l.Transitions[0].Src == 0) && (l.Transitions[0].Dst == 1));
		Test.Assert(Math.Abs(l.Transitions[0].Duration - 0.15f) < 1e-6f);
		Test.Assert((l.Transitions[0].Conditions.Count == 1) && (l.Transitions[0].Conditions[0].Op == 2));
		Test.Assert(Math.Abs(l.Transitions[0].Conditions[0].Threshold - 0.1f) < 1e-6f);
		Test.Assert((l.MaskWeights.Count == 2) && (l.MaskWeights[1] == 0.5f));
		Test.Assert((back.Layers[1].Name == "Upper") && (back.Layers[1].Weight == 0.5f));
		Test.Assert(b.LayerLayouts.Count == 2);
		Test.Assert(b.LayerLayouts[0].StatePositions[1].X == 420.0f);
		Test.Assert(b.LayerLayouts[0].AnyStatePosition.Y == 75.0f);
		// The same bytes again is a no-op.
		Test.Assert(!AnimationGraphEdit.Apply(b, blob));
	}

	[Test]
	public static void DeletingAStateRepointsTransitionsAndTheDefault()
	{
		let doc = scope GraphDocument();
		let layer = doc.AddLayer("Base");
		layer.AddState("Idle", 0);
		layer.AddState("Walk", 0);
		layer.AddState("Run", 0);
		layer.DefaultState = 2;
		layer.AddTransition(-1, 1); // any -> walk
		layer.AddTransition(0, 1);  // idle -> walk
		layer.AddTransition(1, 2);  // walk -> run
		layer.AddTransition(0, 2);  // idle -> run

		Test.Assert(!layer.DeleteState(5));
		Test.Assert(layer.DeleteState(1));
		Test.Assert((layer.States.Count == 2) && (layer.States[1].Name == "Run"));
		// Everything touching Walk went; the rest slid down; the default followed Run.
		Test.Assert(layer.Transitions.Count == 1);
		Test.Assert((layer.Transitions[0].Src == 0) && (layer.Transitions[0].Dst == 1));
		Test.Assert(layer.DefaultState == 1);
		Test.Assert(layer.DeleteState(1));
		Test.Assert((layer.DefaultState == 0) && layer.Transitions.IsEmpty);
		Test.Assert(layer.StateLabel(-1) == "Any State");
		Test.Assert(layer.StateLabel(9) == "?");
	}

	[Test]
	public static void RemovingAParameterRemapsEveryReference()
	{
		let doc = scope GraphDocument();
		doc.AddParam("Speed", 0);
		doc.AddParam("Jump", 3);
		doc.AddParam("Dir", 0);
		let layer = doc.AddLayer("Base");
		let blend = layer.AddState("Move", 2);
		blend.ParamIndexX = 0;
		blend.ParamIndexY = 2;
		let one = layer.AddState("Turn", 1);
		one.ParamIndex = 1;
		let t = layer.AddTransition(0, 1);
		for (int32 i < 3)
		{
			let c = new GraphCondition();
			c.ParamIndex = i;
			t.Conditions.Add(c);
		}

		Test.Assert(!doc.RemoveParam(3));
		Test.Assert(doc.RemoveParam(1));
		Test.Assert((doc.Params.Count == 2) && (doc.Params[1].Name == "Dir"));
		Test.Assert((blend.ParamIndexX == 0) && (blend.ParamIndexY == 1));
		Test.Assert(one.ParamIndex == -1);
		Test.Assert(t.Conditions.Count == 2);
		Test.Assert((t.Conditions[0].ParamIndex == 0) && (t.Conditions[1].ParamIndex == 1));

		// The last layer never goes.
		Test.Assert(!doc.RemoveLayer(0));
		doc.AddLayer("Extra");
		Test.Assert(doc.RemoveLayer(1) && (doc.Layers.Count == 1));
	}

	[Test]
	public static void LayoutsFollowTheModelAndNewStatesLandOnAGrid()
	{
		let asset = scope AnimationGraphAsset();
		let doc = scope GraphDocument();
		let layer = doc.AddLayer("Base");
		for (int i < 7)
			layer.AddState(scope $"S{i}", 0);
		doc.AddLayer("Upper");
		AnimationGraphEdit.SyncLayouts(asset, doc);
		Test.Assert(asset.LayerLayouts.Count == 2);
		Test.Assert(asset.LayerLayouts[0].StatePositions.Count == 7);
		// Five per row, then the next row down.
		Test.Assert(asset.LayerLayouts[0].StatePositions[0] == Float2(240.0f, 90.0f));
		Test.Assert(asset.LayerLayouts[0].StatePositions[5] == Float2(240.0f, 160.0f));
		Test.Assert(asset.LayerLayouts[1].StatePositions.IsEmpty);

		// Removing trims; the kept positions stay put.
		asset.LayerLayouts[0].StatePositions[0] = .(1.0f, 2.0f);
		Test.Assert(layer.DeleteState(6));
		Test.Assert(doc.RemoveLayer(1));
		AnimationGraphEdit.SyncLayouts(asset, doc);
		Test.Assert((asset.LayerLayouts.Count == 1) && (asset.LayerLayouts[0].StatePositions.Count == 6));
		Test.Assert(asset.LayerLayouts[0].StatePositions[0] == Float2(1.0f, 2.0f));
	}

	[Test]
	public static void TheCreatorRoundTripsThroughARealProject()
	{
		AnimationPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_graph_creator_test", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let ctx = scope EditorContext();
		ctx.SetProject(project);

		let empty = scope EditorContext();
		Test.Assert(AnimationGraphAssetCreators.CreateAnimationGraphInstance(empty, null) == null);

		let instance = AnimationGraphAssetCreators.CreateAnimationGraphInstance(ctx, null);
		Test.Assert(instance != null);
		Test.Assert(instance.GetPath(.. scope .()) == "Animation/AnimationGraph");
		Test.Assert(AssetTypeNames.Matches(instance.TypeName, "AnimationGraphAsset"));
		let object = instance.ReadObject();
		Test.Assert(object != null);
		defer delete object;
		let readBack = object as AnimationGraphAsset;
		Test.Assert(readBack != null);
		Test.Assert(readBack.Source.LayerName.Count == 1);
		Test.Assert(readBack.LayerLayouts.Count == 1);
		let doc = scope GraphDocument();
		doc.Load(readBack.Source);
		Test.Assert((doc.Layers[0].States.Count == 1) && (doc.Layers[0].States[0].Name == "Idle"));
	}
}
