// Level - the playing scene's own script: the clock, the quota and the fail conditions.
//
// Set on MainScene's script settings. It counts deliveries against the quota (Subscriber emits
// "Delivered"), runs the countdown, and when the bike throws its last paper (Bike emits
// "OutOfPapers") it gives that paper a grace period to land before failing. Its verdict goes to
// the run, where the Game puts up the end-of-level screen.
//
// In a game run the scene bus IS the run bus: one bus per run. A scene event a behaviour emits is
// heard by this Level and by the Game alike, so nothing is relayed; re-emitting the same name would
// deliver it twice. The Level emits only NEW signals, "QuotaMet" and "LevelFailed".
class Level
{
	Scene@ scene;

	[90.0, "Time limit (seconds)"] float timeLimit;
	[3, "Deliveries needed to clear"] int quota;
	[3.0, "Grace after the last paper (s)"] float paperGrace;

	private float m_timeLeft = 0.0f;
	private int m_delivered = 0;
	private bool m_ended = false;
	private bool m_started = false;
	private bool m_outOfPapers = false; // the last paper has been thrown; grace clock running
	private float m_graceLeft = 0.0f;   // seconds left for an in-flight paper to still deliver

	void onStart()
	{
		m_timeLeft = timeLimit;
		m_delivered = 0;
		m_ended = false;
		m_started = true;
		m_outOfPapers = false;
		m_graceLeft = 0.0f;
		updateHud();
	}

	void onUpdate(float dt)
	{
		if (!m_started || m_ended)
		{
			return;
		}

		m_timeLeft -= dt;
		if (m_timeLeft <= 0.0f)
		{
			m_timeLeft = 0.0f;
			fail(0); // out of time
			return;
		}

		if (m_outOfPapers)
		{
			m_graceLeft -= dt;
			if (m_graceLeft <= 0.0f)
			{
				fail(1); // out of papers
				return;
			}
		}

		updateHud();
	}

	// A paper landed in a subscriber's zone.
	void onDelivered(int points)
	{
		if (m_ended)
		{
			return;
		}
		m_delivered += 1;
		updateHud();
		if (m_delivered >= quota)
		{
			m_ended = true;
			Run.Emit("QuotaMet", m_delivered);
		}
	}

	// The bike threw its last paper: start the grace clock for it to land.
	void onOutOfPapers(int unused)
	{
		if (m_ended || m_outOfPapers)
		{
			return;
		}
		m_outOfPapers = true;
		m_graceLeft = (paperGrace > 0.0f) ? paperGrace : 3.0f;
	}

	void onStop() {}

	private void fail(int reason)
	{
		m_ended = true;
		Run.Emit("LevelFailed", reason);
	}

	private void updateHud()
	{
		Ui.FindLabel("hud-timer").SetText("Time " + int(m_timeLeft + 0.5f));
		Ui.FindLabel("hud-deliveries").SetText("Delivered " + m_delivered + " / " + quota);
	}
}
