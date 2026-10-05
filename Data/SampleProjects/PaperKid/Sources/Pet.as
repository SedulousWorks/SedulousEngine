// Pet - a dog or a cat on a lawn of the title backdrop. It trots to a spot on its lawn (the
// rectangle xMin..xMax by zMin..zMax), does something there (stands about, sits, lies down, or
// its own thing: the dog sniffs the grass, the cat grooms), then trots to another spot.
//
// Its model is its first child, with the clips the slots name (Tools/blender/animals.py). Every
// clip starts and ends in the same standing pose, so a switch at a clip's end does not snap; the
// held actions last their clip's length, and standing about loops Idle for a while.
//
// It walks by the Walk clip's own travel: the model's animator moves this entity by the clip's
// root motion (Entity mode, aimed here), so the feet never slide. Pet.as only steers (it turns the
// way it wants to go) and sets the pace (the clip's speed), slower while still turning.
class Pet
{
	Entity self;
	Scene@ scene;

	[-12.0, "Lawn's left edge (m)"] float xMin;
	[-6.0, "Lawn's right edge (m)"] float xMax;
	[9.0, "Lawn's far edge (m)"] float zMin;
	[13.0, "Lawn's near edge (m)"] float zMax;
	[0.8, "Walking speed (m/s)"] float speed;
	[0.55, "Metres the walk clip covers at speed 1 (its root motion)"] float walkMetres;
	["asset:AnimationClip", "Walk (loops)"] Guid walkClip;
	["asset:AnimationClip", "Standing about (loops)"] Guid idleClip;
	["asset:AnimationClip", "Sitting down and up again"] Guid sitClip;
	[4.0, "Sit clip's length (s)"] float sitSeconds;
	["asset:AnimationClip", "Lying down and up again"] Guid lieClip;
	[5.0, "Lie clip's length (s)"] float lieSeconds;
	["asset:AnimationClip", "Its own thing (sniffing, grooming)"] Guid ownClip;
	[3.0, "Own clip's length (s)"] float ownSeconds;

	private Entity m_model;
	private bool m_walking = false;
	private float m_toX = 0.0f;
	private float m_toZ = 0.0f;
	private float m_yaw = 0.0f;  // radians; 0 faces +Z
	private float m_left = 0.0f; // seconds left of what it is doing where it stands

	void onStart()
	{
		m_model = self.GetFirstChild();
		m_yaw = Random.Range(-3.14159f, 3.14159f);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
		// Start in the middle of something, not all walking off at once.
		doSomething();
		m_left = Random.Range(0.5f, m_left);
	}

	void onUpdate(float dt)
	{
		if (!m_walking)
		{
			m_left -= dt;
			if (m_left <= 0.0f)
			{
				walkSomewhere();
			}
			return;
		}
		Float3 p = self.GetLocalTransform().Position;
		float dx = m_toX - p.X;
		float dz = m_toZ - p.Z;
		float far = Sqrt(dx * dx + dz * dz);
		if (far < 0.05f)
		{
			doSomething();
			return;
		}
		// Turn toward the spot (the short way round, easing), and walk the way it faces, so it
		// curves round rather than sliding sideways.
		float turn = Atan2(dx, dz) - m_yaw;
		while (turn > 3.14159f) { turn -= 6.28318f; }
		while (turn < -3.14159f) { turn += 6.28318f; }
		float ease = 4.0f * dt;
		m_yaw += turn * ((ease < 1.0f) ? ease : 1.0f);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
		// Slow while still turning a long way round, so it does not orbit the spot; and slow as it
		// arrives, so the clip's travel stops on the spot rather than past it.
		float facing = Cos(turn);
		if (facing < 0.2f)
		{
			facing = 0.2f;
		}
		float arriving = far / 0.3f;
		if (arriving > 1.0f)
		{
			arriving = 1.0f;
		}
		if (arriving < 0.3f)
		{
			arriving = 0.3f;
		}
		setPace(speed * facing * arriving);
	}

	private void walkSomewhere()
	{
		m_toX = Random.Range(xMin, xMax);
		m_toZ = Random.Range(zMin, zMax);
		m_walking = true;
		playClip(walkClip);
		setPace(speed);
	}

	private void doSomething()
	{
		m_walking = false;
		int pick = Random.IntRange(0, 3);
		if (pick == 1 && !sitClip.IsNil)
		{
			playClip(sitClip);
			m_left = sitSeconds;
		}
		else if (pick == 2 && !lieClip.IsNil)
		{
			playClip(lieClip);
			m_left = lieSeconds;
		}
		else if (pick == 3 && !ownClip.IsNil)
		{
			playClip(ownClip);
			m_left = ownSeconds;
		}
		else
		{
			playClip(idleClip);
			m_left = Random.Range(2.0f, 5.0f);
		}
		if (m_model.IsValid())
		{
			SkeletalAnimationComponent(m_model).Speed = 1.0f;
		}
	}

	private void playClip(Guid clip)
	{
		if (!m_model.IsValid() || clip.IsNil)
		{
			return;
		}
		scene.Animation.SetClip(m_model, clip);
		scene.Animation.Play(m_model);
	}

	private void setPace(float pace)
	{
		if (m_model.IsValid())
		{
			SkeletalAnimationComponent(m_model).Speed = pace / walkMetres;
		}
	}
}
