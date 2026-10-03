using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The body a RigidBodyComponent makes, described once: body creation and the static geometry
/// the navigation bake reads both describe bodies here, so the bake sees exactly what the
/// bodies collide with.
static class PhysicsBodies
{
	/// The body `component` makes on `entity`: its settings, the entity's world pose, its own
	/// shape and the ColliderComponents under it (a compound at their offsets). Heightfield
	/// samples are copied into buffers added to `heightBuffers` (OWNED by the caller), which
	/// the description points into and which must outlive it. False, logged, when the
	/// transform does not decompose or a shape's resource is missing.
	public static bool Describe(Scene scene, RigidBodyComponent* component, EntityHandle entity,
		BodyDesc outDesc, List<List<float>> heightBuffers)
	{
		if (!Decompose(scene.GetWorldMatrix(entity), let position, let rotation, let scale))
			return false;

		outDesc.Motion = component.Motion;
		outDesc.Layer = component.Layer;
		outDesc.Friction = component.Friction;
		outDesc.Restitution = component.Restitution;
		outDesc.LinearDamping = component.LinearDamping;
		outDesc.AngularDamping = component.AngularDamping;
		outDesc.IsTrigger = component.IsTrigger;
		outDesc.ContinuousCollision = component.ContinuousCollision;
		outDesc.MassOverride = component.Mass;
		outDesc.Group = component.CollisionGroup;
		// The reverse map, so a contact can name the entity again.
		outDesc.UserData = PhysicsEntityPacking.PackEntity(entity);
		outDesc.Position = position;
		outDesc.Rotation = rotation;

		var own = ShapeDesc();
		own.Kind = component.Shape;
		own.HalfExtents = component.HalfExtents;
		own.Radius = component.Radius;
		own.HalfHeight = component.HalfHeight;
		own.PlaneHalfExtent = component.PlaneHalfExtent;

		if (component.Shape == .Cooked)
		{
			let cooked = component.CollisionShape.Get;
			if (cooked == null)
			{
				GlobalLog(.Warning,
					"Physics: '{}' has a cooked shape but no collision shape resource, so the body was skipped",
					scene.GetEntityName(entity));
				return false;
			}
			own.Cooked = cooked.Blob;
			// Cooked geometry is authored at unit scale, so the entity's scale applies here.
			own.Scale = scale;
		}
		else if (component.Shape == .Heightfield)
		{
			if (!FillHeightfield(ref own, component.Heightfield, heightBuffers))
			{
				GlobalLog(.Warning,
					"Physics: '{}' has a heightfield shape but no heightfield resource, so the body was skipped",
					scene.GetEntityName(entity));
				return false;
			}
		}

		// A shape that can only be static, the backend's MustBeStatic: a plane, a heightfield,
		// a cooked triangle mesh. Under a moving body the world makes it static rather than
		// tripping the backend's mass assert, by the backend's own rule; named HERE, where the
		// entity is known, so the author can find the component.
		let staticOnly = (component.Shape == .Plane) || (component.Shape == .Heightfield)
			|| ((component.Shape == .Cooked) && (component.CollisionShape.Get != null)
				&& !component.CollisionShape.Get.Convex);
		if ((component.Motion != .Static) && staticOnly)
		{
			GlobalLog(.Error,
				"Physics: '{}': a {} body cannot use a {} shape, which is static only, having no mass and no mesh against mesh collision; simulated as static",
				scene.GetEntityName(entity),
				(component.Motion == .Kinematic) ? "kinematic" : "dynamic",
				(component.Shape == .Plane) ? "plane"
					: (component.Shape == .Heightfield) ? "heightfield" : "triangle mesh");
		}

		outDesc.Shapes.Add(own);
		AddDescendantColliders(scene, outDesc, entity, heightBuffers);

		// A referenced SURFACE wins over the inline fields.
		if (let material = component.Material.Get)
		{
			outDesc.Friction = material.Friction;
			outDesc.Restitution = material.Restitution;
			outDesc.Density = material.Density;
		}
		return true;
	}

	/// The hierarchy's extra shapes fold into the body's compound at their offset relative to
	/// the body's entity, captured NOW.
	private static void AddDescendantColliders(Scene scene, BodyDesc desc, EntityHandle entity,
		List<List<float>> heightBuffers)
	{
		let colliders = scene.GetSystem<ColliderComponentManager>();
		if (colliders == null)
			return;

		let bodyInverse = Inverse(scene.GetWorldMatrix(entity));
		colliders.ForEach(scope [&] (extra, child) =>
			{
				if (!IsDescendantOf(scene, child, entity))
					return;

				if (!Decompose(scene.GetWorldMatrix(child) * bodyInverse,
					let localPosition, let localRotation, let localScale))
					return;

				var shape = ShapeDesc();
				shape.Kind = extra.Shape;
				shape.HalfExtents = extra.HalfExtents;
				shape.Radius = extra.Radius;
				shape.HalfHeight = extra.HalfHeight;
				shape.PlaneHalfExtent = extra.PlaneHalfExtent;

				if (extra.Shape == .Cooked)
				{
					let cooked = extra.CollisionShape.Get;
					if (cooked == null)
						return;
					shape.Cooked = cooked.Blob;
					shape.Scale = localScale;
				}
				else if (extra.Shape == .Heightfield)
				{
					if (!FillHeightfield(ref shape, extra.Heightfield, heightBuffers))
						return;
				}

				shape.LocalPosition = localPosition;
				shape.LocalRotation = localRotation;
				desc.Shapes.Add(shape);
			});
	}

	/// Converts a heightfield's stored samples into the world heights the backend wants, into
	/// a buffer that outlives the description.
	private static bool FillHeightfield(ref ShapeDesc shape, Ref<Heightfield> reference,
		List<List<float>> heightBuffers)
	{
		let heightfield = reference.Get;
		if ((heightfield == null) || heightfield.IsEmpty)
			return false;

		let buffer = new List<float>();
		heightBuffers.Add(buffer);

		let samples = heightfield.Samples;
		// A CUT sample has no surface: the no collision height takes every triangle that
		// touches it out of the body, which is the same rule the renderer's indices follow.
		let holes = heightfield.Holes;
		buffer.Resize(samples.Length);
		for (int i < samples.Length)
		{
			buffer[i] = ((i < holes.Length) && (holes[i] != 0))
				? ShapeDesc.NoCollisionHeight
				: heightfield.SampleToWorldY((float)samples[i]);
		}

		shape.HeightSamples = .(buffer.Ptr, buffer.Count);
		shape.HeightSampleCount = (uint32)heightfield.Size;
		shape.HeightWorldSize = heightfield.WorldSize;
		return true;
	}

	public static bool IsDescendantOf(Scene scene, EntityHandle child, EntityHandle ancestor)
	{
		var current = child;
		while (current.IsAssigned)
		{
			if (current == ancestor)
				return true;
			current = scene.GetParent(current);
		}
		return false;
	}
}
