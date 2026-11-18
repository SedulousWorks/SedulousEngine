// Finish - the finish line: when the rider crosses it down the course, "RunFinished". It holds
// the course's medal times too, and announces them at the start ("MedalGold", "MedalSilver",
// "MedalBronze", each in hundredths of a second) for Snowline.as to judge a run by. Placed by
// Tools/course.py at the course line's end, facing up the course, with its course's times.

class Finish
{
	Entity self;
	Scene@ scene;

	[0.0, "The course's heading at the finish (radians; 0 runs toward +Z)"] float heading;
	[50.0, "A gold medal's time, penalties included (s)"] float gold;
	[56.0, "A silver medal's time (s)"] float silver;
	[64.0, "A bronze medal's time (s)"] float bronze;

	private Entity m_rider;
	private bool m_crossed = false;
	private bool m_seen = false;
	private float m_lastAlong = 0.0f;

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
		scene.Scripts.Emit("MedalGold", int(gold * 100.0f + 0.5f));
		scene.Scripts.Emit("MedalSilver", int(silver * 100.0f + 0.5f));
		scene.Scripts.Emit("MedalBronze", int(bronze * 100.0f + 0.5f));
	}

	void onUpdate(float dt)
	{
		if (m_crossed || !m_rider.IsValid())
			return;
		Float3 d = m_rider.GetWorldPosition() - self.GetWorldPosition();
		float along = d.X * Sin(heading) + d.Z * Cos(heading);
		if (m_seen && m_lastAlong < 0.0f && along >= 0.0f)
		{
			m_crossed = true;
			scene.Scripts.Emit("RunFinished", 0);
		}
		m_lastAlong = along;
		m_seen = true;
	}

	// A new run: the line waits for the rider again.
	void onRunRestart(int unused)
	{
		m_crossed = false;
		m_seen = false;
	}
}
