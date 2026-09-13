using Sedulous.Core;

namespace Sedulous.Engine.Audio;

/// One listener's world pose for a frame.
struct ListenerPose
{
	public Float3 Position = .(0.0f, 0.0f, 0.0f);
	public Float3 Forward = .(0.0f, 0.0f, -1.0f);
	public Float3 Up = .(0.0f, 1.0f, 0.0f);
	public Float3 Velocity = .(0.0f, 0.0f, 0.0f);

	public this() {}
}
