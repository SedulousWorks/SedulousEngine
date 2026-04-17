namespace Sedulous.UI;

using System;

/// Physics-based kinetic scroll — exponential velocity decay.
/// Owned as a member by scrollable views, not a separate object.
public struct MomentumHelper
{
	public float VelocityX;
	public float VelocityY;
	public float Friction = 6.0f;       // higher = stops sooner
	public float StopThreshold = 0.5f;  // px/sec — below this, snap to 0

	/// Update velocities and return the displacement this frame.
	public (float dx, float dy) Update(float deltaTime) mut
	{
		if (Math.Abs(VelocityX) < StopThreshold && Math.Abs(VelocityY) < StopThreshold)
		{
			VelocityX = 0;
			VelocityY = 0;
			return (0, 0);
		}

		let decay = 1.0f - Math.Min(Friction * deltaTime, 1.0f);
		let dx = VelocityX * deltaTime;
		let dy = VelocityY * deltaTime;
		VelocityX *= decay;
		VelocityY *= decay;

		if (Math.Abs(VelocityX) < StopThreshold) VelocityX = 0;
		if (Math.Abs(VelocityY) < StopThreshold) VelocityY = 0;

		return (dx, dy);
	}

	/// True if any velocity remains.
	public bool IsActive => VelocityX != 0 || VelocityY != 0;
}
