// Guard - walks a round with a lantern, and sees and hears the thief. On the guard's entity, which
// carries a navigation agent and the model (its graph: Speed, Searching); the lantern's spot light
// is a child, and what it lights is what he sees.
//
// - Patrol: the route's points (the children of `route`) in turn, round and round.
// - Seeing: the thief inside the lantern's cone and range, nothing between his eye and the thief's
//   chest (a ray that ignores the guards' own group), fills `awareness` by how lit the thief is
//   (scene.Render.LightAt, his own lantern included) and faster the nearer; unseen, it drains.
// - Within `touch` he notices the thief whatever the light (bumped into).
// - A shut door in his way he opens (Knock; he has the keys).
// - Suspicious at half: he stops and turns to look. Chase when full: he runs at the thief and
//   catches him within `catchDistance` (a Caught event: the thief to his checkpoint, the guards to
//   their rounds). Lose him, or hear a Noise within its reach: Search, go there and look round,
//   then back to the round.

const int kPatrol = 0;
const int kSuspicious = 1;
const int kChase = 2;
const int kSearch = 3;

class Guard
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;
	[null, "The round: its children are the points walked in turn"] Entity route;
	[null, "The lantern's spot light (a child): its cone and range are what he sees"] Entity lantern;
	[null, "The meter over his head (a UI billboard: a mark and a bar)"] Entity meter;
	[1.2, "Walking speed (m/s): the Walk clip's"] float walkSpeed;
	[4.0, "Running speed (m/s): the Run clip's"] float runSpeed;
	[1.6, "Eye height (m)"] float eyeHeight;
	[1.2, "Seconds to see a fully lit thief at arm's length"] float noticeSeconds;
	[0.15, "The light (luminance) that counts as half lit"] float halfLight;
	[0.4, "How fast awareness drains, unseen (per second)"] float forget;
	[1.0, "Catches the thief within this (m)"] float catchDistance;
	[14.0, "How far away a noise of loudness 1 is heard (m)"] float hearing;
	[4.0, "Seconds spent looking round at a searched place"] float searchSeconds;
	[1.2, "Within this (m) he feels the thief, cone or no cone: bumped into, he notices"] float touch;
	[3.0, "Seconds after a catch the guards leave the thief be (he is back at his checkpoint)"] float grace;
	[2, "The guards' collision group: their own rays look past it"] int group;

	private int m_state = kPatrol;
	private float awareness = 0.0f;
	private Entity m_point;
	private Float3 m_spot = Float3(0.0f, 0.0f, 0.0f);
	private float m_timer = 0.0f;
	private Float3 m_home = Float3(0.0f, 0.0f, 0.0f);
	private Float3 m_last = Float3(0.0f, 0.0f, 0.0f);
	private float m_yaw = 0.0f;
	private Entity m_figure;
	private float m_calm = 0.0f; // after a catch: not looking for the thief yet
	private Float3 m_heard = Float3(0.0f, 0.0f, 0.0f); // the last noise he went to look at
	private float m_knockIn = 0.0f; // until the next look for a door in his way

	void onStart()
	{
		m_home = self.GetWorldPosition();
		m_last = m_home;
		patrol();
	}

	void onUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		see(dt);
		NavAgentComponent agent = NavAgentComponent(self);
		if (m_state == kPatrol)
		{
			if (awareness >= 0.5f)
			{
				m_state = kSuspicious;
				agent.Stop();
			}
			else if (agent.Finished)
			{
				next();
			}
		}
		else if (m_state == kSuspicious)
		{
			face(thief.GetWorldPosition(), dt);
			if (awareness >= 1.0f)
			{
				m_state = kChase;
				scene.Scripts.Emit("Spotted", 0); // the game counts it (Lamplight.as)
			}
			else if (awareness < 0.25f)
			{
				search(m_spot);
			}
		}
		else if (m_state == kChase)
		{
			Float3 t = thief.GetWorldPosition();
			agent.NavigateAt(t, runSpeed, 0.5f);
			if (flatDistance(self.GetWorldPosition(), t) <= catchDistance)
			{
				// Caught: once (stand down now; the event reaches everyone next frame).
				scene.Scripts.Emit("Caught", self.GetWorldPosition());
				standDown();
			}
			else if (awareness < 0.5f)
			{
				search(m_spot); // lost him: where he was last seen
			}
		}
		else if (m_state == kSearch)
		{
			if (awareness >= 0.5f)
			{
				m_state = kSuspicious;
				agent.Stop();
			}
			else if (agent.Finished)
			{
				m_timer -= dt;
				if (m_timer <= 0.0f)
					patrol();
			}
		}
		animate(dt);
		show();
		knock(dt);
	}

	// A shut door in his way (a guard has the keys): what is just ahead of him at the waist, told
	// to open (Door.as answers on its hinge, the collider's parent). The navigation runs through
	// doorways whether their doors are open or not, so without this he would walk into one and stop.
	private void knock(float d)
	{
		m_knockIn -= d;
		if (m_knockIn > 0.0f)
			return;
		m_knockIn = 0.25f;
		Float3 p = self.GetWorldPosition();
		Float3 ahead = Float3(Sin(m_yaw), 0.0f, Cos(m_yaw)); // the model faces +Z
		uint mask = 0xFFFFFFFF & ~(uint(1) << uint(group));
		PhysicsHit hit = scene.Physics.RayCast(Float3(p.X, p.Y + 1.0f, p.Z), ahead, 1.2f, mask);
		if (!hit.Hit)
			return;
		Entity thing = hit.Entity;
		Entity hinge = thing.IsValid() ? thing.GetParent() : Entity::Invalid;
		if (hinge.IsValid())
			hinge.Send("Knock", p);
	}

	// The meter over his head: hidden while he has seen nothing, then the bar fills with his
	// awareness under a "?", and a "!" once he is after the thief.
	private void show()
	{
		if (!meter.IsValid())
			return;
		UIBillboardComponent board = UIBillboardComponent(meter);
		bool shown = awareness > 0.02f || m_state == kChase;
		board.Visible = shown;
		if (!shown)
			return;
		ViewGroup panel = board.Root;
		panel.FindProgressBar("meter").SetValue(m_state == kChase ? 1.0f : awareness);
		panel.FindLabel("mark").SetText(m_state == kChase ? "!" : "?");
	}

	// A noise: heard within its reach, it is searched (unless he is already after the thief).
	void onNoise(Float4 n)
	{
		if (m_state == kChase || m_state == kSuspicious)
			return;
		Float3 at = Float3(n.X, n.Y, n.Z);
		if (flatDistance(self.GetWorldPosition(), at) <= hearing * n.W)
		{
			m_heard = at;
			search(m_heard);
		}
	}

	// The thief caught (by any guard): back to the round, forgetting him for a while.
	void onCaught(Float3 at)
	{
		standDown();
	}

	private void standDown()
	{
		awareness = 0.0f;
		m_calm = grace;
		NavAgentComponent(self).Stop();
		patrol();
	}

	// How much of the thief this guard sees this frame, into awareness.
	private void see(float d)
	{
		float rate = -forget;
		if (m_calm > 0.0f)
		{
			m_calm -= d;
			awareness = 0.0f;
			return;
		}
		if (thief.IsValid() && lantern.IsValid())
		{
			Float3 eye = self.GetWorldPosition();
			eye = Float3(eye.X, eye.Y + eyeHeight, eye.Z);
			Float3 t = thief.GetWorldPosition();
			Float3 chest = Float3(t.X, t.Y + 0.4f, t.Z);
			Float3 to = Float3(chest.X - eye.X, chest.Y - eye.Y, chest.Z - eye.Z);
			float dist = Sqrt(to.X * to.X + to.Y * to.Y + to.Z * to.Z);
			LightComponent cone = LightComponent(lantern);
			Float3 ahead = RotateVector(lantern.GetWorldRotation(), Float3(0.0f, 0.0f, -1.0f));
			float cosAngle = dist > 0.001f ? (to.X * ahead.X + to.Y * ahead.Y + to.Z * ahead.Z) / dist : 1.0f;
			uint mask = 0xFFFFFFFF & ~(uint(1) << uint(group));
			if (dist < cone.Range && cosAngle >= Cos(cone.OuterAngle))
			{
				PhysicsHit hit = scene.Physics.RayCast(eye, Float3(to.X / dist, to.Y / dist, to.Z / dist), dist, mask);
				if (!hit.Hit)
				{
					Float3 light = scene.Render.LightAt(chest, mask);
					float lum = 0.2126f * light.X + 0.7152f * light.Y + 0.0722f * light.Z;
					float lit = lum / (lum + halfLight);
					float near = 1.0f - dist / cone.Range;
					rate = lit * (0.4f + 0.6f * near) / noticeSeconds;
					m_spot = t;
				}
			}
		}
		if (thief.IsValid() && flatDistance(self.GetWorldPosition(), thief.GetWorldPosition()) <= touch)
		{
			rate = 2.0f; // too close to miss
			m_spot = thief.GetWorldPosition();
		}
		awareness += rate * d;
		awareness = awareness < 0.0f ? 0.0f : (awareness > 1.0f ? 1.0f : awareness);
	}

	private void patrol()
	{
		m_state = kPatrol;
		if (!m_point.IsValid())
			m_point = route.IsValid() ? route.GetFirstChild() : Entity::Invalid;
		go(m_point, walkSpeed);
	}

	private void next()
	{
		if (m_point.IsValid())
			m_point = m_point.GetNextSibling();
		if (!m_point.IsValid() && route.IsValid())
			m_point = route.GetFirstChild();
		go(m_point, walkSpeed);
	}

	private void go(Entity point, float speed)
	{
		if (!point.IsValid())
			return;
		NavAgentComponent(self).NavigateAt(point.GetWorldPosition(), speed, 0.3f);
	}

	private void search(Float3 at)
	{
		m_state = kSearch;
		m_timer = searchSeconds;
		NavAgentComponent(self).NavigateAt(at, walkSpeed, 0.6f);
	}

	// The body faces where it goes, or (suspicious) the thief; the graph follows the speed.
	private void animate(float d)
	{
		Float3 p = self.GetWorldPosition();
		float vx = (p.X - m_last.X) / d;
		float vz = (p.Z - m_last.Z) / d;
		m_last = p;
		float speed = Sqrt(vx * vx + vz * vz);
		if (speed > 0.2f && m_state != kSuspicious)
			face(Float3(p.X + vx, p.Y, p.Z + vz), d);
		Entity fig = figure();
		if (fig.IsValid())
		{
			scene.Animation.SetFloat(fig, "Speed", speed);
			scene.Animation.SetBool(fig, "Searching", (m_state == kSearch && speed < 0.2f) || m_state == kSuspicious);
		}
	}

	private void face(Float3 at, float d)
	{
		Float3 p = self.GetWorldPosition();
		float want = Atan2(at.X - p.X, at.Z - p.Z); // the model faces +Z
		float delta = want - m_yaw;
		while (delta > 3.14159265f) delta -= 6.2831853f;
		while (delta < -3.14159265f) delta += 6.2831853f;
		float k = 8.0f * d;
		m_yaw += delta * (k > 1.0f ? 1.0f : k);
		self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
	}

	private float flatDistance(Float3 a, Float3 b)
	{
		float dx = a.X - b.X;
		float dz = a.Z - b.Z;
		return Sqrt(dx * dx + dz * dz);
	}

	// The model's skinned mesh, which carries the graph: Guard (the instance) / GuardRig / Guard.
	private Entity figure()
	{
		if (!m_figure.IsValid())
		{
			Entity model = self.FindChildByName("Guard");
			Entity rig = model.IsValid() ? model.FindChildByName("GuardRig") : Entity::Invalid;
			m_figure = rig.IsValid() ? rig.FindChildByName("Guard") : Entity::Invalid;
		}
		return m_figure;
	}
}
