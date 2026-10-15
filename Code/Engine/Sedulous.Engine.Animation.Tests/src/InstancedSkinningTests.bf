using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Animation.Tests;

/// Instanced skinning with several clips (masquerade.md P2): the pose pool holds a block of
/// phases per clip, each clip on its own clock, and the sets it feeds learn how many poses a
/// clip has, so an instance's clip picks its block. The skeleton and clips are resource
/// references and the targets entity references, saved with the scene.
class InstancedSkinningTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// A clip holding the one bone at `x` the whole time.
	private static void HoldAt(AnimationClip clip, float x)
	{
		let track = clip.GetOrCreatePositionTrack(0);
		track.AddKeyframe(0.0f, .(x, 0, 0));
		track.AddKeyframe(1.0f, .(x, 0, 0));
	}

	private static void OneBone(Skeleton skeleton)
	{
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.Bones[0].Name.Set("root");
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		skeleton.ComputeInverseBindPoses();
	}

	private static Scene CrowdScene()
	{
		let scene = new Scene();
		scene.AddSystem<InstancedMeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(scene);
		return scene;
	}

	[Test]
	public static void ABlockOfPosesPerClipAndTheSetToldHowManyAClipHas()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let idle = scope AnimationClip("Idle", 1.0f, true);
		HoldAt(idle, 1.0f);
		let dance = scope AnimationClip("Dance", 1.0f, true);
		HoldAt(dance, 2.0f);

		let level = CrowdScene();
		defer delete level;
		let crowd = level.CreateEntity("Guests");
		let mesh = level.GetSystem<InstancedMeshComponentManager>().Add(crowd);
		let skinning = level.GetSystem<InstancedSkinningComponentManager>().Add(crowd);
		skinning.Skeleton.SetDirect(skeleton);
		for (let clip in AnimationClip[2](idle, dance))
		{
			var reference = Ref<AnimationClip>(Guid());
			reference.SetDirect(clip);
			skinning.Clips.Add(reference);
		}
		skinning.PoseCount = 3;

		level.Update(1.0f / 30.0f);
		Test.Assert(mesh.PosePool != null);
		Test.Assert(mesh.PoseCount == 6, "two clips by three phases");
		Test.Assert(mesh.PosesPerClip == 3, "so an instance's clip picks its block");
		Test.Assert(mesh.BoneCount == 1);
		for (uint32 pose < 6)
		{
			let x = mesh.PosePool[pose].M[3][0];
			Test.Assert(Near(x, (pose < 3) ? 1.0f : 2.0f), scope $"pose {pose} at {x}: Idle's block, then Dance's");
		}
		// An instance on clip 1 draws from Dance's block, whatever the policy picks for its phase.
		Test.Assert(PoseSelection.SelectPose(.Hashed, 7, mesh.PoseCount, null, 1, mesh.PosesPerClip) >= 3);
	}

	/// A target named by id is fed; one naming no entity is skipped, not a crash.
	[Test]
	public static void TargetsAreFedByIdAndAMissingOneIsSkipped()
	{
		let skeleton = scope Skeleton(1);
		OneBone(skeleton);
		let idle = scope AnimationClip("Idle", 1.0f, true);
		HoldAt(idle, 1.0f);

		let level = CrowdScene();
		defer delete level;
		let sets = level.GetSystem<InstancedMeshComponentManager>();
		let animator = level.CreateEntity("Animator");
		let masks = level.CreateEntity("Masks");
		let own = sets.Add(animator);
		let fed = sets.Add(masks);
		let skinning = level.GetSystem<InstancedSkinningComponentManager>().Add(animator);
		skinning.Skeleton.SetDirect(skeleton);
		var reference = Ref<AnimationClip>(Guid());
		reference.SetDirect(idle);
		skinning.Clips.Add(reference);
		skinning.PoseCount = 2;
		skinning.Targets.Add(EntityRef(Guid.Create()));
		skinning.Targets.Add(EntityRef(level.GetEntityId(masks)));

		level.Update(1.0f / 30.0f);
		Test.Assert((fed.PosePool != null) && (fed.PoseCount == 2), "the target by id");
		Test.Assert(own.PosePool == null, "with targets named, its own set is not fed");
	}

	[Test]
	public static void TheSkeletonClipsAndTargetsAreSavedWithTheScene()
	{
		let skeletonId = Guid.Create();
		let idleId = Guid.Create();
		let danceId = Guid.Create();
		let blob = scope MemoryStream();
		Guid partId;
		{
			let level = CrowdScene();
			defer delete level;
			let crowd = level.CreateEntity("Guests");
			let part = level.CreateEntity("Masks");
			partId = level.GetEntityId(part);
			let skinning = level.GetSystem<InstancedSkinningComponentManager>().Add(crowd);
			skinning.Skeleton.SetId(skeletonId);
			skinning.Clips.Add(Ref<AnimationClip>(idleId));
			skinning.Clips.Add(Ref<AnimationClip>(danceId));
			skinning.PoseCount = 5;
			skinning.Speed = 1.5f;
			skinning.Targets.Add(EntityRef(partId));
			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, level);
			Test.Assert(writer.IsOk);
		}

		let loaded = CrowdScene();
		defer delete loaded;
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		InstancedSkinningComponent* skinning = null;
		loaded.GetSystem<InstancedSkinningComponentManager>().ForEach(scope [&] (component, owner) =>
			{
				skinning = component;
			});
		Test.Assert(skinning != null);
		Test.Assert(skinning.Skeleton.Id == skeletonId);
		Test.Assert(skinning.Clips.Count == 2);
		Test.Assert(skinning.Clips[0].Id == idleId);
		Test.Assert(skinning.Clips[1].Id == danceId);
		Test.Assert(skinning.PoseCount == 5);
		Test.Assert(Near(skinning.Speed, 1.5f));
		Test.Assert(skinning.Targets.Count == 1);
		Test.Assert(skinning.Targets[0].Id == partId);
	}
}
