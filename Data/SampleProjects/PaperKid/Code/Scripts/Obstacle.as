// Obstacle - something the bike crashes into: a car, a pedestrian, the street junk. When the bike
// comes within reach it is told it crashed ("Crashed"), and this obstacle waits a moment before it
// can be hit again, so one bump is one crash.
class Obstacle
{
	Entity self;
	Scene@ scene;

	[1.0, "Reach from this entity's origin to the bike's centre (m)"] float radius;
	[2.0, "Seconds before this obstacle can be hit again"] float cooldown;

	private Entity m_bike;
	private float m_wait = 0.0f;

	void onStart()
	{
		m_bike = scene.FindEntityByName("Bike");
	}

	void onUpdate(float dt)
	{
		if (m_wait > 0.0f)
		{
			m_wait -= dt;
			return;
		}
		if (!m_bike.IsValid())
		{
			return;
		}
		Float3 at = self.GetWorldPosition();
		Float3 bike = m_bike.GetWorldPosition();
		float dx = bike.X - at.X;
		float dz = bike.Z - at.Z;
		if (dx * dx + dz * dz < radius * radius)
		{
			m_wait = cooldown;
			m_bike.Send("Crashed");
		}
	}
}
