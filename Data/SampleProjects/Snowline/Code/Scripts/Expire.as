// Expire - removes its entity once it has lived `life` seconds: on a one-shot effect's prefab
// (Prefabs/GemSparkle, gems.py), so a spawned burst does not stay in the scene after it is spent.
class Expire
{
	Entity self;

	[1.5, "How long the entity lasts (s)"] float life;

	private float m_age = 0.0f;

	void onUpdate(float dt)
	{
		m_age += dt;
		if (m_age >= life)
			self.Destroy();
	}
}
