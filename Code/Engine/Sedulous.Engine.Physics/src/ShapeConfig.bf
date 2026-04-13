namespace Sedulous.Engine.Physics;

using Sedulous.Core.Mathematics;
using System;

/// Type of collision shape.
public enum ShapeType : uint8
{
	Box,
	Sphere,
	Capsule,
	Cylinder,
	Plane
}

/// Configuration for a collision shape.
/// Describes the shape geometry to be created in the physics world.
[CRepr]
public struct ShapeConfig
{
	/// Shape type.
	public ShapeType Type = .Box;

	/// Half-extents for Box shape.
	public Vector3 HalfExtents = .(0.5f, 0.5f, 0.5f);

	/// Radius for Sphere, Capsule, Cylinder shapes.
	public float Radius = 0.5f;

	/// Half-height for Capsule, Cylinder shapes (Y-axis aligned).
	public float HalfHeight = 0.5f;

	/// Factory: box shape with half-extents.
	public static Self Box(Vector3 halfExtents) => .() { Type = .Box, HalfExtents = halfExtents };

	/// Factory: box shape with uniform half-extent.
	public static Self Box(float halfExtent) => .() { Type = .Box, HalfExtents = .(halfExtent, halfExtent, halfExtent) };

	/// Factory: sphere shape.
	public static Self Sphere(float radius) => .() { Type = .Sphere, Radius = radius };

	/// Factory: capsule shape (Y-axis aligned).
	public static Self Capsule(float halfHeight, float radius) => .() { Type = .Capsule, HalfHeight = halfHeight, Radius = radius };

	/// Factory: cylinder shape (Y-axis aligned).
	public static Self Cylinder(float halfHeight, float radius) => .() { Type = .Cylinder, HalfHeight = halfHeight, Radius = radius };

	/// Factory: infinite ground plane.
	public static Self Plane() => .() { Type = .Plane };
}
