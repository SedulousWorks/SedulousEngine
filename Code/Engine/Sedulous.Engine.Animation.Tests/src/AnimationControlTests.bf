using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Animation.Tests;

/// The runtime control surface on the managers: the verbs a script drives a player with,
/// which the component data cannot reach because the player is the manager's.
static class AnimationControlTests
{
	private const float cStep = 1.0f / 60.0f;

	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// Before the first tick there is no player, and every verb is a quiet no-op.
	[Test]
	public static void ClipVerbsAreNoOpsUntilThePlayerIsBuilt()
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
		let entity = scene.CreateEntity("Rig");
		animators.Add(entity);

		animators.Play(entity);
		animators.Stop(entity);
		animators.Pause(entity);
		animators.Resume(entity);
		animators.SetTime(entity, 1.0f);
		Test.Assert(!animators.IsPlaying(entity));
		Test.Assert(Near(animators.Time(entity), 0.0f));

		// And an entity with no animator at all.
		let bare = scene.CreateEntity("Bare");
		animators.Play(bare);
		Test.Assert(!animators.IsPlaying(bare));
	}

	[Test]
	public static void ClipVerbsDriveTheBuiltPlayer()
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
		let entity = scene.CreateEntity("Rig");

		let skeleton = scope Skeleton(2);
		AnimationResourceFixture.BuildChain(skeleton);
		let walk = scope AnimationClip("walk", 1.0f, false);

		let animator = animators.Add(entity);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(walk);
		animator.AutoPlay = false;

		// Built, but AutoPlay is off so nothing plays.
		scene.Update(cStep);
		Test.Assert(animator.Player != null);
		Test.Assert(!animators.IsPlaying(entity));

		animators.Play(entity);
		Test.Assert(animators.IsPlaying(entity));
		scene.Update(cStep);
		scene.Update(cStep);
		Test.Assert(animators.Time(entity) > 0.0f, "the clock runs");

		// Pause holds the clock; Resume lets it go.
		animators.Pause(entity);
		Test.Assert(!animators.IsPlaying(entity));
		let held = animators.Time(entity);
		scene.Update(cStep);
		Test.Assert(Near(animators.Time(entity), held));
		animators.Resume(entity);
		Test.Assert(animators.IsPlaying(entity));

		// SetTime seeks.
		animators.SetTime(entity, 0.5f);
		Test.Assert(Near(animators.Time(entity), 0.5f));

		// Stop rewinds and halts.
		animators.Stop(entity);
		Test.Assert(!animators.IsPlaying(entity));
		Test.Assert(Near(animators.Time(entity), 0.0f));

		// Play again restarts from the top.
		animators.SetTime(entity, 0.5f);
		animators.Play(entity);
		Test.Assert(Near(animators.Time(entity), 0.0f));
	}

	/// SetClip by id binds through the manager the scene was resolved with, and the next
	/// tick plays the new clip because AutoPlay is on.
	[Test]
	public static void SetClipRebindsByIdThroughTheResolvedManager()
	{
		let fixture = scope AnimationResourceFixture("scratch_engine_animctl_db");
		let skeletonId = fixture.CookSkeleton("Skel");
		let walkId = fixture.CookClip("Walk", 2.0f);
		let runId = fixture.CookClip("Run", 0.5f);

		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
		let entity = scene.CreateEntity("Rig");
		let animator = animators.Add(entity);
		animator.Skeleton.SetId(skeletonId);
		animator.Clip.SetId(walkId);

		SceneResolve.ResolveSceneResources(scene, fixture.Manager);
		Test.Assert(animators.Resources === fixture.Manager, "the manager is remembered");

		scene.Update(cStep);
		Test.Assert(animator.Player != null);
		Test.Assert(Near(animator.Player.CurrentClip.Duration, 2.0f));

		animators.SetClip(entity, runId);
		Test.Assert(animator.Clip.Id == runId);
		scene.Update(cStep);
		Test.Assert(animator.Player.CurrentClip != null);
		Test.Assert(Near(animator.Player.CurrentClip.Duration, 0.5f), "the swap played");

		// An entity without an animator is a no-op.
		animators.SetClip(scene.CreateEntity("Bare"), walkId);
	}

	/// Without a resolve there is no manager: the identity lands, the direct object is
	/// dropped, and nothing binds until a resolve comes.
	[Test]
	public static void SetClipBeforeAnyResolveSetsTheIdentityOnly()
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let animators = scene.AddSystem<SkeletalAnimationComponentManager>();
		let entity = scene.CreateEntity("Rig");
		let walk = scope AnimationClip("walk", 1.0f, false);
		let animator = animators.Add(entity);
		animator.Clip.SetDirect(walk);

		let id = Guid.Create();
		animators.SetClip(entity, id);
		Test.Assert(animators.Resources == null);
		Test.Assert(animator.Clip.Id == id);
		Test.Assert(animator.Clip.Get == null, "the direct override is gone");
	}

	[Test]
	public static void GraphParametersReachThePlayer()
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		let graphs = scene.AddSystem<AnimationGraphComponentManager>();
		let entity = scene.CreateEntity("Rig");

		let skeleton = scope Skeleton(2);
		AnimationResourceFixture.BuildChain(skeleton);
		let graph = scope AnimationGraph();
		let speed = graph.AddParameter("Speed", .Float);
		let grounded = graph.AddParameter("Grounded", .Bool);
		let jump = graph.AddParameter("Jump", .Trigger);
		graph.AddLayer(new AnimationLayer("Base"));

		let component = graphs.Add(entity);
		component.Skeleton.SetDirect(skeleton);
		component.Graph.SetDirect(graph);

		// No player yet: quiet no-ops.
		graphs.SetFloat(entity, "Speed", 3.0f);
		graphs.SetTrigger(entity, "Jump");

		scene.Update(cStep);
		let player = component.Player;
		Test.Assert(player != null);
		Test.Assert(Near(player.GetFloat(speed), 0.0f), "the early set was dropped, not queued");

		graphs.SetFloat(entity, "Speed", 3.0f);
		graphs.SetBool(entity, "Grounded", true);
		graphs.SetTrigger(entity, "Jump");
		Test.Assert(Near(player.GetFloat(speed), 3.0f));
		Test.Assert(player.GetBool(grounded));
		Test.Assert(player.GetBool(jump), "armed");

		// The update consumes the trigger and keeps the rest.
		scene.Update(cStep);
		Test.Assert(!player.GetBool(jump), "consumed");
		Test.Assert(Near(player.GetFloat(speed), 3.0f));
		Test.Assert(player.GetBool(grounded));

		// An unknown name is a no-op, as is an entity without a graph.
		graphs.SetFloat(entity, "Missing", 9.0f);
		graphs.SetBool(scene.CreateEntity("Bare"), "Grounded", false);
		Test.Assert(player.GetBool(grounded));
	}
}
