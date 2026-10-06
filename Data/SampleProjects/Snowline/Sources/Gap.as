// Gap - judges a jump over a crevasse. On an entity at the crevasse's lip, facing down the course
// (Tools/course.py; a kicker launches the rider off the edge, Kicker.as).
//
// Once the rider passes the lip within `reach` of it, its first touch of the snow is judged: short
// of `short` metres past the lip (in the crevasse, before its ramp up) is "GapShort", which the
// board takes as a crash; at or past it is "GapCleared" (the distance flown, in centimetres, at
// the touch), which the game scores. A rider who rolls in without leaving the snow is short as
// well, once it is past the crevasse's wall. A rider flying over is judged where it touches down,
// so the distance is the one flown.

class Gap
{
	Entity self;
	Scene@ scene;

	[0.0, "The course's heading at the lip (radians; 0 runs toward +Z)"] float heading;
	[13.5, "Past the lip, how far a landing is still in the crevasse (m)"] float short;
	[30.0, "How far either side of the course the crevasse spans (m)"] float reach;

	private Entity m_rider;
	private float m_lastAlong = -1000.0f;
	private bool m_armed = false; // past the lip this pass, not judged yet
	private bool m_flew = false;  // off the snow since the lip

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
	}

	void onUpdate(float dt)
	{
		if (!m_rider.IsValid())
			return;
		Float3 d = m_rider.GetWorldPosition() - self.GetWorldPosition();
		float along = d.X * Sin(heading) + d.Z * Cos(heading);
		float across = d.X * Cos(heading) - d.Z * Sin(heading);
		if (!m_armed && m_lastAlong < 0.0f && along >= 0.0f && Abs(across) <= reach)
		{
			m_armed = true;
			m_flew = false;
		}
		m_lastAlong = along;
		if (!m_armed)
			return;
		bool grounded = CharacterComponent(m_rider).Grounded;
		if (!grounded)
			m_flew = true;
		if (grounded && (m_flew || along > 2.0f))
			judge(along); // past the crevasse by now if it flew over it
	}

	private void judge(float along)
	{
		m_armed = false;
		if (along < short)
			scene.Scripts.Emit("GapShort", int(along * 100.0f + 0.5f));
		else
			scene.Scripts.Emit("GapCleared", int(along * 100.0f + 0.5f));
	}

	// A new run: the gap waits for the rider again.
	void onRunRestart(int unused)
	{
		m_lastAlong = -1000.0f;
		m_armed = false;
		m_flew = false;
	}
}
