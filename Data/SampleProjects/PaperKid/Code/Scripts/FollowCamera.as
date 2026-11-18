// FollowCamera - the chase camera: it springs toward a seat behind and above the target and aims at
// it. "Behind" is the camera's own lag: as the bike rides on, the camera falls back, so the ground
// direction from the bike back to the camera already points the right way. A crash ("BikeCrashed")
// shakes it.
class FollowCamera
{
	Entity self;
	Scene@ scene;

	[null, "The entity to follow (the bike)"] Entity target;
	[8.0, "Distance behind the target (m)"] float distance;
	[3.4, "Height above the target (m)"] float height;
	[1.2, "Aim this far above the target (m)"] float lookHeight;
	[4.5, "Position spring rate (higher = snappier)"] float positionSmoothing;
	[0.35, "How long a crash shakes the camera (s)"] float shakeTime;
	[0.35, "How far a crash shakes it at first (m)"] float shakeAmount;

	// The follow works on an unshaken position; a crash's shake is added only to where the camera
	// is drawn, dying away, so it never pulls the follow off course.
	private Float3 m_base = Float3(0.0f, 0.0f, 0.0f);
	private float m_shake = 0.0f;

	void onStart()
	{
		if (!target.IsValid())
		{
			return;
		}
		// Start straight behind the bike's facing, not wherever the scene put the camera.
		Float3 at = target.GetWorldPosition();
		Float3 back = RotateVector(target.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, -1.0f));
		Float3 seat = Float3(at.X + back.X * distance, at.Y + height, at.Z + back.Z * distance);
		self.SetLocalPosition(seat);
		m_base = seat;
		faceToward(seat, Float3(at.X, at.Y + lookHeight, at.Z));
	}

	void onBikeCrashed(int count)
	{
		m_shake = shakeTime;
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f || !target.IsValid())
		{
			return;
		}
		// The target's LOCAL position (the bike is a root): physics has already written this
		// frame's interpolated pose there.
		Float3 at = target.GetLocalTransform().Position;
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
		float len = Sqrt(dir.X * dir.X + dir.Y * dir.Y + dir.Z * dir.Z);
		if (len < 0.0001f)
		{
			return;
		}
		self.SetLocalRotation(FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}

	private float clamp01(float v)
	{
		if (v < 0.0f) { return 0.0f; }
		if (v > 1.0f) { return 1.0f; }
		return v;
	}
}
