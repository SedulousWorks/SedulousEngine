// CameraRig - the camera above and behind the thief, turned a quarter at a time (TurnLeft and
// TurnRight), swinging round to the new quarter rather than cutting to it, and following the thief
// with a little lag so a step does not jolt the view.
//
// Its globals carry the rig's name: every behaviour compiles into one module here, and Thief.as
// has a kPi and a Saturate of its own.
const float kRigPi = 3.14159265f;

float RigSaturate(float x)
{
	return x < 0.0f ? 0.0f : (x > 1.0f ? 1.0f : x);
}

class CameraRig
{
	Entity self;

	[null, "The thief to follow"] Entity target;
	[6.5, "Distance back from the thief, along the floor (m)"] float distance;
	[7.0, "Height above the thief (m)"] float height;
	[0.8, "Aim this far above the thief's feet (m)"] float lookHeight;
	[6.0, "How quickly it catches up with the thief"] float follow;
	[7.0, "How quickly it swings to a new quarter"] float swing;

	private int m_quarter = 0;    // 0 = looking north (-Z), then quarters clockwise
	private float m_yaw = 0.0f;   // the swing's current angle (radians)
	private Float3 m_focus = Float3(0.0f, 0.0f, 0.0f);

	void onStart()
	{
		if (target.IsValid())
			m_focus = target.GetWorldPosition();
		place();
	}

	void onUpdate(float dt)
	{
		if (Input.WasPressed("TurnLeft"))
			m_quarter = (m_quarter + 3) % 4;
		if (Input.WasPressed("TurnRight"))
			m_quarter = (m_quarter + 1) % 4;
		float want = float(m_quarter) * kRigPi * 0.5f;
		float delta = want - m_yaw;
		while (delta > kRigPi) delta -= 2.0f * kRigPi;
		while (delta < -kRigPi) delta += 2.0f * kRigPi;
		m_yaw += delta * RigSaturate(swing * dt);
		if (target.IsValid())
		{
			Float3 at = target.GetWorldPosition();
			float k = RigSaturate(follow * dt);
			m_focus = Float3(m_focus.X + (at.X - m_focus.X) * k, m_focus.Y + (at.Y - m_focus.Y) * k,
			                 m_focus.Z + (at.Z - m_focus.Z) * k);
		}
		place();
	}

	// Behind the focus for the current angle: yaw 0 sits south of it (+Z) looking north.
	// Engine forward is -Z: yaw = atan2(-dir.x, -dir.z); a positive pitch looks up.
	private void place()
	{
		Float3 seat = Float3(m_focus.X - Sin(m_yaw) * distance, m_focus.Y + height,
		                     m_focus.Z + Cos(m_yaw) * distance);
		self.SetLocalPosition(seat);
		Float3 dir = Float3(m_focus.X - seat.X, m_focus.Y + lookHeight - seat.Y, m_focus.Z - seat.Z);
		float len = Length(dir);
		if (len < 0.0001f)
			return;
		self.SetLocalRotation(FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}
}
