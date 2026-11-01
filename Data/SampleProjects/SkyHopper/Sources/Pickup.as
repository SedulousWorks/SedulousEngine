// Pickup - something worth taking that is not a coin: a heart (a life) or a gem (a bonus). It
// spins and bobs like a coin, and when the player comes within reach it is taken: the event named
// in `takenEvent` goes out with `value` ("LifeCollected", "GemCollected"), a sparkle and a chime
// mark it, and it is gone. On the pickup's entity, whose first child is its model.

// FX/FxCoinSparkle: the burst where something was taken.
Guid kTakenSparkle = Guid::FromString("e93dd0c2-fe3e-7f43-a636-f9eae8fe7b7b");

// Audio/powerUp7 (Kenney Digital Audio, CC0), played higher than a coin's.
Guid kTakenSound = Guid::FromString("cd3e0197-ff26-a740-8ad2-a7774508f0f8");

class Pickup
{
	Entity self;
	Scene@ scene;

	["LifeCollected", "The event announcing it was taken"] string takenEvent;
	[1, "The event's value"] int value;
	[1.3, "Pickup reach from the player's centre (m)"] float radius;
	[2.0, "Spin rate (rad/s)"] float spinSpeed;
	[0.25, "Bob height (m)"] float bobHeight;
	[1.3, "The chime's pitch"] float chimePitch;

	private Entity m_player;
	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private float m_time = 0.0f;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
		m_home = self.GetLocalTransform().Position;
	}

	void onUpdate(float dt)
	{
		m_time += dt;
		self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, m_time * spinSpeed));
		self.SetLocalPosition(Float3(m_home.X, m_home.Y + Sin(m_time * 2.0f) * bobHeight, m_home.Z));
		if (m_player.IsValid() && (Distance(m_player.GetWorldPosition(), self.GetWorldPosition()) < radius))
		{
			scene.Scripts.Emit(takenEvent, value);
			scene.Prefabs.Spawn(kTakenSparkle, self.GetWorldPosition());
			Audio.PlayOneShot(kTakenSound, AudioBus::Effects, 0.8f, chimePitch);
			Input.Rumble(0.1f, 0.5f, 0.12f);
			self.Destroy();
		}
	}
}
