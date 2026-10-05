using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Physics.Tests;

/// The scene to world bridge: components become bodies when the scene starts, the fixed step
/// simulates them, and the render frame reads interpolated poses.
class PhysicsSceneTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	[Test]
	public static void ComponentsBuildBodiesAtStartAndDynamicsLand()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(5.0f);
		play.Start();

		Test.Assert(play.Physics.World != null);
		Test.Assert(play.Physics.World.BodyCount == 2);

		play.Step(240);
		play.Settle();

		// Resting on the floor, its own half extent above the surface.
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 0.5f, 0.05f));

		// Stopping tears the world down and clears the handles with it.
		play.Scene.Stop();
		Test.Assert(play.Physics.World == null);
		Test.Assert(!play.Bodies.Get(@box).Body.IsValid);
	}

	/// The interpolation reads the double buffer: nought is the previous pose, one the
	/// current, and a half is exactly between them.
	[Test]
	public static void InterpolationBlendsBetweenTheLastTwoFixedPoses()
	{
		let play = scope PhysicsPlayScene();
		// Free fall, with no floor to land on.
		let @box = play.AddBox(10.0f);
		play.Start();
		// Long enough to be moving properly.
		play.Step(30);

		let body = play.Bodies.Get(@box);
		Test.Assert(body != null);

		let previous = body.PrevPosition.Y;
		let current = body.CurrPosition.Y;
		Test.Assert(previous > current);

		play.Settle(0.0f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, previous));

		play.Settle(1.0f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, current));

		play.Settle(0.5f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, (previous + current) * 0.5f));
	}

	/// A KINEMATIC body follows the scene, and what rests on it is carried along by friction
	/// rather than left behind.
	[Test]
	public static void KinematicBodiesFollowTheSceneAndCarryWhatRestsOnThem()
	{
		let play = scope PhysicsPlayScene();
		let platform = play.AddBox(0.0f, .Kinematic);
		let rider = play.AddBox(1.5f);
		play.Start();

		// Land the rider first.
		play.Step(120);

		// Then slide the platform two units over two seconds.
		for (int i < 120)
		{
			var transform = play.Scene.GetLocalTransform(platform);
			transform.Position.X += 2.0f / 120.0f;
			play.Scene.SetLocalTransform(platform, transform);
			play.Scene.UpdateTransforms();
			play.Step(1);
		}

		play.Settle();

		let position = play.Scene.GetWorldPosition(rider);
		// Dragged along.
		Test.Assert(position.X > 1.0f);
		// And still on top: the platform's upper face plus the rider's half extent.
		Test.Assert(Near(position.Y, 1.0f, 0.1f));
	}

	/// A descendant's collider folds into its ancestor's body as a compound, at the offset it
	/// had when the scene started.
	[Test]
	public static void DescendantCollidersCompoundIntoTheAncestorBody()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let body = play.AddBox(0.5f, .Static);
		let arm = play.Scene.CreateEntity("arm");
		play.Scene.SetParent(arm, body);
		play.Scene.SetLocalPosition(arm, .(2.0f, 0.0f, 0.0f));
		play.Colliders.Add(arm).HalfExtents = .(0.5f, 0.5f, 0.5f);

		play.Start();

		// The arm is only reachable if the compound actually carries its shape.
		Test.Assert(play.Physics.World.RayCast(.(2.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f,
			let hit));
		Test.Assert(Near(hit.Position.Y, 1.0f, 0.05f));
	}

	/// A scaled body's child colliders keep their world place and size: the physics body carries
	/// no scale, so a child measured against the body's whole matrix came out unscaled (Sky
	/// Hopper's spikes, a prefab scaled 0.45 whose model carries cooked collision, stood 3.4 m
	/// tall in the physics world and 1.5 m on screen).
	[Test]
	public static void AScaledBodysChildCollidersKeepTheirWorldPlaceAndSize()
	{
		// A unit cube hull, cooked once: the shape a model import's collision carries.
		let corners = scope List<Float3>();
		let ends = float[2](-0.5f, 0.5f);
		for (let x in ends)
			for (let y in ends)
				for (let z in ends)
					corners.Add(.(x, y, z));
		let hull = scope CollisionShape();
		Test.Assert(ShapeCooking.CookConvexHull(corners, hull.Blob));
		hull.Convex = true;

		// A static body scaled 0.5, with a child 4 m out along x carrying the cube scaled 2: in
		// the world the child sits 2 m out and is 1 m across, its top at 0.5.
		let play = scope PhysicsPlayScene();
		let body = play.AddBox(0.0f, .Static);
		play.Bodies.Get(body).HalfExtents = .(0.01f, 0.01f, 0.01f);
		var bodyTransform = play.Scene.GetLocalTransform(body);
		bodyTransform.Scale = .(0.5f, 0.5f, 0.5f);
		play.Scene.SetLocalTransform(body, bodyTransform);

		let piece = play.Scene.CreateEntity("piece");
		play.Scene.SetParent(piece, body);
		var pieceTransform = Transform();
		pieceTransform.Position = .(4.0f, 0.0f, 0.0f);
		pieceTransform.Scale = .(2.0f, 2.0f, 2.0f);
		play.Scene.SetLocalTransform(piece, pieceTransform);
		let collider = play.Colliders.Add(piece);
		collider.Shape = .Cooked;
		collider.CollisionShape.SetDirect(hull);

		play.Start();

		Test.Assert(play.Physics.World.RayCast(.(2.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f, let hit));
		Test.Assert(Near(hit.Position.Y, 0.5f, 0.05f), "its top: 1 m across");
		// Nothing where the unscaled offset (4 m) or an unscaled 2 m cube would have reached.
		Test.Assert(!play.Physics.World.RayCast(.(3.6f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f, ?));
	}

	/// A trigger raises an ENTER whose sides resolve back to the entities that own them.
	[Test]
	public static void TriggersRaiseEventsResolvedToEntities()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let volume = play.AddBox(2.0f, .Kinematic);
		let sensor = play.Bodies.Get(volume);
		sensor.IsTrigger = true;
		sensor.HalfExtents = .(1.0f, 1.0f, 1.0f);

		let faller = play.AddBox(6.0f);
		play.Start();

		let recorder = scope RecordingContactListener();
		let listeners = scope List<IContactListener>();
		listeners.Add(recorder);
		play.Physics.SetContactListeners(listeners);

		var entered = false;
		for (int i = 0; (i < 240) && !entered; i++)
		{
			play.Step(1);
			for (let contact in recorder.Contacts)
			{
				if (contact.Kind != .TriggerEnter)
					continue;

				if (((contact.A == volume) && (contact.B == faller))
					|| ((contact.A == faller) && (contact.B == volume)))
					entered = true;
			}
		}

		Test.Assert(entered);
	}
	/// The editor's simulate cycle, run twice: capture, start, simulate, stop, restore.
	///
	/// This is the shape that hangs rather than the shape that fails. A restore puts the
	/// entities back while the world still holds bodies for them, so a cycle that does not
	/// tear the world down leaves stale bodies the next start builds duplicates against.
	/// Terminating with the boxes back where they were authored is the whole assertion.
	[Test]
	public static void TheEditorSimulateCycleTerminates()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		// The persistent ids, NOT the handles: a restore drains the scene and rebuilds it, so
		// every handle taken before the cycle is stale afterwards. The ids survive the
		// snapshot, which is what makes the same box findable on the other side.
		let boxIds = scope List<Guid>();
		for (int i < 8)
		{
			let entity = play.AddBox(3.0f + (float)i);
			play.Scene.SetLocalPosition(entity, .((float)i * 0.5f, 3.0f + (float)i, 0.0f));
			boxIds.Add(play.Scene.GetEntityId(entity));
		}
		play.Scene.UpdateTransforms();

		for (int cycle < 2)
		{
			let snapshot = SceneSnapshot.Capture(play.Scene);
			defer delete snapshot;
			Test.Assert(snapshot != null);

			play.Start();
			play.Step(120);

			play.Scene.Stop();
			Test.Assert(snapshot.Restore(play.Scene) case .Ok);
			play.Scene.SetSimulationEnabled(false);
			play.Step(60); // the stopped scene still ticks, and must stay put

			play.Scene.UpdateTransforms();
			for (int i < boxIds.Count)
			{
				let restored = play.Scene.FindEntity(boxIds[i]);
				Test.Assert(restored.IsAssigned, scope $"cycle {cycle}: box {i} came back");

				let y = play.Scene.GetWorldPosition(restored).Y;
				Test.Assert(PhysicsPlayScene.Near(y, 3.0f + (float)i, 0.01f),
					scope $"cycle {cycle}: box {i} is back where it was authored, not {y}");
			}
		}
	}

	/// The navigation bake reads level geometry from the scene's static geometry sources.
	/// Physics' is its static, solid bodies (a compound with its child colliders), read in edit
	/// mode with no world: what moves (dynamic, kinematic), what lets things through (a
	/// trigger) and what has no body (an inactive entity) give nothing.
	[Test]
	public static void StaticGeometryIsTheStaticSolidBodiesCompoundsIncluded()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor(); // its top at y nought
		let scene = play.Scene;
		let solid = play.AddBox(0.5f, .Static);
		scene.SetLocalPosition(solid, .(10.0f, 0.5f, 0.0f));
		let arm = scene.CreateEntity("arm");
		scene.SetParent(arm, solid);
		scene.SetLocalPosition(arm, .(2.0f, 0.0f, 0.0f));
		play.Colliders.Add(arm).HalfExtents = .(0.5f, 0.5f, 0.5f);
		scene.SetLocalPosition(play.AddBox(0.5f, .Dynamic), .(-10.0f, 0.5f, 0.0f));
		scene.SetLocalPosition(play.AddBox(0.5f, .Kinematic), .(-20.0f, 0.5f, 0.0f));
		let trigger = play.AddBox(0.5f, .Static);
		scene.SetLocalPosition(trigger, .(20.0f, 0.5f, 0.0f));
		play.Bodies.Get(trigger).IsTrigger = true;
		let off = play.AddBox(0.5f, .Static);
		scene.SetLocalPosition(off, .(30.0f, 0.5f, 0.0f));
		scene.SetActive(off, false);
		scene.UpdateTransforms(); // edit mode: no start, no world

		let source = play.Bodies.AsStaticGeometrySource;
		Test.Assert(source != null);
		Test.Assert(play.Colliders.AsStaticGeometrySource == null);
		let triangles = scope List<Float3>();
		let region = AABB(.(-40, -5, -40), .(40, 5, 40));
		source.CollectStaticGeometry(scene, region, 0.3f, triangles);
		Test.Assert(!triangles.IsEmpty, "no static geometry");
		Test.Assert((triangles.Count % 3) == 0);
		int floor = 0;
		int raised = 0;
		for (int i = 0; i < triangles.Count; i += 3)
		{
			let centre = (triangles[i] + triangles[i + 1] + triangles[i + 2]) * (1.0f / 3.0f);
			if (centre.Y < 0.01f)
			{
				floor++; // the floor's faces, and the bottoms of the boxes standing on it
				continue;
			}
			raised++;
			// Only the compound: its body at ten and its arm at twelve.
			Test.Assert((centre.X > 9.4f) && (centre.X < 12.6f), scope $"{centre}");
		}
		Test.Assert(floor > 0, scope $"{floor} floor, {raised} raised");
		Test.Assert(raised == 20, scope $"{raised}"); // two boxes' tops and sides
	}

	/// What foot IK asks (inverse-kinematics.md P3): the ground under a foot. A checkpoint
	/// trigger standing on the floor is not a floor.
	[Test]
	public static void TheSceneRayQueryFindsSolidGroundAndPassesThroughATrigger()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor(); // top at y = 0
		let checkpoint = play.AddBox(0.5f, .Static);
		let sensor = play.Bodies.Get(checkpoint);
		sensor.IsTrigger = true;
		sensor.HalfExtents = .(1.0f, 0.5f, 1.0f); // y 0 to 1, right under the probe
		let crate = play.AddBox(0.5f, .Static);
		play.Scene.SetLocalPosition(crate, .(4.0f, 0.5f, 0.0f)); // a solid box beside it, top at 1
		play.Start();

		let rays = play.Physics.AsRayQuery;
		Test.Assert(rays != null);
		Test.Assert(rays.CastRay(.(0, 3, 0), .(0, -1, 0), 10.0f, 0xFFFFFFFF, var hit));
		Test.Assert(Math.Abs(hit.Position.Y) < 1e-3f, "through the trigger, onto the floor");
		Test.Assert(Math.Abs(hit.Distance - 3.0f) < 1e-3f);
		Test.Assert(Math.Abs(hit.Normal.Y - 1.0f) < 1e-3f);

		Test.Assert(rays.CastRay(.(4, 3, 0), .(0, -1, 0), 10.0f, 0xFFFFFFFF, out hit));
		Test.Assert(Math.Abs(hit.Position.Y - 1.0f) < 1e-3f, "a solid box is ground");

		Test.Assert(!rays.CastRay(.(0, 3, 0), .(0, -1, 0), 2.0f, 0xFFFFFFFF, out hit), "out of reach");

		// The script ray still sees triggers: what a game may ask for on purpose.
		Test.Assert(play.Physics.World.RayCast(.(0, 3, 0), .(0, -1, 0), 10.0f, let raw));
		Test.Assert(Math.Abs(raw.Position.Y - 1.0f) < 1e-3f);
	}
}
