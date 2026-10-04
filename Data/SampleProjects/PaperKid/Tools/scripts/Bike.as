// Bike - the player's ride, on the Bike entity (a Character component: a kinematic capsule).
//
// "Move": Y is throttle and brake, X steers. The bike keeps a heading and a signed speed, turns
// the heading (harder the faster it goes, and reversed while backing up), drives the character
// along it, and points the entity the same way.
//
// "Throw" launches a paper along the aim: the bike's forward, biased toward the nearest delivery
// zone in front (the soft auto-aim), with an upward arc. The Level owns the paper count: each
// throw is "PaperThrown", and the Level answers with "PapersLeft".
//
// A crash ("Crashed", sent by an Obstacle) knocks the bike back against the way it was going and
// leaves the steering and throttle weak for a moment; the Level takes the time penalty.
//
// The feel: the bike leans into its turns (harder the faster it goes) and wobbles while it
// recovers from a crash, which kicks up road dust; a throw and a crash each have their sound,
// pitched a little at random so repeats do not sound the same, and each kicks the pad (a crash a
// heavy jolt, a throw a flick). A cleared block bursts confetti over the rider. Near a subscriber,
// the throw is shown before it is made: a trail of glowing dots along the path a paper would take,
// drifting forward, and a ring spinning on the porch the throw is pulled toward (the AimDot and
// TargetRing prefabs, spawned once and moved each frame).

Guid kPaper = Guid::FromString("{{Prefab:Newspaper}}");
Guid kAimDot = Guid::FromString("{{Prefab:AimDot}}");
Guid kTargetRing = Guid::FromString("{{Prefab:TargetRing}}");
Guid kFxDust = Guid::FromString("{{Prefab:FxDust}}");
Guid kFxConfetti = Guid::FromString("{{Prefab:FxConfetti}}");

const int kAimDots = 14;
const float kAimStep = 0.09f; // flight seconds between dots
Guid kThrowSound = Guid::FromString("{{Throw}}");
Guid kCrashSound = Guid::FromString("{{Crash}}");

class Bike
{
	Entity self;
	Scene@ scene;

	[11.0, "Top forward speed (m/s)"] float maxSpeed;
	[3.5, "Top reverse speed (m/s)"] float reverseSpeed;
	[10.0, "Throttle ramp (m/s^2)"] float acceleration;
	[22.0, "Brake ramp (m/s^2)"] float braking;
	[5.0, "Roll-down when coasting (m/s^2)"] float coastDeceleration;
	[120.0, "Turn rate at full speed (deg/s)"] float turnSpeedDegrees;
	[0.3, "Steering authority at a crawl (0..1)"] float minSteerFraction;

	[9.0, "Throw speed (m/s)"] float throwSpeed;
	[0.55, "Throw arc (upward share)"] float throwArc;
	[0.85, "Auto-aim strength (0 = straight ahead, 1 = lands on the zone)"] float autoAim;
	[16.0, "Auto-aim reach (m)"] float aimRange;
	[2, "The delivery zones' collision group"] int zoneGroup;

	[1.5, "After a crash, how long the controls stay weak (s)"] float crashTime;
	[0.25, "The controls' strength while recovering (0..1)"] float crashControl;
	[4.0, "The speed a crash knocks the bike back at (m/s)"] float knockback;
	[14.0, "Lean into a turn at full speed (deg)"] float maxLean;

	private float m_heading = 0.0f; // radians; 0 faces +Z
	private float m_speed = 0.0f;
	private int m_papers = -1;      // -1: the Level has not said yet
	private float m_aimX = 0.0f;
	private float m_aimZ = 1.0f;
	private bool m_hasTarget = false;
	private Float3 m_target = Float3(0.0f, 0.0f, 0.0f);
	private float m_recovering = 0.0f; // seconds of weak controls left after a crash
	private float m_lean = 0.0f;       // degrees, eased toward the steering
	private array<Entity> m_dots;
	private Entity m_ring;
	private float m_clock = 0.0f;      // drives the dots' drift and the ring's spin

	void onStart()
	{
		// Start facing the way the scene placed the bike.
		Float3 forward = RotateVector(self.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, 1.0f));
		m_heading = Atan2(forward.X, forward.Z);
		// The throw's guides, hidden until there is a throw to show.
		Float3 at = self.GetLocalTransform().Position;
		for (int i = 0; i < kAimDots; i++)
		{
			Entity dot = scene.Prefabs.Spawn(kAimDot, at);
			if (dot.IsValid())
			{
				dot.SetActive(false);
				m_dots.insertLast(dot);
			}
		}
		m_ring = scene.Prefabs.Spawn(kTargetRing, at);
		if (m_ring.IsValid())
		{
			m_ring.SetActive(false);
		}
	}

	void onPapersLeft(int papers)
	{
		m_papers = papers;
	}

	void onCrashed()
	{
		if (m_recovering > 0.0f)
		{
			return; // still down from the last one
		}
		m_recovering = crashTime;
		// Bounce back against the way the bike was going: off whatever it ran into.
		m_speed = (m_speed >= 0.0f) ? -knockback : knockback;
		Audio.PlayOneShot(kCrashSound, AudioBus::Effects, 1.0f, Random.Range(0.9f, 1.1f));
		Input.Rumble(0.9f, 0.5f, 0.35f); // the jolt of a crash
		// Road dust off the wheels (the bike's centre is 0.9 above them).
		scene.Prefabs.Spawn(kFxDust, self.GetLocalTransform().Position + Float3(0.0f, -0.8f, 0.0f));
		scene.Scripts.Emit("BikeCrashed", 1);
	}

	// The block is cleared: confetti bursts over the rider, and hangs in the slow motion after.
	void onQuotaMet(int secondsLeft)
	{
		scene.Prefabs.Spawn(kFxConfetti, self.GetLocalTransform().Position + Float3(0.0f, 1.6f, 0.0f));
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f)
		{
			return;
		}
		Float2 move = Input.Value2D("Move");
		if (m_recovering > 0.0f)
		{
			m_recovering -= dt;
			move = Float2(move.X * crashControl, move.Y * crashControl);
		}
		updateSpeed(move.Y, dt);
		updateHeading(move.X, dt);
		Float3 forward = facing();
		CharacterComponent(self).Move(forward.X * m_speed, forward.Z * m_speed);
		// Lean into the turn (a positive roll tips the top toward screen right from behind, the
		// way a right turn leans), eased so it settles rather than snaps; wobble while recovering.
		float authority = Abs(m_speed) / maxSpeed;
		if (authority > 1.0f) { authority = 1.0f; }
		float lean = move.X * maxLean * authority;
		m_lean += (lean - m_lean) * clamp01(8.0f * dt);
		float wobble = (m_recovering > 0.0f) ? Sin(m_recovering * 24.0f) * 9.0f * (m_recovering / crashTime) : 0.0f;
		self.SetLocalRotation(FromYawPitchRoll(m_heading, 0.0f, DegreesToRadians(m_lean + wobble)));

		m_clock += dt;
		if (m_papers == 0)
		{
			hideGuides();
		}
		else
		{
			computeAim();
			placeGuides();
			if (Input.WasPressed("Throw") && throwPaper())
			{
				Audio.PlayOneShot(kThrowSound, AudioBus::Effects, 0.8f, Random.Range(0.9f, 1.15f));
				Input.Rumble(0.0f, 0.25f, 0.05f); // the flick of a throw
				scene.Scripts.Emit("PaperThrown", 1);
			}
		}
	}

	private float clamp01(float v)
	{
		if (v < 0.0f) { return 0.0f; }
		if (v > 1.0f) { return 1.0f; }
		return v;
	}

	private Float3 facing()
	{
		return Float3(Sin(m_heading), 0.0f, Cos(m_heading));
	}

	private void updateSpeed(float throttle, float dt)
	{
		if (throttle > 0.0f)
		{
			m_speed += throttle * ((m_speed < 0.0f) ? braking : acceleration) * dt;
		}
		else if (throttle < 0.0f)
		{
			m_speed += throttle * ((m_speed > 0.0f) ? braking : acceleration) * dt;
		}
		else if (m_speed > 0.0f)
		{
			m_speed -= coastDeceleration * dt;
			if (m_speed < 0.0f) { m_speed = 0.0f; }
		}
		else if (m_speed < 0.0f)
		{
			m_speed += coastDeceleration * dt;
			if (m_speed > 0.0f) { m_speed = 0.0f; }
		}
		if (m_speed > maxSpeed) { m_speed = maxSpeed; }
		if (m_speed < -reverseSpeed) { m_speed = -reverseSpeed; }
	}

	// A positive yaw turns +Z toward +X, which is screen left from behind: right steer lowers it.
	private void updateHeading(float steer, float dt)
	{
		if (steer == 0.0f || m_speed == 0.0f)
		{
			return;
		}
		float authority = Abs(m_speed) / maxSpeed;
		if (authority > 1.0f) { authority = 1.0f; }
		if (authority < minSteerFraction) { authority = minSteerFraction; }
		float direction = (m_speed >= 0.0f) ? 1.0f : -1.0f;
		m_heading -= steer * direction * DegreesToRadians(turnSpeedDegrees) * authority * dt;
	}

	// The throw's horizontal aim: forward, pulled toward the nearest zone in front.
	private void computeAim()
	{
		Float3 pos = self.GetWorldPosition();
		Float3 f = facing();
		float aimX = f.X;
		float aimZ = f.Z;
		m_hasTarget = false;
		array<Entity> zones;
		scene.Physics.OverlapSphere(pos, aimRange, zones, uint(1) << uint(zoneGroup));
		float best = aimRange * aimRange + 1.0f;
		for (uint i = 0; i < zones.length(); i++)
		{
			Float3 z = zones[i].GetWorldPosition();
			float dx = z.X - pos.X;
			float dz = z.Z - pos.Z;
			float dist2 = dx * dx + dz * dz;
			if (dist2 < 0.0001f)
			{
				continue;
			}
			float len = Sqrt(dist2);
			if ((dx / len) * f.X + (dz / len) * f.Z > 0.1f && dist2 < best)
			{
				best = dist2;
				aimX = f.X + (dx / len - f.X) * autoAim;
				aimZ = f.Z + (dz / len - f.Z) * autoAim;
				m_hasTarget = true;
				m_target = z;
			}
		}
		float l = Sqrt(aimX * aimX + aimZ * aimZ);
		m_aimX = aimX / l;
		m_aimZ = aimZ / l;
	}

	private Float3 launchPoint()
	{
		Float3 pos = self.GetWorldPosition();
		Float3 f = facing();
		// Above the rider's head, so the paper never meets the bike's own capsule on the way out.
		return Float3(pos.X + f.X * 0.6f, pos.Y + 1.6f, pos.Z + f.Z * 0.6f);
	}

	// The paper's launch velocity: along the aim at the throw speed, plus the bike's own speed.
	// With a zone locked, the ground part leans (by autoAim) toward the velocity that lands the
	// paper on the zone in its flight time - the soft auto-aim corrects the range as well as the
	// direction, so a throw at a marked porch from a moving bike usually lands.
	private Float3 launchVelocity()
	{
		float mag = Sqrt(1.0f + throwArc * throwArc);
		Float3 carry = facing() * m_speed;
		float vx = m_aimX / mag * throwSpeed + carry.X;
		float vy = throwArc / mag * throwSpeed;
		float vz = m_aimZ / mag * throwSpeed + carry.Z;
		if (m_hasTarget)
		{
			Float3 from = launchPoint();
			float g = -scene.Physics.Gravity.Y;
			float drop = from.Y - (m_target.Y + 0.4f);
			float flight = (vy + Sqrt(vy * vy + 2.0f * g * drop)) / g;
			if (flight > 0.05f)
			{
				vx += ((m_target.X - from.X) / flight - vx) * autoAim;
				vz += ((m_target.Z - from.Z) / flight - vz) * autoAim;
			}
		}
		return Float3(vx, vy, vz);
	}

	// The throw's path, under the scene's gravity: a dot every kAimStep seconds of flight, the
	// row drifting forward one step each half second and shrinking toward its end, stopped where
	// the path meets the ground. The ring sits on the zone the throw is pulled toward. Both show
	// only while a subscriber is in reach, so the road stays clear between houses.
	private void placeGuides()
	{
		if (!m_hasTarget)
		{
			hideGuides();
			return;
		}
		Float3 p = launchPoint();
		Float3 v = launchVelocity();
		float g = scene.Physics.Gravity.Y;
		float drift = (m_clock * 2.0f) - float(int(m_clock * 2.0f));
		bool landed = false;
		for (uint i = 0; i < m_dots.length(); i++)
		{
			float t = kAimStep * (float(i) + drift + 0.5f);
			float y = p.Y + v.Y * t + 0.5f * g * t * t;
			if (landed || y < 0.0f)
			{
				landed = true;
				m_dots[i].SetActive(false);
				continue;
			}
			m_dots[i].SetActive(true);
			m_dots[i].SetLocalPosition(Float3(p.X + v.X * t, y, p.Z + v.Z * t));
			float size = 1.0f - 0.45f * (float(i) / float(m_dots.length()));
			m_dots[i].SetLocalScale(Float3(size, size, size));
		}
		if (!m_ring.IsValid())
		{
			return;
		}
		m_ring.SetActive(true);
		m_ring.SetLocalPosition(Float3(m_target.X, 0.02f, m_target.Z));
		m_ring.SetLocalRotation(FromYawPitchRoll(DegreesToRadians(m_clock * 70.0f), 0.0f, 0.0f));
		float pulse = 1.0f + 0.08f * Sin(m_clock * 6.0f);
		m_ring.SetLocalScale(Float3(pulse, 1.0f, pulse));
	}

	private void hideGuides()
	{
		for (uint i = 0; i < m_dots.length(); i++)
		{
			m_dots[i].SetActive(false);
		}
		if (m_ring.IsValid())
		{
			m_ring.SetActive(false);
		}
	}

	private bool throwPaper()
	{
		Entity paper = scene.Prefabs.Spawn(kPaper, launchPoint());
		if (!paper.IsValid())
		{
			return false;
		}
		// An impulse is mass times the change in speed; the paper's mass is its rigid body's.
		float mass = RigidBodyComponent(paper).Mass;
		if (mass <= 0.0f)
		{
			mass = 1.0f;
		}
		scene.Physics.ApplyImpulse(paper, launchVelocity() * mass);
		return true;
	}
}
