// Avalanche - chases the rider down the last stretch. On an entity following the course line (a
// path follow on the Course spline, stopped), with the Avalanche particle effect under it ("Front")
// and a looping Rumble source ("Rumble"). Placed by Tools/course.py on a course that has one.
//
// When the rider passes `release` metres down the line, the snow breaks loose `lead` metres behind
// it ("AvalancheReleased") and runs down the line, gathering speed from `startSpeed` at `gather`
// m/s each second up to `topSpeed`: a rider riding clean stays ahead; one who crashes loses it. The
// gap is announced as it changes ("AvalancheGap", whole metres) for the HUD, the rumble grows as it
// closes, and so does the pad's. Within `reach` of the rider it catches it ("AvalancheCaught": the
// board crashes) and is spent: it rolls on over the rider and past for `passSeconds`, then settles.
// (Coming on again, it caught a crashed rider over and over: low on Ridge the slope is gentle, so a
// rider down in the snow never gets back the speed to outrun it.) It stops at the finish
// ("RunFinished"), and a new run ("RunRestart") puts it back to wait.

class Avalanche
{
	Entity self;
	Scene@ scene;

	[null, "The course line (an entity with a spline)"] Entity course;
	[300.0, "How far down the line the rider sets it off (m)"] float release;
	[35.0, "How far behind the rider it breaks loose (m)"] float lead;
	[15.0, "Its speed as it breaks loose (m/s)"] float startSpeed;
	[22.5, "Its fastest (m/s): a little over a clean, untucked rider's on Ridge's last stretch"] float topSpeed;
	[3.0, "How fast it gathers speed (m/s each second)"] float gather;
	[4.0, "How close it comes to catch the rider (m)"] float reach;
	[2.5, "How long it rolls on past the rider it caught before it settles (s)"] float passSeconds;
	[60.0, "The gap at which the rumble is faint (m)"] float hearFrom;
	[0.9, "The rumble's loudest volume"] float rumbleVolume;

	private Entity m_rider;
	private bool m_released = false;
	private bool m_finished = false;
	private float m_speed = 0.0f;
	private int m_lastGap = -1;
	private float m_padTimer = 0.0f;
	private float m_passing = -1.0f; // after a catch, how long it rolls on yet (s); -1 before one

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
		park();
	}

	void onUpdate(float dt)
	{
		if (!m_rider.IsValid() || !course.IsValid() || m_finished)
			return;
		SplineHit here = scene.Splines.ClosestPoint(course, m_rider.GetWorldPosition());
		if (!here.Valid)
			return;
		float rider = here.Distance;
		PathFollowComponent follow = PathFollowComponent(self);
		if (!m_released)
		{
			if (rider < release)
				return;
			m_released = true;
			m_speed = startSpeed;
			follow.Distance = rider - lead;
			follow.Playing = true;
			scene.Particles.Play(child("Front"));
			Entity rumble = child("Rumble");
			scene.Audio.SetVolume(rumble, 0.0f, 0.0f);
			scene.Audio.Play(rumble);
			scene.Scripts.Emit("AvalancheReleased", int(lead));
		}
		if (m_passing >= 0.0f)
		{
			// Spent: over the rider and on, then settled.
			m_passing -= dt;
			if (m_passing < 0.0f)
			{
				m_finished = true;
				quiet();
			}
			return;
		}
		m_speed += gather * dt;
		m_speed = (m_speed > topSpeed) ? topSpeed : m_speed;
		follow.Speed = m_speed;
		float gap = rider - follow.Distance;
		if (gap <= reach)
		{
			scene.Scripts.Emit("AvalancheCaught", 1);
			scene.Scripts.Emit("AvalancheGap", 0);
			Input.Rumble(1.0f, 0.6f, 0.6f);
			m_passing = passSeconds;
			return;
		}
		int metres = gap > 0.0f ? int(gap) : 0;
		if (metres != m_lastGap)
		{
			m_lastGap = metres;
			scene.Scripts.Emit("AvalancheGap", metres);
		}
		// Louder and harder on the pad the closer it is: faint at hearFrom, loudest at reach.
		float near = 1.0f - (gap - reach) / (hearFrom - reach);
		near = (near < 0.0f) ? 0.0f : ((near > 1.0f) ? 1.0f : near);
		scene.Audio.SetVolume(child("Rumble"), rumbleVolume * (0.25f + 0.75f * near), 0.2f);
		m_padTimer -= dt;
		if (m_padTimer <= 0.0f && near > 0.3f)
		{
			Input.Rumble(0.5f * near, 0.15f * near, 0.25f);
			m_padTimer = 0.2f;
		}
	}

	// Over the line: the snow settles behind the rider.
	void onRunFinished(int unused)
	{
		m_finished = true;
		quiet();
	}

	// A new run: back to waiting, still and silent.
	void onRunRestart(int unused)
	{
		park();
	}

	private void park()
	{
		m_released = false;
		m_finished = false;
		m_speed = 0.0f;
		m_lastGap = -1;
		m_passing = -1.0f;
		PathFollowComponent follow = PathFollowComponent(self);
		follow.Speed = 0.0f;
		follow.Distance = 0.0f;
		quiet();
	}

	private void quiet()
	{
		PathFollowComponent(self).Speed = 0.0f;
		Entity front = child("Front");
		if (front.IsValid())
			scene.Particles.Stop(front);
		Entity rumble = child("Rumble");
		if (rumble.IsValid())
			scene.Audio.SetVolume(rumble, 0.0f, 1.0f);
	}

	private Entity child(string name)
	{
		return self.FindChildByName(name);
	}
}
