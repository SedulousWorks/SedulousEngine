using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// The rest pose: a skinned mesh fed no palette draws its raw vertices, which an FBX file keeps
/// in its authoring tool's axes (the bind matrices carry the turn upright). So an animator feeds
/// its meshes the player's standing pose even while the scene stands still (the editor's edit
/// mode, a thumbnail), the clip waiting for the simulation, and a graph player starts in the
/// rest pose.
class RestPoseTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// One bone at the origin whose inverse bind turns a quarter about X: the palette at rest is
	/// that turn, what stands a Z up FBX mesh upright.
	private static Skeleton TurnedRig()
	{
		let skeleton = new Skeleton(1);
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[0].InverseBindPose = Float4x4.RotationX(-HalfPi);
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		return skeleton;
	}

	private static Float3 Moved(Float4x4 m) => TransformPoint(.(0, 0, 1), m);

	[Test]
	public static void AStandingScenesAnimatorFeedsTheRestPoseAndHoldsItsClip()
	{
		let skeleton = TurnedRig();
		defer delete skeleton;
		let clip = scope AnimationClip("Lift", 1.0f, true);
		clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 2, 0));
		clip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 2, 0));

		// The scene first on the way out: its animator borrows the skeleton and the clip.
		let level = new Scene("rest");
		defer delete level;
		let meshes = level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let body = level.CreateEntity("Body");
		meshes.Add(body);
		let animators = level.GetSystem<SkeletalAnimationComponentManager>();
		let animator = animators.Add(body);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(clip);

		level.SetSimulationEnabled(false);
		level.Update(0.5f);
		let mesh = meshes.Get(body);
		Test.Assert((mesh.BoneMatrices != null) && (mesh.BoneCount == 1));
		let rest = Moved(Float4x4.RotationX(-HalfPi));
		Test.Assert(Near(Moved(mesh.BoneMatrices[0]).Y, rest.Y), "turned, not raw");
		Test.Assert(Near(Moved(mesh.BoneMatrices[0]).Z, rest.Z));
		let player = animators.Get(body).Player;
		Test.Assert(player != null);
		Test.Assert(player.CurrentClip == null, "the clip waits for the simulation");
		Test.Assert(Near(player.CurrentTime, 0.0f));

		// Simulating, the clip plays: the bone lifts by two.
		level.SetSimulationEnabled(true);
		level.Update(0.25f);
		Test.Assert(player.CurrentClip === clip);
		Test.Assert(Near(Moved(meshes.Get(body).BoneMatrices[0]).Y, rest.Y + 2.0f));
	}

	[Test]
	public static void AnAnimatorWithNoClipFeedsTheRestPoseWhileSimulatingToo()
	{
		let skeleton = TurnedRig();
		defer delete skeleton;
		let level = new Scene("rest");
		defer delete level;
		let meshes = level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let body = level.CreateEntity("Body");
		meshes.Add(body);
		level.GetSystem<SkeletalAnimationComponentManager>().Add(body).Skeleton.SetDirect(skeleton);
		level.Update(0.5f);
		let mesh = meshes.Get(body);
		Test.Assert(mesh.BoneMatrices != null);
		Test.Assert(Near(Moved(mesh.BoneMatrices[0]).Y, Moved(Float4x4.RotationX(-HalfPi)).Y));
	}

	[Test]
	public static void AGraphPlayerStartsInTheRigsRestPoseFedWhileTheSceneStandsStill()
	{
		let skeleton = TurnedRig();
		defer delete skeleton;
		skeleton.Bones[0].LocalBindPose.Position = .(0, 3, 0);
		let graph = scope AnimationGraph();

		let level = new Scene("rest");
		defer delete level;
		let meshes = level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let body = level.CreateEntity("Body");
		meshes.Add(body);
		let component = level.GetSystem<AnimationGraphComponentManager>().Add(body);
		component.Skeleton.SetDirect(skeleton);
		component.Graph.SetDirect(graph);
		level.SetSimulationEnabled(false);
		level.Update(0.5f);
		let mesh = meshes.Get(body);
		Test.Assert(mesh.BoneMatrices != null);
		// Its rest position (three up) under the turn, not the identity a default pose gives.
		Test.Assert(Near(Moved(mesh.BoneMatrices[0]).Y, Moved(Float4x4.RotationX(-HalfPi)).Y + 3.0f));
	}
}
