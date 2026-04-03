using System;
using System.Collections;
using Sedulous.Physics;
using Sedulous.Physics.Jolt;
using Sedulous.Core.Mathematics;

namespace Sedulous.Physics.Tests;

class PhysicsWorldTests
{
	[Test]
	public static void TestWorldCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		Test.Assert(world.IsInitialized);
		Test.Assert(world.BodyCount == 0);
	}

	[Test]
	public static void TestGravity()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let defaultGravity = world.Gravity;
		Test.Assert(Math.Abs(defaultGravity.Y - (-9.81f)) < 0.01f);

		world.Gravity = .(0, -20, 0);
		let newGravity = world.Gravity;
		Test.Assert(Math.Abs(newGravity.Y - (-20f)) < 0.01f);
	}

	[Test]
	public static void TestSphereShapeCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));
		Test.Assert(shape.IsValid);

		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestBoxShapeCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateBoxShape(.(1.0f, 2.0f, 3.0f));
		Test.Assert(shapeResult case .Ok(let shape));
		Test.Assert(shape.IsValid);

		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestCapsuleShapeCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateCapsuleShape(1.0f, 0.5f);
		Test.Assert(shapeResult case .Ok(let shape));
		Test.Assert(shape.IsValid);

		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestDynamicBodyCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 10, 0);
		bodyDescriptor.BodyType = .Dynamic;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));
		Test.Assert(body.IsValid);
		Test.Assert(world.IsValidBody(body));
		Test.Assert(world.BodyCount == 1);

		let pos = world.GetBodyPosition(body);
		Test.Assert(Math.Abs(pos.Y - 10.0f) < 0.01f);

		world.DestroyBody(body);
		Test.Assert(!world.IsValidBody(body));
		Test.Assert(world.BodyCount == 0);

		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestStaticBodyCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateBoxShape(.(100.0f, 1.0f, 100.0f));
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, -1, 0);
		bodyDescriptor.BodyType = .Static;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));
		Test.Assert(world.GetBodyType(body) == .Static);

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestKinematicBodyCreation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateBoxShape(.(1.0f, 1.0f, 1.0f));
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 5, 0);
		bodyDescriptor.BodyType = .Kinematic;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));
		Test.Assert(world.GetBodyType(body) == .Kinematic);

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestBodyTransform()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 0, 0);
		bodyDescriptor.Rotation = .Identity;
		bodyDescriptor.BodyType = .Kinematic;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));

		// Set new transform
		world.SetBodyTransform(body, .(10, 20, 30), .Identity);

		let pos = world.GetBodyPosition(body);
		Test.Assert(Math.Abs(pos.X - 10.0f) < 0.01f);
		Test.Assert(Math.Abs(pos.Y - 20.0f) < 0.01f);
		Test.Assert(Math.Abs(pos.Z - 30.0f) < 0.01f);

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestVelocity()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 10, 0);
		bodyDescriptor.BodyType = .Dynamic;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));

		// Set linear velocity
		world.SetLinearVelocity(body, .(5, 0, 0));
		let linVel = world.GetLinearVelocity(body);
		Test.Assert(Math.Abs(linVel.X - 5.0f) < 0.01f);

		// Set angular velocity
		world.SetAngularVelocity(body, .(0, 1, 0));
		let angVel = world.GetAngularVelocity(body);
		Test.Assert(Math.Abs(angVel.Y - 1.0f) < 0.01f);

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestSimulationStep()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		// Create floor
		let floorShapeResult = world.CreateBoxShape(.(100, 1, 100));
		Test.Assert(floorShapeResult case .Ok(let floorShape));

		var floorDescriptor = PhysicsBodyDescriptor();
		floorDescriptor.Shape = floorShape;
		floorDescriptor.Position = .(0, -1, 0);
		floorDescriptor.BodyType = .Static;
		let floorBody = world.CreateBody(floorDescriptor);
		Test.Assert(floorBody case .Ok);

		// Create falling sphere
		let sphereShapeResult = world.CreateSphereShape(0.5f);
		Test.Assert(sphereShapeResult case .Ok(let sphereShape));

		var sphereDescriptor = PhysicsBodyDescriptor();
		sphereDescriptor.Shape = sphereShape;
		sphereDescriptor.Position = .(0, 10, 0);
		sphereDescriptor.BodyType = .Dynamic;
		let sphereBody = world.CreateBody(sphereDescriptor);
		Test.Assert(sphereBody case .Ok(let body));

		let initialY = world.GetBodyPosition(body).Y;

		// Simulate for some time
		for (int i = 0; i < 60; i++)
		{
			world.Step(1.0f / 60.0f, 1);
		}

		let finalY = world.GetBodyPosition(body).Y;

		// Ball should have fallen
		Test.Assert(finalY < initialY);

		world.DestroyBody(floorBody.Value);
		world.DestroyBody(body);
		world.ReleaseShape(floorShape);
		world.ReleaseShape(sphereShape);
	}

	[Test]
	public static void TestRayCast()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		// Create a box to hit
		let boxShapeResult = world.CreateBoxShape(.(1, 1, 1));
		Test.Assert(boxShapeResult case .Ok(let @box));

		var boxDescriptor = PhysicsBodyDescriptor();
		boxDescriptor.Shape = @box;
		boxDescriptor.Position = .(0, 0, 10);
		boxDescriptor.BodyType = .Static;
		let boxBody = world.CreateBody(boxDescriptor);
		Test.Assert(boxBody case .Ok(let body));

		// Ray that hits the box
		RayCastQuery hitQuery = .(.(0, 0, 0), .(0, 0, 1), 100.0f);

		RayCastResult hitResult = ?;
		let didHit = world.RayCast(hitQuery, out hitResult);
		Test.Assert(didHit);
		Test.Assert(hitResult.Body.IsValid);
		Test.Assert(hitResult.Fraction < 1.0f);

		// Ray that misses
		RayCastQuery missQuery = .(.(0, 0, 0), .(1, 0, 0), 100.0f);

		RayCastResult missResult = ?;
		let didMiss = world.RayCast(missQuery, out missResult);
		Test.Assert(!didMiss);

		world.DestroyBody(body);
		world.ReleaseShape(@box);
	}

	[Test]
	public static void TestBodyActivation()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 10, 0);
		bodyDescriptor.BodyType = .Dynamic;
		bodyDescriptor.AllowSleep = true;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));

		// Body should be active initially
		Test.Assert(world.IsBodyActive(body));

		// Deactivate
		world.DeactivateBody(body);
		Test.Assert(!world.IsBodyActive(body));

		// Reactivate
		world.ActivateBody(body);
		Test.Assert(world.IsBodyActive(body));

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestUserData()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(1.0f);
		Test.Assert(shapeResult case .Ok(let shape));

		var bodyDescriptor = PhysicsBodyDescriptor();
		bodyDescriptor.Shape = shape;
		bodyDescriptor.Position = .(0, 0, 0);
		bodyDescriptor.BodyType = .Static;
		bodyDescriptor.UserData = 12345;

		let bodyResult = world.CreateBody(bodyDescriptor);
		Test.Assert(bodyResult case .Ok(let body));

		Test.Assert(world.GetBodyUserData(body) == 12345);

		world.SetBodyUserData(body, 67890);
		Test.Assert(world.GetBodyUserData(body) == 67890);

		world.DestroyBody(body);
		world.ReleaseShape(shape);
	}

	[Test]
	public static void TestMultipleBodies()
	{
		let descriptor = PhysicsWorldDescriptor();
		let worldResult = JoltPhysicsWorld.Create(descriptor);
		Test.Assert(worldResult case .Ok(let world));
		defer delete world;

		let shapeResult = world.CreateSphereShape(0.5f);
		Test.Assert(shapeResult case .Ok(let shape));

		List<BodyHandle> bodies = scope .();

		// Create multiple bodies
		for (int i = 0; i < 10; i++)
		{
			var bodyDescriptor = PhysicsBodyDescriptor();
			bodyDescriptor.Shape = shape;
			bodyDescriptor.Position = .((float)i * 2, 10, 0);
			bodyDescriptor.BodyType = .Dynamic;

			if (world.CreateBody(bodyDescriptor) case .Ok(let body))
				bodies.Add(body);
		}

		Test.Assert(world.BodyCount == 10);
		Test.Assert(bodies.Count == 10);

		// Destroy all bodies
		for (let body in bodies)
			world.DestroyBody(body);

		Test.Assert(world.BodyCount == 0);

		world.ReleaseShape(shape);
	}
}
