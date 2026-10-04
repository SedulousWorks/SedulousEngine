// PlayerController - the player's movement, jump, facing and animation.
//
// On the Player entity, which carries a Character component (a kinematic capsule: its
// position is the capsule's centre). The model is the entity's first child, the Character
// prefab instance, whose root plays the skeletal clips.
//
// The camera looks down -Z from behind, so the "Move" axis maps straight to the ground plane:
// W (+Y) walks toward -Z, D (+X) toward +X.
//
// A fall or a hit is paced so the player can find themselves again: a poof where they went, a
// moment out of sight while the camera glides back to the safe ground (the player already moved
// there, facing the way they stood on it), a poof as they reappear, then a moment of blinking
// in which nothing can hurt. Safe ground is a spot stood still on with ground all round it: near
// an edge the nearest spot that has it is kept instead, so a respawn never starts half off a ledge.
//
// The pad rumbles with the game: a heavy jolt for a fall or a hit, a sharp kick off a stomped
// enemy, a thud for a hard landing, and a happy pulse at the flag.

// The Character model's clips (Models/Character/Character).
Guid kIdleClip = Guid::FromString("9d570e4d-2821-d043-abc6-bd79566a5dc3");
Guid kRunClip = Guid::FromString("4a8fbc98-4874-514f-983d-7a060c8713c0");
Guid kJumpClip = Guid::FromString("4dfca5b6-4d94-cc43-a328-3210e392d7a1");

// The effects (FX/*): dust at the feet on a jump and a hard landing, a poof on a respawn.
Guid kDust = Guid::FromString("0f9877ac-2cfa-fe41-b1bf-bbc2be01dba3");
Guid kPoof = Guid::FromString("5d7697bb-a73a-0f43-8c69-86bc81a81f3a");
/// From the capsule's centre to its feet: half height plus radius.
const float kFeet = 0.95f;

// The sounds (Audio/*).
Guid kJumpSound = Guid::FromString("f0771aa4-37aa-8a47-92f1-43e708c441e0");
Guid kHurtSound = Guid::FromString("4425182f-1d33-d244-a267-0d020575d807");
Guid kFallSound = Guid::FromString("ba04916a-434c-684d-8c3d-00cbab83ca76");

class PlayerController
{
	Entity self;
	Scene@ scene;

	[7.0, "Top run speed (m/s)"] float moveSpeed;
	[40.0, "Ground acceleration (m/s^2)"] float acceleration;
	[12.0, "Air acceleration (m/s^2)"] float airAcceleration;
	[9.5, "Jump launch speed (m/s)"] float jumpSpeed;
	[0.12, "Coyote time: a jump still counts this long after leaving a ledge (s)"] float coyoteTime;
	[0.12, "Jump buffer: a press this early before landing still jumps (s)"] float jumpBuffer;
	[14.0, "Turn rate toward the move direction (rad/s)"] float turnSpeed;
	[-15.0, "Below this height the player falls out and respawns"] float killHeight;
	[0.4, "Standing still this long on ground makes it the respawn point (s)"] float safeGroundTime;
	[8.0, "Bounce speed off a stomped enemy (m/s)"] float bounceSpeed;
	[0.8, "Out of sight after a fall or a hit, while the camera glides back (s)"] float respawnDelay;
	[1.2, "Blinking after reappearing, when nothing can hurt (s)"] float graceTime;
	[0.7, "Safe ground reaches at least this far round the spot on every side (m)"] float safeMargin;

	// ---- runtime ----
	private float m_velX = 0.0f;
	private float m_velZ = 0.0f;
	private float m_yaw = 0.0f;
	private float m_sinceGrounded = 0.0f;
	private float m_sinceJumpPressed = 1000.0f;
	private int m_anim = -1; // 0 idle, 1 run, 2 jump
	private Float3 m_spawn = Float3(0.0f, 0.0f, 0.0f);
	private Entity m_model;
	private int m_deaths = 0;
	/// Seconds left of the grace after a respawn, while a hazard still touching cannot hurt.
	private float m_invulnerable = 0.0f;
	/// How long the player has stood grounded; past a moment, where it stands is safe ground.
	private float m_groundedFor = 0.0f;
	/// Grounded last frame, and how long the current time in the air has lasted.
	private bool m_wasGrounded = true;
	private float m_airTime = 0.0f;
	/// The level is won: no more input, the player stands and enjoys it.
	private bool m_celebrating = false;
	/// Seconds left out of sight before reappearing (below 0: not respawning).
	private float m_respawning = -1.0f;
	/// The current still moment has been looked at for safe ground (once per stand).
	private bool m_safeChecked = false;
	/// The facing the player had on the safe ground, which a respawn gives back.
	private float m_spawnYaw = 0.0f;
	private Entity m_camera;

	void onStart()
	{
		m_spawn = self.GetWorldPosition();
		m_model = self.GetFirstChild();
		m_camera = scene.FindEntityByName("Camera");
		playAnim(0);
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f)
		{
			return;
		}
		if (m_invulnerable > 0.0f)
		{
			m_invulnerable -= dt;
		}
		CharacterComponent character(self);
		if (m_respawning >= 0.0f)
		{
			// Out of sight at the safe ground, standing still while the camera arrives.
			character.Move(0.0f, 0.0f);
			m_respawning -= dt;
			if (m_respawning < 0.0f)
			{
				showModel(true);
				scene.Prefabs.Spawn(kPoof, self.GetWorldPosition());
			}
			return;
		}
		if (m_invulnerable > 0.0f)
		{
			// The grace after reappearing: a blink, ten times a second.
			showModel(int(m_invulnerable * 10.0f) % 2 == 0);
		}
		else
		{
			showModel(true);
		}
		bool grounded = character.Grounded;
		m_sinceGrounded = grounded ? 0.0f : m_sinceGrounded + dt;
		// A hard landing kicks up dust; a hop off a step does not.
		if (grounded && !m_wasGrounded && (m_airTime > 0.35f))
		{
			dust();
			Input.Rumble(0.3f, 0.1f, 0.08f); // the thud of landing
		}
		m_airTime = grounded ? 0.0f : m_airTime + dt;
		m_wasGrounded = grounded;
		// Safe ground: a spot stood STILL on for a moment becomes the respawn point, so a fall
		// costs one jump, not the level. Still, because walking into a hazard passes over
		// ground that is not safe; standing still inside a hazard's reach hurts at once.
		bool still = (m_velX * m_velX + m_velZ * m_velZ) < 0.25f;
		m_groundedFor = (grounded && still) ? m_groundedFor + dt : 0.0f;
		if (m_groundedFor <= 0.0f)
		{
			m_safeChecked = false;
		}
		if ((m_groundedFor > safeGroundTime) && (m_invulnerable <= 0.0f) && !m_safeChecked)
		{
			m_safeChecked = true;
			Float3 spot = self.GetWorldPosition();
			if (findSafeSpot(self.GetWorldPosition(), spot))
			{
				m_spawn = spot + Float3(0.0f, 0.1f, 0.0f);
				m_spawnYaw = m_yaw;
			}
		}
		m_sinceJumpPressed = Input.WasPressed("Jump") ? 0.0f : m_sinceJumpPressed + dt;

		// Steer the horizontal velocity toward the stick, snappier on the ground.
		Float2 move = m_celebrating ? Float2(0.0f, 0.0f) : Input.Value2D("Move");
		float targetX = move.X * moveSpeed;
		float targetZ = -move.Y * moveSpeed;
		float rate = (grounded ? acceleration : airAcceleration) * dt;
		m_velX = approach(m_velX, targetX, rate);
		m_velZ = approach(m_velZ, targetZ, rate);
		character.Move(m_velX, m_velZ);

		// Jump: buffered, and allowed a moment after walking off a ledge.
		if (!m_celebrating && (m_sinceJumpPressed <= jumpBuffer) && (m_sinceGrounded <= coyoteTime))
		{
			character.Jump(jumpSpeed);
			dust();
			Audio.PlayOneShot(kJumpSound, AudioBus::Effects, 0.8f);
			m_sinceJumpPressed = 1000.0f;
			m_sinceGrounded = 1000.0f;
		}

		// Face the way we move.
		float speed = Sqrt(m_velX * m_velX + m_velZ * m_velZ);
		if (speed > 0.5f)
		{
			float wanted = Atan2(m_velX, m_velZ);
			m_yaw = turnToward(m_yaw, wanted, turnSpeed * dt);
			self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, m_yaw));
		}

		if (!grounded)
		{
			playAnim(2);
		}
		else if (speed > 0.5f)
		{
			playAnim(1);
		}
		else
		{
			playAnim(0);
		}

		// The grace after a respawn also covers the frame or two before the teleport lands,
		// when the player is still below the kill height.
		if ((m_invulnerable <= 0.0f) && (self.GetWorldPosition().Y < killHeight))
		{
			Audio.PlayOneShot(kFallSound);
			respawn();
		}
	}

	// Came down on an enemy: bounce off it, in the air as on the ground.
	void onBounce()
	{
		CharacterComponent character(self);
		character.Launch(bounceSpeed);
		m_sinceGrounded = 1000.0f; // the bounce is not a coyote jump
		Input.Rumble(0.25f, 0.6f, 0.12f); // a sharp kick off the enemy
	}

	// A hazard or an enemy touched the player: the same as a fall, with a jolt of the camera.
	void onHurt()
	{
		if ((m_invulnerable <= 0.0f) && !m_celebrating)
		{
			shake(0.35f);
			Audio.PlayOneShot(kHurtSound);
			respawn();
		}
	}

	// The flag is reached: stop taking input and stand still for the celebration.
	void onCelebrate()
	{
		m_celebrating = true;
		Input.Rumble(0.2f, 0.5f, 0.35f); // a happy pulse
	}

	// A fall or a hit: a poof where the player went, then back to the last safe ground with no
	// momentum, out of sight until the camera is there (onUpdate brings them back).
	void respawn()
	{
		if (m_respawning >= 0.0f)
		{
			return; // already on the way back
		}
		m_deaths += 1;
		m_velX = 0.0f;
		m_velZ = 0.0f;
		scene.Prefabs.Spawn(kPoof, self.GetWorldPosition());
		Input.Rumble(0.8f, 0.5f, 0.3f); // the jolt of a fall or a hit
		CharacterComponent character(self);
		character.SetPosition(m_spawn);
		m_yaw = m_spawnYaw;
		self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitY, m_yaw));
		showModel(false);
		playAnim(0);
		m_respawning = respawnDelay;
		m_invulnerable = respawnDelay + graceTime;
		scene.Scripts.Emit("PlayerDied", m_deaths);
	}

	private void showModel(bool shown)
	{
		if (m_model.IsValid() && m_model.IsActive() != shown)
		{
			m_model.SetActive(shown);
		}
	}

	// The spot nearest `at` (searched on a 0.4 m grid out to 0.8 m) where the ground reaches
	// safeMargin past it on all four sides, level with the player's feet: false when there is none.
	private bool findSafeSpot(Float3 at, Float3 &out spot)
	{
		array<float> steps = {0.0f, -0.4f, 0.4f, -0.8f, 0.8f};
		float feet = at.Y - kFeet;
		float best = 1000.0f;
		bool found = false;
		for (uint i = 0; i < steps.length(); i++)
		{
			for (uint j = 0; j < steps.length(); j++)
			{
				float x = at.X + steps[i];
				float z = at.Z + steps[j];
				float distance = steps[i] * steps[i] + steps[j] * steps[j];
				if (distance < best && groundAt(x, z, feet) && groundAt(x + safeMargin, z, feet)
					&& groundAt(x - safeMargin, z, feet) && groundAt(x, z + safeMargin, feet)
					&& groundAt(x, z - safeMargin, feet))
				{
					best = distance;
					spot = Float3(x, at.Y, z);
					found = true;
				}
			}
		}
		return found;
	}

	// Flat ground under (x, z) level with the player's feet. The islands' tops are flat and their
	// edges rounded, so a probe on the bevel (a little lower) counts as the edge, not as ground.
	private bool groundAt(float x, float z, float feet)
	{
		PhysicsHit hit = scene.Physics.RayCast(Float3(x, feet + 0.6f, z), Float3(0.0f, -1.0f, 0.0f), 1.2f);
		return hit.Hit && Abs(hit.Position.Y - feet) < 0.08f;
	}

	private void dust()
	{
		scene.Prefabs.Spawn(kDust, self.GetWorldPosition() - Float3(0.0f, kFeet - 0.05f, 0.0f));
	}

	private void shake(float strength)
	{
		if (m_camera.IsValid())
		{
			m_camera.Send("Shake", strength);
		}
	}

	private void playAnim(int which)
	{
		if (which == m_anim || !m_model.IsValid())
		{
			return;
		}
		m_anim = which;
		Guid clip = kIdleClip;
		if (which == 1)
		{
			clip = kRunClip;
		}
		else if (which == 2)
		{
			clip = kJumpClip;
		}
		scene.Animation.SetClip(m_model, clip);
		scene.Animation.Play(m_model);
	}

	private float approach(float value, float target, float step)
	{
		if (value < target)
		{
			return (value + step > target) ? target : value + step;
		}
		return (value - step < target) ? target : value - step;
	}

	// Turn an angle toward another the short way round, by at most `step`.
	private float turnToward(float from, float to, float step)
	{
		float pi = 3.14159265f;
		float delta = to - from;
		while (delta > pi) { delta -= 2.0f * pi; }
		while (delta < -pi) { delta += 2.0f * pi; }
		if (Abs(delta) <= step)
		{
			return to;
		}
		return from + ((delta > 0.0f) ? step : -step);
	}
}
