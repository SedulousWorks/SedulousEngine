namespace Sedulous.Physics;

using System;
using Sedulous.Core.Mathematics;

/// Descriptor for creating a physics character controller.
struct CharacterDescriptor
{
	/// The shape to use for the character (typically a capsule).
	public ShapeHandle Shape = .Invalid;

	/// Initial position.
	public Vector3 Position = .Zero;

	/// Initial rotation.
	public Quaternion Rotation = .Identity;

	/// The up direction for the character.
	public Vector3 Up = .(0, 1, 0);

	/// Collision layer.
	public uint16 Layer = 1;

	/// Maximum slope angle the character can walk on (in radians).
	public float MaxSlopeAngle = Math.PI_f / 4.0f; // 45 degrees

	/// Mass of the character (affects push force on other bodies).
	public float Mass = 80.0f;

	/// Maximum strength with which the character can push other bodies.
	public float MaxStrength = 100.0f;

	/// Padding around the character shape for predictive contacts.
	public float CharacterPadding = 0.02f;

	/// How far to scan for the ground.
	public float PredictiveContactDistance = 0.1f;

	/// Friction of the character against the ground.
	public float Friction = 0.5f;

	/// How far the character can step up onto ledges.
	public float MaxStepHeight = 0.5f;

	/// User data associated with this character.
	public uint64 UserData = 0;

	/// Creates a character descriptor.
	public this() { }

	/// Creates a character descriptor with a capsule shape.
	public this(Vector3 position, float height, float radius)
	{
		Position = position;
		// Note: Shape needs to be created separately and assigned
	}
}
