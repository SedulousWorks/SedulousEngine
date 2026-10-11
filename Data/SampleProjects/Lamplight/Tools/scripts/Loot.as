// Loot - something to take: walked over, it is taken (a Loot event with its value, a chime, and it
// is gone). The level's target is taken the same way and says so instead (Taken), so the level
// script (Level.as) knows the thief may now leave by the exit.
class Loot
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;
	[10, "What it is worth"] int value;
	[false, "The level's target: carried to the exit, it ends the level"] bool target;
	[0.9, "How near the thief takes it (m)"] float reach;
	[0.6, "How fast it turns, to catch the eye (turns a second)"] float spin;

	private float m_turn = 0.0f; // degrees

	void onUpdate(float dt)
	{
		m_turn += spin * 360.0f * dt;
		self.SetLocalRotation(FromYawPitchRoll(DegreesToRadians(m_turn), 0.0f, 0.0f));
		if (!thief.IsValid())
			return;
		Float3 a = self.GetWorldPosition();
		Float3 b = thief.GetWorldPosition();
		float dx = a.X - b.X;
		float dz = a.Z - b.Z;
		if (dx * dx + dz * dz > reach * reach)
			return;
		Audio.PlayOneShot3DPath(target ? "Audio/Taken" : "Audio/Coins", a);
		if (target)
			scene.Scripts.Emit("Taken", value);
		else
			scene.Scripts.Emit("Loot", value);
		self.Destroy();
	}
}
