// PlayerGhost - the player's own best run, ridden again beside them. On the ghost's entity, whose
// first child is the rider model in its own see-through colour. Placed by Tools/course.py.
//
// Every run is recorded from the rider's first frame ("RunStarted") at `sampleRate` samples a
// second, each sample the rider's position and facing (x, y, z, yaw). When a run sets the course's
// best (Snowline.as's "NewBest"), its recording is saved as the course's ghost ("ghost.<scene>", a
// list of numbers in the save) and becomes the ghost of the runs after it. The ghost rides the
// saved run, interpolated between its samples; with none saved it stays hidden.

const int kSampleSize = 4; // x, y, z, yaw

class PlayerGhost
{
	Entity self;
	Scene@ scene;

	[10.0, "Samples recorded each second"] float sampleRate;

	private Entity m_rider;
	private Entity m_model;
	private array<float> m_recording; // this run, as it is ridden
	private array<float> m_ghost;     // the best run, played back
	private bool m_started = false;
	private bool m_recordingOn = false;
	private float m_time = 0.0f;
	private float m_nextSample = 0.0f;

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
		m_model = self.GetFirstChild();
		Save.GetFloats(key(), m_ghost);
		show(m_ghost.length() >= kSampleSize * 2);
	}

	void onRunStarted(int unused)
	{
		m_started = true;
		m_recordingOn = true;
	}

	// A new run: record afresh, and ride the best from the top.
	void onRunRestart(int unused)
	{
		m_recording.resize(0);
		m_recordingOn = true;
		m_time = 0.0f;
		m_nextSample = 0.0f;
		show(m_ghost.length() >= kSampleSize * 2);
	}

	// The run is over: stop recording (the rider coasts on past the line).
	void onRunFinished(int unused)
	{
		m_recordingOn = false;
	}

	// This run is the course's best: it is the ghost from now on, and it is saved.
	void onNewBest(int hundredths)
	{
		m_ghost = m_recording;
		Save.SetFloats(key(), m_ghost);
		Save.Flush();
	}

	void onUpdate(float dt)
	{
		if (!m_started || !m_rider.IsValid())
			return;
		m_time += dt;
		if (m_recordingOn && m_time >= m_nextSample)
		{
			record();
			m_nextSample += 1.0f / sampleRate;
		}
		play();
	}

	private void record()
	{
		Float3 at = m_rider.GetWorldPosition();
		Float3 forward = RotateVector(m_rider.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, 1.0f));
		m_recording.insertLast(at.X);
		m_recording.insertLast(at.Y);
		m_recording.insertLast(at.Z);
		m_recording.insertLast(Atan2(forward.X, forward.Z));
	}

	// The saved run at this run's time, between its two samples; it stays at its last one once its
	// run is over.
	private void play()
	{
		int samples = int(m_ghost.length()) / kSampleSize;
		if (samples < 2)
			return;
		float at = m_time * sampleRate;
		int i = int(at);
		if (i >= samples - 1)
		{
			i = samples - 2;
			at = float(samples - 1);
		}
		float k = at - float(i);
		int a = i * kSampleSize;
		int b = a + kSampleSize;
		Float3 p = Float3(m_ghost[a] + (m_ghost[b] - m_ghost[a]) * k,
			m_ghost[a + 1] + (m_ghost[b + 1] - m_ghost[a + 1]) * k,
			m_ghost[a + 2] + (m_ghost[b + 2] - m_ghost[a + 2]) * k);
		float turn = m_ghost[b + 3] - m_ghost[a + 3];
		while (turn > 3.14159f) turn -= 6.28318f;
		while (turn < -3.14159f) turn += 6.28318f;
		float yaw = m_ghost[a + 3] + turn * k;
		self.SetLocalPosition(p);
		self.SetLocalRotation(FromYawPitchRoll(yaw, 0.0f, 0.0f));
	}

	private void show(bool visible)
	{
		if (m_model.IsValid())
			m_model.SetActive(visible);
	}

	private string key()
	{
		return "ghost." + scene.Name;
	}
}
