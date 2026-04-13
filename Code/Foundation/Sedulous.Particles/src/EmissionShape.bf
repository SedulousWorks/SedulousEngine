namespace Sedulous.Particles;

using System;
using Sedulous.Core.Mathematics;

/// Type of emission shape.
public enum EmissionShapeType : uint8
{
	/// Point emitter (all particles spawn at origin).
	Point,

	/// Sphere volume or surface.
	Sphere,

	/// Upper hemisphere volume or surface.
	Hemisphere,

	/// Cone (direction + angle).
	Cone,

	/// Box volume or surface.
	Box,

	/// Circle (flat disc on XZ plane).
	Circle,

	/// Edge (line segment along X-axis).
	Edge
}

/// Defines the shape from which particles are emitted.
[CRepr]
public struct EmissionShape
{
	/// Shape type.
	public EmissionShapeType Type;

	/// Size parameter: radius for Sphere/Hemisphere/Cone/Circle, half-extents for Box.
	public Vector3 Size;

	/// Cone angle in radians.
	public float ConeAngle;

	/// Arc angle in radians (0 or 2*PI = full shape, e.g. PI = half circle).
	/// Applies to Sphere, Circle, and Cone shapes.
	public float Arc;

	/// Whether to emit from surface only (vs volume).
	public bool EmitFromSurface;

	/// Gets the effective arc angle (0 means full 2*PI).
	private float EffectiveArc => (Arc <= 0 || Arc >= Math.PI_f * 2.0f) ? Math.PI_f * 2.0f : Arc;

	/// Samples a position and direction from this shape.
	public void Sample(Random rng, out Vector3 position, out Vector3 direction)
	{
		switch (Type)
		{
		case .Point:
			position = .Zero;
			direction = .(0, 1, 0);

		case .Sphere:
			let arc = EffectiveArc;
			let dir = RandomOnUnitSphereArc(rng, arc);
			if (EmitFromSurface)
				position = dir * Size.X;
			else
				position = dir * Size.X * (float)Math.Pow(rng.NextDouble(), 1.0 / 3.0);
			direction = Vector3.Normalize(dir);

		case .Hemisphere:
			var dir = RandomOnUnitSphereArc(rng, EffectiveArc);
			if (dir.Y < 0) dir.Y = -dir.Y;
			if (EmitFromSurface)
				position = dir * Size.X;
			else
				position = dir * Size.X * (float)Math.Pow(rng.NextDouble(), 1.0 / 3.0);
			direction = Vector3.Normalize(dir);

		case .Cone:
			let cosAngle = Math.Cos(ConeAngle);
			let z = cosAngle + (1.0f - cosAngle) * (float)rng.NextDouble();
			let phi = (float)(rng.NextDouble()) * EffectiveArc;
			let sinTheta = Math.Sqrt(1.0f - z * z);
			direction = Vector3(sinTheta * Math.Cos(phi), z, sinTheta * Math.Sin(phi));
			if (EmitFromSurface)
				position = direction * Size.X;
			else
				position = direction * Size.X * (float)rng.NextDouble();

		case .Box:
			if (EmitFromSurface)
			{
				let face = rng.Next(6);
				var pos = Vector3(
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.X,
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.Y,
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.Z
				);
				switch (face)
				{
				case 0: pos.X = Size.X; direction = .(1, 0, 0);
				case 1: pos.X = -Size.X; direction = .(-1, 0, 0);
				case 2: pos.Y = Size.Y; direction = .(0, 1, 0);
				case 3: pos.Y = -Size.Y; direction = .(0, -1, 0);
				case 4: pos.Z = Size.Z; direction = .(0, 0, 1);
				default: pos.Z = -Size.Z; direction = .(0, 0, -1);
				}
				position = pos;
			}
			else
			{
				position = Vector3(
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.X,
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.Y,
					(float)(rng.NextDouble() * 2.0 - 1.0) * Size.Z
				);
				direction = .(0, 1, 0);
			}

		case .Circle:
			let angle = (float)(rng.NextDouble()) * EffectiveArc;
			float r;
			if (EmitFromSurface)
				r = Size.X;
			else
				r = Size.X * Math.Sqrt((float)rng.NextDouble());
			position = Vector3(Math.Cos(angle) * r, 0, Math.Sin(angle) * r);
			direction = .(0, 1, 0);

		case .Edge:
			// Line segment along X-axis, length = Size.X * 2
			let t = (float)(rng.NextDouble() * 2.0 - 1.0);
			position = Vector3(t * Size.X, 0, 0);
			direction = .(0, 1, 0);
		}
	}

	/// Generates a random unit vector on the sphere with arc restriction on azimuth.
	private static Vector3 RandomOnUnitSphereArc(Random rng, float arc)
	{
		let theta = (float)(rng.NextDouble()) * arc;
		let phi = Math.Acos(2.0f * (float)rng.NextDouble() - 1.0f);
		let sinPhi = Math.Sin(phi);
		return Vector3(
			sinPhi * Math.Cos(theta),
			Math.Cos(phi),
			sinPhi * Math.Sin(theta)
		);
	}

	// Factory methods

	public static Self Point()
	{
		var shape = Self();
		shape.Type = .Point;
		shape.Size = .Zero;
		return shape;
	}

	public static Self Sphere(float radius, bool surface = false)
	{
		var shape = Self();
		shape.Type = .Sphere;
		shape.Size = .(radius, radius, radius);
		shape.EmitFromSurface = surface;
		return shape;
	}

	public static Self Hemisphere(float radius, bool surface = false)
	{
		var shape = Self();
		shape.Type = .Hemisphere;
		shape.Size = .(radius, radius, radius);
		shape.EmitFromSurface = surface;
		return shape;
	}

	public static Self Cone(float angleRadians, float radius = 0)
	{
		var shape = Self();
		shape.Type = .Cone;
		shape.Size = .(radius, 0, 0);
		shape.ConeAngle = angleRadians;
		return shape;
	}

	public static Self Box(Vector3 halfExtents, bool surface = false)
	{
		var shape = Self();
		shape.Type = .Box;
		shape.Size = halfExtents;
		shape.EmitFromSurface = surface;
		return shape;
	}

	public static Self Circle(float radius, bool surface = false, float arc = 0)
	{
		var shape = Self();
		shape.Type = .Circle;
		shape.Size = .(radius, 0, 0);
		shape.EmitFromSurface = surface;
		shape.Arc = arc;
		return shape;
	}

	public static Self Edge(float halfLength)
	{
		var shape = Self();
		shape.Type = .Edge;
		shape.Size = .(halfLength, 0, 0);
		return shape;
	}

	/// Creates a sphere with arc restriction (partial sphere emission).
	public static Self SphereArc(float radius, float arcRadians, bool surface = false)
	{
		var shape = Self();
		shape.Type = .Sphere;
		shape.Size = .(radius, radius, radius);
		shape.EmitFromSurface = surface;
		shape.Arc = arcRadians;
		return shape;
	}

	/// Creates a cone with arc restriction.
	public static Self ConeArc(float angleRadians, float arcRadians, float radius = 0)
	{
		var shape = Self();
		shape.Type = .Cone;
		shape.Size = .(radius, 0, 0);
		shape.ConeAngle = angleRadians;
		shape.Arc = arcRadians;
		return shape;
	}
}
