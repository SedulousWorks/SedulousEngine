using System;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The body wireframes.
///
/// The colour says what a body IS at a glance: green is an awake dynamic one, grey a sleeping
/// one, blue static or kinematic, and amber a trigger.
static class PhysicsDebugDraw
{
	private static Color cTrigger = .(1.0f, 0.8f, 0.2f, 1.0f);
	private static Color cAwake = .(0.3f, 1.0f, 0.4f, 1.0f);
	private static Color cAsleep = .(0.5f, 0.6f, 0.5f, 1.0f);
	private static Color cStatic = .(0.4f, 0.6f, 1.0f, 1.0f);
	private static Color cGrounded = .(0.2f, 0.9f, 0.9f, 1.0f);
	private static Color cAirborne = .(0.9f, 0.5f, 0.9f, 1.0f);

	/// A plane draws as a bounded grid patch, which reads far better than one enormous quad.
	private const int32 cPlaneCells = 10;
	private const float cPlaneMaxExtent = 25.0f;

	public static void Draw(PhysicsSceneSystem system, DebugDraw draw)
	{
		let world = system.World;
		let scene = system.OwningScene;
		if ((world == null) || (scene == null))
			return;

		if (let bodies = scene.GetSystem<RigidBodyComponentManager>())
		{
			bodies.ForEach(scope [&] (component, entity) =>
				{
					DrawBody(scene, world, draw, component, entity);
				});
		}

		if (let characters = scene.GetSystem<CharacterComponentManager>())
		{
			characters.ForEach(scope [&] (component, entity) =>
				{
					if (!component.Character.IsValid)
						return;

					let position = world.CharacterPosition(component.Character);
					let color = (component.Ground == .OnGround) ? cGrounded : cAirborne;

					draw.DrawWireSphere(.(position.X, position.Y + component.HalfHeight,
						position.Z), component.Radius, color);
					draw.DrawWireSphere(.(position.X, position.Y - component.HalfHeight,
						position.Z), component.Radius, color);
					draw.DrawWireBoxCenter(position, .(component.Radius, component.HalfHeight,
						component.Radius), color);
				});
		}
	}

	private static void DrawBody(Scene scene, PhysicsWorld world, DebugDraw draw,
		RigidBodyComponent* component, EntityHandle entity)
	{
		if (!component.Body.IsValid)
			return;

		world.GetBodyTransform(component.Body, let position, let rotation);

		let color = component.IsTrigger ? cTrigger
			: (component.Motion == .Dynamic)
				? (world.IsActive(component.Body) ? cAwake : cAsleep)
				: cStatic;

		let worldMatrix = Transform(position, rotation, .(1, 1, 1)).ToMatrix();

		switch (component.Shape)
		{
		case .Box:
			draw.DrawTransformedBox(.(-component.HalfExtents.X, -component.HalfExtents.Y,
				-component.HalfExtents.Z), component.HalfExtents, worldMatrix, color);

		case .Sphere:
			draw.DrawWireSphere(position, component.Radius, color);

		case .Capsule:
			draw.DrawWireSphere(position, component.Radius, color);
			draw.DrawTransformedBox(
				.(-component.Radius, -(component.HalfHeight + component.Radius),
					-component.Radius),
				.(component.Radius, component.HalfHeight + component.Radius, component.Radius),
				worldMatrix, color);

		case .Plane:
			let extent = Math.Min(component.PlaneHalfExtent, cPlaneMaxExtent);
			for (int32 g = -cPlaneCells; g <= cPlaneCells; g++)
			{
				let offset = extent * (float)g / cPlaneCells;
				draw.DrawLine(TransformPoint(Float3(offset, 0, -extent), worldMatrix),
					TransformPoint(Float3(offset, 0, extent), worldMatrix), color);
				draw.DrawLine(TransformPoint(Float3(-extent, 0, offset), worldMatrix),
					TransformPoint(Float3(extent, 0, offset), worldMatrix), color);
			}

		case .Heightfield:
			// The footprint's BOX rather than a per cell wireframe: honest about where the
			// surface is without walking every sample.
			if (let heightfield = component.Heightfield.Get)
			{
				let size = heightfield.WorldSize;
				draw.DrawTransformedBox(.(-size.X * 0.5f, heightfield.MinY, -size.Y * 0.5f),
					.(size.X * 0.5f, heightfield.MaxY, size.Y * 0.5f), worldMatrix, color);
			}

		case .Cooked:
			if (let cooked = component.CollisionShape.Get)
			{
				// The outline is authored at unit scale, so the entity's scale re-applies.
				let shapeMatrix = Decompose(scene.GetWorldMatrix(entity), ?, ?, let scale)
					? Transform(position, rotation, scale).ToMatrix() : worldMatrix;

				let outline = cooked.Outline;
				for (int t = 0; (t + 2) < outline.Count; t += 3)
				{
					let a = TransformPoint(outline[t + 0], shapeMatrix);
					let b = TransformPoint(outline[t + 1], shapeMatrix);
					let c = TransformPoint(outline[t + 2], shapeMatrix);
					draw.DrawLine(a, b, color);
					draw.DrawLine(b, c, color);
					draw.DrawLine(c, a, color);
				}
			}
		}
	}
}
