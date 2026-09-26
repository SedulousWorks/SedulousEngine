// Bike - the player's ride.
//
// A per-entity behavior on the bike entity, which carries a Character component (a kinematic
// character controller: arcade feel, no ragdoll). Each frame it reads the "Move" axis (WASD in
// the default input map): Y is throttle and brake, X is steer. It keeps a heading (yaw) and a
// scalar speed, turns the heading, then drives the character with a horizontal velocity along
// that heading. The follow camera trails this entity's transform.
//
// The SAME yaw that turns local forward (+Z) into the world velocity also sets the entity's
// rotation, so the model always points where it moves.

// The paper prefab thrown on the Throw action. Keep in sync with Prefabs/Paper.
Guid kPaperPrefab = Guid::FromString("322880fe-e4b5-1844-a540-e0bc869183dd");

class Bike
{
	Entity self;
	Scene@ scene;

	// ---- tunables ----
	float maxSpeed = 9.0f;            // top forward speed (m/s)
	float reverseSpeed = 3.5f;        // top reverse speed (m/s)
	float acceleration = 14.0f;       // throttle ramp (m/s^2)
	float braking = 22.0f;            // active brake / reverse ramp (m/s^2)
	float coastDeceleration = 8.0f;   // roll-down when coasting (m/s^2)
	float turnSpeedDegrees = 130.0f;  // yaw rate at full speed (deg/s)
	float minSteerFraction = 0.25f;   // steering authority floor (0..1)

	// ---- throwing ----
	float throwImpulse = 60.0f;       // launch strength; scales with paper mass
	float throwArc = 0.65f;           // upward bias
	float autoAim = 0.6f;             // 0 = straight, 1 = locked on
	float aimRange = 18.0f;           // auto-aim range (m)
	int startingPapers = 10;          // papers per level
	int subscriberGroup = 2;          // the subscriber zones' collision group

	// ---- aim preview: a debug-drawn arc of where the throw will go ----
	float aimPreviewSpeed = 10.0f;    // visual only (m/s)
	float aimPreviewTime = 1.5f;      // seconds of arc drawn

	// ---- runtime state (private, so not authored) ----
	private float m_heading = 0.0f;   // yaw in RADIANS (0 = facing world +Z)
	private float m_speed = 0.0f;     // signed forward speed (negative = reversing)
	private int m_papers = 0;         // papers remaining
	private float m_aimX = 0.0f;      // horizontal aim direction (unit XZ)
	private float m_aimZ = 1.0f;
	private bool m_hasTarget = false; // the auto-aim locked a subscriber zone this frame
	private Float3 m_targetPos = Float3(0.0f, 0.0f, 0.0f);

	void onStart()
	{
		m_papers = startingPapers;
		updatePapersHud();
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f)
		{
			return;
		}

		Float2 move = Input.Value2D("Move");
		float throttle = move.Y; // W = +1 (forward), S = -1 (back)
		float steer = move.X;    // D = +1 (right),   A = -1 (left)

		updateSpeed(throttle, dt);
		updateHeading(steer, dt);
		applyMotion();

		// Preview the throw every frame the bike has papers; debug draw is immediate mode, so it
		// has to be re-issued from onUpdate.
		if (m_papers > 0)
		{
			computeAim();
			drawAimPreview();
		}

		// A paper is only consumed when the throw actually spawned one, so a failed prefab
		// resolve cannot burn papers toward the out-of-papers fail condition.
		if (m_papers > 0 && Input.WasPressed("Throw") && throwPaper())
		{
			m_papers -= 1;
			updatePapersHud();
			// On the LAST paper, tell the Level: it grace-waits for this one to land, then fails
			// if the quota is still unmet.
			if (m_papers == 0)
			{
				scene.Scripts.Emit("OutOfPapers", 0);
			}
		}
	}

	// Mirror the remaining paper count into the HUD (a no-op when the HUD is not shown).
	private void updatePapersHud()
	{
		Ui.FindLabel("hud-papers").SetText("Papers " + m_papers);
	}

	// Ramp the signed speed toward the throttle intent, clamped to the forward/reverse caps.
	private void updateSpeed(float throttle, float d)
	{
		if (throttle > 0.0f)
		{
			// Accelerating forward (brake harder first if we were reversing).
			float rate = (m_speed < 0.0f) ? braking : acceleration;
			m_speed += throttle * rate * d;
		}
		else if (throttle < 0.0f)
		{
			// Braking, then reversing.
			float rate = (m_speed > 0.0f) ? braking : acceleration;
			m_speed += throttle * rate * d;
		}
		else if (m_speed > 0.0f)
		{
			m_speed -= coastDeceleration * d;
			if (m_speed < 0.0f) { m_speed = 0.0f; }
		}
		else if (m_speed < 0.0f)
		{
			m_speed += coastDeceleration * d;
			if (m_speed > 0.0f) { m_speed = 0.0f; }
		}

		if (m_speed > maxSpeed) { m_speed = maxSpeed; }
		if (m_speed < -reverseSpeed) { m_speed = -reverseSpeed; }
	}

	// Turn the heading. Steering authority scales with speed (a parked bike barely turns) and
	// inverts while reversing, so backing up steers the way a vehicle actually does.
	private void updateHeading(float steer, float d)
	{
		if (steer == 0.0f || m_speed == 0.0f)
		{
			return;
		}

		float speedFraction = Abs(m_speed) / maxSpeed;
		if (speedFraction > 1.0f) { speedFraction = 1.0f; }
		if (speedFraction < minSteerFraction) { speedFraction = minSteerFraction; }

		float direction = (m_speed >= 0.0f) ? 1.0f : -1.0f;
		float turnRate = DegreesToRadians(turnSpeedDegrees);
		// A positive yaw about +Y turns local forward (+Z) toward +X, which is screen LEFT from
		// the trailing camera, so a positive steer (D = right) DECREASES the heading.
		m_heading -= steer * direction * turnRate * speedFraction * d;
	}

	// Drive the character along the heading and point the entity the same way.
	private void applyMotion()
	{
		Quaternion facing = Quaternion::FromAxisAngle(Float3(0.0f, 1.0f, 0.0f), m_heading);
		Float3 forward = RotateVector(facing, Float3(0.0f, 0.0f, 1.0f));

		scene.Physics.MoveCharacter(self, forward.X * m_speed, forward.Z * m_speed);
		self.SetLocalRotation(facing);
	}

	// The throw's HORIZONTAL aim: the bike's heading, biased by a soft auto-aim toward the
	// nearest subscriber zone in front. Fills m_aimX/m_aimZ (unit XZ) and the locked target.
	private void computeAim()
	{
		Float3 pos = self.GetWorldPosition();
		float fx = Sin(m_heading); // forward XZ, matching applyMotion: (sin h, 0, cos h)
		float fz = Cos(m_heading);

		float aimX = fx;
		float aimZ = fz;
		m_hasTarget = false;

		array<Entity> zones;
		scene.Physics.OverlapSphere(pos, aimRange, zones, uint(1 << subscriberGroup));
		float bestDist = aimRange * aimRange + 1.0f;
		for (uint i = 0; i < zones.length(); i++)
		{
			Float3 zp = zones[i].GetWorldPosition();
			float dx = zp.X - pos.X;
			float dz = zp.Z - pos.Z;
			float dist2 = dx * dx + dz * dz;
			if (dist2 < 0.0001f) { continue; }
			float len = Sqrt(dist2);
			float ndx = dx / len;
			float ndz = dz / len;
			if (ndx * fx + ndz * fz > 0.1f && dist2 < bestDist) // in front, and nearer
			{
				bestDist = dist2;
				aimX = fx + (ndx - fx) * autoAim; // lerp forward toward the zone
				aimZ = fz + (ndz - fz) * autoAim;
				m_hasTarget = true;
				m_targetPos = zp;
			}
		}
		float l = Sqrt(aimX * aimX + aimZ * aimZ);
		if (l > 0.0001f) { aimX /= l; aimZ /= l; }
		m_aimX = aimX;
		m_aimZ = aimZ;
	}

	// Debug-draw the throw's projected path: the ballistic arc under the scene's gravity, plus a
	// marker on the locked target. The launch SPEED is a visual tunable; the real throw is an
	// impulse whose speed depends on the paper's mass, so tune aimPreviewSpeed to match.
	private void drawAimPreview()
	{
		Float3 pos = self.GetWorldPosition();
		float fx = Sin(m_heading);
		float fz = Cos(m_heading);
		Float3 origin = Float3(pos.X + fx, pos.Y + 1.2f, pos.Z + fz); // the throw's spawn point

		float mag = Sqrt(1.0f + throwArc * throwArc);
		float vx = m_aimX / mag * aimPreviewSpeed;
		float vy = throwArc / mag * aimPreviewSpeed;
		float vz = m_aimZ / mag * aimPreviewSpeed;
		float g = scene.Physics.Gravity.Y;

		Color amber = Color(1.0f, 0.85f, 0.1f);
		int steps = 24;
		float step = aimPreviewTime / float(steps);
		Float3 prev = origin;
		for (int i = 1; i <= steps; i++)
		{
			float t = step * float(i);
			Float3 p = Float3(origin.X + vx * t, origin.Y + vy * t + 0.5f * g * t * t,
				origin.Z + vz * t);
			scene.Debug.Line(prev, p, amber);
			prev = p;
			if (p.Y < 0.0f) { break; } // stop at the ground plane
		}
		if (m_hasTarget)
		{
			scene.Debug.WireSphere(m_targetPos, 0.6f, Color(0.2f, 1.0f, 0.3f));
		}
	}

	// Spawn and launch a paper along the freshly computed aim. Returns whether one spawned.
	private bool throwPaper()
	{
		computeAim();
		Float3 pos = self.GetWorldPosition();
		float fx = Sin(m_heading);
		float fz = Cos(m_heading);

		// In front of and above the bike, so the paper clears it.
		Float3 origin = Float3(pos.X + fx, pos.Y + 1.2f, pos.Z + fz);
		Entity paper = scene.Prefabs.Spawn(kPaperPrefab, origin);
		if (!paper.IsValid())
		{
			return false;
		}
		// (m_aimX, throwArc, m_aimZ) with a unit horizontal: normalise so throwImpulse is the
		// magnitude.
		float mag = Sqrt(1.0f + throwArc * throwArc);
		scene.Physics.ApplyImpulse(paper, Float3(m_aimX / mag * throwImpulse,
			throwArc / mag * throwImpulse, m_aimZ / mag * throwImpulse));
		return true;
	}
}
