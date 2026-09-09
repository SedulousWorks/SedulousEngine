using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Bounces particles off a small set of world planes, spheres and boxes.
///
/// Runs as a behaviour, so it corrects LAST frame's penetration rather than predicting this
/// one: a particle is pushed back to the surface, its inbound normal velocity is reflected by
/// Bounce and its tangential velocity damped by Friction. Optionally it also ages toward
/// death, which is how splashes and sparks die on contact.
///
/// The shape counts are fixed and small on purpose. This is an analytic stand in for a few
/// obvious obstacles, not a physics query.
///
/// Describes ITSELF rather than carrying [Serializable]: the generated body walks every field,
/// and a fixed array of shape structs is not something the value dispatcher can write. The
/// hand written body is count bound instead, which is the shape the record wants anyway.
class CollisionBehavior : ParticleBehavior, ISerializable
{
	public const int32 MaxPlanes = 4;
	public const int32 MaxSpheres = 4;
	public const int32 MaxBoxes = 4;

	public CollisionPlane[MaxPlanes] Planes = .(.(), .(), .(), .());
	public CollisionSphere[MaxSpheres] Spheres = .(.(), .(), .(), .());
	public CollisionBox[MaxBoxes] Boxes = .(.(), .(), .(), .());

	/// One by default: the ground at y = 0.
	public int32 PlaneCount = 1;
	public int32 SphereCount = 0;
	public int32 BoxCount = 0;

	/// The particle's own radius, which offsets every surface outward.
	public float Radius = 0.0f;
	/// Normal restitution: nought sticks, one bounces perfectly.
	public float Bounce = 0.5f;
	/// Tangential damping on contact, nought to one.
	public float Friction = 0.1f;
	/// The fraction of its REMAINING life a particle loses per hit, nought to one.
	public float LifetimeLoss = 0.0f;

	public override BehaviorSupport Support => .Both;

	public override void DeclareStreams(ParticleStreamContainer streams)
	{
		streams.EnsureStream(.Velocity, .Float3);
	}

	/// COUNT BOUND, and the counts are clamped on the way in so a malformed record cannot
	/// walk off the fixed arrays.
	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		SerializeValue(ar, "planeCount", ref PlaneCount);
		SerializeValue(ar, "sphereCount", ref SphereCount);
		SerializeValue(ar, "boxCount", ref BoxCount);
		PlaneCount = Clamp(PlaneCount, 0, MaxPlanes);
		SphereCount = Clamp(SphereCount, 0, MaxSpheres);
		BoxCount = Clamp(BoxCount, 0, MaxBoxes);

		for (int32 i = 0; i < PlaneCount; i++)
		{
			ar.Key("plane");
			Planes[i].Serialize(ar);
		}
		for (int32 i = 0; i < SphereCount; i++)
		{
			ar.Key("sphere");
			Spheres[i].Serialize(ar);
		}
		for (int32 i = 0; i < BoxCount; i++)
		{
			ar.Key("box");
			Boxes[i].Serialize(ar);
		}

		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "bounce", ref Bounce);
		SerializeValue(ar, "friction", ref Friction);
		SerializeValue(ar, "lifetimeLoss", ref LifetimeLoss);
		ar.EndObject();
	}

	public override void Update(ParticleStreamContainer streams, ref ParticleUpdateContext context)
	{
		let positions = streams.Positions;
		let velocities = streams.Velocities;
		if ((positions == null) || (velocities == null))
			return;

		let ages = streams.Ages;
		let lifetimes = streams.Lifetimes;
		let planes = Min(PlaneCount, MaxPlanes);
		let spheres = Min(SphereCount, MaxSpheres);
		let boxes = Min(BoxCount, MaxBoxes);

		for (int32 i = 0; i < streams.AliveCount; i++)
		{
			for (int32 p = 0; p < planes; p++)
			{
				let plane = Planes[p];
				let penetration = Dot(plane.Normal, positions[i]) - plane.Distance - Radius;
				if (penetration < 0.0f)
					Resolve(ref positions[i], ref velocities[i], plane.Normal, penetration,
						ages, lifetimes, i);
			}

			for (int32 s = 0; s < spheres; s++)
			{
				let sphere = Spheres[s];
				let delta = positions[i] - sphere.Center;
				let distance = Length(delta);
				let penetration = distance - sphere.Radius - Radius;
				// A particle at the exact centre has no contact normal to push along.
				if ((penetration < 0.0f) && (distance > 1.0e-4f))
					Resolve(ref positions[i], ref velocities[i], delta / distance, penetration,
						ages, lifetimes, i);
			}

			for (int32 b = 0; b < boxes; b++)
			{
				let shape = Boxes[b];
				let delta = positions[i] - shape.Center;
				let extents = Float3(shape.HalfExtents.X + Radius, shape.HalfExtents.Y + Radius,
					shape.HalfExtents.Z + Radius);
				let absolute = Float3(Abs(delta.X), Abs(delta.Y), Abs(delta.Z));
				if ((absolute.X >= extents.X) || (absolute.Y >= extents.Y)
					|| (absolute.Z >= extents.Z))
					continue;

				// Inside: leave along the axis it is LEAST deep on, which is the nearest
				// face and so the shortest way out.
				let px = extents.X - absolute.X;
				let py = extents.Y - absolute.Y;
				let pz = extents.Z - absolute.Z;
				Float3 normal;
				float depth;
				if ((px <= py) && (px <= pz))
				{
					normal = .((delta.X < 0.0f) ? -1.0f : 1.0f, 0.0f, 0.0f);
					depth = px;
				}
				else if (py <= pz)
				{
					normal = .(0.0f, (delta.Y < 0.0f) ? -1.0f : 1.0f, 0.0f);
					depth = py;
				}
				else
				{
					normal = .(0.0f, 0.0f, (delta.Z < 0.0f) ? -1.0f : 1.0f);
					depth = pz;
				}
				Resolve(ref positions[i], ref velocities[i], normal, -depth, ages, lifetimes, i);
			}
		}
	}

	/// Pushes a penetrating particle out along the contact normal and reflects the part of
	/// its velocity that was heading in.
	private void Resolve(ref Float3 position, ref Float3 velocity, Float3 normal,
		float penetration, CPUStream<float> ages, CPUStream<float> lifetimes, int32 index)
	{
		// Penetration is negative, so this ADDS along the normal.
		position -= normal * penetration;

		let normalSpeed = Dot(velocity, normal);
		// Already leaving. Reflecting here would pull it back in and make a particle that
		// sticks to the surface jitter.
		if (normalSpeed >= 0.0f)
			return;

		let normalVelocity = normal * normalSpeed;
		let tangentVelocity = velocity - normalVelocity;
		velocity = tangentVelocity * (1.0f - Friction) - normalVelocity * Bounce;

		if ((LifetimeLoss > 0.0f) && (ages != null) && (lifetimes != null))
			ages[index] += (lifetimes[index] - ages[index]) * LifetimeLoss;
	}
}
