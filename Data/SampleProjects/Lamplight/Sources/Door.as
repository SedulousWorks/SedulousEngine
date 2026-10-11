// Door - a door on its hinge (this entity, at the hinge edge; the leaf and its kinematic collider
// are children, so they swing with it). Locked, it is picked by holding Interact at it: the thief's
// hand goes to the lock (two-bone IK on the thief, TwoBoneIkComponent), a bar fills on the HUD,
// and letting go starts the pick over. Unlocked, Interact opens it away from the thief and closes
// it again. A guard who comes to it (Knock) opens it, locked or not: guards have the keys.

const float kDoorPi = 3.14159265f;

class Door
{
	Entity self;
	Scene@ scene;

	[null, "The thief (it carries the hand's two-bone IK)"] Entity thief;
	[true, "Locked at the start"] bool locked;
	[3.0, "Seconds of holding Interact to pick the lock"] float pickSeconds;
	[0.8, "How near the lock the thief must stand (m): within an arm's reach"] float reach;
	[0.0, "The door's yaw when shut (degrees; the leaf runs along +X from the hinge)"] float shutYaw;
	[0.94, "The lock's distance along the leaf from the hinge (m)"] float lockAlong;
	[1.0, "The lock's height (m)"] float lockHeight;
	[100.0, "How far it swings open (degrees)"] float openAngle;
	[160.0, "How fast it swings (degrees a second)"] float swingSpeed;

	private float m_angle = 0.0f;
	private float m_target = 0.0f;
	private float m_pick = 0.0f;
	private bool m_picking = false;
	private bool m_prompting = false;

	void onStart()
	{
		turn(shutYaw);
	}

	void onUpdate(float dt)
	{
		if (!thief.IsValid())
			return;
		float yaw = shutYaw * kDoorPi / 180.0f;
		Float3 hinge = self.GetWorldPosition();
		Float3 along = Float3(Cos(yaw), 0.0f, -Sin(yaw)); // the shut leaf, hinge to lock
		Float3 normal = Float3(Sin(yaw), 0.0f, Cos(yaw)); // its face
		Float3 t = thief.GetWorldPosition();
		float side = (t.X - hinge.X) * normal.X + (t.Z - hinge.Z) * normal.Z >= 0.0f ? 1.0f : -1.0f;
		// The lock on the thief's face of the shut leaf.
		Float3 lock = Float3(hinge.X + along.X * lockAlong + normal.X * side * 0.05f, hinge.Y + lockHeight,
		                     hinge.Z + along.Z * lockAlong + normal.Z * side * 0.05f);
		float dx = lock.X - t.X;
		float dz = lock.Z - t.Z;
		bool near = dx * dx + dz * dz <= reach * reach && m_angle == 0.0f;

		bool picking = locked && near && Input.IsDown("Interact");
		if (picking)
		{
			m_pick += dt;
			scene.Animation.SetIkTarget(thief, lock);
			scene.Scripts.Emit("Picking", lock);
			if (m_pick >= pickSeconds)
			{
				locked = false;
				picking = false;
			}
		}
		else
		{
			m_pick = 0.0f; // let go: the pick starts over
		}
		if (picking != m_picking)
		{
			m_picking = picking;
			TwoBoneIkComponent ik = TwoBoneIkComponent(thief);
			ik.Weight = picking ? 1.0f : 0.0f;
		}
		if (!locked && Input.WasPressed("Interact") && (near || m_target != 0.0f))
		{
			// Open away from the thief (turned by a, the leaf points along (cos a, 0, -sin a), so
			// away from the thief's side is a = side x the angle); shut again from either side.
			m_target = m_target != 0.0f ? 0.0f : side * openAngle;
		}
		float step = swingSpeed * dt;
		float delta = m_target - m_angle;
		m_angle = Abs(delta) <= step ? m_target : m_angle + (delta > 0.0f ? step : -step);
		turn(shutYaw + m_angle);
		prompt(near || (!locked && m_target != 0.0f && dx * dx + dz * dz <= 4.0f * reach * reach));
	}

	// A guard at the door (Guard.as knocks): he has the keys, so a shut door opens away from him,
	// locked or not, and stays open behind him.
	void onKnock(Float3 at)
	{
		if (m_target != 0.0f || m_angle != 0.0f)
			return;
		float yaw = shutYaw * kDoorPi / 180.0f;
		Float3 hinge = self.GetWorldPosition();
		float side = (at.X - hinge.X) * Sin(yaw) + (at.Z - hinge.Z) * Cos(yaw) >= 0.0f ? 1.0f : -1.0f;
		locked = false;
		m_target = side * openAngle;
	}

	// The hinge turned to `degrees` about up (the hinge is a root, so its own turn is its turn in
	// the world).
	private void turn(float degrees)
	{
		self.SetLocalRotation(FromYawPitchRoll(degrees * kDoorPi / 180.0f, 0.0f, 0.0f));
	}

	// The HUD's prompt and the pick's progress while in reach; cleared on leaving, only by the door
	// that set it.
	private void prompt(bool show)
	{
		if (show)
		{
			Label text = Ui.FindLabel("hud-prompt");
			if (text.IsValid)
			{
				text.SetText(locked ? (m_picking ? "Picking the lock..." : "Hold Interact: pick the lock")
				                    : (m_target != 0.0f ? "Interact: close the door" : "Interact: open the door"));
			}
			Ui.Find("hud-prompt-panel").SetVisible(true);
			ProgressBar bar = Ui.FindProgressBar("hud-pick");
			if (bar.IsValid)
			{
				bar.SetVisible(m_picking);
				bar.SetValue(m_pick / pickSeconds);
			}
			m_prompting = true;
		}
		else if (m_prompting)
		{
			Ui.Find("hud-prompt-panel").SetVisible(false);
			m_prompting = false;
		}
	}
}
