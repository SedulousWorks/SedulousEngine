// Pebble - a thrown stone (Thief.as throws it). Its first hard landing clacks and makes a Noise
// there, loud enough to draw a guard who hears it (Guard.as) away to look. Gone a while after.
class Pebble
{
	Entity self;
	Scene@ scene;

	[1.0, "How loud its landing is (0..1)"] float loudness;
	[1.5, "Landing slower than this (m/s) is not a clack"] float hardLanding;
	[6.0, "Seconds before the pebble is gone"] float lifetime;

	private float m_age = 0.0f;
	private bool m_landed = false;

	void onContactBegin(Entity other, Float3 point, Float3 normal, float speed)
	{
		if (m_landed || speed < hardLanding)
			return;
		m_landed = true;
		Audio.PlayOneShot3DPath("Audio/StepStone2", point);
		scene.Scripts.Emit("Noise", Float4(point.X, point.Y, point.Z, loudness));
	}

	void onUpdate(float dt)
	{
		m_age += dt;
		if (m_age >= lifetime)
			self.Destroy();
	}
}
