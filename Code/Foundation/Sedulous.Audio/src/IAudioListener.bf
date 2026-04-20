using Sedulous.Core.Mathematics;

namespace Sedulous.Audio;

/// 3D audio listener that determines how sounds are heard.
/// Typically attached to the camera or player position.
/// Pure math - no backend-specific state.
class AudioListener
{
	private Vector3 mPosition = .Zero;
	private Vector3 mForward = .(0, 0, -1);  // Looking down negative Z
	private Vector3 mUp = .(0, 1, 0);

	/// Gets or sets the world position of the listener.
	public Vector3 Position
	{
		get => mPosition;
		set => mPosition = value;
	}

	/// Gets or sets the forward direction the listener is facing.
	public Vector3 Forward
	{
		get => mForward;
		set => mForward = Vector3.Normalize(value);
	}

	/// Gets or sets the up direction of the listener.
	public Vector3 Up
	{
		get => mUp;
		set => mUp = Vector3.Normalize(value);
	}

	/// Transforms a world position to listener-local coordinates.
	/// Returns position relative to listener with:
	/// - Positive X = right
	/// - Positive Y = up
	/// - Positive Z = backward (away from listener's forward)
	public Vector3 WorldToLocal(Vector3 worldPos)
	{
		let relativePos = worldPos - mPosition;
		let right = Vector3.Normalize(Vector3.Cross(mForward, mUp));
		return .(
			Vector3.Dot(relativePos, right),
			Vector3.Dot(relativePos, mUp),
			-Vector3.Dot(relativePos, mForward)
		);
	}
}
