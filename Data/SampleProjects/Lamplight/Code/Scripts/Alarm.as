// Alarm - the upper floor's bell: when a guard gives chase (Spotted), it rings, and every guard on
// the floor hears it and comes to where the thief was seen (a Noise there, loud enough for the whole
// floor; a guard already giving chase keeps chasing). The game says so (Alarm). Once rung it rests
// a while before it can ring again.
class Alarm
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;
	[40.0, "How loud: a noise of loudness 1 is heard 14 m away"] float loudness;
	[8.0, "Seconds before it can ring again"] float rest;

	private float m_resting = 0.0f;

	void onUpdate(float dt)
	{
		if (m_resting > 0.0f)
			m_resting -= dt;
	}

	void onSpotted(int unused)
	{
		if (m_resting > 0.0f || !thief.IsValid())
			return;
		m_resting = rest;
		Float3 at = thief.GetWorldPosition();
		Audio.PlayOneShot3DPath("Audio/Bell", at);
		scene.Scripts.Emit("Noise", Float4(at.X, at.Y, at.Z, loudness));
		scene.Scripts.Emit("Alarm", at);
	}
}
