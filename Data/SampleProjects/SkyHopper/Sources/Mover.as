// Mover - moves an entity back and forth and spins it: a saw sliding along its track, a spiky
// ball swinging across a bridge. The motion is a smooth swing (a sine) from where it was placed,
// `distance` either side along `axis`; the spin is about `spinAxis`. With a Hazard on the same
// entity, the hazard hurts wherever the mover has taken it.

class Mover
{
	Entity self;
	Scene@ scene;

	[(1.0, 0.0, 0.0), "The direction it swings along"] Float3 axis;
	[2.0, "How far either side of its place it swings (m)"] float distance;
	[1.0, "Swings per second (Hz)"] float rate;
	[0.0, "Where in its swing it starts, 0 to 1 (staggers several movers)"] float phase;
	[(0.0, 0.0, 1.0), "The axis it spins about"] Float3 spinAxis;
	[0.0, "Spin rate (rad/s)"] float spinSpeed;

	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private Quaternion m_rest;
	private float m_time = 0.0f;

	void onStart()
	{
		m_home = self.GetLocalTransform().Position;
		m_rest = self.GetLocalTransform().Rotation;
	}

	void onUpdate(float dt)
	{
		m_time += dt;
		float swing = Sin((m_time * rate + phase) * 6.28318f) * distance;
		self.SetLocalPosition(m_home + axis * swing);
		if (spinSpeed != 0.0f)
		{
			self.SetLocalRotation(Quaternion::FromAxisAngle(spinAxis, m_time * spinSpeed) * m_rest);
		}
	}
}
