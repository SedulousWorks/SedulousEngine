using Sedulous.Core.Mathematics;

namespace Sedulous.Audio;

/// Interface for the 3D audio listener that determines how sounds are heard.
/// Typically attached to the camera or player position.
interface IAudioListener
{
	/// Gets or sets the world position of the listener.
	Vector3 Position { get; set; }

	/// Gets or sets the forward direction the listener is facing.
	Vector3 Forward { get; set; }

	/// Gets or sets the up direction of the listener.
	Vector3 Up { get; set; }
}
