using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Animation.Tests;

/// A skeletal animator's resource references: they round trip by id, resolve through the
/// manager's proxies, and the picks that land one at a time still start playback.
class SkeletalAnimationRefTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static SkeletalAnimationComponent* Sole(Scene scene)
	{
		SkeletalAnimationComponent* found = null;
		scene.GetSystem<SkeletalAnimationComponentManager>().ForEach(scope [&] (component, owner) =>
			{
				found = component;
			});
		return found;
	}

	[Test]
	public static void ASceneRoundTripResolvesTheSkeletonAndClipThroughProxies()
	{
		let fixture = scope AnimationResourceFixture("scratch_engine_animref_db");
		let skeletonId = fixture.CookSkeleton("Skel");
		let clipId = fixture.CookClip("Walk");

		// Author a scene referencing both BY ID only.
		let blob = scope MemoryStream();
		{
			let scene = scope Scene();
			let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
			let entity = scene.CreateEntity("Rig");
			let animator = animators.Add(entity);
			animator.Skeleton.SetId(skeletonId);
			animator.Clip.SetId(clipId);
			animator.Speed = 1.5f;
			animator.StartTime = 0.25f;

			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		// Load into a FRESH scene, then run the post load resolve.
		let loaded = scope Scene();
		loaded.AddSystem<MeshComponentManager>();
		let animators = loaded.AddSystem<SkeletalAnimationComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(animators.ComponentCount == 1);
		let animator = Sole(loaded);
		Test.Assert(animator != null);

		// The identities and the tunables survived, and nothing is bound until the resolve.
		Test.Assert(animator.Skeleton.Id == skeletonId);
		Test.Assert(animator.Clip.Id == clipId);
		Test.Assert(animator.Skeleton.Get == null);
		Test.Assert(animator.Clip.Get == null);
		Test.Assert(Near(animator.Speed, 1.5f));
		Test.Assert(Near(animator.StartTime, 0.25f));

		SceneResolve.ResolveSceneResources(loaded, fixture.Manager);

		let skeleton = animator.Skeleton.Get;
		Test.Assert(skeleton != null);
		Test.Assert(skeleton.BoneCount == 2);
		Test.Assert(skeleton.FindBone("child") == 1);

		let clip = animator.Clip.Get;
		Test.Assert(clip != null);
		Test.Assert(Near(clip.Duration, 2.0f));
		Test.Assert(clip.IsLooping);

		// The close and reopen flow: after the load and the resolve, the FIRST tick builds the
		// player and starts the persisted clip.
		Test.Assert(animator.Player == null);
		loaded.Update(1.0f / 60.0f);
		Test.Assert(animator.Player != null);
		Test.Assert(animator.Player.CurrentClip === clip);
	}

	/// A DIRECT object is the sample and spawn path: it wins, and it serializes nothing.
	[Test]
	public static void RuntimeObjectsStillAssign()
	{
		let skeleton = scope Skeleton(2);
		AnimationResourceFixture.BuildChain(skeleton);
		let clip = scope AnimationClip("walk", 1.0f, false);

		var animator = SkeletalAnimationComponent();
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(clip);

		Test.Assert(animator.Skeleton.Get === skeleton);
		Test.Assert(animator.Clip.Get === clip);
		Test.Assert(animator.Skeleton.Id == Guid());
		Test.Assert(animator.Clip.Id == Guid());
	}

	/// The editor flow: references land ONE AT A TIME across frames. Playback has to start
	/// when the clip arrives after the player was already built for the skeleton, and to
	/// restart when the clip behind the reference changes.
	[Test]
	public static void SequentialPicksStartPlayback()
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
		let entity = scene.CreateEntity("Rig");

		let skeleton = scope Skeleton(2);
		AnimationResourceFixture.BuildChain(skeleton);
		let walk = scope AnimationClip("walk", 1.0f, false);
		let run = scope AnimationClip("run", 0.5f, false);

		let animator = animators.Add(entity);

		// Only the skeleton is picked: a player exists, but nothing plays.
		animator.Skeleton.SetDirect(skeleton);
		scene.Update(1.0f / 60.0f);
		Test.Assert(animator.Player != null);
		Test.Assert(animator.Player.CurrentClip == null);

		// The clip pick lands, and it starts on the EXISTING player.
		animator.Clip.SetDirect(walk);
		scene.Update(1.0f / 60.0f);
		Test.Assert(animator.Player.CurrentClip === walk);

		// A DIFFERENT clip replays, which is the same mechanism a hot reload's swap takes.
		animator.Clip.SetDirect(run);
		scene.Update(1.0f / 60.0f);
		Test.Assert(animator.Player.CurrentClip === run);
	}

	/// ONE animator drives every part of a multi part character, named by stable id, and the
	/// names survive a round trip.
	[Test]
	public static void OneAnimatorFeedsSeveralPartsAndTheRefsPersist()
	{
		let skeleton = scope Skeleton(2);
		AnimationResourceFixture.BuildChain(skeleton);
		let clip = scope AnimationClip("walk", 1.0f, true);

		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();

		let rig = scene.CreateEntity("Rig");
		let partA = scene.CreateEntity("PartA");
		let partB = scene.CreateEntity("PartB");
		meshes.Add(partA);
		meshes.Add(partB);

		let animator = animators.Add(rig);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(clip);
		animator.MeshEntities.Add(EntityRef(scene.GetEntityId(partA)));
		animator.MeshEntities.Add(EntityRef(scene.GetEntityId(partB)));

		scene.Update(1.0f / 60.0f);

		let fedA = meshes.Get(partA);
		let fedB = meshes.Get(partB);
		Test.Assert(fedA != null);
		Test.Assert(fedB != null);
		// Both parts received the ONE player's matrices.
		Test.Assert(fedA.BoneMatrices != null);
		Test.Assert(fedB.BoneMatrices != null);
		Test.Assert(fedA.BoneCount == 2);
		// The same evaluation, rather than a player each.
		Test.Assert(fedA.BoneMatrices == fedB.BoneMatrices);

		// The references are part of the persisted state, still naming the same entities.
		let blob = scope MemoryStream();
		{
			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene();
		loaded.AddSystem<MeshComponentManager>();
		loaded.AddSystem<SkeletalAnimationComponentManager>();
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let reloaded = Sole(loaded);
		Test.Assert(reloaded != null);
		Test.Assert(reloaded.MeshEntities.Count == 2);
		Test.Assert(loaded.GetEntityName(loaded.FindEntity(reloaded.MeshEntities[0].Id)) == "PartA");
		Test.Assert(loaded.GetEntityName(loaded.FindEntity(reloaded.MeshEntities[1].Id)) == "PartB");
	}
}
