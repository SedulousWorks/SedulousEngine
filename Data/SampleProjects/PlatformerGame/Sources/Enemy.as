// Enemy - a patroller: it walks back and forth along X between two points, facing the way it
// walks. Touching it hurts the player, unless the player comes down on it from above, which
// defeats it ("EnemyDefeated") and bounces the player off it. On the enemy's entity, whose first child is its model.
// FX/FxStompStars: the burst where an enemy was stomped.
Guid kStompStars = Guid::FromString("4690f883-70cf-d244-ac13-e9a94aefc730");

// Audio/impactSoft_heavy_000 (Kenney Impact Sounds, CC0): an enemy stomped flat.
Guid kSquashSound = Guid::FromString("411669a4-eadb-2c4b-b74d-a7d86338559c");

class Enemy
{
	Entity self;
	Scene@ scene;

	[3.0, "Patrol half-width along X (m)"] float patrolDistance;
	[2.0, "Walk speed (m/s)"] float speed;
	[1.1, "Touch reach from the enemy's origin to the player's centre (m)"] float radius;
	[0.5, "The player's centre this far above the enemy's counts as a stomp (m)"] float stompHeight;
	["", "The model's walk clip (an AnimationClip guid); empty keeps its idle"] string walkClip;

	private Entity m_player;
	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private float m_offset = 0.0f;
	private float m_direction = 1.0f;
	private float m_lastPlayerY = 0.0f;

	void onStart()
	{
		m_player = scene.FindEntityByName("Player");
		m_home = self.GetLocalTransform().Position;
		Entity model = self.GetFirstChild();
		if (model.IsValid() && (walkClip.length() > 0))
		{
			scene.Animation.SetClip(model, Guid::FromString(walkClip));
			scene.Animation.Play(model);
		}
		if (m_player.IsValid())
		{
			m_lastPlayerY = m_player.GetWorldPosition().Y;
		}
	}

	void onUpdate(float dt)
	{
		m_offset += m_direction * speed * dt;
		if (m_offset > patrolDistance)
		{
			m_offset = patrolDistance;
			m_direction = -1.0f;
		}
		else if (m_offset < -patrolDistance)
		{
			m_offset = -patrolDistance;
			m_direction = 1.0f;
		}
		self.SetLocalPosition(Float3(m_home.X + m_offset, m_home.Y, m_home.Z));
		self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, (m_direction > 0.0f) ? 1.5708f : -1.5708f));

		if (!m_player.IsValid())
		{
			return;
		}
		Float3 at = m_player.GetWorldPosition();
		bool falling = at.Y < m_lastPlayerY;
		m_lastPlayerY = at.Y;
		Float3 here = self.GetWorldPosition();
		if (Distance(at, here) >= radius + stompHeight)
		{
			return;
		}
		if (falling && (at.Y > here.Y + stompHeight))
		{
			scene.Scripts.Emit("EnemyDefeated", 1);
			m_player.Send("Bounce");
			scene.Prefabs.Spawn(kStompStars, here + Float3(0.0f, 0.4f, 0.0f));
			Audio.PlayOneShot(kSquashSound);
			self.Destroy();
		}
		else if (Distance(at, here) < radius)
		{
			m_player.Send("Hurt");
		}
	}
}
