namespace Sedulous.Engine.Input;

using Sedulous.Core.Mathematics;

/// Unified value type for action states.
/// Supports bool (button), float (axis), and Vector2 (2D composite).
struct InputValue
{
	public float X;
	public float Y;

	/// Returns true if the value represents an active/pressed state.
	public bool AsBool => X > 0.5f;

	/// Returns the primary axis value.
	public float AsFloat => X;

	/// Returns the 2D vector value.
	public Vector2 AsVector2 => .(X, Y);

	/// Creates a bool value.
	public static InputValue FromBool(bool value) => .() { X = value ? 1.0f : 0.0f, Y = 0.0f };

	/// Creates a float value.
	public static InputValue FromFloat(float value) => .() { X = value, Y = 0.0f };

	/// Creates a Vector2 value.
	public static InputValue FromVector2(Vector2 value) => .() { X = value.X, Y = value.Y };

	/// Creates a Vector2 value from components.
	public static InputValue FromVector2(float x, float y) => .() { X = x, Y = y };

	/// Zero value.
	public static InputValue Zero => .() { X = 0.0f, Y = 0.0f };
}
