// TimedLife - removes its entity a while after it appears: what a one-shot effect's prefab
// carries, so whoever spawns it can forget it.
class TimedLife
{
	Entity self;
	Scene@ scene;

	[3.0, "Seconds before the entity removes itself"] float seconds;

	private float m_age = 0.0f;

	void onUpdate(float dt)
	{
		m_age += dt;
		if (m_age >= seconds)
		{
			self.Destroy();
		}
	}
}
