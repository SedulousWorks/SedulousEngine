using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// Bodies and colliders measure their entities for the scene (ISceneEntityBounds) by their
/// authored shapes, through the entity's world matrix; a plane is endless and measures
/// nothing. The managers answer, not the physics scene system, which exists only while
/// simulating.
class EntityBoundsTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void BodiesAndCollidersMeasureByTheirAuthoredShapes()
	{
		let scene = scope Scene("bounds");
		let bodies = scene.AddSystem<RigidBodyComponentManager>();
		let colliders = scene.AddSystem<ColliderComponentManager>();

		// A crateBounds body, moved and scaled: its half extents through the world matrix.
		let crate = scene.CreateEntity("crate");
		var transform = Transform();
		transform.Position = .(0.0f, 2.0f, 0.0f);
		transform.Scale = .(2.0f, 1.0f, 1.0f);
		scene.SetLocalTransform(crate, transform);
		let body = bodies.Add(crate);
		body.Shape = .Box;
		body.HalfExtents = .(1.0f, 0.5f, 0.25f);

		// A capsule collider: its radius across, its half height plus radius along Y.
		let post = scene.CreateEntity("post");
		scene.SetLocalPosition(post, .(5.0f, 0.0f, 0.0f));
		let capsule = colliders.Add(post);
		capsule.Shape = .Capsule;
		capsule.Radius = 0.3f;
		capsule.HalfHeight = 1.0f;

		// A plane is endless: it measures nothing.
		let ground = scene.CreateEntity("ground");
		bodies.Add(ground).Shape = .Plane;
		scene.UpdateTransforms();

		Test.Assert(scene.EntityWorldBounds(crate, let crateBounds));
		Test.Assert(Near(crateBounds.Min.X, -2.0f) && Near(crateBounds.Max.X, 2.0f));
		Test.Assert(Near(crateBounds.Min.Y, 1.5f) && Near(crateBounds.Max.Z, 0.25f));

		Test.Assert(scene.EntityWorldBounds(post, let pill));
		Test.Assert(Near(pill.Min.X, 4.7f) && Near(pill.Max.Y, 1.3f));

		Test.Assert(!scene.EntityWorldBounds(ground, ?));
	}
}
