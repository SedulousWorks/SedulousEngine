using Sedulous.Core;

namespace Sedulous.UI;

/// Kinetic scrolling. Call Update each frame and add the displacement it answers to the
/// scroll offset.
struct MomentumHelper
{
	/// In pixels per second.
	public float VelocityX = 0.0f;
	public float VelocityY = 0.0f;

	/// Higher decelerates faster.
	public float Friction = 6.0f;

	/// Velocity below this is snapped to nought, so a flick settles rather than creeping
	/// forever at an imperceptible speed.
	public float StopThreshold = 0.5f;

	public this() {}

	public bool IsActive => (Abs(VelocityX) > StopThreshold) || (Abs(VelocityY) > StopThreshold);

	/// Advances by deltaTime, answering the displacement to apply.
	public Float2 Update(float deltaTime) mut
	{
		if (!IsActive)
			return .(0.0f, 0.0f);

		// Clamped so a long frame cannot overshoot into a negative decay and fling the
		// content backwards.
		let decay = 1.0f - Min(Friction * deltaTime, 1.0f);
		let dx = VelocityX * deltaTime;
		let dy = VelocityY * deltaTime;

		VelocityX *= decay;
		VelocityY *= decay;

		if (Abs(VelocityX) < StopThreshold)
			VelocityX = 0.0f;
		if (Abs(VelocityY) < StopThreshold)
			VelocityY = 0.0f;

		return .(dx, dy);
	}

	public void Stop() mut
	{
		VelocityX = 0.0f;
		VelocityY = 0.0f;
	}
}
