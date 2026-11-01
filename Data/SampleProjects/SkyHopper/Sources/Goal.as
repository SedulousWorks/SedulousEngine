// Goal - the level's end: the player reaching the flag emits "GoalReached", once.
// FX/FxConfetti: the celebration at the flag.
Guid kConfetti = Guid::FromString("292a3bbc-dd5c-9847-b793-2147a3a3bdd8");

class Goal
{
	Entity self;
	Scene@ scene;

	[1.8, "Reach from the flag's base to the player's centre (m)"] float radius;

	private Entity m_player;
	private bool m_reached = false;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
	}

	void onUpdate(float dt)
	{
		if (m_reached || !m_player.IsValid())
		{
			return;
		}
		if (Distance(m_player.GetWorldPosition(), self.GetWorldPosition()) < radius)
		{
			m_reached = true;
			scene.Prefabs.Spawn(kConfetti, self.GetWorldPosition() + Float3(0.0f, 1.0f, 0.0f));
			m_player.Send("Celebrate");
			scene.Scripts.Emit("GoalReached", 0);
		}
	}
}
