// Kicker - launches the rider off the lip. On the kicker's entity, whose origin is where its ramp
// comes out of the snow and whose +Z runs up the ramp (Tools/course.py, blender/props.py).
//
// The ramp is solid to the rider, but a character's contacts over a curve at speed are uneven: one
// run left the lip at 16 m/s, the next hopped on the curve, lost half its speed and barely left the
// snow. So the kicker sets the launch itself: it notes the rider's speed as it reaches the foot,
// and when the rider crosses the lip within the kicker's width it announces the launch to the board
// ("KickerLaunch", the speed in cm/s, after "KickerAngle", the lip's angle above level in tenths of
// a degree): the entry speed less what the climb takes (v^2 = v0^2 - 2 g h), off the lip's angle.

class Kicker
{
	Entity self;
	Scene@ scene;

	[3.88, "From the origin up the ramp to the lip (m)"] float run;
	[1.4, "The lip's height above the origin (m)"] float lipHeight;
	[29.0, "The ramp's angle at the lip, against its own base (degrees)"] float lipAngle;
	[5.0, "The kicker's width (m)"] float width;

	private Entity m_rider;
	private float m_lastAlong = -1000.0f;
	private float m_entrySpeed = -1.0f; // the rider's speed at the foot this pass; -1 for none

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
	}

	void onUpdate(float dt)
	{
		if (!m_rider.IsValid())
			return;
		// The rider in the kicker's frame: along its ramp (level), across it.
		Float3 forward = RotateVector(self.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, 1.0f));
		float flat = Sqrt(forward.X * forward.X + forward.Z * forward.Z);
		float fx = forward.X / flat;
		float fz = forward.Z / flat;
		Float3 d = m_rider.GetWorldPosition() - self.GetWorldPosition();
		float along = d.X * fx + d.Z * fz;
		float across = d.X * fz - d.Z * fx;
		bool within = Abs(across) <= width * 0.5f;
		if (within && m_lastAlong < 0.0f && along >= 0.0f)
		{
			Float3 v = CharacterComponent(m_rider).Velocity;
			m_entrySpeed = Length(v);
		}
		float lip = run * flat; // the lip's distance along, level
		if (within && m_entrySpeed > 0.0f && m_lastAlong < lip && along >= lip)
		{
			float squared = m_entrySpeed * m_entrySpeed - 2.0f * 9.81f * lipHeight;
			float speed = squared > 1.0f ? Sqrt(squared) : 1.0f;
			// The lip's angle above level: its angle on the ramp less how far the kicker tips down
			// the slope it stands on.
			float tilt = RadiansToDegrees(Atan2(-forward.Y, flat));
			scene.Scripts.Emit("KickerAngle", int((lipAngle - tilt) * 10.0f + 0.5f));
			scene.Scripts.Emit("KickerLaunch", int(speed * 100.0f + 0.5f));
			m_entrySpeed = -1.0f;
		}
		if (along > lip + 2.0f)
			m_entrySpeed = -1.0f; // past the kicker (round its side): this pass is over
		m_lastAlong = along;
	}

	// A new run: the kicker waits for the rider again.
	void onRunRestart(int unused)
	{
		m_lastAlong = -1000.0f;
		m_entrySpeed = -1.0f;
	}
}
