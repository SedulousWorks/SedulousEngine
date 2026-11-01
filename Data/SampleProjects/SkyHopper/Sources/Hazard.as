// Hazard - spikes and the like: the player touching one is hurt (sent "Hurt"), walking into it or
// landing on it.
//
// Touching is a box, not a sphere: within `radius` across the ground and with the player's centre
// no higher than `touchHeight` above the hazard's origin. A sphere could never be reached: the
// hazard's own collider stops the player at its side, with the player's centre a metre above the
// ground, and stood on top the centre is higher still (the spikes are 1.5 m tall: their centre
// stands 2.5 m above their origin).
class Hazard
{
	Entity self;
	Scene@ scene;

	[1.1, "Touch reach across the ground, hazard to player (m)"] float radius;
	[2.6, "Touching while the player's centre is at most this far above the hazard's origin (m): its top plus the player's feet (0.95)"] float touchHeight;

	private Entity m_player;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
	}

	void onUpdate(float dt)
	{
		if (!m_player.IsValid())
		{
			return;
		}
		Float3 at = m_player.GetWorldPosition();
		Float3 here = self.GetWorldPosition();
		float dx = at.X - here.X;
		float dz = at.Z - here.Z;
		float above = at.Y - here.Y;
		if ((dx * dx + dz * dz < radius * radius) && (above <= touchHeight) && (above > -0.5f))
		{
			m_player.Send("Hurt");
		}
	}
}
