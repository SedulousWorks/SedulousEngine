using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// What an animator does with the root motion its clips carry (root-motion.md P2).
[Scriptable]
enum RootMotionMode : uint8
{
	/// Nothing: the character stays where its game puts it (the default).
	Ignore,
	/// The animator's entity, or its RootMotionTarget, moves and turns by it (a non physics actor).
	Entity,
	/// The nearest character at or above it walks by it (it still collides) and turns.
	Character,
	/// Held for scene.Animation.RootMotionTranslation and RootMotionYaw.
	Script,
}

/// An animator's root motion as of its last tick: Script mode reads it, the others use it.
struct RootMotionRuntime
{
	/// The last tick's travel, in the world.
	public Float3 WorldTranslation = .(0, 0, 0);
	/// And its turn about up, radians.
	public float Yaw = 0.0f;
	/// A character's move is ours to zero when we stop.
	public bool DrivingCharacter = false;
	public EntityHandle Character = .Invalid;

	public this() {}
}

/// An animator's tick of root motion, by its mode. The delta is in the skeleton's model space
/// (the first mesh entity's world), so it is carried into the world through that, whatever lies
/// between the animator and its mesh (an armature at rest).
static class RootMotionApply
{
	private static ISceneCharacterMotion Mover(Scene scene)
	{
		for (let system in scene.Systems)
		{
			if (let mover = system.AsCharacterMotion)
				return mover;
		}
		return null;
	}

	/// A character we were walking stops: one zero move, so it does not walk on by our last.
	public static void Release(Scene scene, ref RootMotionRuntime runtime)
	{
		if (runtime.DrivingCharacter && scene.IsValid(runtime.Character))
		{
			if (let mover = Mover(scene))
				mover.MoveCharacter(runtime.Character, .(0, 0, 0));
		}
		runtime.DrivingCharacter = false;
		runtime.Character = .Invalid;
	}

	/// The entity whose world is the skeleton's model space: the first mesh it feeds, else its own.
	private static EntityHandle ModelEntity(Scene scene, List<EntityRef> meshes, EntityHandle owner)
	{
		if (meshes != null)
		{
			for (let mesh in meshes)
			{
				let e = scene.FindEntity(mesh.Id);
				if (scene.IsValid(e))
					return e;
			}
		}
		return owner;
	}

	/// Turns `entity` by `yaw` about the model's up (`upWorld`), seen in its own frame.
	private static void Turn(Scene scene, EntityHandle entity, float yaw, Float3 upWorld)
	{
		if (yaw == 0.0f)
			return;
		var axis = TransformDirection(upWorld, Inverse(scene.ComposeWorldMatrix(entity)));
		axis = (LengthSquared(axis) > 1.0e-12f) ? Normalized(axis) : Float3(0, 1, 0);
		var t = scene.GetLocalTransform(entity);
		t.Rotation = Normalized(t.Rotation * Quaternion.FromAxisAngle(axis, yaw));
		scene.SetLocalTransform(entity, t);
	}

	public static void Apply(Scene scene, EntityHandle owner, List<EntityRef> meshes, EntityRef target, RootMotionMode mode,
		ref RootMotionRuntime runtime, RootMotionDelta delta, float deltaTime)
	{
		let model = scene.ComposeWorldMatrix(ModelEntity(scene, meshes, owner));
		let upWorld = TransformDirection(.(0, 1, 0), model);
		runtime.WorldTranslation = TransformDirection(delta.Translation, model);
		runtime.Yaw = delta.Yaw;
		if (mode != .Character)
			Release(scene, ref runtime);
		if (mode == .Entity)
		{
			// The named entity (a gameplay root holding the model), else the animator's own:
			// moved in its parent's space, turned about the model's up.
			var moved = owner;
			if (!target.IsNil)
			{
				let named = scene.FindEntity(target.Id);
				if (!scene.IsValid(named))
					return;
				moved = named;
			}
			let parent = scene.GetParent(moved);
			let local = scene.IsValid(parent)
				? TransformDirection(runtime.WorldTranslation, Inverse(scene.ComposeWorldMatrix(parent)))
				: runtime.WorldTranslation;
			var t = scene.GetLocalTransform(moved);
			t.Position = t.Position + local;
			scene.SetLocalTransform(moved, t);
			Turn(scene, moved, delta.Yaw, upWorld);
			return;
		}
		if (mode != .Character)
			return;

		let mover = Mover(scene);
		var e = owner;
		for (int depth = 0; (mover != null) && scene.IsValid(e) && (depth < 1024); depth++)
		{
			if (mover.HasCharacter(e))
				break;
			e = scene.GetParent(e);
		}
		if ((mover == null) || !scene.IsValid(e) || !mover.HasCharacter(e))
		{
			Release(scene, ref runtime);
			return;
		}
		if (runtime.DrivingCharacter && (runtime.Character != e))
			Release(scene, ref runtime);
		// A velocity for the next fixed step: the controller collides and slides, one step late.
		var velocity = (deltaTime > 0.0f) ? runtime.WorldTranslation * (1.0f / deltaTime) : Float3(0, 0, 0);
		velocity.Y = 0.0f;
		mover.MoveCharacter(e, velocity);
		runtime.DrivingCharacter = true;
		runtime.Character = e;
		Turn(scene, e, delta.Yaw, upWorld);
	}
}
