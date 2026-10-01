// Hazard - spikes and the like: the player coming within reach is hurt (sent "Hurt").
class Hazard
{
	Entity self;
	Scene@ scene;

	[1.2, "Reach from the hazard's origin to the player's centre (m)"] float radius;

	private Entity m_player;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
	}

	void onUpdate(float dt)
	{
		if (m_player.IsValid() && (Distance(m_player.GetWorldPosition(), self.GetWorldPosition()) < radius))
		{
			m_player.Send("Hurt");
		}
	}
}
