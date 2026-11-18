// Flicker - a flame's light that will not hold still: its intensity wanders round what it was
// authored at, two slow waves and a quick one, so a torch breathes rather than burns flat. Off (a
// torch put out, Lamp.as) it stays off.
class Flicker
{
	Entity self;
	Scene@ scene;

	[0.18, "How far the intensity wanders, as a share of its own"] float amount;
	[1.0, "How fast it wanders"] float rate;

	private float m_base = 0.0f;
	private float m_time = 0.0f;

	void onStart()
	{
		m_base = LightComponent::of(self).Intensity;
		m_time = self.GetWorldPosition().X * 1.7f + self.GetWorldPosition().Z * 0.9f; // each torch its own
	}

	void onUpdate(float dt)
	{
		m_time += dt * rate;
		float wave = 0.5f * Sin(m_time * 2.3f) + 0.3f * Sin(m_time * 5.1f + 1.3f)
		             + 0.2f * Sin(m_time * 13.7f + 0.4f);
		LightComponent::of(self).Intensity = m_base * (1.0f + amount * wave);
	}
}
