// Enemy - a patroller: it walks back and forth along X between two points, facing the way it
// walks. Touching it hurts the player, unless the player comes down on it from the air, which
// defeats it ("EnemyDefeated") and bounces the player off it. On the enemy's entity, whose first child is its model.
//
// Touching is a box, not a sphere: within `radius` across the ground and with the player's centre
// no higher than `touchHeight` above the enemy's origin (and not below it). Only a player in the
// air and on the way down stomps; one on the ground, walking or standing into the enemy, is hurt,
// however the enemy's origin sits against the ground the player walks on.
//
// A flier (the bee) is the same enemy in the air: it hovers, bobbing `hoverHeight` up and down,
// and may patrol across the path (along Z) rather than along it. It is stomped and hurts the same
// way, measured from where it flies.
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
	[1.1, "Touch reach across the ground, enemy to player (m)"] float radius;
	[1.8, "Touching while the player's centre is at most this far above the enemy's origin (m)"] float touchHeight;
	[1.0, "Falling at least this fast counts as coming down on the enemy (m/s)"] float stompSpeed;
	["", "The model's walk clip (an AnimationClip guid); empty keeps its idle"] string walkClip;
	[0.0, "Hover: bob this far up and down as it patrols (m); 0 walks"] float hoverHeight;
	[2.0, "Hover bob rate (rad/s)"] float hoverSpeed;
	[false, "Patrol along Z (across the path) rather than X"] bool patrolAlongZ;

	private Entity m_player;
	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private float m_offset = 0.0f;
	private float m_direction = 1.0f;
	private float m_lastPlayerY = 0.0f;
	private float m_time = 0.0f;

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
		m_time += dt;
		float bob = Sin(m_time * hoverSpeed) * hoverHeight;
		if (patrolAlongZ)
		{
			self.SetLocalPosition(Float3(m_home.X, m_home.Y + bob, m_home.Z + m_offset));
			self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, (m_direction > 0.0f) ? 0.0f : 3.14159f));
		}
		else
		{
			self.SetLocalPosition(Float3(m_home.X + m_offset, m_home.Y + bob, m_home.Z));
			self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, (m_direction > 0.0f) ? 1.5708f : -1.5708f));
		}

		if (!m_player.IsValid())
		{
			return;
		}
		Float3 at = m_player.GetWorldPosition();
		float fallSpeed = (dt > 0.0f) ? (m_lastPlayerY - at.Y) / dt : 0.0f;
		m_lastPlayerY = at.Y;
		Float3 here = self.GetWorldPosition();
		float dx = at.X - here.X;
		float dz = at.Z - here.Z;
		float above = at.Y - here.Y;
		if ((dx * dx + dz * dz >= radius * radius) || (above > touchHeight) || (above < 0.0f))
		{
			return;
		}
		bool airborne = !CharacterComponent(m_player).Grounded;
		if (airborne && (fallSpeed >= stompSpeed))
		{
			scene.Scripts.Emit("EnemyDefeated", 1);
			m_player.Send("Bounce");
			scene.Prefabs.Spawn(kStompStars, here + Float3(0.0f, 0.4f, 0.0f));
			Audio.PlayOneShot(kSquashSound);
			self.Destroy();
		}
		else
		{
			m_player.Send("Hurt");
		}
	}
}
