// Vehicle - drives laps of the ring road on the navmesh, corner to corner, in its lane: the ring it
// is placed on (its distance from the middle along the nearer axis), so one prefab drives any
// block's ring. Inner lanes lap clockwise, outer ones anticlockwise (`direction`). The Level sets
// the speed ("TrafficSpeed").
class Vehicle
{
	Entity self;
	Scene@ scene;

	[1, "1 laps clockwise (seen from above), -1 anticlockwise"] int direction;
	[6.0, "Driving speed until the Level sets one (m/s)"] float speed;

	private int m_corner = 0;
	private float m_lane = 22.0f;

	void onStart()
	{
		NavAgentComponent(self).MaxSpeed = speed;
		// Head for the corner ahead of where the car stands.
		Float3 at = self.GetWorldPosition();
		m_lane = Abs(at.X) > Abs(at.Z) ? Abs(at.X) : Abs(at.Z);
		m_corner = nearestCorner(at);
		advance();
	}

	void onTrafficSpeed(float s)
	{
		speed = s;
		NavAgentComponent(self).MaxSpeed = speed;
	}

	void onUpdate(float dt)
	{
		NavAgentComponent agent = NavAgentComponent(self);
		if (agent.Finished)
		{
			advance();
		}
		// Face the way it drives.
		Float3 v = agent.DesiredVelocity;
		if (v.X * v.X + v.Z * v.Z > 0.25f)
		{
			self.SetLocalRotation(FromYawPitchRoll(Atan2(v.X, v.Z), 0.0f, 0.0f));
		}
	}

	private void advance()
	{
		m_corner = (m_corner + direction + 4) % 4;
		NavAgentComponent(self).Navigate(corner(m_corner));
	}

	// The ring's corners, clockwise seen from above (+Y): north-west, north-east, south-east,
	// south-west, on this car's lane.
	private Float3 corner(int index)
	{
		if (index == 0) { return Float3(-m_lane, 0.0f, -m_lane); }
		if (index == 1) { return Float3(m_lane, 0.0f, -m_lane); }
		if (index == 2) { return Float3(m_lane, 0.0f, m_lane); }
		return Float3(-m_lane, 0.0f, m_lane);
	}

	private int nearestCorner(Float3 at)
	{
		int best = 0;
		float bestDist = 1.0e9f;
		for (int i = 0; i < 4; i++)
		{
			Float3 c = corner(i);
			float d = (c.X - at.X) * (c.X - at.X) + (c.Z - at.Z) * (c.Z - at.Z);
			if (d < bestDist)
			{
				bestDist = d;
				best = i;
			}
		}
		return best;
	}
}
