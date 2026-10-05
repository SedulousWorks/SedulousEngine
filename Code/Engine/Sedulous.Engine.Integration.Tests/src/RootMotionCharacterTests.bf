using System;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Integration.Tests;

/// Root motion through a real character (root-motion.md P2): an animator in Character mode walks
/// the character above it by the clip, through the scene's character capability, so it still
/// collides; it stops at a wall, stands when the clip stops, and is let go on Ignore.
class RootMotionCharacterTests
{
	[Test]
	public static void ACharacterWalkedByItsClipStopsAtAWallAndWhenTheClipDoes()
	{
		let skeleton = scope Skeleton(1);
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		let walk = scope AnimationClip("Walk", 1.0f, true);
		walk.RootMotion.Horizontal = true;
		for (int i <= 10)
		{
			walk.RootMotion.Times.Add((float)i * 0.1f);
			walk.RootMotion.Positions.Add(.(0, 0, 0.2f * (float)i));
			walk.RootMotion.Yaws.Add(0.0f);
		}
		walk.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
		walk.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 0, 0));

		let level = scope Scene("walk");
		PhysicsScene.AddPhysicsSceneManagers(level);
		level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let bodies = level.GetSystem<RigidBodyComponentManager>();
		let characters = level.GetSystem<CharacterComponentManager>();

		void Box(StringView name, Float3 at, Float3 half)
		{
			let e = level.CreateEntity(name);
			level.SetLocalPosition(e, at);
			let body = bodies.Add(e);
			body.Motion = .Static;
			body.Layer = .Static;
			body.HalfExtents = half;
		}
		Box("floor", .(0, -0.5f, 0), .(50, 0.5f, 50));
		Box("wall", .(0, 1, 4), .(5, 1, 0.25f)); // its near face at z = 3.75

		let hero = level.CreateEntity("Hero");
		level.SetLocalPosition(hero, .(0, 0.9f, 0));
		characters.Add(hero);
		// The model under it, its origin at the feet; the animator walks 2 m a second along +Z.
		let model = level.CreateEntity("Model");
		level.SetParent(model, hero);
		level.SetLocalPosition(model, .(0, -0.9f, 0));
		let animators = level.GetSystem<SkeletalAnimationComponentManager>();
		let animator = animators.Add(model);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(walk);
		animator.RootMotion = .Character;

		level.UpdateTransforms();
		level.Start();
		level.SetSimulationEnabled(true);
		let dt = 1.0f / 60.0f;
		void Frame()
		{
			level.FixedUpdate(dt);
			level.Update(dt);
		}
		// Where the controller has it: the entity's transform is written by the render time
		// interpolation, which a bare fixed and frame loop never runs.
		float HeroZ() => characters.Get(hero).CurrPosition.Z;

		for (int i < 60) // a second: about 2 m
			Frame();
		let afterOne = HeroZ();
		Test.Assert(Math.Abs(afterOne - 2.0f) < 0.2f, scope $"after a second at {afterOne}");
		for (int i < 180) // three more: it would be at 8 m through the wall
			Frame();
		let atWall = HeroZ();
		Test.Assert(atWall < 3.75f, scope $"stopped by the wall, at {atWall}");
		Test.Assert(atWall > 3.75f - 0.35f - 0.1f, scope $"against it, at {atWall}");

		// The clip stops: the character stands rather than walking on by the last move.
		animators.Get(model).Player.Stop();
		for (int i < 30)
			Frame();
		Test.Assert(Math.Abs(characters.Get(hero).MoveVelocity.Z) < 1e-5f);
		// And switched to Ignore, the animator lets the character go.
		animators.Get(model).Player.Play(walk);
		Frame();
		Test.Assert(characters.Get(hero).MoveVelocity.Z > 1.0f);
		animators.Get(model).RootMotion = .Ignore;
		Frame();
		Test.Assert(Math.Abs(characters.Get(hero).MoveVelocity.Z) < 1e-5f);
	}
}
