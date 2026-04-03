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
}
