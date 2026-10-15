// Player - a guest someone plays. On a guest's entity like any other (a navigation agent and an
// Instance Member of a costume), so it looks like one. It moves where the stick points, relative
// to where the camera looks, by driving its agent at that velocity (no path to wait for): the crowd
// makes way round it and it round the crowd, as guests do for each other. A guest's stroll by
// default; Sprint is faster (and marks you, Ball.as); Dance, held, dances; Tag tells the ball
// (Ball.as decides who is in reach). It shoulders past guests, at half pace while it is pressed
// against one (`crowd`), so it cannot plough through a group; standing guests step out of its way
// (Guest.as). It wears its costume on a child, one of six looks (Ball.as picks), so the clip goes
// to each look. Its `activity` is a guest's.
//
// Over the network the host moves every hunter: a client's own hunter sends its stick, sprint,
// dance and tags to the host (Net "input" and "tag"), the host's Ball hands them to the hunter
// ("Input"), and the transform and activity come back replicated. A spawned hunter (a joining
// player's) finds the camera, the crowd and the Ball by name, and the client's own tells the
// camera to follow it.
//
// Its globals carry its name: every behaviour compiles into one module here, and Guest.as names
// the clips too.
const int kPlayerIdle = 0; // the clips, in the Guests entity's instanced skinning order
const int kPlayerWalk = 1;
const int kPlayerDance = 3;

class Player
{
	Entity self;
	Scene@ scene;

	[null, "The camera whose facing makes forward"] Entity camera;
	[null, "The crowd: its children's children are the guests it pushes past"] Entity crowd;
	[0.55, "Nearer than this to a guest (m) is pressing against it"] float pressDistance;
	[0.5, "Its pace while pressing against a guest (of the full)"] float pressPace;
	[1.0, "Walking speed (m/s): a guest's, the Walk clip's"] float walkSpeed;
	[3.0, "Sprinting speed (m/s)"] float sprintSpeed;
	[0, "What the player is doing (0 idle, 1 walk, 2 talk, 3 dance): the clip it plays", replicated] int activity;
	[false, "Sprinting now (a hunter sees it)", replicated] bool sprinting;

	private float m_yaw = 0.0f;
	private bool m_moving = false;
	private float m_pressCheck = 0.0f;
	private bool m_pressed = false;
	private Float4 m_remote = Float4(0.0f, 0.0f, 0.0f, 0.0f); // a remote player's input (the host)
	private float m_remoteAge = 99.0f;
	private int m_sent = -1;          // the input last sent to the host (a client)
	private float m_sendIn = 0.0f;
	private bool m_handedOver = false; // a client's: its agent stopped for the host's transforms
	private bool m_menu = false;       // a menu covers a networked round (Masquerade.as): no input

	void onStart()
	{
		// A spawned hunter (a joining player's) names nothing in the scene: it finds what it needs.
		if (!camera.IsValid())
			camera = scene.FindEntityByName("Camera");
		if (!crowd.IsValid())
			crowd = scene.FindEntityByName("Crowd");
		Entity ball = scene.FindEntityByName("Ball");
		if (ball.IsValid())
			ball.Send("Hunter", self); // so the seats can find it, on every peer
		if (mine() && camera.IsValid())
			camera.Send("Follow", self);
	}

	// Whose: 0 the host, else the id the host gave a client. Mine when this peer plays it.
	private int owner()
	{
		NetworkComponent@ net = NetworkComponent::of(self);
		return net is null ? 0 : int(net.Owner);
	}

	private bool mine()
	{
		int me = Net.LocalPlayer;
		return owner() == (me < 0 ? 0 : me);
	}

	// A menu over a networked round (Masquerade.as): this peer's player stands still under it.
	void onMenu(int shown)
	{
		m_menu = shown != 0;
	}

	// The host: a remote player's stick (x, z), sprint and dance, from Ball.as.
	void onInput(Float4 input)
	{
		m_remote = input;
		m_remoteAge = 0.0f;
	}

	void onUpdate(float dt)
	{
		// What the player asks for: the stick as a direction on the floor, sprint, dance, a tag.
		float dx = 0.0f;
		float dz = 0.0f;
		bool sprint = false;
		bool dance = false;
		bool tag = false;
		if (mine() && !m_menu)
		{
			Float2 stick = Input.Value2D("Move");
			float amount = Sqrt(stick.X * stick.X + stick.Y * stick.Y);
			if (amount >= 0.1f && camera.IsValid())
			{
				if (amount > 1.0f)
					stick = Float2(stick.X / amount, stick.Y / amount);
				// The camera's facing along the floor: forward, and right of it.
				Float3 look = RotateVector(camera.GetWorldRotation(), Float3(0.0f, 0.0f, -1.0f));
				float flat = Max(Sqrt(look.X * look.X + look.Z * look.Z), 0.0001f);
				Float3 forward = Float3(look.X / flat, 0.0f, look.Z / flat);
				Float3 right = Float3(-forward.Z, 0.0f, forward.X);
				dx = forward.X * stick.Y + right.X * stick.X;
				dz = forward.Z * stick.Y + right.Z * stick.X;
			}
			sprint = Input.IsDown("Sprint");
			dance = Input.IsDown("Dance");
			tag = Input.WasPressed("Tag");
		}
		else if (!Net.IsClient)
		{
			m_remoteAge += dt;
			if (m_remoteAge < 0.5f) // a quiet client stands still
			{
				dx = m_remote.X;
				dz = m_remote.Y;
				sprint = m_remote.Z > 0.5f;
				dance = m_remote.W > 0.5f;
			}
		}

		if (Net.IsClient)
		{
			if (!m_handedOver)
			{
				NavAgentComponent::of(self).Stop(); // walking since the scene loaded: the host's now
				m_handedOver = true;
			}
			// The host moves every hunter; a client sends its own player's asking, and plays what
			// the host replicates back.
			if (mine())
			{
				send(dx, dz, sprint, dance, dt);
				if (tag)
					Net.Rpc("tag");
			}
			playClip();
			return;
		}

		NavAgentComponent@ agent = NavAgentComponent::of(self);
		float amount = Sqrt(dx * dx + dz * dz);
		sprinting = false;
		if (amount >= 0.1f)
		{
			sprinting = sprint;
			float speed = sprinting ? sprintSpeed : walkSpeed;
			m_pressCheck -= dt;
			if (m_pressCheck <= 0.0f)
			{
				m_pressCheck = 0.1f;
				m_pressed = pressing();
			}
			if (m_pressed)
				speed *= pressPace;
			agent.Move(dx / amount * Min(amount, 1.0f) * speed, dz / amount * Min(amount, 1.0f) * speed);
			m_moving = true;
			face(dx, dz, dt);
		}
		else
		{
			agent.Move(0.0f, 0.0f);
			m_moving = false;
		}
		if (tag)
			scene.Scripts.Emit("Tag", owner()); // Ball.as finds the seat
		activity = m_moving ? kPlayerWalk : (dance ? kPlayerDance : kPlayerIdle);
		playClip();
	}

	// A client: its player's asking, packed in one number (the stick to a hundredth, sprint and
	// dance as bits), to the host when it changes and five times a second besides.
	private void send(float dx, float dz, bool sprint, bool dance, float d)
	{
		int ix = int(Clamp((dx + 1.0f) * 100.0f + 0.5f, 0.0f, 200.0f));
		int iz = int(Clamp((dz + 1.0f) * 100.0f + 0.5f, 0.0f, 200.0f));
		int packed = (ix * 201 + iz) * 4 + (sprint ? 1 : 0) + (dance ? 2 : 0);
		m_sendIn -= d;
		if (packed != m_sent || m_sendIn <= 0.0f)
		{
			Net.RpcNumber("input", double(packed));
			m_sent = packed;
			m_sendIn = 0.2f;
		}
	}

	// The clip on each of its looks (only the one it wears is drawn), from its replicated activity.
	private void playClip()
	{
		Entity child = self.GetFirstChild();
		while (child.IsValid())
		{
			InstanceMemberComponent@ look = InstanceMemberComponent::of(child);
			if (look !is null)
				look.Clip = uint(activity);
			child = child.GetNextSibling();
		}
	}

	// Pressed against a guest: one of the crowd's within pressDistance.
	private bool pressing()
	{
		if (!crowd.IsValid())
			return false;
		Float3 p = self.GetWorldPosition();
		float near = pressDistance * pressDistance;
		Entity group = crowd.GetFirstChild();
		while (group.IsValid())
		{
			Entity guest = group.GetFirstChild();
			while (guest.IsValid())
			{
				Float3 q = guest.GetWorldPosition();
				float dx = q.X - p.X;
				float dz = q.Z - p.Z;
				if (dx * dx + dz * dz < near)
					return true;
				guest = guest.GetNextSibling();
			}
			group = group.GetNextSibling();
		}
		return false;
	}

	// Face where it goes (the model faces +Z), turning the short way round.
	private void face(float dx, float dz, float d)
	{
		float want = Atan2(dx, dz);
		float delta = want - m_yaw;
		while (delta > 3.14159265f) delta -= 6.2831853f;
		while (delta < -3.14159265f) delta += 6.2831853f;
		m_yaw += delta * Min(10.0f * d, 1.0f);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
	}
}
