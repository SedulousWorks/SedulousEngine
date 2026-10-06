// Ghost - a medal's ghost rider: it rides the course line at the pace that crosses the finish at its
// medal's time, so a rider racing it knows where that medal stands. On the ghost's entity, which
// follows the line (a path follow on the Course spline); its first child is the rider model,
// tinted and see-through. Placed by Tools/course.py, one per medal.
//
// Its time comes from the finish line ("MedalGold", "MedalSilver", "MedalBronze", in hundredths).
// The pace eases in over `rampSeconds`, as a rider gathers speed off the start, then holds: the
// distance at time t is v t^2 / 2r while ramping, then v (t - r/2), and v is chosen so that the
// distance reaches `finishDistance` at the medal's time. It sets off with the rider ("RunStarted"),
// and a new run ("RunRestart") starts it over.

class Ghost
{
	Entity self;
	Scene@ scene;

	[0, "Which medal (0 gold, 1 silver, 2 bronze)"] int medal;
	[0.0, "How far down the course line the finish is (m)"] float finishDistance;
	[3.0, "How long it takes to reach its pace off the start (s)"] float rampSeconds;

	private float m_seconds = 0.0f; // the medal's time
	private float m_time = 0.0f;    // run time
	private bool m_started = false; // the rider has set off
	private Entity m_model;

	void onStart()
	{
		m_model = self.GetFirstChild();
	}

	void onMedalGold(int hundredths) { take(0, hundredths); }
	void onMedalSilver(int hundredths) { take(1, hundredths); }
	void onMedalBronze(int hundredths) { take(2, hundredths); }
	void onRunStarted(int unused) { m_started = true; }

	void onUpdate(float dt)
	{
		if (m_seconds <= 0.0f || !m_started)
			return;
		PathFollowComponent follow = PathFollowComponent(self);
		m_time += dt;
		float cruise = finishDistance / (m_seconds - rampSeconds * 0.5f);
		follow.Speed = (m_time < rampSeconds) ? cruise * m_time / rampSeconds : cruise;
		settle();
	}

	// A new run: back to the top, off again.
	void onRunRestart(int unused)
	{
		m_time = 0.0f;
		PathFollowComponent follow = PathFollowComponent(self);
		follow.Distance = 0.0f;
		follow.Speed = 0.0f;
		follow.Playing = true;
	}

	private void take(int which, int hundredths)
	{
		if (which == medal)
			m_seconds = float(hundredths) / 100.0f;
	}

	// The line is a smooth curve through points on the snow, so between them it can run above or
	// below it: the model sits on the snow found under the line, not on the line.
	private void settle()
	{
		if (!m_model.IsValid())
			return;
		Float3 at = self.GetWorldPosition();
		PhysicsHit hit = scene.Physics.RayCast(Float3(at.X, at.Y + 4.0f, at.Z), Float3(0.0f, -1.0f, 0.0f), 10.0f, 1);
		float y = hit.Hit ? hit.Position.Y - at.Y : 0.0f;
		m_model.SetLocalPosition(Float3(0.0f, y, 0.0f));
	}
}
