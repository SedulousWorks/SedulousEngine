// FollowCamera - the chase camera: it springs toward a seat behind and above the target and aims at
// it. "Behind" is the camera's own lag: as the rider goes on, the camera falls back, so the ground
// direction from the rider back to the camera already points the right way.
class FollowCamera
{
	Entity self;

	[null, "The entity to follow (the rider)"] Entity target;
	[8.0, "Distance behind the target (m)"] float distance;
	[3.4, "Height above the target (m)"] float height;
	[1.2, "Aim this far above the target (m)"] float lookHeight;
	[4.5, "Position spring rate (higher = snappier)"] float positionSmoothing;
	[0.35, "How long a crash shakes the camera (s)"] float shakeTime;
	[0.35, "How far a crash shakes it at first (m)"] float shakeAmount;
	[40.0, "A target this far from the seat has jumped: the camera snaps to it (m)"] float snapDistance;

	// The follow works on an unshaken position; a crash's shake is added only to where the camera
	// is drawn, dying away, so it never pulls the follow off course.
	private Float3 m_base = Float3(0.0f, 0.0f, 0.0f);
	private float m_shake = 0.0f;
	private bool m_reseat = false; // a new run: seat behind the rider again on the next update

	void onStart()
	{
		seatBehind();
	}

	// A new run puts the rider back at the top: the camera goes straight behind it again. Its lag
	// would otherwise seat it on the side it was last on (downhill, at the finish), facing the
	// rider. On the next update, once the board has turned the rider back down the course.
	void onRunRestart(int unused)
	{
		m_reseat = true;
	}

	// Straight behind the rider's facing, not wherever the scene or the last run left the camera.
	private void seatBehind()
	{
		if (!target.IsValid())
			return;
		Float3 at = target.GetWorldPosition();
		Float3 back = RotateVector(target.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, -1.0f));
		Float3 seat = Float3(at.X + back.X * distance, at.Y + height, at.Z + back.Z * distance);
		self.SetLocalPosition(seat);
		m_base = seat;
		faceToward(seat, Float3(at.X, at.Y + lookHeight, at.Z));
	}

	void onRiderCrashed(int count)
	{
		m_shake = shakeTime;
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f || !target.IsValid())
			return;
		if (m_reseat)
		{
			m_reseat = false;
			seatBehind();
			return;
		}
		// This frame's pose: physics has already written the rider's interpolated position, and a
		// world position read in an update is current.
		Float3 at = target.GetWorldPosition();
		Float3 cam = m_base;
		float backX = cam.X - at.X;
		float backZ = cam.Z - at.Z;
		float flat = Sqrt(backX * backX + backZ * backZ);
		if (flat < 0.001f)
		{
			backX = 0.0f;
			backZ = 1.0f;
			flat = 1.0f;
		}
		Float3 seat = Float3(at.X + backX / flat * distance, at.Y + height, at.Z + backZ / flat * distance);
		// A jump of the target (a respawn back at the top) snaps the seat rather than flying the
		// camera the length of the course behind it.
		if (LengthSquared(seat - cam) > snapDistance * snapDistance)
			cam = seat;
		Float3 next = Lerp(cam, seat, clamp01(positionSmoothing * dt));
		m_base = next;
		if (m_shake > 0.0f)
		{
			m_shake -= dt;
			float k = shakeAmount * clamp01(m_shake / shakeTime);
			next = next + Float3(Random.Range(-k, k), Random.Range(-k, k), Random.Range(-k, k));
		}
		self.SetLocalPosition(next);
		faceToward(next, Float3(at.X, at.Y + lookHeight, at.Z));
	}

	// Engine forward is -Z: yaw = atan2(-dir.x, -dir.z); a positive pitch looks up.
	private void faceToward(Float3 from, Float3 to)
	{
		Float3 dir = to - from;
		float len = Length(dir);
		if (len < 0.0001f)
			return;
		self.SetLocalRotation(FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}

	private float clamp01(float v)
	{
		if (v < 0.0f) return 0.0f;
		if (v > 1.0f) return 1.0f;
		return v;
	}
}
