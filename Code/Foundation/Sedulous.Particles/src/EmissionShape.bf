using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// The volume a system spawns into: a tagged shape that answers a position and an outward
/// direction for one particle.
struct EmissionShape
{
	public EmissionShapeType Type = .Point;

	/// Sphere, hemisphere, cone, ring and circle. For an edge, its half length.
	public float Radius = 1.0f;
	/// A box's half extents.
	public Float3 Extents = .(1, 1, 1);
	/// A cone's half angle, in radians.
	public float Angle = 0.7853982f;
	/// How much of the full turn is used, nought to one, which is what makes an arc rather
	/// than a full ring.
	public float Arc = 1.0f;
	/// Whether a sphere, ring or circle spawns on its SURFACE rather than throughout.
	public bool EmitFromShell = false;

	public this() {}

	/// One spawn: a position before the emitter's own offset, and a normalised direction.
	public void Sample(ref Random rng, out Float3 outPosition, out Float3 outDirection)
	{
		let tau = 6.2831853f * Clamp(Arc, 0.0f, 1.0f);

		switch (Type)
		{
		case .Sphere, .Hemisphere:
			// A uniform point on the sphere comes from a uniform HEIGHT and a uniform angle,
			// not from two uniform angles, which would crowd the poles.
			let cosMin = (Type == .Hemisphere) ? 0.0f : -1.0f;
			let z = rng.NextFloat(cosMin, 1.0f);
			let phi = rng.NextFloat(0.0f, tau);
			let r = Sqrt(1.0f - z * z);
			let direction = Float3(r * Cos(phi), r * Sin(phi), z);
			// The cube root is what spreads a volume evenly: a uniform radius would crowd
			// the centre, since the outer shells hold more space.
			outPosition = direction * (EmitFromShell ? Radius
				: (Radius * Pow(rng.NextFloat(), 1.0f / 3.0f)));
			outDirection = direction;

		case .Box:
			outPosition = .(rng.NextFloat(-Extents.X, Extents.X),
				rng.NextFloat(-Extents.Y, Extents.Y),
				rng.NextFloat(-Extents.Z, Extents.Z));
			outDirection = OutwardOrUp(outPosition);

		case .Cone:
			let phi = rng.NextFloat(0.0f, tau);
			// The square root spreads a disc evenly, for the same reason the cube root does
			// a sphere.
			let rr = Radius * Sqrt(rng.NextFloat());
			outPosition = .(rr * Cos(phi), 0.0f, rr * Sin(phi));
			let spread = Sin(Angle);
			outDirection = Normalized(Float3(spread * Cos(phi), Cos(Angle), spread * Sin(phi)));

		case .Ring:
			let phi = rng.NextFloat(0.0f, tau);
			outPosition = .(Radius * Cos(phi), 0.0f, Radius * Sin(phi));
			outDirection = OutwardOrUp(outPosition);

		case .Circle:
			let phi = rng.NextFloat(0.0f, tau);
			let rr = EmitFromShell ? Radius : (Radius * Sqrt(rng.NextFloat()));
			outPosition = .(rr * Cos(phi), 0.0f, rr * Sin(phi));
			outDirection = OutwardOrUp(outPosition);

		case .Edge:
			outPosition = .(rng.NextFloat(-Radius, Radius), 0.0f, 0.0f);
			outDirection = Float3.UnitY;

		default:
			outPosition = Float3.Zero;
			outDirection = Float3.UnitY;
		}
	}

	/// Away from the origin, or straight up when the spawn landed ON it and there is no
	/// outward to speak of.
	private static Float3 OutwardOrUp(Float3 position) =>
		(LengthSquared(position) > 1.0e-6f) ? Normalized(position) : Float3.UnitY;

	public static EmissionShape Point() => .();

	public static EmissionShape Sphere(float radius, bool shell = false)
	{
		var shape = EmissionShape();
		shape.Type = .Sphere;
		shape.Radius = radius;
		shape.EmitFromShell = shell;
		return shape;
	}

	public static EmissionShape Box(Float3 extents)
	{
		var shape = EmissionShape();
		shape.Type = .Box;
		shape.Extents = extents;
		return shape;
	}

	public static EmissionShape Cone(float radius, float angle)
	{
		var shape = EmissionShape();
		shape.Type = .Cone;
		shape.Radius = radius;
		shape.Angle = angle;
		return shape;
	}

	public static EmissionShape Circle(float radius, bool shell = false)
	{
		var shape = EmissionShape();
		shape.Type = .Circle;
		shape.Radius = radius;
		shape.EmitFromShell = shell;
		return shape;
	}

	public static EmissionShape Ring(float radius)
	{
		var shape = EmissionShape();
		shape.Type = .Ring;
		shape.Radius = radius;
		return shape;
	}

	public static EmissionShape Edge(float halfLength)
	{
		var shape = EmissionShape();
		shape.Type = .Edge;
		shape.Radius = halfLength;
		return shape;
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("type");
		SerializeEnum(ar, ref Type);
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "extents", ref Extents);
		SerializeValue(ar, "angle", ref Angle);
		SerializeValue(ar, "arc", ref Arc);
		SerializeValue(ar, "emitFromShell", ref EmitFromShell);
	}
}
