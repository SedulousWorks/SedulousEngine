using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource.Tests;

/// Cooked animation content built into what a player runs.
class AnimationResourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// The DERIVED parts of a skeleton, the name map and the hierarchy, are rebuilt rather
	/// than stored: what comes back has to look up names and pose parents before children.
	[Test]
	public static void ASkeletonRoundTripsWithItsLookupsRebuilt()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_skeleton");
		let id = fixture.CookSkeleton("skel");

		let skeleton = fixture.Manager.Bind<Skeleton>(id);
		Test.Assert(skeleton.Get != null);
		Test.Assert(skeleton.State == .Ready);

		Test.Assert(skeleton.Get.BoneCount == 2);
		Test.Assert(skeleton.Get.FindBone("child") == 1, "the name map came back");
		Test.Assert(skeleton.Get.RootBones.Length == 1, "the hierarchy came back");

		// The inverse bind poses survived, so skinning at the bind pose is still the
		// identity: the invariant an unanimated mesh depends on.
		let skin = scope Float4x4[2];
		skeleton.Get.ComputeSkinningMatrices(default, skin);
		Test.Assert(Near(skin[1].M[0][0], 1.0f));
		Test.Assert(Near(skin[1].M[3][1], 0.0f));
	}

	[Test]
	public static void AClipRoundTripsItsTracksAndEvents()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_clip");
		let id = fixture.CookClip("move");

		let clip = fixture.Manager.Bind<AnimationClip>(id);
		Test.Assert(clip.Get != null);
		Test.Assert(Near(clip.Get.Duration, 1.0f));
		Test.Assert(clip.Get.IsLooping);
		Test.Assert(clip.Get.PositionTracks.Count == 1);
		Test.Assert(clip.Get.RotationTracks.Count == 1);
		Test.Assert(clip.Get.Events.Count == 1);
		Test.Assert(clip.Get.Events[0].Name == "Footstep");

		// And it still SAMPLES the same, which is the only thing the wire exists for.
		let skeleton = scope Skeleton(2);
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();

		let poses = scope BoneTransform[2];
		AnimationSampler.SampleClip(clip.Get, skeleton, 0.5f, poses);
		Test.Assert(Near(poses[0].Position.Y, 5.0f));
	}

	/// The graph is a COMPOSITE: each clip reference resolves through the manager, which is
	/// what records the graph to clip edge and keeps the clip alive while the graph holds it
	/// borrowed.
	[Test]
	public static void AGraphResolvesItsClipReferencesThroughTheManager()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_graph");
		let walkId = fixture.CookClip("walk", 2.0f);

		let record = scope AnimationGraphSource();
		record.ParamName.Add(new String("Moving"));
		record.ParamType.Add((uint8)AnimationParameterType.Bool);

		record.LayerName.Add(new String("Base"));
		record.LayerDefaultState.Add(0);
		record.LayerBlendModeValue.Add((uint8)LayerBlendMode.Override);
		record.LayerWeight.Add(1.0f);
		record.LayerMaskStart.Add(0);
		record.LayerMaskCount.Add(0);
		record.LayerStateStart.Add(0);
		record.LayerStateCount.Add(1);
		record.LayerTransitionStart.Add(0);
		record.LayerTransitionCount.Add(0);

		record.StateName.Add(new String("Walk"));
		record.StateSpeed.Add(1.0f);
		record.StateLoop.Add(true);
		record.StateNodeKind.Add(0);
		record.StateNodeClip.Add(walkId);
		record.StateNodeParamIndex.Add(-1);
		record.StateNodeParamIndexX.Add(-1);
		record.StateNodeParamIndexY.Add(-1);
		record.StateEntryStart.Add(0);
		record.StateEntryCount.Add(0);

		let instance = fixture.Database.RootGroup.CreateInstance("graph",
			AnimationResourceFixture.GraphTypeName);
		instance.WriteObject(record).IgnoreError();

		let graph = fixture.Manager.Bind<AnimationGraph>(instance.Id);
		Test.Assert(graph.Get != null);
		Test.Assert(graph.Get.Parameters.Count == 1);
		Test.Assert(graph.Get.Layers.Count == 1);

		let state = graph.Get.Layers[0].GetState(0);
		Test.Assert(state != null);
		Test.Assert(state.Node != null);
		Test.Assert(state.Node is ClipStateNode);
		// The reference resolved to the real cooked clip, which is two seconds long.
		Test.Assert(Near(state.Node.Duration, 2.0f));
	}

	/// A blend tree comes back with its entries in place and its parameter link intact, so
	/// the player can drive it.
	[Test]
	public static void AGraphRebuildsABlendTreeWithItsEntries()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_graph_tree");
		let walkId = fixture.CookClip("walk", 1.0f);
		let runId = fixture.CookClip("run", 2.0f);

		let record = scope AnimationGraphSource();
		record.ParamName.Add(new String("Speed"));
		record.ParamType.Add((uint8)AnimationParameterType.Float);
		record.ParamFloat.Add(0.0f);

		record.LayerName.Add(new String("Base"));
		record.LayerDefaultState.Add(0);
		record.LayerBlendModeValue.Add((uint8)LayerBlendMode.Override);
		record.LayerWeight.Add(1.0f);
		record.LayerMaskStart.Add(0);
		record.LayerMaskCount.Add(2);
		record.LayerStateStart.Add(0);
		record.LayerStateCount.Add(1);
		record.LayerTransitionStart.Add(0);
		record.LayerTransitionCount.Add(0);

		record.MaskWeight.Add(1.0f);
		record.MaskWeight.Add(0.25f);

		record.StateName.Add(new String("Locomotion"));
		record.StateSpeed.Add(1.0f);
		record.StateLoop.Add(true);
		// One is a blend tree along a single axis.
		record.StateNodeKind.Add(1);
		record.StateNodeClip.Add(Guid());
		record.StateNodeParamIndex.Add(0);
		record.StateNodeParamIndexX.Add(-1);
		record.StateNodeParamIndexY.Add(-1);
		record.StateEntryStart.Add(0);
		record.StateEntryCount.Add(2);

		record.EntryThreshold.Add(0.0f);
		record.EntryPosition.Add(.(0, 0));
		record.EntryClip.Add(walkId);
		record.EntryThreshold.Add(1.0f);
		record.EntryPosition.Add(.(0, 0));
		record.EntryClip.Add(runId);

		let instance = fixture.Database.RootGroup.CreateInstance("graph",
			AnimationResourceFixture.GraphTypeName);
		instance.WriteObject(record).IgnoreError();

		let graph = fixture.Manager.Bind<AnimationGraph>(instance.Id);
		Test.Assert(graph.Get != null);

		let layer = graph.Get.Layers[0];
		Test.Assert(layer.Mask != null);
		Test.Assert(Near(layer.Mask.GetWeight(1), 0.25f));

		let tree = layer.GetState(0).Node as BlendTree1D;
		Test.Assert(tree != null);
		Test.Assert(tree.ParameterIndex == 0);
		Test.Assert(tree.Entries.Count == 2);
		Test.Assert(tree.Entries[0].Clip != null);
		Test.Assert(tree.Entries[1].Clip != null);

		// The parameter drives which clip dominates, which is what the link is for.
		let skeleton = scope Skeleton(2);
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[1].ParentIndex = 0;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();

		let player = scope AnimationGraphPlayer(graph.Get, skeleton);
		player.SetFloat("Speed", 1.0f);
		player.Update(0.016f);
		Test.Assert(Near(tree.Parameter, 1.0f), "the player synced it into the tree");
		Test.Assert(Near(tree.Duration, 2.0f), "the run is dominant now");
	}

	/// A run pointing past its pool yields LESS rather than a read past the end of an array:
	/// cooked bytes reach the runtime by paths a cook never saw.
	[Test]
	public static void ARunPastThePoolIsClampedRatherThanRead()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_graph_short");

		let record = scope AnimationGraphSource();
		record.LayerName.Add(new String("Base"));
		record.LayerDefaultState.Add(0);
		record.LayerBlendModeValue.Add(0);
		record.LayerWeight.Add(1.0f);
		record.LayerMaskStart.Add(0);
		// A mask, a set of states and a set of transitions all claimed, with empty pools.
		record.LayerMaskCount.Add(8);
		record.LayerStateStart.Add(0);
		record.LayerStateCount.Add(4);
		record.LayerTransitionStart.Add(0);
		record.LayerTransitionCount.Add(4);

		let instance = fixture.Database.RootGroup.CreateInstance("graph",
			AnimationResourceFixture.GraphTypeName);
		instance.WriteObject(record).IgnoreError();

		let graph = fixture.Manager.Bind<AnimationGraph>(instance.Id);
		Test.Assert(graph.Get != null);
		Test.Assert(graph.Get.Layers.Count == 1);
		Test.Assert(graph.Get.Layers[0].States.IsEmpty);
		Test.Assert(graph.Get.Layers[0].Transitions.IsEmpty);
		Test.Assert(graph.Get.Layers[0].Mask == null, "no weights, so no mask");
	}

	/// Something else stored under the type name is not a clip rather than a clip that failed
	/// to read, so nothing is built from it.
	[Test]
	public static void ARecordOfTheWrongTypeBuildsNothing()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_mismatch");
		let id = fixture.CookSkeleton("skel");

		let clip = fixture.Manager.Bind<AnimationClip>(id);
		Test.Assert(clip.Get == null);
	}

	/// A clip record whose track table claims more keys than its pool holds must FAIL
	/// CLOSED, and bind nothing through the manager.
	///
	/// Salvaging what parses would hand back a clip quietly short of keyframes, which still
	/// animates and so looks like an authoring mistake rather than a corrupt cook. The run
	/// ending exactly ON the pool is the boundary that must still be accepted.
	[Test]
	public static void AClipRunPastItsPoolRefusesToBuild()
	{
		let source = scope AnimationClipSource();
		source.TrackBone.Add(0);
		source.TrackKindValue.Add(0);
		source.TrackInterp.Add(1);
		source.TrackStart.Add(0);
		source.TrackCount.Add(3); // the pool below holds two
		source.KeyTime.Add(0.0f);
		source.KeyTime.Add(1.0f);
		source.KeyValue.Add(.(0, 0, 0, 0));
		source.KeyValue.Add(.(0, 1, 0, 0));

		let clip = scope AnimationClip();
		Test.Assert(!source.FillClip(clip), "a run past the pool is refused");
		Test.Assert(clip.PositionTracks.Count == 0, "and leaves nothing half built");

		// A track table shorter than its bone list is the same refusal.
		let ragged = scope AnimationClipSource();
		ragged.TrackBone.Add(0);
		ragged.TrackBone.Add(1);
		ragged.TrackStart.Add(0);
		ragged.TrackCount.Add(0);
		Test.Assert(!ragged.FillClip(clip), "a ragged track table is refused");

		// Ending exactly at the pool is well formed and still fills.
		source.TrackCount[0] = 2;
		Test.Assert(source.FillClip(clip));
		Test.Assert(clip.PositionTracks.Count == 1);
		Test.Assert(clip.PositionTracks[0].Keyframes.Count == 2);
	}

	/// And through the manager the malformed record binds NOTHING, rather than a corrupt
	/// clip something downstream would sample.
	[Test]
	public static void AMalformedClipRecordBindsNothing()
	{
		let fixture = scope AnimationResourceFixture("scratch_anim_clip_overrun");

		let source = scope AnimationClipSource();
		source.TrackBone.Add(0);
		source.TrackKindValue.Add(0);
		source.TrackInterp.Add(1);
		source.TrackStart.Add(0);
		source.TrackCount.Add(3);
		source.KeyTime.Add(0.0f);
		source.KeyTime.Add(1.0f);
		source.KeyValue.Add(.(0, 0, 0, 0));
		source.KeyValue.Add(.(0, 1, 0, 0));

		let instance = fixture.Database.RootGroup.CreateInstance("clip",
			AnimationResourceFixture.ClipTypeName);
		instance.WriteObject(source).IgnoreError();

		let bound = fixture.Manager.Bind<AnimationClip>(instance.Id);
		Test.Assert(bound.Get == null, "a malformed record binds nothing");
	}
}
