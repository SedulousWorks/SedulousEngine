// Gem - a pickup off the safe line: it spins and bobs, and when the rider comes within reach it is
// taken ("GemCollected"), with a sparkle and a chime. Taken, its model hides; the gem itself stays,
// so a new run ("RunRestart") brings it back. On the gem's entity, whose first child is the Gem
// model. Placed by Tools/course.py, in rows beside the course between the gates.

// Prefabs/GemSparkle (gems.py): the burst where a gem was taken.
Guid kGemSparkle = Guid::FromString("d8481501-8ba1-064c-b56f-503f47e264c5");

// Audio/GemChime (sounds.py): the chime of a gem taken.
Guid kGemChime = Guid::FromString("64c88944-0a22-4e45-8af5-39858c0ada37");

class Gem
{
	Entity self;
	Scene@ scene;

	[1.4, "Pickup reach from the rider's centre (m)"] float radius;
	[2.5, "Spin rate (rad/s)"] float spinSpeed;
	[0.15, "Bob height (m)"] float bobHeight;
	[1, "Gems this one counts for"] int value;

	private Entity m_rider;
	private Entity m_model;
	private bool m_taken = false;
	private float m_time = 0.0f;

	void onStart()
	{
		m_rider = scene.FindEntityByName("Rider");
		m_model = self.GetFirstChild();
		// Gems along the course bob out of step with each other.
		m_time = self.GetWorldPosition().Z * 0.37f;
		scene.Scripts.Emit("GemRegistered", value);
	}

	void onUpdate(float dt)
	{
		if (m_taken || !m_model.IsValid())
			return;
		m_time += dt;
		m_model.SetLocalRotation(Quaternion::FromAxisAngle(Float3(0.0f, 1.0f, 0.0f), m_time * spinSpeed));
		m_model.SetLocalPosition(Float3(0.0f, Sin(m_time * 2.2f) * bobHeight, 0.0f));
		if (!m_rider.IsValid())
			return;
		// A world position read in an update is this frame's.
		if (Distance(m_rider.GetWorldPosition(), self.GetWorldPosition()) < radius)
		{
			m_taken = true;
			m_model.SetActive(false);
			scene.Scripts.Emit("GemCollected", value);
			scene.Prefabs.Spawn(kGemSparkle, self.GetWorldPosition());
			Audio.PlayOneShot(kGemChime, AudioBus::Effects, 0.6f);
		}
	}

	// A new run: the gem is back for the taking.
	void onRunRestart(int unused)
	{
		m_taken = false;
		if (m_model.IsValid())
			m_model.SetActive(true);
	}
}
