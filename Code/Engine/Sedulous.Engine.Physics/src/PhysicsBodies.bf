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

/// What a described body points into: heightfield samples and the cooked rim of a holed
/// heightfield. It must outlive the description, until the body is made.
class BodyBuffers
{
	public List<List<float>> Heights = new .() ~ DeleteContainerAndItems!(_);
	public List<List<uint8>> Blobs = new .() ~ DeleteContainerAndItems!(_);

	public void Clear()
	{
		ClearAndDeleteItems!(Heights);
		ClearAndDeleteItems!(Blobs);
	}
}

/// The body a RigidBodyComponent makes, described once: body creation and the static geometry
/// the navigation bake reads both describe bodies here, so the bake sees exactly what the
/// bodies collide with.
static class PhysicsBodies
{
	/// The body `component` makes on `entity`: its settings, the entity's world pose, its own
	/// shape and the ColliderComponents under it (a compound at their offsets). Heightfield
	/// samples and a holed heightfield's rim are kept in `buffers` (OWNED by the caller), which
	/// the description points into and which must outlive it. False, logged, when the
	/// transform does not decompose or a shape's resource is missing.
	public static bool Describe(Scene scene, RigidBodyComponent* component, EntityHandle entity,
		BodyDesc outDesc, BodyBuffers buffers)
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
		else if (component.Shape != .Heightfield)
		{
			ScalePrimitive(ref own, scale);
		}
		else
		{
			if (!FillHeightfield(ref own, component.Heightfield, buffers))
			{
				GlobalLog(.Warning,
					"Physics: '{}' has a heightfield shape but no heightfield resource, so the body was skipped",
					scene.GetEntityName(entity));
				return false;
			}
			own.Scale = scale; // the terrain stretched as its entity is
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

		// A holed heightfield's drawn rim goes beside it, after the body's other shapes.
		let rims = scope List<ShapeDesc>();
		if (component.Shape == .Heightfield)
			AddRim(rims, own, component.Heightfield.Get, buffers);
		outDesc.Shapes.Add(own);
		AddDescendantColliders(scene, outDesc, entity, buffers, rims);
		outDesc.Shapes.AddRange(rims);

		// A referenced SURFACE wins over the inline fields.
		if (let material = component.Material.Get)
		{
			outDesc.Friction = material.Friction;
			outDesc.Restitution = material.Restitution;
			outDesc.Density = material.Density;
		}
		return true;
	}

	/// A primitive's size in the entity's scale, as the mesh it stands for is drawn: a box takes
	/// each axis; a sphere, whose shape cannot stretch, the largest; a capsule its height from y
	/// and its radius from x and z; a plane its extent from x and z. Cooked shapes take the scale
	/// whole, and a heightfield has its own world size.
	public static void ScalePrimitive(ref ShapeDesc shape, Float3 scale)
	{
		let s = Float3(Math.Abs(scale.X), Math.Abs(scale.Y), Math.Abs(scale.Z));
		switch (shape.Kind)
		{
		case .Box:
			shape.HalfExtents = .(shape.HalfExtents.X * s.X, shape.HalfExtents.Y * s.Y,
				shape.HalfExtents.Z * s.Z);
		case .Sphere:
			shape.Radius *= Math.Max(s.X, Math.Max(s.Y, s.Z));
		case .Capsule:
			shape.Radius *= Math.Max(s.X, s.Z);
			shape.HalfHeight *= s.Y;
		case .Plane:
			shape.PlaneHalfExtent *= Math.Max(s.X, s.Z);
		default:
		}
	}

	/// The hierarchy's extra shapes fold into the body's compound at their offset relative to
	/// the body's entity, captured NOW.
	///
	/// The physics body has no scale, only its position and rotation, so a child's place is
	/// measured in world units from the body and a cooked child keeps its WORLD scale: measured
	/// against a scaled body (a prefab scaled down) both would come out unscaled, the shape full
	/// size and off its place.
	private static void AddDescendantColliders(Scene scene, BodyDesc desc, EntityHandle entity,
		BodyBuffers buffers, List<ShapeDesc> rims)
	{
		let colliders = scene.GetSystem<ColliderComponentManager>();
		if (colliders == null)
			return;
		if (!Decompose(scene.GetWorldMatrix(entity), let bodyPosition, let bodyRotation, ?))
			return;

		let bodyInverse = Inverse(bodyRotation);
		colliders.ForEach(scope [&] (extra, child) =>
			{
				if (!IsDescendantOf(scene, child, entity))
					return;

				if (!Decompose(scene.GetWorldMatrix(child), let worldPosition, let worldRotation, let worldScale))
					return;
				let localPosition = RotateVector(bodyInverse, worldPosition - bodyPosition);
				let localRotation = bodyInverse * worldRotation;

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
					shape.Scale = worldScale;
				}
				else if (extra.Shape != .Heightfield)
				{
					ScalePrimitive(ref shape, worldScale);
				}
				else
				{
					if (!FillHeightfield(ref shape, extra.Heightfield, buffers))
						return;
					shape.Scale = worldScale;
				}

				shape.LocalPosition = localPosition;
				shape.LocalRotation = localRotation;
				desc.Shapes.Add(shape);
				if (extra.Shape == .Heightfield)
					AddRim(rims, shape, extra.Heightfield.Get, buffers);
			});
	}

	/// Converts a heightfield's stored samples into the world heights the backend wants, into
	/// a buffer that outlives the description.
	private static bool FillHeightfield(ref ShapeDesc shape, Ref<Heightfield> reference,
		BodyBuffers buffers)
	{
		let heightfield = reference.Get;
		if ((heightfield == null) || heightfield.IsEmpty)
			return false;

		let buffer = new List<float>();
		buffers.Heights.Add(buffer);

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

	/// A holed heightfield's drawn rim as a cooked mesh at the field's place and scale, added to
	/// `rims`; nothing for a heightfield with no partly cut cell.
	private static void AddRim(List<ShapeDesc> rims, ShapeDesc field, Heightfield heightfield,
		BodyBuffers buffers)
	{
		if (heightfield == null)
			return;
		let positions = scope List<Float3>();
		let indices = scope List<uint32>();
		if (!TraceHoleRim(heightfield, positions, indices))
			return;
		let blob = new List<uint8>();
		buffers.Blobs.Add(blob);
		if (!ShapeCooking.CookTriangleMesh(positions, indices, .(), blob))
			return;
		var rim = ShapeDesc();
		rim.Kind = .Cooked;
		rim.Cooked = blob;
		rim.Scale = field.Scale;
		rim.LocalPosition = field.LocalPosition;
		rim.LocalRotation = field.LocalRotation;
		rims.Add(rim);
	}

	/// The drawn ground a holed heightfield's collision lacks. Physics cuts a whole triangle at a
	/// cut sample, while the terrain draws a cell until all four of its samples are cut, shaping
	/// the rim where the bilinear hole mask (cut samples 1) crosses one half. So each cell with
	/// some but not all samples cut is traced by marching squares at that half: the ground
	/// corners, the middles of the edges that cross the rim, and, where two diagonal corners are
	/// cut (a saddle), the cell's centre, where the two pieces meet. Heights are the samples' (a
	/// cut one still has its height), bilinear between them. In the heightfield shape's own frame
	/// (centred). False when the heightfield has no partly cut cell.
	public static bool TraceHoleRim(Heightfield heightfield, List<Float3> positions, List<uint32> indices)
	{
		positions.Clear();
		indices.Clear();
		let holes = heightfield.Holes;
		let n = heightfield.Size;
		if (holes.IsEmpty || (n < 2))
			return false;
		let samples = heightfield.Samples;
		let size = heightfield.WorldSize;
		let sx = size.X / (float)(n - 1);
		let sz = size.Y / (float)(n - 1);

		bool Cut(int32 x, int32 z) => holes[(int)z * n + x] != 0;
		float Height(int32 x, int32 z) => heightfield.SampleToWorldY((float)samples[(int)z * n + x]);
		// A point of the cell (x, z) at fractions (u, v) along x and z.
		Float3 At(int32 x, int32 z, float u, float v)
		{
			let h = Height(x, z) * (1 - u) * (1 - v) + Height(x + 1, z) * u * (1 - v)
				+ Height(x + 1, z + 1) * u * v + Height(x, z + 1) * (1 - u) * v;
			return .(-size.X * 0.5f + ((float)x + u) * sx, h, -size.Y * 0.5f + ((float)z + v) * sz);
		}
		// A polygon as a fan, wound so its face looks up (+y), as the heightfield's does.
		void Fan(Span<Float3> poly)
		{
			let start = (uint32)positions.Count;
			for (let p in poly)
				positions.Add(p);
			for (uint32 i = 1; i + 1 < (uint32)poly.Length; i++)
			{
				indices.Add(start);
				indices.Add(start + i + 1);
				indices.Add(start + i);
			}
		}

		// The cell's corners in order around it, as fractions.
		float[4] cornerU = .(0, 1, 1, 0);
		float[4] cornerV = .(0, 0, 1, 1);
		for (int32 z = 0; z + 1 < n; z++)
		{
			for (int32 x = 0; x + 1 < n; x++)
			{
				bool[4] corner = .(Cut(x, z), Cut(x + 1, z), Cut(x + 1, z + 1), Cut(x, z + 1));
				int cuts = 0;
				for (let c in corner)
					if (c)
						cuts++;
				if ((cuts == 0) || (cuts == 4))
					continue; // whole ground (the heightfield has it) or wholly cut
				if ((cuts == 2) && (corner[0] == corner[2]))
				{
					// A saddle: each ground corner keeps the quarter of the cell at it.
					for (int k < 4)
					{
						if (corner[k])
							continue;
						let prev = (k + 3) % 4;
						let next = (k + 1) % 4;
						Float3[4] quarter = .(
							At(x, z, cornerU[k], cornerV[k]),
							At(x, z, (cornerU[k] + cornerU[next]) * 0.5f, (cornerV[k] + cornerV[next]) * 0.5f),
							At(x, z, 0.5f, 0.5f),
							At(x, z, (cornerU[k] + cornerU[prev]) * 0.5f, (cornerV[k] + cornerV[prev]) * 0.5f));
						Fan(quarter);
					}
					continue;
				}
				Float3[8] poly = default;
				int count = 0;
				for (int k < 4)
				{
					let next = (k + 1) % 4;
					if (!corner[k])
						poly[count++] = At(x, z, cornerU[k], cornerV[k]);
					if (corner[k] != corner[next])
						poly[count++] = At(x, z, (cornerU[k] + cornerU[next]) * 0.5f, (cornerV[k] + cornerV[next]) * 0.5f);
				}
				Fan(.(&poly[0], count));
			}
		}
		return !indices.IsEmpty;
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
