using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// A scene carrying the physics managers, which is what every case here is built from.
///
/// The scene system is driven DIRECTLY rather than through the subsystem: what is under test
/// is the per scene runtime, and a bare harness makes the fixed step and the interpolation
/// explicit instead of hidden behind a frame.
class PhysicsPlayScene
{
	public Scene Scene = new .("physics-test") ~ delete _;
	/// BORROWED from the scene.
	public PhysicsSceneSystem Physics = null;

	public this()
	{
		PhysicsScene.AddPhysicsSceneManagers(Scene);
		Physics = Scene.GetSystem<PhysicsSceneSystem>();
	}

	public RigidBodyComponentManager Bodies => Scene.GetSystem<RigidBodyComponentManager>();
	public ColliderComponentManager Colliders => Scene.GetSystem<ColliderComponentManager>();
	public JointComponentManager Joints => Scene.GetSystem<JointComponentManager>();
	public CharacterComponentManager Characters => Scene.GetSystem<CharacterComponentManager>();

	/// A wide, thin static slab just below the origin.
	public EntityHandle AddFloor()
	{
		let entity = Scene.CreateEntity("floor");
		Scene.SetLocalPosition(entity, .(0.0f, -0.5f, 0.0f));

		let body = Bodies.Add(entity);
		body.Motion = .Static;
		body.Layer = .Static;
		body.HalfExtents = .(50.0f, 0.5f, 50.0f);
		return entity;
	}

	public EntityHandle AddBox(float y, MotionKind motion = .Dynamic)
	{
		let entity = Scene.CreateEntity("box");
		Scene.SetLocalPosition(entity, .(0.0f, y, 0.0f));

		let body = Bodies.Add(entity);
		body.Motion = motion;
		body.Layer = (motion == .Static) ? PhysicsLayer.Static
			: (motion == .Kinematic) ? PhysicsLayer.Kinematic : PhysicsLayer.Dynamic;
		return entity;
	}

	public void Start()
	{
		// The world matrices have to be current before the bodies build.
		Scene.UpdateTransforms();
		Scene.Start();
		Scene.SetSimulationEnabled(true);
	}

	public void Step(int steps = 1)
	{
		for (int i < steps)
			Scene.FixedUpdate(1.0f / 60.0f);
	}

	/// Writes the interpolated poses into the scene and settles the world matrices, which is
	/// the order a real frame runs in: the physics subsystem sorts BEFORE the scene's own
	/// update.
	public void Settle(float alpha = 1.0f)
	{
		Physics.ApplyInterpolation(alpha);
		Scene.UpdateTransforms();
	}

	public static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
}
