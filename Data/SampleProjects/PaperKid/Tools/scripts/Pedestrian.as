// Pedestrian - wanders the block on the navmesh: picks a spot around the ring road (on a verge or
// across it), walks there, picks another. The Level sets the walking speed ("PedestrianSpeed") and
// says where the ring road runs ("BlockRing"), which sets the band the walks stay in.
class Pedestrian
{
	Entity self;
	Scene@ scene;

	[1.6, "Walking speed until the Level sets one (m/s)"] float speed;
	[18.0, "Nearest the middle a walk may lead (m)"] float inner;
	[31.0, "Farthest from the middle a walk may lead (m)"] float outer;

	private bool m_walking = false;

	void onStart()
	{
		NavAgentComponent(self).MaxSpeed = speed;
		pickTarget();
	}

	void onPedestrianSpeed(float s)
	{
		speed = s;
		NavAgentComponent(self).MaxSpeed = speed;
	}

	void onBlockRing(float ring)
	{
		inner = ring - 6.0f;
		outer = ring + 7.0f;
		pickTarget();
	}

	void onUpdate(float dt)
	{
		if (m_walking && NavAgentComponent(self).Finished)
		{
			pickTarget();
		}
	}

	// A point in the band around the ring road, on one of its four sides.
	private void pickTarget()
	{
		float along = Random.Range(-outer, outer);
		float across = Random.Range(inner, outer);
		if (Random.Bool())
		{
			across = -across;
		}
		float x = along;
		float z = across;
		if (Random.Bool())
		{
			x = across;
			z = along;
		}
		NavAgentComponent(self).Navigate(Float3(x, 0.0f, z));
		m_walking = true;
	}
}
