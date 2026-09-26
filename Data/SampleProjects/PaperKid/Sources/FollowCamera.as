// FollowCamera - the third-person chase camera.
//
// A per-entity behavior on the camera entity. Each frame it springs toward a point behind and
// above its target (the bike), then aims at a spot just above it. "Behind" is wherever the camera
// already is relative to the target, flattened onto the ground plane, so the camera swings round
// lazily as the bike turns instead of snapping.
class FollowCamera
{
	Entity self;
	Scene@ scene;

	// The entity to follow (the bike).
	Entity target;
	// Distance behind the target (m).
	float distance = 7.0f;
	// Height above the target (m).
	float height = 2.2f;
	// Aim this far above the target (m).
	float lookHeight = 1.3f;
	// Position spring rate (higher = snappier).
	float positionSmoothing = 4.0f;

	void onUpdate(float dt)
	{
		if (dt <= 0.0f || !target.IsValid())
		{
			return;
		}

		Float3 targetPos = target.GetWorldPosition();
		Float3 camPos = self.GetLocalTransform().Position;

		// Horizontal direction from the target back to the camera.
		float backX = camPos.X - targetPos.X;
		float backZ = camPos.Z - targetPos.Z;
		float flatLen = Sqrt(backX * backX + backZ * backZ);
		float dirX;
		float dirZ;
		if (flatLen < 0.001f)
		{
			dirX = 0.0f; // degenerate at spawn (camera atop target): default straight behind (-Z)
			dirZ = -1.0f;
		}
		else
		{
			dirX = backX / flatLen;
			dirZ = backZ / flatLen;
		}

		Float3 desired = Float3(targetPos.X + dirX * distance, targetPos.Y + height,
			targetPos.Z + dirZ * distance);
		Float3 newPos = Lerp(camPos, desired, clamp01(positionSmoothing * dt));
		self.SetLocalPosition(newPos);

		faceToward(newPos, Float3(targetPos.X, targetPos.Y + lookHeight, targetPos.Z));
	}

	// Point the camera's forward (-Z) from `from` toward `to`.
	private void faceToward(Float3 from, Float3 to)
	{
		Float3 dir = Float3(to.X - from.X, to.Y - from.Y, to.Z - from.Z);
		float len = Length(dir);
		if (len < 0.0001f)
		{
			return;
		}
		float yaw = Atan2(-dir.X, -dir.Z);
		float pitch = -Asin(dir.Y / len);
		self.SetLocalRotation(FromYawPitchRoll(yaw, pitch, 0.0f));
	}

	private float clamp01(float v)
	{
		if (v < 0.0f) { return 0.0f; }
		if (v > 1.0f) { return 1.0f; }
		return v;
	}
}
