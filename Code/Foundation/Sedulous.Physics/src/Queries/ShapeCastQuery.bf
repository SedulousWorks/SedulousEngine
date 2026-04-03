namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Input for a shape cast query.
struct ShapeCastQuery
{
	/// Shape to cast.
	public ShapeHandle Shape;

	/// Starting position in world space.
	public Vector3 Position;

	/// Starting rotation.
	public Quaternion Rotation;

	/// Cast direction and distance (direction * distance).
	public Vector3 Direction;

	/// Maximum distance to cast.
	public float MaxDistance = 1000.0f;

	/// Collision layer mask. Only bodies in matching layers are tested.
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Creates a shape cast query.
	public this(ShapeHandle shape, Vector3 position, Quaternion rotation, Vector3 direction, float maxDistance = 1000.0f)
	{
		Shape = shape;
		Position = position;
		Rotation = rotation;
		Direction = direction;
		MaxDistance = maxDistance;
		LayerMask = 0xFFFFFFFF;
	}

	/// Creates a shape cast query with identity rotation.
	public this(ShapeHandle shape, Vector3 position, Vector3 direction, float maxDistance = 1000.0f)
	{
		Shape = shape;
		Position = position;
		Rotation = .Identity;
		Direction = direction;
		MaxDistance = maxDistance;
		LayerMask = 0xFFFFFFFF;
	}
}
