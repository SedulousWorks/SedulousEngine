namespace Sedulous.Scenes;

using Sedulous.Core.Mathematics;

/// Local transform: position, rotation, scale.
public struct Transform
{
	public Vector3 Position;
	public Quaternion Rotation;
	public Vector3 Scale;

	public static readonly Transform Identity = .()
	{
		Position = .Zero,
		Rotation = .Identity,
		Scale = .One
	};

	/// Computes the local-to-parent matrix.
	public Matrix ToMatrix()
	{
		return Matrix.CreateScale(Scale) *
			Matrix.CreateFromQuaternion(Rotation) *
			Matrix.CreateTranslation(Position);
	}

	/// Creates a transform at the given position looking at a target point.
	/// Uses -Z as forward (XNA/MonoGame right-handed convention).
	public static Transform CreateLookAt(Vector3 position, Vector3 target, Vector3 up = .Up)
	{
		// Build a look-at matrix, extract rotation as quaternion
		let lookMatrix = Matrix.CreateLookAt(position, target, up);
		// CreateLookAt returns a view matrix (world->view). We need the inverse
		// rotation to get the world-space orientation of the camera.
		Matrix invLook = .Identity;
		Matrix.Invert(lookMatrix, out invLook);
		let rotation = Quaternion.CreateFromRotationMatrix(invLook);

		return .()
		{
			Position = position,
			Rotation = rotation,
			Scale = .One
		};
	}
}
