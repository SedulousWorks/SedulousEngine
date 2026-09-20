using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;

namespace Sedulous.Editor.Scene.Tests;

/// The component gizmo registry and the collider renderers' gates and shapes.
class ComponentGizmoTests
{
	[Test]
	public static void RenderersResolveByComponentTypeAndUnselectedEntitiesAreGated()
	{
		let registry = scope GizmoRendererRegistry();
		BuiltinGizmoRenderers.Register(registry);
		Test.Assert(registry.Count == 11);

		Test.Assert(registry.Find(typeof(LightComponent)) != null);
		Test.Assert(registry.Find(typeof(RigidBodyComponent)) != null);
		Test.Assert(registry.Find(typeof(ColliderComponent)) != null);
		Test.Assert(registry.Find(typeof(CharacterComponent)) != null);
		Test.Assert(registry.Find(typeof(JointComponent)) != null);
		Test.Assert(registry.Find(typeof(ReflectionProbeComponent)) != null);
		Test.Assert(registry.Find(typeof(CameraComponent)) != null);
		Test.Assert(registry.Find(typeof(DecalComponent)) != null);
		Test.Assert(registry.Find(typeof(NavMeshZoneComponent)) != null);
		Test.Assert(registry.Find(typeof(float)) == null);

		Test.Assert(!registry.Find(typeof(LightComponent)).DrawWhenUnselected);
		Test.Assert(!registry.Find(typeof(NavMeshZoneComponent)).DrawWhenUnselected);
		Test.Assert(registry.Find(typeof(RigidBodyComponent)).DrawWhenUnselected);
	}

	[Test]
	public static void ALightDrawsOnlyWhenSelectedAndAColliderRegardless()
	{
		let scene = scope Scene();
		let lights = scene.AddSystem<LightComponentManager>();
		let bodies = scene.AddSystem<RigidBodyComponentManager>();
		let e = scene.CreateEntity("Lamp");
		lights.Add(e).Type = .Point;
		bodies.Add(e).Shape = .Box;

		let registry = scope GizmoRendererRegistry();
		BuiltinGizmoRenderers.Register(registry);
		let dd = scope DebugDraw();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;
		ctx.ShowColliders = true;

		registry.DrawEntity(e, false, ctx);
		let unselected = dd.LineVertices.Length;
		Test.Assert(unselected > 0); // the collider outline
		dd.Clear();
		registry.DrawEntity(e, true, ctx);
		Test.Assert(dd.LineVertices.Length > unselected); // plus the light's range sphere
	}

	[Test]
	public static void PhysicsColliderGizmoDrawsABoxOnlyWhenShowCollidersIsOn()
	{
		let scene = scope Scene();
		let bodies = scene.AddSystem<RigidBodyComponentManager>();
		let e = scene.CreateEntity("Box");
		let body = bodies.Add(e);
		body.Shape = .Box;
		body.HalfExtents = .(1.0f, 2.0f, 0.5f);

		let dd = scope DebugDraw();
		let renderer = scope PhysicsColliderGizmoRenderer();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;

		ctx.ShowColliders = false;
		renderer.Draw(bodies.GetComponentAddress(e), e, ctx);
		Test.Assert(!dd.HasAnyDraws);

		ctx.ShowColliders = true;
		renderer.Draw(bodies.GetComponentAddress(e), e, ctx);
		Test.Assert(dd.LineVertices.Length > 0);
	}

	[Test]
	public static void JointGizmoIsGatedAnchorOnlyForANilTargetAndAHingeAddsTheAxis()
	{
		let scene = scope Scene();
		let joints = scene.AddSystem<JointComponentManager>();
		let e = scene.CreateEntity("Jointed");
		let joint = joints.Add(e);

		let dd = scope DebugDraw();
		let renderer = scope JointGizmoRenderer();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;

		ctx.ShowColliders = false;
		renderer.Draw(joints.GetComponentAddress(e), e, ctx);
		Test.Assert(!dd.HasAnyDraws);

		ctx.ShowColliders = true;
		renderer.Draw(joints.GetComponentAddress(e), e, ctx);
		Test.Assert(dd.HasAnyDraws);
		let anchorOnly = dd.LineVertices.Length;
		Test.Assert(anchorOnly > 0);

		dd.Clear();
		joint.Kind = .Hinge;
		renderer.Draw(joints.GetComponentAddress(e), e, ctx);
		Test.Assert(dd.LineVertices.Length > anchorOnly);

		// A target draws the link to it.
		dd.Clear();
		let target = scene.CreateEntity("Target");
		scene.SetLocalPosition(target, .(3, 0, 0));
		joint.TargetEntity = .(scene.GetEntityId(target));
		renderer.Draw(joints.GetComponentAddress(e), e, ctx);
		let withTarget = dd.LineVertices.Length;
		Test.Assert(withTarget > anchorOnly);
	}

	[Test]
	public static void CharacterCapsuleDrawsOnlyWhenShowCollidersIsOn()
	{
		let scene = scope Scene();
		let characters = scene.AddSystem<CharacterComponentManager>();
		let e = scene.CreateEntity("Hero");
		characters.Add(e); // defaults: radius 0.35, half height 0.55

		let dd = scope DebugDraw();
		let renderer = scope CharacterColliderGizmoRenderer();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;

		ctx.ShowColliders = false;
		renderer.Draw(characters.GetComponentAddress(e), e, ctx);
		Test.Assert(!dd.HasAnyDraws);

		ctx.ShowColliders = true;
		renderer.Draw(characters.GetComponentAddress(e), e, ctx);
		Test.Assert(dd.HasAnyDraws);
		Test.Assert(dd.LineVertices.Length > 0);
	}

	[Test]
	public static void ChildColliderDrawsItsWireframeOnlyWhenShowCollidersIsOn()
	{
		let scene = scope Scene();
		let colliders = scene.AddSystem<ColliderComponentManager>();
		let parent = scene.CreateEntity("Body");
		let child = scene.CreateEntity("Fist");
		scene.SetParent(child, parent);
		let collider = colliders.Add(child);
		collider.Shape = .Box;
		collider.HalfExtents = .(0.25f, 0.25f, 0.25f);

		let dd = scope DebugDraw();
		let renderer = scope ChildColliderGizmoRenderer();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;

		ctx.ShowColliders = false;
		renderer.Draw(colliders.GetComponentAddress(child), child, ctx);
		Test.Assert(!dd.HasAnyDraws);

		ctx.ShowColliders = true;
		renderer.Draw(colliders.GetComponentAddress(child), child, ctx);
		Test.Assert(dd.HasAnyDraws);
		Test.Assert(dd.LineVertices.Length > 0);
	}

	[Test]
	public static void AnInactiveEntitysColliderDrawsDimmedGrayNotSkipped()
	{
		let scene = scope Scene();
		let bodies = scene.AddSystem<RigidBodyComponentManager>();
		let e = scene.CreateEntity("Box");
		let body = bodies.Add(e);
		body.Shape = .Box;
		body.Motion = .Dynamic; // the active colour is green: R != G

		let registry = scope GizmoRendererRegistry();
		BuiltinGizmoRenderers.Register(registry);
		let dd = scope DebugDraw();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;
		ctx.ShowColliders = true;

		scene.SetActive(e, false);
		registry.DrawEntity(e, true, ctx);
		Test.Assert(dd.LineVertices.Length > 0); // dimmed, NOT skipped
		let packed = dd.LineVertices[0].Color;
		let r = packed & 0xFF;
		let g = (packed >> 8) & 0xFF;
		let b = (packed >> 16) & 0xFF;
		Test.Assert(r == g); // a uniform grey: the dim colour, not the dynamic green
		Test.Assert(g == b);

		scene.SetActive(e, true);
		let dd2 = scope DebugDraw();
		ctx.Debug = dd2;
		registry.DrawEntity(e, true, ctx);
		Test.Assert(dd2.LineVertices.Length > 0);
		let active = dd2.LineVertices[0].Color;
		Test.Assert((active & 0xFF) != ((active >> 8) & 0xFF)); // green: R != G
	}

	[Test]
	public static void TheCapsuleColliderDrawsCapSpheresAndSideLinesNotABox()
	{
		let scene = scope Scene();
		let bodies = scene.AddSystem<RigidBodyComponentManager>();
		let e = scene.CreateEntity("Cap");
		let body = bodies.Add(e);
		body.Shape = .Capsule;
		body.Radius = 0.5f;
		body.HalfHeight = 1.0f;

		let dd = scope DebugDraw();
		let renderer = scope PhysicsColliderGizmoRenderer();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;
		ctx.ShowColliders = true;
		renderer.Draw(bodies.GetComponentAddress(e), e, ctx);

		Test.Assert(dd.LineVertices.Length > 100);
		var sideVerts = 0;
		for (let v in dd.LineVertices)
		{
			let atCapY = (Abs(v.Position.Y - 1.0f) < 0.001f) || (Abs(v.Position.Y + 1.0f) < 0.001f);
			let onRim = (Abs(Abs(v.Position.X) - 0.5f) < 0.001f) || (Abs(Abs(v.Position.Z) - 0.5f) < 0.001f);
			if (atCapY && onRim)
				sideVerts++;
		}
		Test.Assert(sideVerts >= 8); // the four side lines' endpoints, plus coincident ring verts
	}

	[Test]
	public static void CameraProbeDecalAndZoneGizmosDrawTheirShapes()
	{
		let scene = scope Scene();
		let cameras = scene.AddSystem<CameraComponentManager>();
		let probes = scene.AddSystem<ReflectionProbeComponentManager>();
		let decals = scene.AddSystem<DecalComponentManager>();
		let zones = scene.AddSystem<NavMeshZoneComponentManager>();
		let e = scene.CreateEntity("All");
		cameras.Add(e);
		probes.Add(e);
		decals.Add(e);
		zones.Add(e);

		let registry = scope GizmoRendererRegistry();
		BuiltinGizmoRenderers.Register(registry);
		let dd = scope DebugDraw();
		let ctx = scope GizmoContext();
		ctx.Scene = scene;
		ctx.Debug = dd;

		registry.DrawEntity(e, false, ctx);
		Test.Assert(!dd.HasAnyDraws); // none of these show unselected
		registry.DrawEntity(e, true, ctx);
		Test.Assert(dd.LineVertices.Length > 0);
	}
}
