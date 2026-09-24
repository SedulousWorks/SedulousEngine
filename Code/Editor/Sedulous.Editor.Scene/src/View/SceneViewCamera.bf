using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// Where a scene page's editor camera stood, as much of it as is worth storing.
///
/// The camera itself is a live object with input state; this is the orbit framing, which is
/// all a reopened page needs to come back where it was left.
struct SceneViewCamera
{
	public Float3 Position = .Zero;
	public float Yaw = 0.0f;
	public float Pitch = 0.0f;
	public float FocusDistance = 12.0f;

	public this() {}
	public this(Float3 position, float yaw, float pitch, float focusDistance)
	{
		Position = position;
		Yaw = yaw;
		Pitch = pitch;
		FocusDistance = focusDistance;
	}
}
