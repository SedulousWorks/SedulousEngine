namespace Sedulous.GUI;

using System;

/// Physics-based kinetic scrolling helper. Struct - embed in ScrollView.
/// Call Update() each frame; apply the returned displacement to scroll offset.
public struct MomentumHelper
{
	/// Current velocity in pixels/second.
	public float VelocityX;
	public float VelocityY;

	/// Friction coefficient (higher = faster deceleration).
	public float Friction = 6.0f;

	/// Velocity below this is snapped to zero.
	public float StopThreshold = 0.5f;

	/// Whether momentum is active.
	public bool IsActive => Math.Abs(VelocityX) > StopThreshold || Math.Abs(VelocityY) > StopThreshold;

	/// Advance physics by deltaTime. Returns displacement to apply to scroll offset.
	public (float dx, float dy) Update(float deltaTime) mut
	{
		if (!IsActive)
			return (0, 0);

		let decay = 1.0f - Math.Min(Friction * deltaTime, 1.0f);
		let dx = VelocityX * deltaTime;
		let dy = VelocityY * deltaTime;

		VelocityX *= decay;
		VelocityY *= decay;

		if (Math.Abs(VelocityX) < StopThreshold) VelocityX = 0;
		if (Math.Abs(VelocityY) < StopThreshold) VelocityY = 0;

		return (dx, dy);
	}

	/// Stop all momentum immediately.
	public void Stop() mut
	{
		VelocityX = 0;
		VelocityY = 0;
	}
}
