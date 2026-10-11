// Thief - the player: moves on the floor relative to where the camera looks (up on the stick is
// away from the camera, whichever quarter it has turned to), at a sneak (crouched), a walk or a
// run, and turns to face where it goes. The character controller keeps it on the floor and out of
// the walls; the model's graph (graph.py) follows by Speed and Crouched. Caught (Guard.as), it goes
// back to the last checkpoint. Throw lobs a pebble ahead (Pebble.as), to draw a guard away.

const float kPi = 3.14159265f;

float Saturate(float x)
{
	return x < 0.0f ? 0.0f : (x > 1.0f ? 1.0f : x);
}

class Thief
{
	Entity self;
	Scene@ scene;

	[null, "The camera whose facing makes forward"] Entity camera;
	[1.0, "Sneaking speed (m/s): crouched, silent"] float sneakSpeed;
	[1.6, "Walking speed (m/s)"] float walkSpeed;
	[4.5, "Running speed (m/s): loud"] float runSpeed;
	[10.0, "How fast the body turns toward where it goes"] float turnRate;
	["asset:Prefab", "The pebble thrown (Prefabs/Pebble)"] Guid pebble;
	[7.0, "How fast a pebble leaves the hand (m/s)"] float throwSpeed;
	[0.8, "Seconds between throws"] float throwEvery;

	private float m_yaw = 0.0f;
	private Entity m_figure;
	private Float3 m_checkpoint = Float3(0.0f, 0.0f, 0.0f); // where a catch sends the thief back
	private float m_sinceThrow = 99.0f;

	// The model's skinned mesh, which carries the graph: Thief (the instance) / ThiefRig / Thief.
	private Entity figure()
	{
		if (!m_figure.IsValid())
		{
			Entity model = self.FindChildByName("Thief");
			Entity rig = model.IsValid() ? model.FindChildByName("ThiefRig") : Entity::Invalid;
			m_figure = rig.IsValid() ? rig.FindChildByName("Thief") : Entity::Invalid;
		}
		return m_figure;
	}

	void onUpdate(float dt)
	{
		CharacterComponent body = CharacterComponent(self);
		bool crouched = Input.IsDown("Sneak");
		m_sinceThrow += dt;
		if (Input.WasPressed("Throw") && m_sinceThrow >= throwEvery)
		{
			m_sinceThrow = 0.0f;
			throwPebble();
		}
		animate(body, crouched);

		Float2 stick = Input.Value2D("Move");
		float amount = Sqrt(stick.X * stick.X + stick.Y * stick.Y);
		if (amount < 0.05f || !camera.IsValid())
		{
			body.Move(0.0f, 0.0f);
			return;
		}
		if (amount > 1.0f)
		{
			stick = Float2(stick.X / amount, stick.Y / amount);
		}
		// The camera's facing along the floor: forward, and right of it.
		Float3 look = RotateVector(camera.GetWorldRotation(), Float3(0.0f, 0.0f, -1.0f));
		float flat = Sqrt(look.X * look.X + look.Z * look.Z);
		if (flat < 0.0001f)
		{
			return;
		}
		Float3 forward = Float3(look.X / flat, 0.0f, look.Z / flat);
		Float3 right = Float3(-forward.Z, 0.0f, forward.X);
		float speed = crouched ? sneakSpeed : (Input.IsDown("Run") ? runSpeed : walkSpeed);
		float vx = (forward.X * stick.Y + right.X * stick.X) * speed;
		float vz = (forward.Z * stick.Y + right.Z * stick.X) * speed;
		body.Move(vx, vz);

		// Face where it goes (the model faces +Z), turning the short way round.
		float want = Atan2(vx, vz);
		float delta = want - m_yaw;
		while (delta > kPi) delta -= 2.0f * kPi;
		while (delta < -kPi) delta += 2.0f * kPi;
		m_yaw += delta * Saturate(turnRate * dt);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
	}

	void onStart()
	{
		m_checkpoint = self.GetWorldPosition();
	}

	// Caught by a guard (Guard.as): back to the last checkpoint.
	void onCaught(Float3 at)
	{
		CharacterComponent(self).SetPosition(m_checkpoint);
	}

	// A checkpoint reached: a catch now sends the thief back here, and the HUD says so.
	void onCheckpoint(Float3 at)
	{
		m_checkpoint = at;
		Label note = Ui.FindLabel("hud-note");
		if (note.IsValid)
		{
			note.SetText("Checkpoint");
			note.SetOpacity(1.0f);
			note.SetVisible(true);
			note.FadeTo(0.0f, 2.5f);
		}
	}

	// A door's lock being picked (Door.as): face it and stand still, the hand on it.
	void onPicking(Float3 at)
	{
		Float3 p = self.GetWorldPosition();
		m_yaw = Atan2(at.X - p.X, at.Z - p.Z);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
	}

	// A pebble from the hand, ahead and up, the way the thief faces.
	private void throwPebble()
	{
		if (pebble.IsNil)
		{
			return;
		}
		Float3 p = self.GetWorldPosition();
		Float3 ahead = Float3(Sin(m_yaw), 0.0f, Cos(m_yaw)); // the model faces +Z
		Entity stone = scene.Prefabs.Spawn(pebble, Float3(p.X + ahead.X * 0.4f, p.Y + 0.5f, p.Z + ahead.Z * 0.4f));
		if (!stone.IsValid())
		{
			return;
		}
		// An impulse is the mass times the change in speed: up at about 35 degrees. The pebble's
		// prefab carries a rigid body (an entity without one would fail the handler here).
		float mass = RigidBodyComponent(stone).Mass;
		if (mass <= 0.0f)
		{
			mass = 1.0f;
		}
		float v = throwSpeed * mass;
		scene.Physics.ApplyImpulse(stone, Float3(ahead.X * v * 0.82f, v * 0.57f, ahead.Z * v * 0.82f));
	}

	// The graph by what the body did: its speed along the floor (so a thief pressed against a wall
	// stands rather than runs on the spot), and crouched while sneaking.
	private void animate(CharacterComponent body, bool crouched)
	{
		Entity fig = figure();
		if (!fig.IsValid())
		{
			return;
		}
		Float3 v = body.Velocity;
		scene.Animation.SetFloat(fig, "Speed", Sqrt(v.X * v.X + v.Z * v.Z));
		scene.Animation.SetBool(fig, "Crouched", crouched);
	}
}
