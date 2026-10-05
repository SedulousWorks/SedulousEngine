// Coin - a pickup: it spins and bobs, and when the player comes within reach it is collected
// ("CoinCollected") and gone. On the coin's entity, whose first child is the Coin model.
// FX/FxCoinSparkle: the burst where a coin was taken.
Guid kCoinSparkle = Guid::FromString("e93dd0c2-fe3e-7f43-a636-f9eae8fe7b7b");

// Audio/powerUp7 (Kenney Digital Audio, CC0): the chime of a coin taken.
Guid kCoinSound = Guid::FromString("cd3e0197-ff26-a740-8ad2-a7774508f0f8");

// The hero looks at the nearest coin within its reach (an AimIkComponent on the Player). Coins
// share these, one script module: the first coin to update in a frame starts it over.
double g_lookFrame = -1.0;
float g_lookNearest = 0.0f;

class Coin
{
	Entity self;
	Scene@ scene;

	[1.3, "Pickup reach from the player's centre (m)"] float radius;
	[3.0, "Spin rate (rad/s)"] float spinSpeed;
	[0.2, "Bob height (m)"] float bobHeight;
	[1, "Points"] int value;
	[7.0, "The hero looks at the nearest coin within this (m)"] float lookRadius;

	private Entity m_player;
	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private float m_time = 0.0f;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
		m_home = self.GetLocalTransform().Position;
		scene.Scripts.Emit("CoinRegistered", 1);
	}

	void onUpdate(float dt)
	{
		m_time += dt;
		self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, m_time * spinSpeed));
		self.SetLocalPosition(Float3(m_home.X, m_home.Y + Sin(m_time * 2.5f) * bobHeight, m_home.Z));
		if (!m_player.IsValid())
			return;
		float distance = Distance(m_player.GetWorldPosition(), self.GetWorldPosition());
		look(distance);
		if (distance < radius)
		{
			// A coin still in reach takes the look back next frame.
			AimIkComponent(m_player).Active = false;
			scene.Scripts.Emit("CoinCollected", value);
			scene.Prefabs.Spawn(kCoinSparkle, self.GetWorldPosition());
			Audio.PlayOneShot(kCoinSound, AudioBus::Effects, 0.7f);
			self.Destroy();
		}
	}

	// The nearest coin in reach this frame turns the hero's head to it; none, and the head eases back.
	private void look(float distance)
	{
		AimIkComponent aim(m_player);
		double frame = scene.Scripts.Elapsed;
		if (frame != g_lookFrame)
		{
			g_lookFrame = frame;
			g_lookNearest = lookRadius;
			aim.Active = false;
		}
		if (distance < g_lookNearest)
		{
			g_lookNearest = distance;
			scene.Animation.SetIkTarget(m_player, self.GetWorldPosition());
			aim.Active = true;
		}
	}
}
// recook 1790769637
