// FollowCamera - a platformer camera: behind and above the player at a fixed offset, springing
// after it and aiming just above it. The offset never turns, so the controls stay world
// relative: forward is always away from the camera.
class FollowCamera
{
	Entity self;
	Scene@ scene;

	[null, "The entity to follow (the player)"] Entity target;
	[11.0, "Distance behind the target (m)"] float distance;
	[6.0, "Height above the target (m)"] float height;
	[1.0, "Aim this far above the target (m)"] float lookHeight;
	[5.0, "Position spring rate (higher = snappier)"] float positionSmoothing;
	[6.0, "How fast a shake dies away (per second)"] float shakeDecay;

	/// The shake's strength now (m), set by "Shake" and decaying to nothing.
	private float m_shake = 0.0f;
	/// Where the follow has the camera, before any shake.
	private Float3 m_followPos = Float3(0.0f, 0.0f, 0.0f);

	// Something jolted the view: a hit, a landing from high up. Strength in metres.
	void onShake(float strength)
	{
		if (strength > m_shake)
		{
			m_shake = strength;
		}
	}

	void onStart()
	{
		if (target.IsValid())
		{
			Float3 at = target.GetWorldPosition();
			Float3 start = Float3(at.X, at.Y + height, at.Z + distance);
			self.SetLocalPosition(start);
			m_followPos = start;
			faceToward(start, Float3(at.X, at.Y + lookHeight, at.Z));
		}
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f || !target.IsValid())
		{
			return;
		}
		Float3 at = target.GetWorldPosition();
		Float3 desired = Float3(at.X, at.Y + height, at.Z + distance);
		Float3 newPos = Lerp(m_followPos, desired, clamp01(positionSmoothing * dt));
		m_followPos = newPos;
		self.SetLocalPosition(newPos);
		faceToward(newPos, Float3(at.X, at.Y + lookHeight, at.Z));
		// The shake rides on top of the follow, which never sees it.
		if (m_shake > 0.001f)
		{
			self.SetLocalPosition(newPos + Float3(Random.Range(-m_shake, m_shake), Random.Range(-m_shake, m_shake), 0.0f));
			m_shake -= m_shake * clamp01(shakeDecay * dt);
		}
	}

	// Tilt the camera's forward (-Z) down toward `to`. The camera never turns (it always looks
	// down -Z), so the aim is a pitch alone: a rotation about +X, negative to look down.
	private void faceToward(Float3 from, Float3 to)
	{
		float dy = to.Y - from.Y;
		float dz = from.Z - to.Z;
		if (Abs(dy) + Abs(dz) < 0.0001f)
		{
			return;
		}
		self.SetLocalRotation(Quaternion::FromAxisAngle(Float3::UnitX, Atan2(dy, dz)));
	}

	private float clamp01(float v)
	{
		if (v < 0.0f) { return 0.0f; }
		if (v > 1.0f) { return 1.0f; }
		return v;
	}
}
